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

  if f5.vip_is_missing?(new_resource.name)
    converge_by("Create vip #{new_resource.name}") do
      f5.create_vip(new_resource.name, new_resource.pool, new_resource.address, new_resource.port, new_resource.protocol)
      Chef::Log.info("#{new_resource} created vip #{new_resource.name} at #{new_resource.address}:#{new_resource.port}/#{new_resource.protocol}")
    end
  end

  if f5.vip_default_pool(new_resource.name) != new_resource.pool
    f5.set_vip_pool(new_resource.name, new_resource.pool)
  end
end
