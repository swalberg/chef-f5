require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'

describe 'f5_test::test_other_lb' do

  let(:api) { double('F5::Icontrol') }

  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_pool']).converge(described_recipe) }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item("f5", "default").and_return({ host: '1.2.3.4', username: 'api', password: 'testing' })
    stub_data_bag_item("f5", "lb2").and_return({ host: '4.4.4.4', username: 'test2', password: 'testing' })
    allow_any_instance_of(ChefF5).to receive(:pool_is_missing?).and_return(false)
    allow_any_instance_of(ChefF5).to receive(:pool_is_missing_node?).and_return(false)
    allow(api).to receive_message_chain("LocalLB.NodeAddressV2") { double('API', get_list:  {:item=>["/Common/fauxhai.local", "/Common/two"], :"@s:type"=>"A:Array", :"@a:array_type"=>"y:string[2]"}) }
  end

  it 'calls the second load balancer' do
    expect(F5::Icontrol::API).to receive(:new).with(host: '4.4.4.4', username: 'test2', password: 'testing')
    chef_run
  end
end
