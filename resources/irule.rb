property :name, String
property :irule_name, [NilClass, String], default: nil
property :definition, String
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :partition, String, default: '/Common/'

action :create do
  load_f5_gem
  actual_irule_name = new_resource.irule_name || new_resource.name
  irule = ChefF5::IRule.new(node, new_resource, new_resource.load_balancer, new_resource.partition)

  if irule.is_missing?(actual_irule_name)
    converge_by "Create IRule #{actual_irule_name}" do
      irule.create(actual_irule_name, new_resource.definition)
      return
    end
  end

  if irule.definition_changed?(actual_irule_name, new_resource.definition)
    converge_by "Update definition of IRule #{actual_irule_name}" do
      irule.update_definition(actual_irule_name, new_resource.definition)
    end
  end
end

action :destroy do
  actual_irule_name = new_resource.irule_name || new_resource.name
  irule = ChefF5::IRule.new(node, new_resource, new_resource.load_balancer, new_resource.partition)

  unless irule.is_missing?(actual_irule_name)
    converge_by "Destroy IRule #{actual_irule_name}" do
      irule.destroy(name)
    end
  end
end

action_class do
  include ChefF5::GemHelper
end

