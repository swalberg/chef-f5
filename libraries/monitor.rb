require_relative './base_client'
module ChefF5
  class Monitor < BaseClient
    PROPERTY_NAMES = %w(STYPE_UNSET STYPE_SEND STYPE_GET STYPE_RECEIVE STYPE_USERNAME STYPE_PASSWORD STYPE_RUN STYPE_NEWSGROUP STYPE_DATABASE STYPE_DOMAIN STYPE_ARGUMENTS STYPE_FOLDER STYPE_BASE STYPE_FILTER STYPE_SECRET STYPE_METHOD STYPE_URL STYPE_COMMAND STYPE_METRICS STYPE_POST STYPE_USERAGENT STYPE_AGENT_TYPE STYPE_CPU_COEFFICIENT STYPE_CPU_THRESHOLD STYPE_MEMORY_COEFFICIENT STYPE_MEMORY_THRESHOLD STYPE_DISK_COEFFICIENT STYPE_DISK_THRESHOLD STYPE_SNMP_VERSION STYPE_COMMUNITY STYPE_SEND_PACKETS STYPE_TIMEOUT_PACKETS STYPE_RECEIVE_DRAIN STYPE_RECEIVE_ROW STYPE_RECEIVE_COLUMN STYPE_DEBUG STYPE_SECURITY STYPE_MODE STYPE_CIPHER_LIST STYPE_NAMESPACE STYPE_PARAMETER_NAME STYPE_PARAMETER_VALUE STYPE_PARAMETER_TYPE STYPE_RETURN_TYPE STYPE_RETURN_VALUE STYPE_SOAP_FAULT STYPE_SSL_OPTIONS STYPE_CLIENT_CERTIFICATE STYPE_PROTOCOL STYPE_MANDATORY_ATTRS STYPE_FILENAME STYPE_ACCOUNTING_NODE STYPE_ACCOUNTING_PORT STYPE_SERVER_ID STYPE_CALL_ID STYPE_SESSION_ID STYPE_FRAMED_ADDRESS STYPE_PROGRAM STYPE_VERSION STYPE_SERVER STYPE_SERVICE STYPE_GW_MONITOR_ADDRESS STYPE_GW_MONITOR_SERVICE STYPE_GW_MONITOR_INTERVAL STYPE_GW_MONITOR_PROTOCOL STYPE_DB_COUNT STYPE_REQUEST STYPE_HEADERS STYPE_FILTER_NEG STYPE_SERVER_IP STYPE_SNMP_PORT STYPE_POOL_NAME STYPE_NAS_IP STYPE_CLIENT_KEY STYPE_MAX_LOAD_AVERAGE STYPE_CONCURRENCY_LIMIT STYPE_FAILURES STYPE_FAILURE_INTERVAL STYPE_RESPONSE_TIME STYPE_RETRY_TIME STYPE_DIAMETER_ACCT_APPLICATION_ID STYPE_DIAMETER_AUTH_APPLICATION_ID STYPE_DIAMETER_ORIGIN_HOST STYPE_DIAMETER_ORIGIN_REALM STYPE_DIAMETER_HOST_IP_ADDRESS STYPE_DIAMETER_VENDOR_ID STYPE_DIAMETER_PRODUCT_NAME STYPE_DIAMETER_VENDOR_SPECIFIC_VENDOR_ID STYPE_DIAMETER_VENDOR_SPECIFIC_ACCT_APPLICATION_ID STYPE_DIAMETER_VENDOR_SPECIFIC_AUTH_APPLICATION_ID STYPE_RUN_V2 STYPE_CLIENT_CERTIFICATE_V2 STYPE_CLIENT_KEY_V2).freeze unless defined?(PROPERTY_NAMES)
    def monitor_is_missing?(name)
      response = api.LocalLB.Monitor.get_template_list

      return true if response[:item].nil?
      response[:item].find { |t| t[:template_name] == with_partition(name) }.nil?
    end

    def create_monitor(name, **attributes)
      template_type = attributes.delete(:template_type) || 'TTYPE_HTTP'
      dest_ip = attributes.delete :dest_ip
      dest_port = attributes.delete :dest_port
      attributes[:dest_ipport] = {
        address_type: address_type(dest_ip, dest_port),
        ipport: {
          address: dest_ip,
          port: dest_port,
        },
      }
      api.LocalLB.Monitor.create_template(
        templates: { item: [{ template_name: with_partition(name), template_type: template_type }] },
        template_attributes: { item: [attributes] }
      )
    end

    def delete_monitor(name)
      api.LocalLB.Monitor.delete_template(
        template_names: { item: [with_partition(name)] }
      )
    end

    def common_attributes_changed?(name, dest_ip:, dest_port:)
      current = api.LocalLB.Monitor.get_template_destination(template_names: { item: [with_partition(name)] })
      current_dest_ip = current[:item][:ipport][:address]
      current_dest_port = current[:item][:ipport][:port]
      current_dest_type = current[:item][:address_type]
      current_dest_ip != dest_ip ||
        current_dest_port != dest_port ||
        current_dest_type != address_type(dest_ip, dest_port)
    end

    def update_common_attributes(name, dest_ip:, dest_port:)
      api.LocalLB.Monitor.set_template_destination(
        template_names: { item: [with_partition(name)] },
        destinations: { item: [{ address_type: address_type(dest_ip, dest_port),
                                 ipport: { address: dest_ip, port: dest_port } }] }
      )
    end

    # Returns keys that don't match
    def string_properties_match?(name, properties)
      validate_string_properties(name, properties)
      properties.each_with_object([]) do |(prop, value), out|
        current = api.LocalLB.Monitor.get_template_string_property(
          template_names: { item: [with_partition(name)] },
          property_types: { item: [prop] }
        )
        out << prop unless current[:item][:value] == value
      end
    end

    def validate_string_properties(name, properties)
      bad_props = properties.keys.select { |prop| !PROPERTY_NAMES.include?(prop) }
      msg = "Invalid properties for monitor #{name}. "\
        "Bad properties: #{bad_props.join(', ')} "\
        "Valid property names are: #{PROPERTY_NAMES.join ', '}"
      raise ArgumentError, msg unless bad_props.empty?
    end

    def update_string_properties(name, mismatches, properties)
      properties.each do |prop, value|
        next unless mismatches.include? prop
        api.LocalLB.Monitor.set_template_string_property(
          template_names: { item: [with_partition(name)] },
          values: { item: [{ type: prop, value: value }] })
      end
    end

    def address_type(dest_ip, dest_port)
      # All possible types from F5 documenation: ATYPE_UNSET|ATYPE_STAR_ADDRESS_STAR_PORT|ATYPE_STAR_ADDRESS_EXPLICIT_PORT|ATYPE_EXPLICIT_ADDRESS_EXPLICIT_PORT|ATYPE_STAR_ADDRESS|ATYPE_EXPLICIT_ADDRESS
      # https://devcentral.f5.com/Wiki/iControl.LocalLB__AddressType.ashx
      # The types are redundant so the case statement below covers all relevant
      # combinations.
      ip_0 = '0.0.0.0'
      if dest_ip == ip_0 && dest_port == '0'
        'ATYPE_STAR_ADDRESS_STAR_PORT'
      elsif dest_ip != ip_0 && dest_port != '0'
        'ATYPE_EXPLICIT_ADDRESS_EXPLICIT_PORT'
      elsif dest_ip == ip_0 && dest_port != '0'
        'ATYPE_STAR_ADDRESS_EXPLICIT_PORT'
      else
        'ATYPE_UNSET'
      end
    end

    def timeout_changed?(name, timeout)
      current = api.LocalLB.Monitor.get_template_integer_property(
        template_names: { item: [with_partition(name)] },
        property_types: { item: ['ITYPE_TIMEOUT'] }
      )
      current[:item][:value].to_i != timeout
    end

    def update_timeout(name, timeout)
      api.LocalLB.Monitor.set_template_integer_property(
        template_names: { item: [with_partition(name)] },
        values: { item: [{ type: 'ITYPE_TIMEOUT', value: timeout.to_s }] }
      )
    end

    def interval_changed?(name, interval)
      current = api.LocalLB.Monitor.get_template_integer_property(
        template_names: { item: [with_partition(name)] },
        property_types: { item: ['ITYPE_INTERVAL'] }
      )
      current[:item][:value].to_i != interval
    end

    def update_interval(name, interval)
      api.LocalLB.Monitor.set_template_integer_property(
        template_names: { item: [with_partition(name)] },
        values: { item: [{ type: 'ITYPE_INTERVAL', value: interval.to_s }] }
      )
    end
  end
end
