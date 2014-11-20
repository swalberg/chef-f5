require 'spec_helper'

describe "f5_test::test_create_pool" do

  let(:chef_run) { ChefSpec::SoloRunner.new(step_into: ['f5_pool']).converge(described_recipe) }

  it 'does something' do
    expect(chef_run).to install_chef_gem('f5-icontrol')
  end
end

