module ChefF5
  class BaseClient

    def initialize(node, resource, load_balancer, partition)
      @node = node
      @resource = resource
      @load_balancer = load_balancer
      @partition = partition

      # local module aliases reduce repetetive call chains
      @ProfileContextType = F5::Icontrol::LocalLB::ProfileContextType
      @ProfileType        = F5::Icontrol::LocalLB::ProfileType
      @EnabledStatus      = F5::Icontrol::LocalLB::EnabledStatus
      @EnabledState       = F5::Icontrol::Common::EnabledState
    end

    private

    def strip_partition(key)
      key.gsub(%r{^/Common/}, '') if key
    end

    def with_partition(key)
      if key =~ %r{^/} || key.to_s.empty?
        key
      else
        "/#{@partition}/#{key}"
      end
    end

    def api
      @api ||= begin
        credentials = ChefF5::Credentials.new(@node, @resource).credentials_for(@load_balancer)
        F5::Icontrol::API.new(
          nil,
          host: credentials[:host],
          username: credentials[:username],
          password: credentials[:password]
        )
      end
      @api.System.Session.set_active_folder(folder: "/#{@partition}")
      @api
    end
  end
end
