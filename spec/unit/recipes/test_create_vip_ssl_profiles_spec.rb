require 'spec_helper'
require 'f5/icontrol'
require 'f5/icontrol/locallb/profile_context_type'
require 'f5/icontrol/locallb/profile_type'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_ssl_profiles' do
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

    context 'and the client ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }

        # must allow the server profile and sat to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the client ssl profile' do
        expect(server_api).to receive(:add_profile).with({
            virtual_servers: ['/Common/myvip'],
            profiles: [[{
                profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_CLIENT,
                profile_name: '/Common/client.cert'
              }]]
          })
        chef_run
      end
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

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'does not add the client ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
            virtual_servers: anything,
            profiles: [[{
                profile_context: 1, # PROFILE_CONTEXT_TYPE_CLIENT
                profile_name: anything
              }]]
          })
        chef_run
      end
    end

    context 'and the server ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }

        # must allow the client profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the server ssl profile' do
        expect(server_api).to receive(:add_profile).with({
          virtual_servers: ['/Common/myvip'],
          profiles: [[{
            profile_context: 2, # PROFILE_CONTEXT_TYPE_SERVER,
            profile_name: '/Common/server.cert'
            }]]
          })
        chef_run
      end
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

      it 'does not add the server ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
          virtual_servers: anything,
          profiles: [[{
              profile_context: 2, # PROFILE_CONTEXT_TYPE_SERVER
              profile_name: anything
            }]]
          })
        chef_run
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

    context 'and the client ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the client ssl profile' do
        expect(server_api).to receive(:add_profile).with({
            virtual_servers: ['/Common/myvip'],
            profiles: [[{
                profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_CLIENT,
                profile_name: '/Common/client.cert'
              }]]
          })
        chef_run
      end
    end

    context 'and the client ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: F5::Icontrol::LocalLB::ProfileType::PROFILE_TYPE_CLIENT_SSL,
              profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_CLIENT,
              profile_name: '/Common/client.cert'
            }]] }
        }

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'does not add the client ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
            virtual_servers: anything,
            profiles: [[{
                profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_CLIENT,
                profile_name: anything
              }]]
          })
        chef_run
      end
    end

    context 'and the server ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[]] }
        }

        # must allow the client profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the server ssl profile' do
        expect(server_api).to receive(:add_profile).with({
          virtual_servers: ['/Common/myvip'],
          profiles: [[{
            profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_SERVER,
            profile_name: '/Common/server.cert'
            }]]
          })
        chef_run
      end
    end

    context 'and the server ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [[{
              profile_type: F5::Icontrol::LocalLB::ProfileType::PROFILE_TYPE_SERVER_SSL,
              profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_SERVER,
              profile_name: '/Common/server.cert'
            }]] }
        }
      end

      it 'does not add the server ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
          virtual_servers: anything,
          profiles: [[{
              profile_context: F5::Icontrol::LocalLB::ProfileContextType::PROFILE_CONTEXT_TYPE_SERVER,
              profile_name: anything
            }]]
          })
        chef_run
      end
    end
  end
end
