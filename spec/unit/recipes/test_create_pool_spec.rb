require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_pool' do
  let(:api) { double('F5::Icontrol') }

  let(:chef_run) {
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_pool']).converge(described_recipe)
  }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
  end

  context 'managing the pool' do
    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_enabled?).and_return(true)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
    end

    context 'the pool does not exist' do
      before do
        allow(api).to receive_message_chain('LocalLB.Pool.get_list') {
          { :item => ['/Common/test1', '/Common/mchan01'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }
      end

      it 'creates the pool' do
        expect(api).to receive_message_chain('LocalLB', 'Pool', 'create_v2') { true }

        expect(chef_run).to create_f5_pool('reallybasic').with(
          ip: '10.0.0.2',
          host: 'fauxhai.local',
          port: 80,
          monitor: 'test-monitor'
        )
      end
    end

    context 'the pool already exists' do
      let (:pool) { double }

      before do
        allow(api).to receive_message_chain('LocalLB.Pool') { pool }
        allow(pool).to receive(:get_list) {
          { :item => ['/Common/reallybasic', '/Common/mchan01'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }
      end

      it 'does not create the pool' do
        expect(pool).to_not receive(:create_v2)
        chef_run
      end

      context 'the pool exists but is different' do
      end
    end
  end

  context 'managing manually enabled nodes' do
    let (:node) { double }

    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_enabled?).and_return(true)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
      allow(api).to receive_message_chain('LocalLB.NodeAddressV2') { node }
    end

    context 'the node exists' do
      before do
        expect(node).to receive(:get_list) {
          { :item => ['/Common/fauxhai.local', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }
      end

      it 'does not add the node' do
        expect(node).to_not receive(:create)
        chef_run
      end

      it 'does not set the node enabled status' do
        expect(node).to_not receive(:set_session_enabled_state)
        chef_run
      end
    end

    context 'the node does not exist' do
      before do
        expect(node).to receive(:get_list) {
          { :item => ['/Common/a', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }
      end

      it 'does add the node' do
        expect(node).to receive(:create)
        chef_run
      end

      it 'does not set the node enabled status' do
        allow(node).to receive(:create)
        expect(node).to_not receive(:set_session_enabled_state)
        chef_run
      end
    end
  end

  context 'managing a monitor' do
    let (:pool) { double }
    let (:node) { double }

    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_enabled?).and_return(true)
      allow(api).to receive_message_chain('LocalLB.Pool') { pool }
      allow(api).to receive_message_chain('LocalLB.NodeAddressV2') { node }
      expect(node).to receive(:get_list) {
        { :item => ['/Common/fauxhai.local', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
      }
      allow(pool).to receive(:get_monitor_association) {
        { :item => { pool_name: '/Common/reallybasic', monitor_rule: { :type => 'MONITOR_RULE_TYPE_SINGLE', :quorum => '0', :monitor_templates => { :item => '/Common/test-monitor', :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[1]' }, :"@s:type" => 'iControl:LocalLB.MonitorRule' } }, :"@s:type" => 'A:Array', :"@a:array_type" => 'iControl:LocalLB.Pool.MonitorAssociation[1]' }
      }
    end
    context 'the monitor is already on assigned to the pool' do
      before do
        allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
      end
      it 'doesnt add the monitor to the pool' do
        expect(pool).to_not receive(:set_monitor_association)
        chef_run
      end
    end

    context 'the monitor isnt assigned to the pool' do
      before do
        allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(true)
      end
      it 'adds the monitor to the pool' do
        expect(pool).to receive(:set_monitor_association)
        chef_run
      end
    end
  end
end
