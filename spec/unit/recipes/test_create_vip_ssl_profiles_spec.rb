require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_ssl_profiles' do
  let(:api) { double('F5::Icontrol') }
  let(:server_api) { double('F5::Icontrol::LocalLB::VirtualServer') }
  let(:profile_type) {
    F5::Icontrol::LocalLB::ProfileType
  }
  let(:profile_context_type) {
    F5::Icontrol::LocalLB::ProfileContextType
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

    context 'and the client ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [] } }
        }

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the client ssl profile' do
        expect(server_api).to receive(:add_profile).with({
            virtual_servers: { item: ['/Common/myvip'] },
            profiles: { item: [ { item: [ {
                profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
                profile_name: '/Common/client.cert'
              }]}]
           }})
        chef_run
      end
    end

    context 'and the client ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [{
              profile_type: profile_type::PROFILE_TYPE_CLIENT_SSL.member,
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
              profile_name: '/Common/client.cert'
            }]
          }}
        }

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'does not add the client ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
            virtual_servers: anything,
            profiles: { item: [ { item: [ {
                profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
                profile_name: anything
            }]}]
          }})
        chef_run
      end
    end

    context 'and the server ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [] } }
        }

        # must allow the client profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the server ssl profile' do
        expect(server_api).to receive(:add_profile).with({
          virtual_servers: { item: ['/Common/myvip'] },
          profiles: { item: [ { item: [ {
            profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
            profile_name: '/Common/server.cert'
          }]}]
        }})
        chef_run
      end
    end

    context 'and the server ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [{
              profile_type: profile_type::PROFILE_TYPE_SERVER_SSL.member,
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
              profile_name: '/Common/server.cert'
            }]
          }}
        }
      end

      it 'does not add the server ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
          virtual_servers: anything,
          profiles: { item: [ { item: [ {
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
              profile_name: anything
            }]
          }]
        }})
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
          { item: { item: [] } }
        }

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the client ssl profile' do
        expect(server_api).to receive(:add_profile).with({
            virtual_servers: { item: ['/Common/myvip'] },
            profiles: { item: [ { item: [ {
                profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
                profile_name: '/Common/client.cert'
              }]}]
           }})
        chef_run
      end
    end

    context 'and the client ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [{
              profile_type: profile_type::PROFILE_TYPE_CLIENT_SSL.member,
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
              profile_name: '/Common/client.cert'
            }]
          }}
        }

        # must allow the server profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'does not add the client ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
            virtual_servers: anything,
            profiles: { item: [ { item: [ {
                profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
                profile_name: anything
            }]}]
          }})
        chef_run
      end
    end

    context 'and the server ssl profile is missing' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [] } }
        }

        # must allow the client profile to be set
        allow(server_api).to receive(:add_profile)
      end

      it 'adds the server ssl profile' do
        expect(server_api).to receive(:add_profile).with({
          virtual_servers: { item: ['/Common/myvip'] },
          profiles: { item: [ { item: [ {
            profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
            profile_name: '/Common/server.cert'
          }]}]
        }})
        chef_run
      end
    end

    context 'and the server ssl profile is present' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: { item: [{
              profile_type: profile_type::PROFILE_TYPE_SERVER_SSL.member,
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
              profile_name: '/Common/server.cert'
            }]
          }}
        }
      end

      it 'does not add the server ssl profile' do
        expect(server_api).to_not receive(:add_profile).with({
          virtual_servers: anything,
          profiles: { item: [ { item: [ {
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
              profile_name: anything
            }]
          }]
        }})
        chef_run
      end
    end

    context 'and the vip has no profiles' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item: [] }
        }
      end

      it 'adds a client profile' do
        allow(server_api).to receive(:add_profile)

        expect(server_api).to receive(:add_profile).with({
          virtual_servers: { item: ['/Common/myvip'] },
          profiles: { item: [ { item: [ {
            profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
            profile_name: '/Common/client.cert'
            }]}]
          }})
        chef_run
      end

      it 'adds a server profile' do
        allow(server_api).to receive(:add_profile)

        expect(server_api).to receive(:add_profile).with({
          virtual_servers: anything,
          profiles: { item: [ { item: [ {
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
              profile_name: anything
            }]
          }]
        }})
        chef_run
      end
    end

    context 'and the vip has one TCP profile' do
      before do
        allow(server_api).to receive(:get_profile) {
          { item:
            { item:
              {:profile_type=>"PROFILE_TYPE_TCP", :profile_context=>"PROFILE_CONTEXT_TYPE_ALL", :profile_name=>"/Common/tcp"}
            }
          }
        }
      end

      it 'adds a client profile' do
        allow(server_api).to receive(:add_profile)

        expect(server_api).to receive(:add_profile).with({
          virtual_servers: { item: ['/Common/myvip'] },
          profiles: { item: [ { item: [ {
            profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_CLIENT.member,
            profile_name: '/Common/client.cert'
            }]}]
          }})
        chef_run
      end

      it 'adds a server profile' do
        allow(server_api).to receive(:add_profile)

        expect(server_api).to receive(:add_profile).with({
          virtual_servers: anything,
          profiles: { item: [ { item: [ {
              profile_context: profile_context_type::PROFILE_CONTEXT_TYPE_SERVER.member,
              profile_name: anything
            }]
          }]
        }})
        chef_run
      end
    end
  end
end
