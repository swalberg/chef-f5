property :address, String, regex: /.*/
property :port, [Integer, String], regex: /^\d+$/
property :protocol, String, regex: /^[A-Z_]+$/, default: 'PROTOCOL_TCP'
property :pool, String, regex: /.*/
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String

action :create do
  load_f5_gem
  f5 = ChefF5::Client.new(node, new_resource, new_resource.load_balancer)

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

action_class do
  include ChefF5::GemHelper
end
