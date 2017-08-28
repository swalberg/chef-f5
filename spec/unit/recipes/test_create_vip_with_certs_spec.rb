require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_with_certs' do
  let(:api) { double('F5::Icontrol') }
  let(:server_api) { double('F5::Icontrol::LocalLB::VirtualServer') }

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

  context 'when managing an new vip' do
    before do
      allow(server_api).to receive(:get_list) {
        { item: [] }
      }
    end

    context 'and the client ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
      end

      it 'adds the client ssl profile'
    end

    context 'and the client ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: 6, # PROFILE_TYPE_CLIENT_SSL
              profile_context: 1, # PROFILE_CONTEXT_TYPE_CLIENT
              profile_name: '/Common/client.cert'
            }]] }
        }
      end

      it 'does not add the client ssl profile'
    end

    context 'and the client ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
      end

      it 'adds the client ssl profile'
    end

    context 'and the client ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: 6, # PROFILE_TYPE_CLIENT_SSL
              profile_context: 1, # PROFILE_CONTEXT_TYPE_CLIENT
              profile_name: '/Common/client.cert'
            }]] }
        }
      end

      it 'does not add the client ssl profile'
    end

    context 'and the server ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
      end

      it 'adds the server ssl profile'
    end

    context 'and the server ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: 5, # PROFILE_TYPE_SERVER_SSL
              profile_context: 2, # PROFILE_CONTEXT_TYPE_SERVER
              profile_name: '/Common/server.cert'
            }]] }
        }
      end

      it 'does not add the server ssl profile'
    end

    context 'and the source address translation type is incorrect' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: [
              1 # SRC_TRANS_NONE
            ]
          }
        }
      end

      it 'sets the source address translation'
    end

    context 'and the source address translation type is correct' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: [
              2 # SRC_TRANS_AUTOMAP
            ]
          }
        }
      end

      it 'does not set the source address translation'
    end
  end

  context 'when managing an existing vip' do
    before do
      allow(server_api).to receive(:get_list) {
        { item: [] }
      }
    end

    context 'and the client ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
      end

      it 'adds the client ssl profile'
    end

    context 'and the client ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: 6, # PROFILE_TYPE_CLIENT_SSL
              profile_context: 1, # PROFILE_CONTEXT_TYPE_CLIENT
              profile_name: '/Common/client.cert'
            }]] }
        }
      end

      it 'does not add the client ssl profile'
    end

    context 'and the server ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }
      end

      it 'adds the server ssl profile'
    end

    context 'and the server ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: 5, # PROFILE_TYPE_SERVER_SSL
              profile_context: 2, # PROFILE_CONTEXT_TYPE_SERVER
              profile_name: '/Common/server.cert'
            }]] }
        }
      end

      it 'does not add the server ssl profile'
    end

    context 'and the source address translation type is incorrect' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: [
              1 # SRC_TRANS_NONE
            ]
          }
        }
      end

      it 'sets the source address translation'
    end

    context 'and the source address translation type is correct' do
      before do
        allow(server_api).to receive(:get_source_address_translation_type) {
          { item: [
              2 # SRC_TRANS_AUTOMAP
            ]
          }
        }
      end

      it 'does not set the source address translation'
    end
  end
end
