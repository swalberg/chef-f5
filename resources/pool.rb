property :pool_name, [NilClass, String], default: nil
property :host, String, regex: /.*/
property :ip, String, regex: /.*/
property :port, [String, Integer], regex: /^(\*|\d+)$/
property :monitor, String, regex: /.*/
property :lb_method, String, regex: /^[A-Z_]+$/
property :ratio, [NilClass, Integer], default: nil
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :partition, String, default: '/Common/'
property :enabled_status, [:manual, :enabled, :disabled], default: node['f5']['enabled_status']

create_node = proc do
  actual_pool_name = new_resource.pool_name || new_resource.name
  if @f5.node_is_missing?(new_resource.host)
    converge_by("Add node #{new_resource.host}") do
      @f5.add_node(new_resource.host, new_resource.ip)
    end
  end

  if @f5.pool_is_missing_node?(actual_pool_name, new_resource.host)
    converge_by("Add #{new_resource.host} to pool #{actual_pool_name}") do
      @f5.add_node_to_pool(actual_pool_name, new_resource.host, new_resource.port)
    end
  end
  if new_resource.enabled_status != :manual
    current_enabled_status = @f5.node_is_enabled?(new_resource.host)
    if (new_resource.enabled_status == :disabled && current_enabled_status == true)
      converge_by("Disabling '#{new_resource.host}' (was previously enabled)") do
        @f5.node_disable(new_resource.host)
      end
    elsif (new_resource.enabled_status == :enabled && current_enabled_status == false)
      converge_by("Enabling '#{new_resource.host}' (was previously disabled)") do
        @f5.node_enable(new_resource.host)
      end
    end
  end

  if new_resource.ratio
    if @f5.pool_ratio_changed?(actual_pool_name, new_resource.ratio, new_resource.host, new_resource.port)
      converge_by("Updating ratio on pool #{actual_pool_name}") do
        @f5.pool_update_ratio(actual_pool_name, new_resource.ratio, new_resource.host, new_resource.port)
      end
    else
      Chef::Log.debug("#{actual_pool_name} has the correct ratio.")
    end
  end
end

create_pool = proc do
  actual_pool_name = new_resource.pool_name || new_resource.name
  if @f5.pool_is_missing?(actual_pool_name)
    converge_by("Create pool #{actual_pool_name}") do
      if new_resource.lb_method
        @f5.create_pool(actual_pool_name, new_resource.lb_method)
      else
        @f5.create_pool(actual_pool_name)
      end
    end
  end

  if new_resource.monitor
    if @f5.pool_is_missing_monitor?(actual_pool_name, new_resource.monitor)
      converge_by("Add monitor #{new_resource.monitor} to pool #{actual_pool_name}") do
        begin
          @f5.add_monitor(actual_pool_name, new_resource.monitor)
        rescue StandardError => e
          Chef::Log.info("Adding monitor #{new_resource.monitor} failed. Ensure it exists.")
          Chef::Log.info(e.inspect)
        end
      end
    else
      Chef::Log.debug("#{actual_pool_name} already has monitor #{new_resource.monitor}")
    end
  end

  if new_resource.lb_method
    if @f5.pool_lb_method_changed?(actual_pool_name, new_resource.lb_method)
      converge_by("Updating lb_method on pool #{actual_pool_name}") do
        @f5.pool_update_lb_method(actual_pool_name, new_resource.lb_method)
      end
    else
      Chef::Log.debug("#{actual_pool_name} has the correct lb_method.")
    end
  end
end

action :create do
  load_f5_gem
  @f5 = ChefF5::Client.new(node, new_resource, new_resource.load_balancer, new_resource.partition)

  instance_eval(&create_pool)

  instance_eval(&create_node) unless new_resource.host.nil?
end

action :add do
  load_f5_gem
  @f5 = ChefF5::Client.new(node, new_resource, new_resource.load_balancer, new_resource.partition)

  instance_eval(&create_node)
end

action_class do
  include ChefF5::GemHelper
end
