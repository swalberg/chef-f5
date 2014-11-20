actions :create, :delete

default_action :create

attribute :host, :kind_of => String, :regex => /.*/
attribute :port, :kind_of => String, :regex => /^\d+$/
attribute :lb_method, :kind_of => String, :regex => /^[A-Z_]+$/

