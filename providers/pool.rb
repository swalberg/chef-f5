use_inline_resources

def whyrun_supported?
  true
end

action :create do
  package %w(gcc zlib-devel patch) do
    action :nothing
  end.run_action(:install)

  chef_gem 'f5-icontrol' do
    compile_time true
    version node['f5']['gem_version']
  end

  f5 = ChefF5.new(node, new_resource, new_resource.load_balancer)

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
