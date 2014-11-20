require 'spec_helper'
require 'f5/icontrol'

describe 'f5_test::test_create_pool' do

  let(:api) { double('F5::Icontrol') }

  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: ['f5_pool']).converge(described_recipe) }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
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
  end

  context 'the pool exists but is different' do
  end
end

