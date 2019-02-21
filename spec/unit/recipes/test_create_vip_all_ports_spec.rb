require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/vip'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_all_ports' do
  let(:api) { double('F5::Icontrol') }
  let(:server_api) { double('F5::Icontrol::LocalLB::VirtualServer') }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '7.3.1611',
      step_into: ['f5_vip']
    ) do |node|
      node.normal[:f5][:credentials][:default] = {
        host: '1.2.3.4',
        username: 'api',
        password: 'testing',
      }
    end.converge(described_recipe)
  end

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow(api).to receive_message_chain('System.Session.set_active_folder')
    allow(api)
      .to receive_message_chain('LocalLB.VirtualServer') { server_api }

    allow_any_instance_of(Chef::RunContext::CookbookCompiler)
      .to receive(:compile_libraries).and_return(true)

    stub_data_bag_item('f5', 'default')
      .and_return(host: '1.2.3.4', username: 'api', password: 'testing')
    allow(server_api).to receive(:get_rule).and_return(item: {})
  end

  context 'when managing the vip' do
    before do
      # these vips have no profiles
      allow(server_api).to receive(:get_profile) {
        { item: { item: [] } }
      }

      allow(server_api).to receive(:get_destination_v2) {
        { item: { address: '86.75.30.9', port: '80' } }
      }

      # these vips have their SAT set to None
      allow(server_api)
        .to receive(:get_source_address_translation_type) {
              { item: [
                F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType::SRC_TRANS_NONE,
              ] }
            }
    end

    context 'and the vip does not exist' do
      before do
        allow(server_api).to receive(:get_list) {
          { item: [] }
        }
        allow(server_api).to receive(:get_destination_v2) {
          { item: { address: '86.75.30.9', port: '0' } }
        }
      end

      it 'creates the vip with port 0 (i.e. any)' do
        allow_any_instance_of(ChefF5::VIP)
          .to receive(:vip_default_pool).and_return('reallybasic')

        expect(server_api).to receive(:create).with(
          definitions: {
            item: {
              name: '/Common/myvip',
              address: '86.75.30.9',
              port: '0',
              protocol: 'PROTOCOL_TCP' },
          },
          wildmasks: { item: '255.255.255.255' },
          resources: {
            item: {
              type: 'RESOURCE_TYPE_REJECT',
              default_pool_name: '',
            },
          },
          profiles: {
            item: [
              item: {
                profile_context: 'PROFILE_CONTEXT_TYPE_ALL',
                profile_name: 'http',
              },
            ],
          }
        )

        expect(server_api).to receive(:set_type)
        chef_run
      end
    end

    context 'and the vip already exists' do
      before do
        allow(server_api).to receive(:get_list) {
          { item: ['/Common/myvip'] }
        }
        allow(server_api).to receive(:get_destination_v2) {
          { item: { address: '86.75.30.9', port: '0' } }
        }
      end

      it 'does not create the vip' do
        allow_any_instance_of(ChefF5::VIP).to receive(:vip_default_pool)
        allow_any_instance_of(ChefF5::VIP).to receive(:set_vip_pool)
        chef_run
      end
    end
  end
end
