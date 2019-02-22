property :vip_name, [NilClass, String], default: nil
property :address, String, regex: /.*/
property :port, [Integer, String], regex: /^(\*|\d+)$/
property :protocol, String, regex: /^[A-Z_]+$/, default: 'PROTOCOL_TCP'
property :pool, String, regex: /.*/
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :partition, String, default: '/Common/'
property :client_ssl_profile, String
property :server_ssl_profile, String
property :snat_pool, [:manual, :none, :automap, String], default: :manual
property :enforced_firewall_policy, [:manual, :none, String], default: :manual
property :staged_firewall_policy, [:manual, :none, String], default: :manual
property :irules, Array, default: []
property :http_profile, [NilClass, String, Symbol], default: nil

IPv4 = %r{^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$}

def resolve_ip(name)
  if name =~ IPv4
    name
  else
    DNSLookup.new(name).address
  end
end

action :create do
  load_f5_gem
  actual_vip_name = new_resource.vip_name || new_resource.name
  vip = ChefF5::VIP.new(node, new_resource, new_resource.load_balancer, new_resource.partition)
  ip = resolve_ip(new_resource.address)

  next if ip.nil?

  if vip.vip_is_missing?(actual_vip_name)
    converge_by("Create vip #{actual_vip_name}") do
      vip.create_vip(actual_vip_name, ip, new_resource.port, new_resource.protocol)
      Chef::Log.info("#{new_resource} created vip #{actual_vip_name} at #{ip}:#{new_resource.port}/#{new_resource.protocol}")
    end
  end

  old_address = vip.address(actual_vip_name)
  port = new_resource.port == '*' ? '0' : new_resource.port.to_s
  unless old_address == [ip, port]
    converge_by "Updating VIP ip address from #{old_address} to #{ip}" do
      vip.update_address(actual_vip_name, ip, new_resource.port)
    end
  end

  if vip.vip_default_pool(actual_vip_name) != new_resource.pool
    vip.set_vip_pool(actual_vip_name, new_resource.pool)
  end

  if new_resource.client_ssl_profile
    unless vip.has_client_ssl_profile?(actual_vip_name, new_resource.client_ssl_profile)
      converge_by("Add client ssl profile '#{new_resource.client_ssl_profile}' to '#{actual_vip_name}'") do
        vip.add_client_ssl_profile(actual_vip_name, new_resource.client_ssl_profile)
        Chef::Log.info("Added client ssl profile '#{new_resource.client_ssl_profile}' to '#{actual_vip_name}'")
      end
    end
  end

  if new_resource.server_ssl_profile
    unless vip.has_server_ssl_profile?(actual_vip_name, new_resource.server_ssl_profile)
      converge_by("Add server ssl profile '#{new_resource.server_ssl_profile}' to '#{actual_vip_name}'") do
        vip.add_server_ssl_profile(actual_vip_name, new_resource.server_ssl_profile)
        Chef::Log.info("Added server ssl profile '#{new_resource.server_ssl_profile}' to '#{actual_vip_name}'")
      end
    end
  end

  http_profile = new_resource.http_profile
  existing_profile_name = vip.has_any_http_profile?(actual_vip_name)
  if http_profile
    if http_profile == :none
      converge_by("Removing HTTP profile #{existing_profile_name} from #{actual_vip_name}") do
        vip.remove_http_profile(actual_vip_name, existing_profile_name)
      end if existing_profile_name
    elsif !vip.has_http_profile?(actual_vip_name, http_profile)
      converge_by "Set HTTP profile for #{actual_vip_name} to #{http_profile}" do
        vip.set_http_profile(actual_vip_name, http_profile, existing_profile_name)
      end
    end
  end

  if new_resource.enforced_firewall_policy != :manual
    current_enforced_firewall_policy = vip.vip_enforced_firewall_policy(actual_vip_name)
    unless current_enforced_firewall_policy == new_resource.enforced_firewall_policy
      if vip.firewall_policy_missing?(new_resource.enforced_firewall_policy)
        raise "Firewall policy #{new_resource.enforced_firewall_policy} does not exist"
      end
      converge_by("Set enforced firewall policy on '#{actual_vip_name}' to '#{new_resource.enforced_firewall_policy}'") do
        vip.set_enforced_firewall_policy(actual_vip_name, new_resource.enforced_firewall_policy)
        Chef::Log.info("Set enforced firewall policy on '#{actual_vip_name}' to '#{new_resource.enforced_firewall_policy}'")
      end
    end
  end

  if new_resource.staged_firewall_policy != :manual
    current_staged_firewall_policy = vip.vip_staged_firewall_policy(actual_vip_name)
    unless current_staged_firewall_policy == new_resource.staged_firewall_policy
      if vip.firewall_policy_missing?(new_resource.staged_firewall_policy)
        raise "Firewall policy #{new_resource.staged_firewall_policy} does not exist"
      end
      converge_by("Set staged firewall policy on '#{actual_vip_name}' to '#{new_resource.staged_firewall_policy}'") do
        vip.set_staged_firewall_policy(actual_vip_name, new_resource.staged_firewall_policy)
        Chef::Log.info("Set staged firewall policy on '#{actual_vip_name}' to '#{new_resource.staged_firewall_policy}'")
      end
    end
  end

  if new_resource.snat_pool != :manual
    current_snat_pool = vip.get_snat_pool(actual_vip_name)

    unless current_snat_pool == new_resource.snat_pool

      converge_by("Change server source address translation from"\
                  " '#{current_snat_pool}' to"\
                  " '#{new_resource.snat_pool}'") do

        vip.set_snat_pool(actual_vip_name, new_resource.snat_pool)

        Chef::Log.info("Changed server source address translation from"\
                    " '#{current_snat_pool}' to"\
                    " '#{new_resource.snat_pool}'")
      end
    end
  end
  added, changed, removed, target = vip.irules_changed?(actual_vip_name, new_resource.irules)
  unless [added, changed, removed].all? { |l| l.empty? }
    msg = "Update IRules for #{actual_vip_name}; "\
      "The following rules changed: #{changed.join ', '}."\
      "The following rules have been added: #{added.to_a.join ', '}"\
      "The following rules have been removed: #{removed.to_a.join ', '}"
    converge_by msg do
      vip.update_irules(actual_vip_name, target, added, changed, removed)
    end
  end
end

action_class do
  include ChefF5::GemHelper
end
