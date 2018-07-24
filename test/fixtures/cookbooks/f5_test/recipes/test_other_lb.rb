f5_pool 'reallybasic' do
  ip node['ipaddress']
  host node['fqdn']
  port 80
  load_balancer 'lb2'
end
