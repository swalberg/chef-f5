require_relative './base_client'
require_relative './irule_diff'
# rubocop:disable Naming/PredicateName
module ChefF5
  class VIP < BaseClient
    def vip_is_missing?(name)
      response = api.LocalLB.VirtualServer.get_list

      vips = response[:item]
      return true if vips.nil?

      vips = Array(vips)

      vips.grep(/#{with_partition name}/).empty?
    end

    def vip_default_pool(name)
      response = api.LocalLB.VirtualServer.get_default_pool_name(
        virtual_servers: { item: name }
      )

      response[:item]
    end

    def create_vip(name, address, port, protocol = 'PROTOCOL_TCP', wildcard = '255.255.255.255')
      # F5 GUI allows and suggests using '*' to indicate 'any port' but on
      # submit the '*' is replaced with a '0' and the API only accepts '0'
      port = 0 if port == '*'

      api.LocalLB.VirtualServer.create(definitions: {
                                         item: {
                                           name: with_partition(name),
                                           address: address,
                                           port: port.to_s,
                                           protocol: protocol },
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
                                             profile_context: @ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member,
                                             profile_name: 'http' }] })

      api.LocalLB.VirtualServer.set_type(
        virtual_servers: { item: name },
        types: { item: 'RESOURCE_TYPE_POOL' }
      )
    end

    def address(vip)
      res = api.LocalLB.VirtualServer.get_destination_v2(virtual_servers: { item: [with_partition(vip)] })
      raise 'No Destination found' unless res && res[:item]
      address = res[:item].is_a?(Array) ? res[:item].first : res[:item]
      [strip_partition(address[:address]), address[:port]]
    end

    def update_address(vip, address, port)
      port = '0' if port == '*'
      api.LocalLB.VirtualServer.set_destination_v2(virtual_servers: { item: [with_partition(vip)] },
                                                   destinations: { item: [{ address: address, port: port }] })
    end

    def set_vip_pool(vip, pool)
      api.LocalLB.VirtualServer.set_default_pool_name(
        virtual_servers: { item: [with_partition(vip)] },
        default_pools: { item: [with_partition(pool)] }
      )
    end

    def has_client_ssl_profile?(vip, profile_name)
      has_profile?(vip, profile_name,
        @ProfileType::PROFILE_TYPE_CLIENT_SSL.member,
        @ProfileContextType::PROFILE_CONTEXT_TYPE_CLIENT.member)
    end

    def has_any_http_profile?(vip)
      has_type_of_profile?(vip,
                   @ProfileType::PROFILE_TYPE_HTTP.member,
                   @ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member
                          )
    end

    def has_http_profile?(vip, profile_name)
      has_profile?(vip, profile_name,
        @ProfileType::PROFILE_TYPE_HTTP.member,
        @ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member)
    end

    def set_http_profile(vip, profile_name, existing_profile = nil)
      remove_http_profile(vip, existing_profile) if existing_profile
      api.LocalLB.VirtualServer.add_profile(
        virtual_servers: { item: [with_partition(vip)] },
        profiles: { item: [ { item: [{
          profile_context: @ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member,
          profile_name: with_partition(profile_name),
        }],
        }] })
    end

    def remove_http_profile(vip, profile_name)
      api.LocalLB.VirtualServer.remove_profile(
        virtual_servers: { item: [with_partition(vip)] },
        profiles: { item: [ { item: [{
          profile_context: @ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member,
          profile_name: with_partition(profile_name),
        }],
        }],
      })
    end

    def has_type_of_profile?(vip, profile_type, profile_context)
      response = api.LocalLB.VirtualServer.get_profile(
        virtual_servers: { item: [with_partition(vip)] }
      )

      return false unless !response.empty? &&
                          !response[:item].empty? &&
                          !response[:item][:item].empty?
      vip_profiles = response[:item][:item]

      vip_profiles = [ vip_profiles ] if vip_profiles.respond_to?(:has_key?)

      current_profiles = vip_profiles.select do |p|
        p[:profile_type] == profile_type &&
          p[:profile_context] == profile_context
      end
      if current_profiles.empty?
        nil
      else
        current_profiles.first[:profile_name]
      end
    end

    def has_profile?(vip, profile_name, profile_type, profile_context)
      response = api.LocalLB.VirtualServer.get_profile(
        virtual_servers: { item: [with_partition(vip)] }
      )

      return false unless !response.empty? &&
                          !response[:item].empty? &&
                          !response[:item][:item].empty?

      vip_profiles = response[:item][:item]

      vip_profiles = [ vip_profiles ] if vip_profiles.respond_to?(:has_key?)

      current_profiles = vip_profiles.select do |p|
        p[:profile_type] == profile_type &&
          p[:profile_context] == profile_context
      end

      current_profiles.any? do |p|
        p[:profile_name] == with_partition(profile_name)
      end
    end

    def add_client_ssl_profile(vip, profile_name)
      api.LocalLB.VirtualServer.add_profile(
        virtual_servers: { item: [with_partition(vip)] },
        profiles: { item: [ { item: [{
          profile_context: @ProfileContextType::PROFILE_CONTEXT_TYPE_CLIENT.member,
          profile_name: with_partition(profile_name),
        }],
        }],
      })
    end

    def has_server_ssl_profile?(vip, profile_name)
      has_profile?(vip, profile_name,
        @ProfileType::PROFILE_TYPE_SERVER_SSL.member,
        @ProfileContextType::PROFILE_CONTEXT_TYPE_SERVER.member)
    end

    def add_server_ssl_profile(vip, profile_name)
      api.LocalLB.VirtualServer.add_profile(
        virtual_servers: { item: [with_partition(vip)] },
        profiles: { item: [ { item: [{
          profile_context: @ProfileContextType::PROFILE_CONTEXT_TYPE_SERVER.member,
          profile_name: with_partition(profile_name),
        }],
        }],
      })
    end

    def get_snat_pool(vip)
      response = api.LocalLB.VirtualServer.get_source_address_translation_type(
        virtual_servers: { item: [with_partition(vip)] }
      )

      source_address_translation_type =
        F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType

      raw_src_trans_type = response[:item]

      src_trans_type_map = {
        # F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType::SRC_TRANS_UNKNOWN,
        none: source_address_translation_type::SRC_TRANS_NONE.member,
        automap: source_address_translation_type::SRC_TRANS_AUTOMAP.member,
        snat: source_address_translation_type::SRC_TRANS_SNATPOOL.member,
        # F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType::SRC_TRANS_LSNPOOL,
      }

      src_trans_type = src_trans_type_map.key(raw_src_trans_type)

      raise 'Unrecognized source translation type:'\
            " `#{raw_src_trans_type}`" unless src_trans_type

      src_trans_type
    end

    def set_snat_pool(vip, snat_pool)
      case snat_pool
      when :none
        api.LocalLB.VirtualServer
           .set_source_address_translation_none(
             virtual_servers: { item: [with_partition(vip)] }
           )
      when :automap
        api.LocalLB.VirtualServer
           .set_source_address_translation_automap(
             virtual_servers: { item: [with_partition(vip)] }
           )
      when :manual
        raise 'Cannot set the source address translation type to `manual`'\
              ' ... what would that even mean?'
      else
        # assume that the requested snat_pool is already defined on the F5
        api.LocalLB.VirtualServer
           .set_source_address_translation_snat_pool(
             virtual_servers: { item: [with_partition(vip)] },
             pools: { item: [with_partition(snat_pool)] }
           )
      end
    end

    def firewall_policy_missing?(name)
      return false if name == :none
      response = api.Security.FirewallPolicy.get_list

      return true if response[:item].nil?
      Array(response[:item]).grep(/#{with_partition name}/).empty?
    end

    def vip_enforced_firewall_policy(vip)
      response = api.LocalLB.VirtualServer.get_enforced_firewall_policy(
        virtual_servers: { item: [with_partition(vip)] }
      )
      firewall_policy = strip_partition(response[:item])
      firewall_policy.to_s.empty? ? :none : firewall_policy
    end

    def vip_staged_firewall_policy(vip)
      response = api.LocalLB.VirtualServer.get_staged_firewall_policy(
        virtual_servers: { item: [with_partition(vip)] }
      )
      firewall_policy = strip_partition(response[:item])
      firewall_policy.to_s.empty? ? :none : firewall_policy
    end

    def set_enforced_firewall_policy(vip, firewall_policy)
      firewall_policy = '' if firewall_policy == :none
      api.LocalLB.VirtualServer.set_enforced_firewall_policy(
        virtual_servers: { item: [with_partition(vip)] },
        policies: { item: [with_partition(firewall_policy)] }
      )
    end

    def set_staged_firewall_policy(vip, firewall_policy)
      firewall_policy = '' if firewall_policy == :none
      api.LocalLB.VirtualServer.set_staged_firewall_policy(
        virtual_servers: { item: [with_partition(vip)] },
        policies: { item: [with_partition(firewall_policy)] }
      )
    end

    def irules_changed?(vip, target_rules)
      current = api.LocalLB.VirtualServer.get_rule(virtual_servers: { item: [with_partition(vip)] })
      current_value = current[:item][:item]
      current_rules = if current_value.nil?
                        {}
                      elsif current_value.is_a?(Hash)
                        { current_value[:rule_name] => current_value[:priority] }
                      else
                        current_value.each_with_object({}) do |irule, out|
                          out[irule[:rule_name]] = irule[:priority]
                        end
                      end

      partitioned_targets = target_rules.map do |rule|
        with_partition(rule)
      end
      IRuleDiff.diff(partitioned_targets, current_rules)
    end

    def update_irules(vip, irules, added, changed, removed)
      added.to_a.each { |r| create_rule vip, r, irules[r].to_s }
      changed.to_a.each { |r| update_rule vip, r, irules[r].to_s }
      removed.to_a.each { |r| remove_rule vip, r }
    end

    def remove_rule(vip, rule)
      api.LocalLB.VirtualServer.remove_rule(virtual_servers: { item: [with_partition(vip)] },
                                            rules: { item: { item: [{ rule_name: with_partition(rule), priority: '0' }] } }
                                           )
    end

    def update_rule(vip, rule_name, priority)
      remove_rule(vip, rule_name)
      create_rule(vip, rule_name, priority)
    end

    def create_rule(vip, rule_name, priority)
      api.LocalLB.VirtualServer.add_rule(virtual_servers: { item: [with_partition(vip)] },
                                         rules: { item: { item: [{ rule_name: with_partition(rule_name), priority: priority }] } }
                                        )
    end
  end
end
