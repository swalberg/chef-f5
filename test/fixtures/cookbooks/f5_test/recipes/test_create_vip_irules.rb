f5_vip 'myvip' do
  address '192.30.253.112'
  port '80'
  protocol 'PROTOCOL_TCP'
  pool 'reallybasic'
  irules %w(test-irule test-irule-2)
end
