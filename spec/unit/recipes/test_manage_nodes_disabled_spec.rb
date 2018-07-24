require 'spec_helper'
require 'f5/icontrol'
require 'f5/icontrol/locallb/enabled_status'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_manage_nodes_disabled' do
  let(:api) { double('F5::Icontrol') }
  let (:node) { double('node') }
  let(:chef_run) {
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_pool']).converge(described_recipe)
  }
  let(:enabled_status) { F5::Icontrol::LocalLB::EnabledStatus }
  let(:enabled_state)  { F5::Icontrol::Common::EnabledState }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow(api).to receive_message_chain('LocalLB.NodeAddressV2') { node }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
  end

  context 'managing explicitly disabled nodes' do
    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
    end

    context 'when the node does not exist' do
      before do
        expect(node).to receive(:get_list) {
          { :item => ['/Common/a', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }

        # after the node is created, it's default status will be enabled:
        # https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__get_object_status.ashx
        allow(node).to receive(:get_object_status).with({
            nodes: { item: ['/Common/fauxhai.local'] }
          }).and_return({ item: {
            availability_status: [],
            enabled_status: enabled_status::ENABLED_STATUS_ENABLED.member,
            status_description: ''
        }})
      end

      it 'does add the node' do
        expect(node).to receive(:create)
        allow(node).to receive(:set_session_enabled_state)
        chef_run
      end

      it 'does set the node enabled status to disabled' do
        allow(node).to receive(:create)
        # https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__set_session_enabled_state.ashx
        expect(node).to receive(:set_session_enabled_state).with({
          nodes: { item: [ '/Common/fauxhai.local' ] },
          states: { item: [ enabled_state::STATE_DISABLED ] }
        })
        chef_run
      end
    end

    context 'the node exists' do
      before do
        expect(node).to receive(:get_list) {
          { :item => ['/Common/fauxhai.local', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }
      end

      context 'and is enabled' do
        before do
          # https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__get_object_status.ashx
          allow(node).to receive(:get_object_status).with({
              nodes: { item: ['/Common/fauxhai.local'] }
            }).and_return({ item: {
              availability_status: [],
              enabled_status: enabled_status::ENABLED_STATUS_ENABLED.member,
              status_description: ''
            }})
        end

        it 'does not add the node' do
          expect(node).to_not receive(:create)
          allow(node).to receive(:set_session_enabled_state)
          chef_run
        end

        it 'does set the node enabled status to disabled' do
          # https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__set_session_enabled_state.ashx
          expect(node).to receive(:set_session_enabled_state).with({
            nodes: { item: [ '/Common/fauxhai.local' ] },
            states: { item: [ enabled_state::STATE_DISABLED ] }
          })
          chef_run
        end
      end

      context 'and is disabled' do
        before do
          # https://devcentral.f5.com/wiki/iControl.LocalLB__NodeAddressV2__get_object_status.ashx
          allow(node).to receive(:get_object_status).with({
              nodes: { item: ['/Common/fauxhai.local'] }
            }).and_return({ item: {
              availability_status: [],
              enabled_status: enabled_status::ENABLED_STATUS_DISABLED.member,
              status_description: ''
            }})
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
    end
  end
end
