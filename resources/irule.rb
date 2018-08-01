property :name, String
property :definition, String
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String

action :create do
  load_f5_gem
  irule = ChefF5::IRule.new(node, new_resource, new_resource.load_balancer)

  if irule.is_missing?(new_resource.name)
    converge_by "Create IRule #{new_resource.name}" do
      irule.create(new_resource.name, new_resource.definition)
      return
    end
  end

  if irule.definition_changed?(new_resource.name, new_resource.definition)
    converge_by "Update definition of IRule #{new_resource.name}" do
      irule.update_definition(new_resource.name, new_resource.definition)
    end
  end
end

action :destroy do
  unless irule.is_missing?(new_resource.name)
    converge_by "Destroy IRule #{new_resource.name}" do
      irule.destroy(name)
    end
  end
end

action_class do
  include ChefF5::GemHelper
end

