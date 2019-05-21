require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/vip'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/dns_lookup'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_irules' do
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
    allow(server_api).to receive(:get_destination_v2) {
      { item: { address: '192.30.253.112', port: '80' } }
    }
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

      allow(server_api).to receive(:get_list).and_return item: ['/Common/myvip']
    end

    context 'and the VIP does not have irules before' do
      before do
        allow(server_api).to receive(:get_rule).and_return(item: {})
        allow_any_instance_of(ChefF5::VIP)
          .to receive(:vip_default_pool).and_return('reallybasic')
      end
      it 'creates the irules' do
        expect(server_api).to receive(:add_rule).with(virtual_servers: { item: ['/Common/myvip'] },
                                                      rules: { item: { item: [{ rule_name: '/Common/test-irule', priority: '0' }] } })
        expect(server_api).to receive(:add_rule).with(virtual_servers: { item: ['/Common/myvip'] },
                                                      rules: { item: { item: [{ rule_name: '/Common/test-irule-2', priority: '1' }] } })
        chef_run
      end
    end

    context 'and an IRule has been deleted' do
      before do
        allow(server_api).to receive(:get_rule).and_return(item: { item: [{ rule_name: '/Common/test-irule', priority: '0' }, { rule_name: '/Common/test-irule-2', priority: '1' }, { rule_name: '/Common/test-irule-3', priority: '2' }] })
        allow_any_instance_of(ChefF5::VIP)
          .to receive(:vip_default_pool).and_return('reallybasic')
      end
      it 'deletes the extra IRule' do
        allow(server_api).to receive(:get_destination_v2) {
          { item: { address: '192.30.253.112', port: '80' } }
        }
        expect(server_api).to receive(:remove_rule).with(virtual_servers: { item: ['/Common/myvip'] },
                                                         rules: { item: { item: [{ rule_name: '/Common/test-irule-3', priority: '0' }] } })
        chef_run
      end
    end
    context 'and the IRules have changed' do
      before do
        allow(server_api).to receive(:get_rule).and_return(item: { item: [{ rule_name: '/Common/test-irule', priority: '1' }, { rule_name: '/Common/test-irule-2', priority: '0' }] })
        allow_any_instance_of(ChefF5::VIP)
          .to receive(:vip_default_pool).and_return('reallybasic')
        # allow_any_instance_of(ChefF5::VIP)
        #   .to receive(:irules_changed?).and_return([[],[],[],{}])
      end
      it 'updates the irules' do
        expect(server_api).to receive(:remove_rule).with(virtual_servers: { item: ['/Common/myvip'] },
                                                         rules: { item: { item: [{ rule_name: '/Common/test-irule-2', priority: '0' }] } })
        expect(server_api).to receive(:add_rule).with(virtual_servers: { item: ['/Common/myvip'] },
                                                      rules: { item: { item: [{ rule_name: '/Common/test-irule-2', priority: '2' }] } })
        chef_run
      end
    end
  end
end
