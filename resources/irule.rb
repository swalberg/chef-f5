property :irule_name, String, name_property: true
property :definition, String
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :partition, String, default: 'Common'

action :create do
  load_f5_gem
  irule = ChefF5::IRule.new(node, new_resource, new_resource.load_balancer, new_resource.partition)
  if irule.missing?(new_resource.irule_name)
    converge_by "Create IRule #{new_resource.irule_name}" do
      irule.create(new_resource.irule_name, new_resource.definition)
      return
    end
  end

  if irule.definition_changed?(new_resource.irule_name, new_resource.definition)
    converge_by "Update definition of IRule #{new_resource.irule_name}" do
      irule.update_definition(new_resource.irule_name, new_resource.definition)
    end
  end
end

action :destroy do
  irule = ChefF5::IRule.new(node, new_resource, new_resource.load_balancer, new_resource.partition)

  unless irule.missing?(new_resource.irule_name)
    converge_by "Destroy IRule #{new_resource.irule_name}" do
      irule.destroy(name)
    end
  end
end

action_class do
  include ChefF5::GemHelper
end
