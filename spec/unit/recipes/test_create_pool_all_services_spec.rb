require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_pool_all_services' do
  let(:api) { double('F5::Icontrol') }
  let(:pool) { double('F5::Icontrol::LocalLB::Pool') }

  let(:chef_run) {
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_pool']).converge(described_recipe)
  }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow(api).to receive_message_chain('LocalLB.Pool') { pool }

    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
  end

  context 'managing nodes' do
    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:node_is_enabled?).and_return(true)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
    end

    context 'the pool does not include the node' do
      before do
        allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(true)
      end

      it 'does add the node with all client ports' do
        expect(pool).to receive(:add_member_v2).with(
          pool_names: { item: ['/Common/reallybasic'] },
          members: { item: { item: [{ address: '/Common/fauxhai.local', port: '0' }] } }
        )
        chef_run
      end
    end
  end
end
