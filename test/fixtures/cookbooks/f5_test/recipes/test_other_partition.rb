f5_pool 'reallybasic' do
  ip '127.0.0.1'
  host 'test_host'
  port 80
  load_balancer 'lb2'
  partition 'DMZ'
end
