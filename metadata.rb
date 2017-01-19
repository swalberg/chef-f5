name             'f5'
maintainer       'Sean Walberg'
maintainer_email 'sean@ertw.com'
license          'MIT'
description      'LWRP to manage an f5 BigIP load balancer'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.9'
issues_url 'https://github.com/swalberg/chef-f5/issues' if respond_to?(:issues_url)
source_url 'https://github.com/swalberg/chef-f5/' if respond_to?(:source_url)

depends 'build-essential'
