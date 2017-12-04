require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/dns_lookup'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_vip_name' do
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

  context 'when managing the vip' do
    before do
      # these vips have no profiles
      allow(server_api).to receive(:get_profile) {
        { item: [[]] }
      }

      # these vips have their SAT set to None
      allow(server_api)
        .to receive(:get_source_address_translation_type) {
          { item: [
              F5::Icontrol::LocalLB::VirtualServer::SourceAddressTranslationType::SRC_TRANS_NONE
          ]}}
    end

    context 'and the name hasnt been created yet' do
      it 'skips all the work' do
        allow_any_instance_of(DNSLookup)
          .to receive(:address).and_return(nil)

        expect(server_api).to_not receive(:create)

        chef_run
      end
    end

    context 'and the vip does not exist' do
      before do
        allow(server_api).to receive(:get_list) {
          { item: [] }
        }
      end

      it 'creates the vip' do
        allow_any_instance_of(ChefF5::Client)
          .to receive(:vip_default_pool).and_return('reallybasic')

        allow_any_instance_of(DNSLookup)
          .to receive(:address).and_return('90.2.1.0')

        expect(server_api).to receive(:create) do |args|
          expect(args[:definitions][:item][:address]).to eq '90.2.1.0'
        end

        expect(server_api).to receive(:set_type)

        expect(chef_run).to create_f5_vip('myvip').with(
          address: 'github.com',
          port: '80',
          protocol: 'PROTOCOL_TCP',
          pool: 'reallybasic'
        )
      end
    end

    context 'and the vip already exists' do
      before do
        allow(server_api).to receive(:get_list) {
          { item: ['/Common/myvip'] }
        }
      end

      it 'does not create the vip' do
        allow_any_instance_of(ChefF5::Client).to receive(:vip_default_pool)
        allow_any_instance_of(ChefF5::Client).to receive(:set_vip_pool)
        chef_run
      end
    end
  end
end

