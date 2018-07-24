f5_vip 'myvip' do
  address '86.75.30.9'
  port '80'
  protocol 'PROTOCOL_TCP'
  pool 'reallybasic'
  staged_firewall_policy :none
end
