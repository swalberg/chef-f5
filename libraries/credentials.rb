class ChefF5
  class Credentials
    include Chef::DSL::DataQuery

    def initialize(node)
      @node = node
    end

    def credentials_for(lb = 'default')
      from_databag(lb) || the_hash[lb] || the_hash[:default] # ~FC001, ~FC010
    end

    private

    def the_hash
      @node[:f5][:credentials]
    end

    def from_databag(databag_name = 'default')
      bag = data_bag_item(:f5, databag_name)
      bag.default_proc = proc { |h, k| h.key?(k.to_s) ? h[k.to_s] : nil } if bag
      bag
    rescue Net::HTTPServerException
      nil
    end
  end
end
