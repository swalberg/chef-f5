require 'spec_helper'
require './libraries/dns_lookup'

describe DNSLookup do
  let(:invalid_name) { 'xxx.yyy.qww' }
  let(:valid_name) { 'github.com' }

  describe '#exists?' do
    it 'exists' do
      expect(described_class.new(valid_name).exists?).to be_truthy
    end

    it 'does not exist' do
      expect(described_class.new(invalid_name).exists?).to be_falsey
    end
  end

  describe '#address' do
    it 'returns nil on an invalid address' do
      expect(described_class.new(invalid_name).address).to be_nil
    end

    it 'returns an address when its valid' do
      expect(described_class.new(valid_name).address).to match /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/
    end
  end
end
