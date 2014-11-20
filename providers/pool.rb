
def whyrun_supported?
  true
end

action :create do
  chef_gem 'f5-icontrol'

  if pool_is_missing?
    converge_by("Create pool #{new_resource.name}") do
      create_pool
    end
  end
end

def pool_is_missing?
  response = api.LocalLB.Pool.get_list

  response[:item].grep(/#{with_partition(new_resource.name)}/).empty?
end

def create_pool
  api.LocalLB.Pool.create_v2(pool_names: { item: [ new_resource.name ]},
                             lb_methods: { item: [ "LB_METHOD_ROUND_ROBIN" ]},
                             members: { item: [] }  )
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

  F5::Icontrol.configure do |f|
    f.host = "mylb"
    f.username = "api"
    f.password = "testing"
  end

  api = F5::Icontrol::API.new
end
