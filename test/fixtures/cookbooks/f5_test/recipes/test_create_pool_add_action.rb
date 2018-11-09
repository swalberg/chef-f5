f5_pool 'reallybasic' do
  ip node['ipaddress']
  host node['fqdn']
  port 80
  action :add
  ratio 1
end
