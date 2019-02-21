require 'spec_helper'
require 'f5/icontrol'

require_relative '../../../libraries/irule'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_irule' do
  let(:api) { double('F5.Icontrol') }

  let(:chef_run) do
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_irule']).converge(described_recipe)
  end

  let(:f5_rule) { double('LocalLB.Rule') }

  let(:rule_definition) do
    <<-EOL
# For hosts that serve both http but attached to http and https vips,
# this lets them know if the request
# originally came in on https
when HTTP_REQUEST {
  HTTP::header insert HTTPS true
}
    EOL
  end

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
    allow(api).to receive_message_chain('LocalLB.Rule') { f5_rule }
    allow(api).to receive_message_chain('System.Session.set_active_folder')
  end

  context 'managing the irule' do
    context 'irule does not exist' do
      before do
        allow_any_instance_of(ChefF5::IRule).to receive(:missing?).and_return(true)
      end
      it 'creates the irule' do
        expect(f5_rule).to receive(:create).with(hash_including(rules: { item: [{ rule_name: '/Common/test-irule', rule_definition: rule_definition }] }))
        chef_run
      end
    end

    context 'the irule does exists' do
      before do
        allow_any_instance_of(ChefF5::IRule).to receive(:missing?).and_return(false)
        allow(f5_rule).to receive(:update_definition)
        allow(f5_rule).to receive(:query_rule)
          .with(hash_including(rule_names: { item: ['/Common/test-irule'] }))
          .and_return(item: {
                        rule_name: '/Common/test-irule', rule_definition: rule_definition
                      })
      end
      context 'and is the same' do
        it 'does not update attributes' do
          expect(f5_rule).not_to receive(:modify_rule)
          chef_run
        end
      end

      context 'the definition is different' do
        before do
          allow(f5_rule).to receive(:query_rule)
            .with(hash_including(rule_names: { item: ['/Common/test-irule'] }))
            .and_return(item: {
                          rule_name: '/Common/test-irule', rule_definition: ''
                        })
        end

        it 'updates the definition' do
          expect(f5_rule).to receive(:modify_rule)
            .with(hash_including(rules: {
                                   item: [{ rule_name: '/Common/test-irule', rule_definition: rule_definition }] }))
          chef_run
        end
      end
    end
  end
end
