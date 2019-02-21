property :monitor_name, [NilClass, String], default: nil
property :template_type, String, regex: /TTYPE_UNSET|TTYPE_ICMP|TTYPE_TCP|TTYPE_TCP_ECHO|TTYPE_EXTERNAL|TTYPE_HTTP|TTYPE_HTTPS|TTYPE_NNTP|TTYPE_FTP|TTYPE_POP3|TTYPE_SMTP|TTYPE_MSSQL|TTYPE_GATEWAY|TTYPE_IMAP|TTYPE_RADIUS|TTYPE_LDAP|TTYPE_WMI|TTYPE_SNMP_DCA|TTYPE_SNMP_DCA_BASE|TTYPE_REAL_SERVER|TTYPE_UDP|TTYPE_NONE|TTYPE_ORACLE|TTYPE_SOAP|TTYPE_GATEWAY_ICMP|TTYPE_SIP|TTYPE_TCP_HALF_OPEN|TTYPE_SCRIPTED|TTYPE_WAP|TTYPE_RPC|TTYPE_SMB|TTYPE_SASP|TTYPE_MODULE_SCORE|TTYPE_FIREPASS|TTYPE_INBAND|TTYPE_RADIUS_ACCOUNTING|TTYPE_DIAMETER|TTYPE_VIRTUAL_LOCATION|TTYPE_MYSQL|TTYPE_POSTGRESQL/
property :parent_template, String
property :interval, Integer
property :timeout, Integer
property :dest_ip, String, default: '0.0.0.0'
property :dest_port, String, default: '0'
property :read_only, [TrueClass, FalseClass], default: false
property :directly_usable, [TrueClass, FalseClass], default: true
property :string_properties, Hash, default: {}
property :load_balancer, String, regex: /.*/, default: 'default'
property :lb_host, String
property :lb_username, String
property :lb_password, String
property :partition, String, default: 'Common'

action :create do
  load_f5_gem
  actual_monitor_name = new_resource.monitor_name || new_resource.name
  monitor = ChefF5::Monitor.new(node, new_resource, new_resource.load_balancer, new_resource.partition)
  if monitor.monitor_is_missing?(actual_monitor_name)
    converge_by "Create monitor template #{actual_monitor_name}" do
      monitor.create_monitor(actual_monitor_name, **f5_attributes)
    end
  end

  changeable_attributes = {
    dest_ip: new_resource.dest_ip,
    dest_port: new_resource.dest_port,
  }
  if monitor.common_attributes_changed?(actual_monitor_name, **changeable_attributes)
    converge_by "Update common attributes on monitor template #{actual_monitor_name}" do
      monitor.update_common_attributes(actual_monitor_name, **changeable_attributes)
    end
  end

  mismatches = monitor.string_properties_match?(actual_monitor_name, new_resource.string_properties)
  unless mismatches.empty?
    msg = "The following string properties are being updated: #{mismatches.join ', '}"
    converge_by msg do
      monitor.update_string_properties(actual_monitor_name, mismatches, new_resource.string_properties)
    end
  end

  if monitor.timeout_changed?(actual_monitor_name, new_resource.timeout)
    converge_by 'Updating timeout' do
      monitor.update_timeout(actual_monitor_name, new_resource.timeout)
    end
  end

  if monitor.interval_changed?(actual_monitor_name, new_resource.interval)
    converge_by 'Updating interval' do
      monitor.update_interval(actual_monitor_name, new_resource.interval)
    end
  end
end

action :destroy do
  load_f5_gem
  actual_monitor_name = new_resource.monitor_name || new_resource.name
  monitor = ChefF5::Monitor.new(node, new_resource, new_resource.load_balancer, new_resource.partition)
  unless monitor.monitor_is_missing?(actual_monitor_name)
    converge_by "Deleting monitor template #{actual_monitor_name}" do
      monitor.delete_monitor(actual_monitor_name)
    end
  end
end

action_class do
  include ChefF5::GemHelper
  def f5_attributes
    {
      template_type: new_resource.template_type,
      parent_template: new_resource.parent_template,
      interval: new_resource.interval,
      timeout: new_resource.timeout,
      dest_ip: new_resource.dest_ip,
      dest_port: new_resource.dest_port,
      is_read_only: new_resource.read_only,
      is_directly_usable: new_resource.directly_usable,
    }
  end
end
