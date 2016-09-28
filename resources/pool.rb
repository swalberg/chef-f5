actions :create, :delete

default_action :create

attribute :host, :kind_of => String, :regex => /.*/
attribute :ip, :kind_of => String, :regex => /.*/
attribute :port, :kind_of => Integer, :regex => /^\d+$/
attribute :monitor, :kind_of => String, :regex => /.*/
attribute :lb_method, :kind_of => String, :regex => /^[A-Z_]+$/
attribute :load_balancer, :kind_of => String, :regex => /.*/, default: 'default'
