require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'

describe 'f5_test::test_create_pool' do

  let(:api) { double('F5::Icontrol') }

  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: ['f5_pool']) do |node|
    node.set[:f5][:credentials][:default] = { host: '1.2.3.4', username: 'api', password: 'testing' }
  end.converge(described_recipe) }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
  end

  context 'managing the pool' do
    before do
      allow_any_instance_of(ChefF5).to receive(:pool_is_missing_node?).and_return(false)
      allow_any_instance_of(ChefF5).to receive(:node_is_missing?).and_return(false)
    end

    context 'the pool does not exist' do
      before do
        allow(api).to receive_message_chain("LocalLB.Pool.get_list") {
          {:item=>["/Common/test1", "/Common/mchan01"], :"@s:type"=>"A:Array", :"@a:array_type"=>"y:string[2]"}
        }
      end

      it 'creates the pool' do
        expect(api).to receive_message_chain("LocalLB", "Pool", "create_v2") { true }
        chef_run
      end

      it 'adds the host to the pool' do
      end
    end

    context 'the pool already exists' do
      let (:pool) { double }

      before do
        allow(api).to receive_message_chain("LocalLB.Pool") { pool }
        allow(pool).to receive(:get_list) {
          {:item=>["/Common/reallybasic", "/Common/mchan01"], :"@s:type"=>"A:Array", :"@a:array_type"=>"y:string[2]"}
        }
      end

      it 'does not create the pool' do
        expect(pool).to_not receive(:create_v2)
        chef_run
      end

      it 'adds the host to the pool' do
      end

      context "managing a member" do

        context "the member already exists" do
        end

        context "the member does not exist" do
        end

      end
    end

    context 'the pool exists but is different' do
    end
  end
end

