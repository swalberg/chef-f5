module ChefF5
  class BaseClient
    def initialize(node, resource, load_balancer, partition = 'Common')
      @node = node
      @resource = resource
      @load_balancer = load_balancer
      @partition = partition[%r{/?([^/]+)/?}, 1]

      # local module aliases reduce repetetive call chains
      # rubocop:disable Naming/VariableName
      @ProfileContextType = F5::Icontrol::LocalLB::ProfileContextType
      @ProfileType        = F5::Icontrol::LocalLB::ProfileType
      @EnabledStatus      = F5::Icontrol::LocalLB::EnabledStatus
      @EnabledState       = F5::Icontrol::Common::EnabledState
      # rubocop:enable Naming/VariableName
    end

    private

    def strip_partition(key)
      key.gsub(%r{^/#{@partition}/}, '') if key
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
        api = F5::Icontrol::API.new(
          nil,
          host: credentials[:host],
          username: credentials[:username],
          password: credentials[:password]
        )
        api.System.Session.set_active_folder(folder: "/#{@partition}")
        api
      end
    end
  end
end
