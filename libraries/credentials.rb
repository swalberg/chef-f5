module ChefF5
  class Credentials
    include Chef::DSL::DataQuery

    def initialize(node, resource)
      @node = node
      @resource = resource
    end

    def credentials_for(lb = 'default')
      creds = from_resource ||
              from_databag(lb) ||
              from_attributes(lb) ||
              from_attributes('default')

      raise "No credentials found for the load balancer #{lb}. See README.md for usage information" unless creds
      creds
    end

    private

    def from_resource
      if @resource.lb_host && @resource.lb_username && @resource.lb_password
        Chef::Log.debug('Using F5 credentials passed from the resource')
        {
          host: @resource.lb_host,
          username: @resource.lb_username,
          password: @resource.lb_password,
        }
      else
        Chef::Log.debug('No F5 credentials passed from the resource')
        nil
      end
    end

    def from_attributes(lb)
      if @node['f5']['credentials'][lb]
        Chef::Log.debug('Using F5 credentials set in attributes')
        @node['f5']['credentials'][lb]
      end
    rescue NoMethodError
      Chef::Log.debug('No F5 credentials set in attributes')
      nil
    end

    def from_databag(bag_item_name = 'default')
      Chef::Log.debug('Using F5 credentials set in data bag')
      bag = data_bag_item(@node['f5']['databag_name'].to_sym, bag_item_name)
      bag.default_proc = proc { |h, k| h.key?(k.to_s) ? h[k.to_s] : nil } if bag
      bag
    rescue Net::HTTPServerException
      nil
    end
  end
end
