# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Legion::Spec::Vcr do
  describe '.cassette_dir' do
    it 'defaults to spec/fixtures/cassettes' do
      expect(described_class.cassette_dir).to eq('spec/fixtures/cassettes')
    end
  end

  describe '.configure' do
    after { described_class.cassette_dir = 'spec/fixtures/cassettes' }

    it 'yields self for configuration' do
      described_class.configure do |vcr|
        vcr.cassette_dir = 'tmp/cassettes'
      end
      expect(described_class.cassette_dir).to eq('tmp/cassettes')
    end
  end

  describe '.use_cassette' do
    let(:tmpdir) { Dir.mktmpdir }

    before { described_class.cassette_dir = tmpdir }
    after do
      described_class.cassette_dir = 'spec/fixtures/cassettes'
      FileUtils.rm_rf(tmpdir)
    end

    context 'with :always record mode' do
      it 'invokes the block' do
        called = false
        described_class.use_cassette('test', record: :always) { called = true }
        expect(called).to be(true)
      end
    end

    context 'with :once record mode (no existing cassette)' do
      it 'invokes the block' do
        called = false
        described_class.use_cassette('test_once', record: :once) { called = true }
        expect(called).to be(true)
      end
    end

    context 'with :none record mode and missing cassette' do
      it 'raises CassetteMissingError' do
        expect do
          described_class.use_cassette('missing', record: :none) { nil }
        end.to raise_error(Legion::Spec::Vcr::CassetteMissingError)
      end
    end

    context 'with :none record mode and existing cassette' do
      let(:cassette_path) { File.join(tmpdir, 'existing.json') }

      before { File.write(cassette_path, '[]') }

      it 'does not raise' do
        expect do
          described_class.use_cassette('existing', record: :none) { nil }
        end.not_to raise_error
      end
    end
  end
end
