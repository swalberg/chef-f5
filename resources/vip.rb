property :address, String, regex: /.*/
property :port, [Integer, String], regex: /^\d+$/
property :protocol, String, regex: /^[A-Z_]+$/, default: 'PROTOCOL_TCP'
property :pool, String, regex: /.*/
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :client_ssl_profile, String
property :server_ssl_profile, String
property :source_address_translation, [:manual, :none, :automap, :snat], default: 'manual'.to_sym

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

  if new_resource.client_ssl_profile
    unless f5.has_client_ssl_profile?(new_resource.name, new_resource.client_ssl_profile)
      converge_by("Add client ssl profile `#{new_resource.client_ssl_profile}` to `#{new_resource.name}`") do
        f5.add_client_ssl_profile(new_resource.name, new_resource.client_ssl_profile)
        Chef::Log.info("Added client ssl profile `#{new_resource.client_ssl_profile}` to `#{new_resource.name}`")
      end
    end
  end

  if new_resource.server_ssl_profile
    unless f5.has_server_ssl_profile?(new_resource.name, new_resource.server_ssl_profile)
      converge_by("Add server ssl profile `#{new_resource.server_ssl_profile}` to `#{new_resource.name}`") do
        f5.add_server_ssl_profile(new_resource.name, new_resource.server_ssl_profile)
        Chef::Log.info("Added server ssl profile `#{new_resource.server_ssl_profile}` to `#{new_resource.name}`")
      end
    end
  end

  if new_resource.source_address_translation != :manual
    current_sat = f5.source_address_translation(new_resource.name)

    unless current_sat == new_resource.source_address_translation

      converge_by("Change server source address translation from"\
                  " `#{current_sat}` to"\
                  " `#{new_resource.source_address_translation}`") do

        f5.set_source_address_translation(
          new_resource.name,
          new_resource.source_address_translation)

        Chef::Log.info("Changed server source address translation from"\
                    " `#{current_sat}` to"\
                    " `#{new_resource.source_address_translation}`")
      end
    end
  end
end

action_class do
  include ChefF5::GemHelper
end
