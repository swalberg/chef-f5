require 'spec_helper'

describe "f5::default" do

  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

end
