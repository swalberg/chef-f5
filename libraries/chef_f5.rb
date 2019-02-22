require_relative './base_client'
module ChefF5
  class Client < BaseClient
    unless defined? LB_METHOD_TYPES
      LB_METHOD_TYPES = %w[
        LB_METHOD_ROUND_ROBIN
        LB_METHOD_RATIO_MEMBER
        LB_METHOD_LEAST_CONNECTION_MEMBER
        LB_METHOD_OBSERVED_MEMBER
        LB_METHOD_PREDICTIVE_MEMBER
        LB_METHOD_RATIO_NODE_ADDRESS
        LB_METHOD_LEAST_CONNECTION_NODE_ADDRESS
        LB_METHOD_FASTEST_NODE_ADDRESS
        LB_METHOD_OBSERVED_NODE_ADDRESS
        LB_METHOD_PREDICTIVE_NODE_ADDRESS
        LB_METHOD_DYNAMIC_RATIO
        LB_METHOD_FASTEST_APP_RESPONSE
        LB_METHOD_LEAST_SESSIONS
        LB_METHOD_DYNAMIC_RATIO_MEMBER
        LB_METHOD_L3_ADDR
        LB_METHOD_UNKNOWN
        LB_METHOD_WEIGHTED_LEAST_CONNECTION_MEMBER
        LB_METHOD_WEIGHTED_LEAST_CONNECTION_NODE_ADDRESS
        LB_METHOD_RATIO_SESSION
        LB_METHOD_RATIO_LEAST_CONNECTION_MEMBER
        LB_METHOD_RATIO_LEAST_CONNECTION_NODE_ADDRESS
      ].freeze
    end

    def node_is_missing?(name)
      response = api.LocalLB.NodeAddressV2.get_list

      return true if response[:item].nil?

      Array(response[:item]).grep(/#{with_partition name}/).empty?
    end

    def node_is_enabled?(name)
      response = api.LocalLB.NodeAddressV2.get_object_status(
        nodes: { item: [with_partition(name)] }
      )

      response[:item][:enabled_status] ==
        @EnabledStatus::ENABLED_STATUS_ENABLED.member
    end

    def node_disable(name)
      api.LocalLB.NodeAddressV2.set_session_enabled_state(
        nodes: { item: [with_partition(name)] },
        states: { item: [@EnabledState::STATE_DISABLED] }
      )
    end

    def node_enable(name)
      api.LocalLB.NodeAddressV2.set_session_enabled_state(
        nodes: { item: [with_partition(name)] },
        states: { item: [@EnabledState::STATE_ENABLED] }
      )
    end

    def pool_is_missing?(name)
      Chef::Log.warn "Folder is: #{api.System.Session.get_active_folder}"
      response = api.LocalLB.Pool.get_list

      return true if response[:item].nil?

      pools = response[:item]

      Array(pools).grep(/#{with_partition name}/).empty?
    end

    def pool_is_missing_node?(pool, node)
      response = api.LocalLB.Pool.get_member_v2(pool_names: { item: [with_partition(pool)] })

      members = response[:item][:item]
      return true if members.nil?

      members = [members] if members.is_a? Hash

      members.map { |m| m[:address] }.grep(/#{with_partition node}/).empty?
    end

    def pool_is_missing_monitor?(pool, monitor)
      monitors = api.LocalLB.Pool.get_monitor_association(pool_names:
        { item: with_partition(pool) })[:item]

      monitors = [monitors] if monitors.is_a? Hash
      monitors.select do |mon|
        mon[:monitor_rule][:monitor_templates][:item] == with_partition(monitor)
      end.empty?
    end

    # @param monitor  String|String[]  name(s) of monitors
    def add_monitor(pool, monitor)
      api.LocalLB.Pool.set_monitor_association(monitor_associations: {
                                                 item: [
                                                   { pool_name: pool,
                                                     monitor_rule: {
                                                       monitor_templates: {
                                                         item: monitor
                                                       },
                                                       quorum: '0',
                                                       # this value is overridden if an array of monitors
                                                       # are passed in. Instead it is set to
                                                       # `MONITOR_RULE_TYPE_AND_LIST`
                                                       type: 'MONITOR_RULE_TYPE_SINGLE'
                                                     } }
                                                 ]
                                               })
    end

    def pool_ratio_changed?(pool, ratio, address, port)
      f5_ratio = api.LocalLB.Pool.get_member_ratio(pool_names: { item: [with_partition(pool)] },
                                                   members: { item: { item: [{ address: address, port: port }] } }) # return long [] []
      f5_ratio[:item][:item] != ratio.to_s
    end

    def pool_update_ratio(pool, ratio, address, port)
      api.LocalLB.Pool.set_member_ratio(pool_names: { item: [with_partition(pool)] },
                                        members: { item: { item: [{ address: address, port: port }] } },
                                        ratios: { item: { item: [ratio] } })
    end

    def pool_lb_method_changed?(pool, lb_method)
      f5_lb_method = api.LocalLB.Pool.get_lb_method(pool_names: { item: [with_partition(pool)] })
      f5_lb_method[:item] != lb_method
    end

    def pool_update_lb_method(pool, lb_method)
      validate_lb_method(lb_method)
      api.LocalLB.Pool.set_lb_method(pool_names: { item: [with_partition(pool)] },
                                     lb_methods: { item: [lb_method] })
    end

    def validate_lb_method(lb_method)
      msg = "Invalid lb_method value: #{lb_method}; valid values are #{LB_METHOD_TYPES.inspect}"
      raise ArgumentError, msg unless LB_METHOD_TYPES.include? lb_method
    end

    def add_node(name, ip)
      api.LocalLB.NodeAddressV2.create(
        nodes: { item: [with_partition(name)] },
        addresses: { item: [ip] },
        limits: { item: [0] }
      )
    end

    def create_pool(name, lb_method = 'LB_METHOD_ROUND_ROBIN')
      api.LocalLB.Pool.create_v2(pool_names: { item: [name] },
                                 lb_methods: { item: [lb_method] },
                                 members: { item: [] })
    end

    def add_node_to_pool(pool, node, port)
      # F5 GUI allows and suggests using '*' to indicate 'any port' but on
      # submit the '*' is replaced with a '0' and the API only accepts '0'
      port = 0 if port == '*'

      api.LocalLB.Pool.add_member_v2(
        pool_names: { item: [with_partition(pool)] },
        members: { item: { item: [{ address: with_partition(node), port: port.to_s }] } }
      )
    end
  end
end
