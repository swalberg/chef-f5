f5_monitor 'test-monitor' do
  template_type 'TTYPE_HTTP'
  parent_template 'http'
  interval 5
  timeout 10
  string_properties(
    'STYPE_SEND' => 'GET /health HTTP/1.1\r\nHost: dontmatter\r\nConnection: Close\r\n\r\n',
    'STYPE_RECEIVE' => 'status.*UP'
  )
end
