name             'f5'
maintainer       'Sean Walberg'
maintainer_email 'sean@ertw.com'
license          'MIT'
description      'Resources for managing an F5 BigIP load balancer'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.4.0'

%w(ubuntu debian redhat centos suse opensuse opensuseleap scientific oracle amazon windows).each do |os|
  supports os
end

issues_url 'https://github.com/swalberg/chef-f5/issues'
source_url 'https://github.com/swalberg/chef-f5/'
chef_version '>= 12.7' if respond_to?(:chef_version)
