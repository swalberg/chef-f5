f5_vip 'myvip' do
  address 'github.com'
  port '80'
  protocol 'PROTOCOL_TCP'
  pool 'reallybasic'
  irules('test-irule' => 0, 'test-irule-2' => 1)
end
