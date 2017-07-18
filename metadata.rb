name             'f5'
maintainer       'Sean Walberg'
maintainer_email 'sean@ertw.com'
license          'MIT'
description      'LWRP to manage an F5 BigIP load balancer'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.9'
issues_url 'https://github.com/swalberg/chef-f5/issues'
source_url 'https://github.com/swalberg/chef-f5/'
chef_version '>= 12.1' if respond_to?(:chef_version)
supports 'all'
depends 'build-essential'
