require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/vip'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_http_profile' do
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
    allow_any_instance_of(ChefF5::VIP).to receive(:vip_default_pool)
    allow_any_instance_of(ChefF5::VIP).to receive(:set_vip_pool)
    allow(server_api).to receive(:get_list) {
      { item: ['/Common/myvip'] }
    }
    allow(server_api).to receive(:get_destination_v2) {
      { item: { address: '86.75.30.9', port: '80' } }
    }
  end

  context 'when managing the vip' do
    before do
      # these vips have their SAT set to None
      allow(server_api)
        .to receive(:get_source_address_translation_type) {
              { item: [
                F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType::SRC_TRANS_NONE,
              ] }
            }
    end

    context 'and the http profile does not exist' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: {} } }
        }
      end

      it 'sets the http profile' do
        expect(server_api).to receive(:add_profile).with(
          hash_including(profiles: { item: [{ item: [
                           hash_including(profile_name: '/Common/http',
                                          profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member
                                         )] }] }))
        chef_run
      end
    end

    context 'and the http profile is correct' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: { profile_type: 'PROFILE_TYPE_HTTP', profile_context: 'PROFILE_CONTEXT_TYPE_ALL', profile_name: '/Common/http' } } }
        }
      end

      it 'does not change the http profile' do
        expect(server_api).not_to receive(:remove_profile)
        expect(server_api).not_to receive(:add_profile)
        chef_run
      end
    end

    context 'and the http profile is different' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: { profile_type: 'PROFILE_TYPE_HTTP', profile_context: 'PROFILE_CONTEXT_TYPE_ALL', profile_name: '/Common/http-access' } } }
        }
      end
      it 'sets the correct profile' do
        expect(server_api).to receive(:remove_profile).with(hash_including(profiles: { item: [{ item: [hash_including(profile_name: '/Common/http-access')] }] }))
        expect(server_api).to receive(:add_profile).with(
          hash_including(profiles: { item: [{ item: [
                           hash_including(profile_name: '/Common/http',
                                          profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_ALL.member
                                         )] }] }))
        chef_run
      end
    end
  end
end
