property :host, String, regex: /.*/
property :ip, String, regex: /.*/
property :port, [String, Integer], regex: /^(\*|\d+)$/
property :monitor, String, regex: /.*/
property :lb_method, String, regex: /^[A-Z_]+$/
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :enabled_status, [:manual, :enabled, :disabled], default: node['f5']['enabled_status']

action :create do
  load_f5_gem
  f5 = ChefF5::Client.new(node, new_resource, new_resource.load_balancer)

  if f5.pool_is_missing?(new_resource.name)
    converge_by("Create pool #{new_resource.name}") do
      f5.create_pool(new_resource.name)
    end
  end

  if f5.node_is_missing?(new_resource.host)
    converge_by("Add node #{new_resource.host}") do
      f5.add_node(new_resource.host, new_resource.ip)
    end
  end

  if f5.pool_is_missing_node?(new_resource.name, new_resource.host)
    converge_by("Add #{new_resource.host} to pool #{new_resource.name}") do
      f5.add_node_to_pool(new_resource.name, new_resource.host, new_resource.port)
    end
  end

  if new_resource.enabled_status != :manual
    current_enabled_status = f5.node_is_enabled?(new_resource.host)
    if (new_resource.enabled_status == :disabled && current_enabled_status == true)
      converge_by("Disabling '#{new_resource.host}' (was previously enabled)") do
        f5.node_disable(new_resource.host)
      end
    elsif (new_resource.enabled_status == :enabled && current_enabled_status == false)
      converge_by("Enabling '#{new_resource.host}' (was previously disabled)") do
        f5.node_enable(new_resource.host)
      end
    end
  end

  if new_resource.monitor
    if f5.pool_is_missing_monitor?(new_resource.name, new_resource.monitor)
      converge_by("Add monitor #{new_resource.monitor} to pool #{new_resource.name}") do
        begin
          f5.add_monitor(new_resource.name, new_resource.monitor)
        rescue StandardError => e
          Chef::Log.info("Adding monitor #{new_resource.monitor} failed. Ensure it exists.")
          Chef::Log.info(e.inspect)
        end
      end
    else
      Chef::Log.debug("#{new_resource.name} already has monitor #{new_resource.monitor}")
    end
  end
end

action_class do
  include ChefF5::GemHelper
end
