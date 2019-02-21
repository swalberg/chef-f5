require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_pool_add_action' do
  let(:api) { double('F5::Icontrol') }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_pool']).converge(described_recipe)
  end

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
  end

  context 'managing manually enabled nodes' do
    let (:node) { double }
    let (:pool) { double }

    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_enabled?).and_return(true)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
      allow(api).to receive_message_chain('LocalLB.NodeAddressV2') { node }
      allow(api).to receive_message_chain('LocalLB.Pool') { pool }
      allow(pool).to receive(:get_member_ratio).and_return(item: { item: '1', "@a:array_type": 'y:long[1]' }, "@s:type": 'A:Array', "@a:array_type": 'y:long[][1]')
      allow(api).to receive_message_chain('System.Session.set_active_folder')
    end

    context 'the node exists' do
      before do
        expect(node).to receive(:get_list) {
          { item: ['/Common/fauxhai.local', '/Common/two'], "@s:type": 'A:Array', "@a:array_type": 'y:string[2]' }
        }
      end

      it 'does not add the node' do
        expect(pool).to_not receive(:get_list)
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
          { item: ['/Common/a', '/Common/two'], "@s:type": 'A:Array', "@a:array_type": 'y:string[2]' }
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

    context 'when the pool member ratio has changed' do
      before do
        allow_any_instance_of(ChefF5::Client).to receive(:node_is_missing?).and_return(false)
        allow(pool).to receive(:get_member_ratio) {
          { item: { item: '2', "@a:array_type": 'y:long[1]' }, "@s:type": 'A:Array', "@a:array_type": 'y:long[][1]' }
        }
      end
      it 'update the pool member ratio' do
        expect(pool).to receive(:set_member_ratio).with(pool_names: { item: ['/Common/reallybasic'] },
                                                        members: { item: { item: [{ address: 'fauxhai.local', port: 80 }] } },
                                                        ratios: { item: { item: [1] } })

        chef_run
      end
    end
  end
end
