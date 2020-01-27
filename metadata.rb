name             'f5'
maintainer       'Sean Walberg'
maintainer_email 'sean@ertw.com'
license          'MIT'
description      'Resources for managing an F5 BigIP load balancer'
version          '0.4.13'

%w(ubuntu debian redhat centos suse opensuseleap scientific oracle amazon windows).each do |os|
  supports os
end

issues_url 'https://github.com/swalberg/chef-f5/issues'
source_url 'https://github.com/swalberg/chef-f5/'
chef_version '>= 12.7'
