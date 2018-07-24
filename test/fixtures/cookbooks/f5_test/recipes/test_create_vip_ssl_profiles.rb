f5_vip 'myvip' do
  address '86.75.30.9'
  port '80'
  protocol 'PROTOCOL_TCP'
  pool 'reallybasic'
  client_ssl_profile 'client.cert'
  server_ssl_profile 'server.cert'
end
