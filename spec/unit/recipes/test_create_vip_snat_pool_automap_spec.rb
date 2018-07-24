require 'spec_helper'
require 'f5/icontrol'
require 'f5/icontrol/locallb/virtual_server/source_address_translation'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_snat_pool_automap' do
  let(:api) { double('F5::Icontrol') }
  let(:server_api) { double('F5::Icontrol::LocalLB::VirtualServer') }
  let(:sat_type) {
    F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType
  }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '7.2.1511',
      step_into: ['f5_vip']
    ) do |node|
      node.normal[:f5][:credentials][:default] = {
        host: '1.2.3.4',
        username: 'api',
        password: 'testing'
      }
    end.converge(described_recipe)
  end

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }

    allow(api)
      .to receive_message_chain('LocalLB.VirtualServer') { server_api }

    allow_any_instance_of(Chef::RunContext::CookbookCompiler)
      .to receive(:compile_libraries).and_return(true)

    stub_data_bag_item('f5', 'default')
      .and_return(host: '1.2.3.4', username: 'api', password: 'testing')
  end

  context 'when managing a new vip' do
    before do
      allow(server_api).to receive(:get_list) {
        { item: [] }
      }

      # these stub out methods not relevant to this context:
      allow(server_api).to receive(:create)
      allow(server_api).to receive(:set_type)
      allow(server_api).to receive(:get_default_pool_name) {
        { item: [] }
      }
      allow(server_api).to receive(:set_default_pool_name)
    end

    context 'and the SNAT pool type is incorrect' do
      before do
        allow(server_api)
          .to receive(:get_source_address_translation_type) {
            { item: sat_type::SRC_TRANS_NONE.member }
        }

        # must allow the client profile to be set
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
        allow(server_api).to receive(:add_profile)
      end

      it 'sets the SNAT pool' do
        expect(server_api).to receive(:set_source_address_translation_automap)
        chef_run
      end
    end

    context 'and the SNAT pool type is correct' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: sat_type::SRC_TRANS_AUTOMAP.member }
        }
      end

      it 'does not set the SNAT pool' do
        expect(server_api)
          .to_not receive(:set_source_address_translation_automap)
      end
    end
  end

  context 'when managing an existing vip' do
    before do
      allow(server_api).to receive(:get_list) {
        { item: ['/Common/myvip'] }
      }

      # these stub out methods not relevant to this context:
      allow(server_api).to receive(:get_default_pool_name) {
        { item: [] }
      }
      allow(server_api).to receive(:set_default_pool_name)
    end

    context 'and the SNAT pool type is incorrect' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: sat_type::SRC_TRANS_NONE.member }
        }

        # must allow the client profile to be set
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
        allow(server_api).to receive(:add_profile)
      end

      it 'sets the SNAT pool' do
        expect(server_api).to receive(:set_source_address_translation_automap)
        chef_run
      end
    end

    context 'and the SNAT pool type is correct' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: sat_type::SRC_TRANS_AUTOMAP.member }
        }
      end

      it 'does not set the SNAT pool' do
        expect(server_api)
          .to_not receive(:set_source_address_translation_automap)
      end
    end
  end
end
