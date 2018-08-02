f5_vip 'myvip' do
  address 'github.com'
  port '80'
  protocol 'PROTOCOL_TCP'
  pool 'reallybasic'
  irules %w(test-irule test-irule-2)
end
