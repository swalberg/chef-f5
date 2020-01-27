require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_other_partition' do
  let(:api) { double('F5::Icontrol') }
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '18.04', step_into: ['f5_pool']).converge(described_recipe) }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow(api).to receive_message_chain('System.Session.set_active_folder').and_raise(ArgumentError)
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
    stub_data_bag_item('f5', 'lb2').and_return(host: '4.4.4.4', username: 'test2', password: 'testing')
  end

  it 'calls the second load balancer' do
    expect(F5::Icontrol::API).to receive(:new).with(nil, host: '4.4.4.4', username: 'test2', password: 'testing')
    expect(api).to receive_message_chain('System.Session.set_active_folder').with(folder: '/DMZ')
    expect { chef_run }.to raise_error(ArgumentError)
  end
end
