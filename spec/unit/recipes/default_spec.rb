require 'spec_helper'

describe "f5::default" do

  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'does something' do
    expect(chef_run).to install_chef_gem('f5-icontrol')
  end
end
