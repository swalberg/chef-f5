use_inline_resources if defined?(use_inline_resources)


def whyrun_supported?
  true
end

action :create do
  package "patch"

  chef_gem 'f5-icontrol'

  f5 = ChefF5.new(node)

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
    converge_by("Add #{new_resource.host} to pool #{pool}") do
      f5.add_node_to_pool(new_resource.name, new_resource.host, new_resource.port)
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} added #{new_resource.host} to pool #{new_resource.name}")
    end
  end
end
