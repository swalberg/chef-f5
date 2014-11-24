class ChefF5
  def initialize(node)
    @node = node
  end

  def node_is_missing?(name)
    response = api.LocalLB.NodeAddressV2.get_list

    response[:item].grep(/#{with_partition name}/).empty?
  end

  def pool_is_missing?(name)
    response = api.LocalLB.Pool.get_list

    response[:item].grep(/#{with_partition name}/).empty?
  end

  def pool_is_missing_node?(pool, node)
    response = api.LocalLB.Pool.get_member_v2(pool_names: { item: [ with_partition(pool) ] } )

    members = response[:item][:item]
    return true if members.nil?

    members = [ members ] if members.is_a? Hash

    members.map { |m| m[:address] }.grep(/#{with_partition node}/).empty?
  end

  def add_node(name, ip)
    api.LocalLB.NodeAddressV2.create(
      nodes: { item: [ with_partition(name) ] },
      addresses: { item: [ ip ] } ,
      limits: { item: [0] } )

  end

  def create_pool(name, lb_method = "LB_METHOD_ROUND_ROBIN")
    api.LocalLB.Pool.create_v2(pool_names: { item: [ name ]},
                               lb_methods: { item: [ lb_method ]},
                               members: { item: [] }  )
  end

  def add_node_to_pool(pool, node, port)
    api.LocalLB.Pool.add_member_v2(
      pool_names: { item: [ with_partition(pool) ]},
      members: { item: { item: [ { address: with_partition(node), port: port } ] } 
    })
  end

  private

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
               credentials = Chef::Credentials.new(@node).credentials_for(:default)

               F5::Icontrol.configure do |f|
                 f.host = credentials[:host]
                 f.username = credentials[:username]
                 f.password = credentials[:password]
               end

               api = F5::Icontrol::API.new
             end
  end

end
