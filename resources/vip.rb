actions :create, :delete

default_action :create

attribute :address, kind_of: String, regex: /.*/
attribute :port, kind_of: [Integer, String], regex: /^\d+$/
attribute :protocol, kind_of: String, regex: /^[A-Z_]+$/, default: 'PROTOCOL_TCP'
attribute :pool, kind_of: String, regex: /.*/
attribute :load_balancer, kind_of: String, regex: /.*/, default: 'default'
attribute :lb_host, kind_of: String
attribute :lb_username, kind_of: String
attribute :lb_password, kind_of: String
