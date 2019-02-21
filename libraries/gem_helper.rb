require 'singleton'
module ChefF5
  class Autoload
    include Singleton
    attr_reader :f5_gem_installed
    def initialize
      @mutex = Mutex.new
    end

    def f5_gem_installed=(new_value)
      @mutex.synchronize { @f5_gem_installed = new_value }
    end
  end

  module GemHelper
    def load_f5_gem
      install_f5_gem
      require 'f5/icontrol'
    end

    def install_f5_gem
      return if Autoload.instance.f5_gem_installed
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

      Autoload.instance.f5_gem_installed = true
    end
  end
end
