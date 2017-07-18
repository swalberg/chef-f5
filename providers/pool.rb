use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do
  package %w(patch libxml2-devel) do
    action :nothing
  end.run_action(:install)

  chef_gem 'f5-icontrol' do
    action :install
    compile_time true
    version node['f5']['gem_version']
  end

  f5 = ChefF5.new(node, new_resource.load_balancer)

  if f5.pool_is_missing?(new_resource.name)
    converge_by("Create pool #{new_resource.name}") do
      f5.create_pool(new_resource.name)
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} created pool #{new_resource.name}")
    end
  end

  if f5.node_is_missing?(new_resource.host)
    converge_by("Add node #{new_resource.host}") do
      f5.add_node(new_resource.host, new_resource.ip)
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} added #{new_resource.host} as a new node")
    end
  end

  if f5.pool_is_missing_node?(new_resource.name, new_resource.host)
    converge_by("Add #{new_resource.host} to pool #{new_resource.name}") do
      f5.add_node_to_pool(new_resource.name, new_resource.host, new_resource.port)
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} added #{new_resource.host} to pool #{new_resource.name}")
    end
  end

  if new_resource.monitor
    if f5.pool_is_missing_monitor?(new_resource.name, new_resource.monitor)
      converge_by("Add monitor #{new_resource.monitor} to pool #{new_resource.name}") do
        begin
          f5.add_monitor(new_resource.name, new_resource.monitor)
          new_resource.updated_by_last_action(true)
          Chef::Log.info("#{new_resource} added monitor #{new_resource.monitor} to pool #{new_resource.name}")
        rescue StandardError => e
          Chef::Log.info("Adding monitor #{new_resource.monitor} failed. Ensure it exists.")
          Chef::Log.info(e.inspect)
        end

      end
    else
      Chef::Log.info("#{new_resource.name} already has monitor #{new_resource.monitor}")
    end
  end
end
