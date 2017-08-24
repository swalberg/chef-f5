require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_disabled_nodes' do
  let(:api) { double('F5::Icontrol') }

  let(:chef_run) { 
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_pool']).converge(described_recipe) 
  }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
  end

  context 'managing disabled nodes' do
    let (:node) { double }

    before do
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5::Client).to receive(:pool_is_missing_monitor?).and_return(false)
      allow(api).to receive_message_chain('LocalLB.NodeAddressV2') { node }
    end

    context 'the node does not exist' do
      before do
        expect(node).to receive(:get_list) {
          { :item => ['/Common/a', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
        }
      end

      it 'does add the node' do
        expect(node).to receive(:create)
        chef_run
      end

      it 'does set the node status to disabled'
    end

    context 'the node exists' do
      context 'and is enabled' do
        before do
          expect(node).to receive(:get_list) {
            { :item => ['/Common/fauxhai.local', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
          }
        end

        it 'does not add the node' do
          expect(node).to_not receive(:create)
          chef_run
        end

        it 'does sets the node status to disabled'
      end

      context 'and is disabled' do
        before do
          expect(node).to receive(:get_list) {
            { :item => ['/Common/fauxhai.local', '/Common/two'], :"@s:type" => 'A:Array', :"@a:array_type" => 'y:string[2]' }
          }
        end

        it 'does not add the node' do
          expect(node).to_not receive(:create)
          chef_run
        end

        it 'does not set the node status'
      end
    end
  end
end
