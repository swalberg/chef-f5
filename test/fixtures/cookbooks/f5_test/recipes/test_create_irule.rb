f5_irule 'test-irule' do
  definition <<-EOL
# For hosts that serve both http but attached to http and https vips,
# this lets them know if the request
# originally came in on https
when HTTP_REQUEST {
  HTTP::header insert HTTPS true
}
  EOL
end
