
def whyrun_supported?
  true
end

action :create do
  chef_gem 'f5-icontrol'

  if pool_does_not_exist?
    converge_by("Create pool #{pool}") do
      create_pool
      Chef::Log.info("#{new_resource} created pool #{pool}")
    end
  end

  if pool_is_missing_node?
    converge_by("Add #{new_resource.host} to pool #{pool}") do
      add_host_to_pool
      Chef::Log.info("#{new_resource} added #{new_resource.host} to pool #{pool}")
    end
  end
end

def pool_does_not_exist?
  response = api.LocalLB.Pool.get_list

  response[:item].grep(/#{pool}/).empty?
end

def pool_is_missing_node?
  response = api.LocalLB.Pool.get_member_v2(pool_names: { item: [ pool ] } )

  members = response[:item][:item]
  members = [ members ] if members.is_a? Hash
  Chef::Log.info(members)
  Chef::Log.info("looking for #{host}")

  a = members.map { |m| m[:address] }.grep(/#{host}/)

  Chef::Log.info(a)

  a.empty?
end

def create_pool
  api.LocalLB.Pool.create_v2(pool_names: { item: [ pool ]},
                             lb_methods: { item: [ "LB_METHOD_ROUND_ROBIN" ]},
                             members: { item: [] }  )
end

def add_host_to_pool
  api.LocalLB.Pool.add_member(pool_names: { item: [ pool ]},
                              members: { item:
                                         { item: [ { address: new_resource.host , port: new_resource.port } ] } 
  })
end

def pool
  with_partition(new_resource.name)
end

def host
  with_partition(new_resource.host)
end

def with_partition(key)
  if key =~ %r{^/}
    key
  else
    "/Common/#{key}"
  end
end


def api
  require 'f5/icontrol'

  @api ||= begin
             credentials = Chef::Credentials.new(node).credentials_for(:default)

             F5::Icontrol.configure do |f|
               f.host = credentials[:host]
               f.username = credentials[:username]
               f.password = credentials[:password]
             end

             api = F5::Icontrol::API.new
           end
end
