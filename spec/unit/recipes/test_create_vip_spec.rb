require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/chef_f5'
require_relative '../../../libraries/credentials'

describe 'f5_test::test_create_vip' do
  let(:api) { double('F5::Icontrol') }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(step_into: ['f5_vip']) do |node|
      node.set[:f5][:credentials][:default] = { host: '1.2.3.4', username: 'api', password: 'testing' }
    end.converge(described_recipe)
  end

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
  end

  context 'managing the vip' do
    context 'the vip does not exist' do
    end

    context 'the vip already exists' do
    end
  end
end
