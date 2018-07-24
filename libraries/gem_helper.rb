module ChefF5
  module GemHelper
    def load_f5_gem
      install_f5_gem
      require 'f5/icontrol'
    end

    def install_f5_gem
      packages = case node['platform_family']
                 when 'rhel', 'fedora', 'amazon', 'suse'
                   %w(gcc zlib-devel patch)
                 when 'debian'
                   %w(gcc zlib1g-dev patch)
                 end

      package packages do
        action :nothing
      end.run_action(:install) unless packages.nil?

      chef_gem 'f5-icontrol' do
        compile_time true
        version node['f5']['gem_version']
      end
    end
  end
end
