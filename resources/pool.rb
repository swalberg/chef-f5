actions :create, :delete

default_action :create

attribute :host, kind_of: String, regex: /.*/
attribute :ip, kind_of: String, regex: /.*/
attribute :port, kind_of: [String, Integer], regex: /^\d+$/
attribute :monitor, kind_of: String, regex: /.*/
attribute :lb_method, kind_of: String, regex: /^[A-Z_]+$/
attribute :load_balancer, kind_of: String, regex: /.*/, default: 'default'
attribute :lb_host, kind_of: String
attribute :lb_username, kind_of: String
attribute :lb_password, kind_of: String
