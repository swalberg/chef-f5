class ChefF5
  def initialize(node, load_balancer)
    @node = node
    @load_balancer = load_balancer
  end

  def node_is_missing?(name)
    response = api.LocalLB.NodeAddressV2.get_list

    return true if response[:item].nil?
    Array(response[:item]).grep(/#{with_partition name}/).empty?
  end

  def vip_is_missing?(name)
    response = api.LocalLB.VirtualServer.get_list

    vips = response[:item]
    return true if vips.nil?

    vips = Array(vips)

    vips.grep(/#{with_partition name}/).empty?
  end

  def pool_is_missing?(name)
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
      { item: with_partition(pool) }
                                                       )[:item]

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
                                                       item: monitor,
                                                     },
                                                     quorum: '0',
                                                     # this value is overridden if an array of monitors
                                                     # are passed in. Instead it is set to
                                                     # `MONITOR_RULE_TYPE_AND_LIST`
                                                     type: 'MONITOR_RULE_TYPE_SINGLE',
                                                   },
                                                 },
                                               ],
                                             })
  end

  def vip_default_pool(name)
    response = api.LocalLB.VirtualServer.get_default_pool_name(
      virtual_servers: { item: name }
    )

    response[:item]
  end

  def add_node(name, ip)
    api.LocalLB.NodeAddressV2.create(
      nodes: { item: [with_partition(name)] },
      addresses: { item: [ip] },
      limits: { item: [0] })
  end

  def create_pool(name, lb_method = 'LB_METHOD_ROUND_ROBIN')
    api.LocalLB.Pool.create_v2(pool_names: { item: [name] },
                               lb_methods: { item: [lb_method] },
                               members: { item: [] })
  end

  def create_vip(name, _pool, address, port, _protocol = 'PROTOCOL_TCP', wildcard = '255.255.255.255')
    api.LocalLB.VirtualServer.create(definitions: {
                                       item: {
                                         name: with_partition(name),
                                         address: address,
                                         port: port.to_s,
                                         protocol: 'PROTOCOL_TCP' },
                                     },
                                     wildmasks: { item: wildcard },
                                     resources: {
                                       item: {
                                         type: 'RESOURCE_TYPE_REJECT',
                                         default_pool_name: '',
                                       },
                                     },
                                     profiles: {
                                       item: [
                                         item: {
                                           profile_context: 'PROFILE_CONTEXT_TYPE_ALL',
                                           profile_name: 'http' }] })

    api.LocalLB.VirtualServer.set_type(
      virtual_servers: { item: name },
      types: { item: 'RESOURCE_TYPE_POOL' }
    )
  end

  def add_node_to_pool(pool, node, port)
    api.LocalLB.Pool.add_member_v2(
      pool_names: { item: [with_partition(pool)] },
      members: { item: { item: [{ address: with_partition(node), port: port.to_s }] },
    })
  end

  def set_vip_pool(vip, pool)
    api.LocalLB.VirtualServer.set_default_pool_name(
      virtual_servers: { item: [with_partition(vip)] },
      default_pools: { item: [with_partition(pool)] }
    )
  end

  private

  def with_partition(key)
    if key =~ %r{^/}
      key
    else
      "/Common/#{key}"
    end
  end

  def api
    require 'f5/icontrol'

    @api ||= begin
               credentials = ChefF5::Credentials.new(@node).credentials_for(@load_balancer)

               api = F5::Icontrol::API.new(
                 nil,
                 host: credentials[:host],
                 username: credentials[:username],
                 password: credentials[:password]
               )
             end
  end
end
