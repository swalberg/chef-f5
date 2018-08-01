require 'spec_helper'
require 'f5/icontrol'
require_relative '../../../libraries/monitor'
require_relative '../../../libraries/credentials'
require_relative '../../../libraries/gem_helper'

describe 'f5_test::test_create_monitor' do
  let(:api) { double('F5::Icontrol') }

  let(:chef_run) {
    ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['f5_monitor']).converge(described_recipe)
  }

  let(:f5_monitor) { double 'LocalLB.Monitor' }

  before do
    allow(F5::Icontrol::API).to receive(:new) { api }
    allow_any_instance_of(Chef::RunContext::CookbookCompiler).to receive(:compile_libraries).and_return(true)
    stub_data_bag_item('f5', 'default').and_return(host: '1.2.3.4', username: 'api', password: 'testing')
    allow(api).to receive_message_chain('LocalLB.Monitor') { f5_monitor }
  end

  context 'managing the monitor' do
    context 'monitor does not exist' do
      before do
        allow_any_instance_of(ChefF5::Monitor).to receive(:monitor_is_missing?).and_return(true)
        allow(f5_monitor).to receive(:create_template)
      end
      it 'creates the monitor' do
        expect(f5_monitor).to receive(:create_template).with(hash_including(
          templates: { item: [{ template_name: '/Common/test-monitor', template_type: 'TTYPE_HTTP' }]},
          template_attributes: { item: [hash_including({
                                          parent_template: 'http',
                                          interval: 5,
                                          timeout: 10,
                                          dest_ipport: {
                                            address_type: 'ATYPE_STAR_ADDRESS_STAR_PORT',
                                            ipport: {
                                              address: '0.0.0.0', port: '0'
                                            }
                                          },
                                          is_read_only: false,
                                          is_directly_usable: true
                                        })]}
        ))
        chef_run
      end
    end

    context 'the monitor does exists' do
      before do
        allow_any_instance_of(ChefF5::Monitor).to receive(:monitor_is_missing?).and_return(false)
        allow(f5_monitor).to receive(:update_common_attributes)
        allow(f5_monitor).to receive(:get_template_destination)
                               .with(hash_including(template_names: { item: ['/Common/test-monitor']}))
                               .and_return({item: {
                                 ipport: {address: '0.0.0.0', port: '0'},
                                 address_type: 'ATYPE_STAR_ADDRESS_STAR_PORT'
                               }})

      end
      context 'and is the same' do
        before do
          allow(f5_monitor).to receive(:get_template_string_property)
                                 .with(hash_including(template_names: { item: ['/Common/test-monitor']}, property_types: {item: ['STYPE_SEND']}))
                                 .and_return({item: {value: 'GET /health HTTP/1.1\r\nHost: dontmatter\r\nConnection: Close\r\n\r\n'}})
                                 .once
          allow(f5_monitor).to receive(:get_template_string_property)
                                 .with(hash_including(template_names: { item: ['/Common/test-monitor']}, property_types: {item: ['STYPE_RECEIVE']}))
                                 .and_return({item: {value: 'status.*UP' }})
                                 .once
        end
        it 'does not update attributes' do
          expect(f5_monitor).not_to receive(:update_common_attributes)
          chef_run
        end
      end

      context 'the string properties are different' do
        before do
          allow(f5_monitor).to receive(:get_template_string_property)
                                 .with(hash_including(template_names: { item: ['/Common/test-monitor']}, property_types: {item: ['STYPE_SEND']}))
                                 .and_return({item: {value: 'GET /health HTTP/1.1\r\nHost: dontmatter\r\nConnection: Close\r\n\r\n'}})
                                 .once
          allow(f5_monitor).to receive(:get_template_string_property)
                                 .with(hash_including(template_names: { item: ['/Common/test-monitor']}, property_types: {item: ['STYPE_RECEIVE']}))
                                 .and_return({item: {value: 'status.*DOWN' }})
                                 .once
          # allow(f5_monitor).to receive(:set_template_string_property)
        end

        it 'updates the string properties' do
          expect(f5_monitor).to receive(:set_template_string_property)
                                  .with(hash_including(template_names: {item: ['/Common/test-monitor']},
                                                       values: {item: [{type: 'STYPE_RECEIVE', value: 'status.*UP'}]}))
          chef_run
        end
      end
    end
  end
end
