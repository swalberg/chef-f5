f5_pool 'reallybasic' do
  ip node['ipaddress']
  host node['fqdn']
  port 80
  monitor 'test-monitor'
end
