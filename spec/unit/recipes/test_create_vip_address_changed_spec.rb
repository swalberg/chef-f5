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

      # these vips have their SAT set to None
      allow(server_api)
        .to receive(:get_source_address_translation_type) {
              { item: [
                F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType::SRC_TRANS_NONE,
              ] }
            }
      allow(server_api).to receive(:get_list) {
        { item: ['/Common/myvip'] }
      }
      allow_any_instance_of(ChefF5::VIP).to receive(:vip_default_pool)
      allow_any_instance_of(ChefF5::VIP).to receive(:set_vip_pool)
    end

    context 'and the ip address has changed' do
      before do
        allow(server_api).to receive(:get_destination_v2) {
          { item: { address: '86.75.30.10', port: '0' } }
        }
      end
      it 'updates the address' do
        expect(server_api).to receive(:set_destination_v2).with(virtual_servers: { item: ['/Common/myvip'] },
                                                                destinations: { item: [{ address: '86.75.30.9', port: '0' }] })
        chef_run
      end
    end
    context 'and the port has changed' do
      before do
        allow(server_api).to receive(:get_destination_v2) {
          { item: { address: '86.75.30.9', port: '80' } }
        }
      end
      it 'updates the address' do
        expect(server_api).to receive(:set_destination_v2).with(virtual_servers: { item: ['/Common/myvip'] },
                                                                destinations: { item: [{ address: '86.75.30.9', port: '0' }] })
        chef_run
      end
    end

    context 'nothing has changed' do
      before do
        allow(server_api).to receive(:get_destination_v2) {
          { item: { address: '86.75.30.9', port: '0' } }
        }
      end
      it 'does not update the address' do
        expect(server_api).not_to receive(:set_destination_v2)
        chef_run
      end
    end
  end
end
