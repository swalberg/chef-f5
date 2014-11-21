class Chef
  class Credentials
    def initialize(node)
      @node = node
    end

    def credentials_for(lb = "default")
      the_hash[lb] || the_hash[:default]
    end

    private

    def the_hash
      @node[:f5][:credentials]
    end
  end
end
