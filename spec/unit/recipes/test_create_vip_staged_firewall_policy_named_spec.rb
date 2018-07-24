require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_staged_firewall_policy_named' do
  let(:api) { double('F5::Icontrol') }
  let(:server_api) { double('F5::Icontrol::LocalLB::VirtualServer') }
  let(:fw_policy_api) { double('F5::Icontrol::Security::FirewallPolicy') }

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

    allow(api)
      .to receive_message_chain('Security.FirewallPolicy') { fw_policy_api }

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

    context 'and the staged firewall policy exists' do
      before do
        allow(fw_policy_api).to receive(:get_list) {
          { item: ['/Common/myfwpolicy-staged'] }
        }
        allow(server_api).to receive(:get_staged_firewall_policy) {
          { item: nil }
        }
        allow(server_api).to receive(:set_staged_firewall_policy)
      end

      it 'adds the staged firewall policy to the vip' do
        expect(server_api).to receive(:get_staged_firewall_policy).with({
          virtual_servers: { item: ['/Common/myvip'] }
         })
        expect(server_api).to receive(:set_staged_firewall_policy).with({
            virtual_servers: { item: ['/Common/myvip'] },
            policies: { item: [ '/Common/myfwpolicy-staged' ] }
           })
        chef_run
      end
    end

    context 'and the staged firewall policy does not exist' do
      before do
        allow(fw_policy_api).to receive(:get_list) {
          { item: [] }
        }
        allow(server_api).to receive(:get_staged_firewall_policy) {
          { item: nil }
        }
      end

      it 'fails to converge' do
        expect(server_api).to receive(:get_staged_firewall_policy).with({
          virtual_servers: { item: ['/Common/myvip'] }
         })
         expect {
          chef_run
        }.to raise_error /Firewall policy myfwpolicy-staged does not exist/
      end
    end
  end

  context 'when managing an existing vip' do
    before do
      allow(server_api).to receive(:get_list) {
        { item: ['myvip'] }
      }

      # these stub out methods not relevant to this context:
      allow(server_api).to receive(:create)
      allow(server_api).to receive(:set_type)
      allow(server_api).to receive(:get_default_pool_name) {
        { item: [] }
      }
      allow(server_api).to receive(:set_default_pool_name)
    end

    context 'and the staged firewall policy exists' do
      before do
        allow(fw_policy_api).to receive(:get_list) {
          { item: ['/Common/myfwpolicy-staged'] }
        }
        allow(server_api).to receive(:get_staged_firewall_policy) {
          { item: nil }
        }
        allow(server_api).to receive(:set_staged_firewall_policy)
      end

      it 'adds the staged firewall policy to the vip' do
        expect(server_api).to receive(:get_staged_firewall_policy).with({
          virtual_servers: { item: ['/Common/myvip'] }
         })
        expect(server_api).to receive(:set_staged_firewall_policy).with({
            virtual_servers: { item: ['/Common/myvip'] },
            policies: { item: [ '/Common/myfwpolicy-staged' ] }
           })
        chef_run
      end
    end

    context 'and the staged firewall policy does not exist' do
      before do
        allow(fw_policy_api).to receive(:get_list) {
          { item: [] }
        }
        allow(server_api).to receive(:get_staged_firewall_policy) {
          { item: nil }
        }
      end

      it 'fails to converge' do
        expect(server_api).to receive(:get_staged_firewall_policy).with({
          virtual_servers: { item: ['/Common/myvip'] }
         })
         expect {
          chef_run
        }.to raise_error /Firewall policy myfwpolicy-staged does not exist/
      end
    end
  end

end
