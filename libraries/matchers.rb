if defined?(ChefSpec)
  def create_f5_vip(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new('f5_vip', 'create', resource_name)
  end

  def create_f5_pool(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new('f5_pool', 'create', resource_name)
  end
end
