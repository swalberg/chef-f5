use_inline_resources if defined?(use_inline_resources)


def whyrun_supported?
  true
end

action :create do
  package "patch"

  chef_gem 'f5-icontrol'

  if pool_is_missing?
    converge_by("Create pool #{pool}") do
      create_pool
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} created pool #{pool}")
    end
  end

  if node_is_missing?
    converge_by("Add node #{new_resource.host}") do
      add_node
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} added #{new_resource.host} as a new node")
    end
  end

  if pool_is_missing_node?
    converge_by("Add #{new_resource.host} to pool #{pool}") do
      add_node_to_pool
      new_resource.updated_by_last_action(true)
      Chef::Log.info("#{new_resource} added #{new_resource.host} to pool #{pool}")
    end
  end
end

def node_is_missing?
  response = api.LocalLB.NodeAddressV2.get_list

  response[:item].grep(/#{host}/).empty?

end

def pool_is_missing?
  response = api.LocalLB.Pool.get_list

  response[:item].grep(/#{pool}/).empty?
end

def pool_is_missing_node?
  response = api.LocalLB.Pool.get_member_v2(pool_names: { item: [ pool ] } )

  members = response[:item][:item]
  return true if members.nil?

  members = [ members ] if members.is_a? Hash

  members.map { |m| m[:address] }.grep(/#{host}/).empty?
end

def add_node
  api.LocalLB.NodeAddressV2.create(
    nodes: { item: [ host ] },
    addresses: { item: [ new_resource.ip ] } ,
    limits: { item: [0] } )
  
end

def create_pool
  api.LocalLB.Pool.create_v2(pool_names: { item: [ pool ]},
                             lb_methods: { item: [ "LB_METHOD_ROUND_ROBIN" ]},
                             members: { item: [] }  )
end

def add_node_to_pool
  api.LocalLB.Pool.add_member_v2(pool_names: { item: [ pool ]},
                                 members: { item:
                                            { item: [ { address: host, port: new_resource.port } ] } 
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
