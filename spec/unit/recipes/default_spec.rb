require 'spec_helper'

describe "f5::default" do

  before do
    stub_data_bag_item("f5", :default).and_return('')
  end

  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

end
