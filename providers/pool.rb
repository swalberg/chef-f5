def whyrun_supported?
  true
end

action :create do
  chef_gem 'f5-icontrol'
end
