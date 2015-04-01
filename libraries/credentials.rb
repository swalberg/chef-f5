class Chef
  class Credentials
    def initialize(node)
      @node = node
    end

    def credentials_for(lb = "default")
      from_databag(lb) || the_hash[lb] || the_hash[:default]
    end

    private

    def the_hash
      @node[:f5][:credentials]
    end

    def from_databag(databag_name = 'default')
      begin
        search(:f5, "id:#{databag_name}").first
      rescue Net::HTTPServerException
        nil
      end
    end
  end
end
