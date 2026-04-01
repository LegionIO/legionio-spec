# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe Legion::Spec::Vcr::Cassette do
  let(:tmpdir)  { Dir.mktmpdir }
  let(:name)    { 'test_cassette' }
  let(:path)    { File.join(tmpdir, "#{name}.json") }

  after { FileUtils.rm_rf(tmpdir) }

  def build_cassette(record: :once)
    described_class.new(name: name, record: record, cassette_dir: tmpdir)
  end

  describe '.hash_request' do
    it 'returns a 64-char hex string' do
      hash = described_class.hash_request(:ask, { message: 'hello' })
      expect(hash).to match(/\A[0-9a-f]{64}\z/)
    end

    it 'returns the same hash for identical requests' do
      h1 = described_class.hash_request(:ask, { message: 'hello' })
      h2 = described_class.hash_request(:ask, { message: 'hello' })
      expect(h1).to eq(h2)
    end

    it 'returns different hashes for different messages' do
      h1 = described_class.hash_request(:ask, { message: 'hello' })
      h2 = described_class.hash_request(:ask, { message: 'world' })
      expect(h1).not_to eq(h2)
    end

    it 'returns different hashes for different methods' do
      h1 = described_class.hash_request(:ask,  { message: 'hello' })
      h2 = described_class.hash_request(:chat, { message: 'hello' })
      expect(h1).not_to eq(h2)
    end

    it 'normalizes string and symbol keys identically' do
      h1 = described_class.hash_request(:ask, { message: 'hello' })
      h2 = described_class.hash_request(:ask, { 'message' => 'hello' })
      expect(h1).to eq(h2)
    end
  end

  describe '#use with :none mode' do
    context 'when cassette file is missing' do
      it 'raises CassetteMissingError' do
        cassette = build_cassette(record: :none)
        expect { cassette.use { nil } }.to raise_error(Legion::Spec::Vcr::CassetteMissingError)
      end
    end

    context 'when cassette file exists' do
      before { File.write(path, '[]') }

      it 'executes the block without error' do
        cassette = build_cassette(record: :none)
        called = false
        cassette.use { called = true }
        expect(called).to be(true)
      end
    end
  end

  describe '#use with :always mode and no Legion::LLM present' do
    it 'executes the block and saves an empty cassette' do
      cassette = build_cassette(record: :always)
      cassette.use { nil }
      expect(File.exist?(path)).to be(true)
      expect(JSON.parse(File.read(path))).to eq([])
    end
  end

  describe '#use with :once mode' do
    context 'when cassette does not exist' do
      it 'records by executing the block and saving an empty cassette' do
        cassette = build_cassette(record: :once)
        cassette.use { nil }
        expect(File.exist?(path)).to be(true)
      end
    end

    context 'when cassette already exists' do
      before { File.write(path, '[]') }

      it 'replays without re-recording' do
        mtime_before = File.mtime(path)
        cassette = build_cassette(record: :once)
        cassette.use { nil }
        expect(File.mtime(path)).to eq(mtime_before)
      end

      it 'executes the block' do
        cassette = build_cassette(record: :once)
        called = false
        cassette.use { called = true }
        expect(called).to be(true)
      end
    end
  end

  describe 'recording and replaying Legion::LLM interactions' do
    let(:fake_llm_module) do
      Module.new do
        def self.ask(**kwargs)
          "response for: #{kwargs[:message]}"
        end

        def self.chat(**kwargs)
          "chat response for: #{kwargs[:message]}"
        end

        def self.embed(**_kwargs)
          [0.1, 0.2, 0.3]
        end

        def self.chat_direct(**kwargs)
          "direct: #{kwargs[:message]}"
        end
      end
    end

    before do
      stub_const('Legion::LLM', fake_llm_module)
    end

    describe 'recording' do
      it 'saves interactions to the cassette file' do
        cassette = build_cassette(record: :always)
        cassette.use { Legion::LLM.ask(message: 'hello') }

        interactions = JSON.parse(File.read(path))
        expect(interactions.length).to eq(1)
        expect(interactions.first['method']).to eq('ask')
        expect(interactions.first['response']).to eq('response for: hello')
        expect(interactions.first['request_hash']).to be_a(String)
      end

      it 'records multiple calls in order' do
        cassette = build_cassette(record: :always)
        cassette.use do
          Legion::LLM.ask(message: 'first')
          Legion::LLM.ask(message: 'second')
        end

        interactions = JSON.parse(File.read(path))
        expect(interactions.length).to eq(2)
        expect(interactions[0]['response']).to eq('response for: first')
        expect(interactions[1]['response']).to eq('response for: second')
      end

      it 'records calls to different methods' do
        cassette = build_cassette(record: :always)
        cassette.use do
          Legion::LLM.ask(message: 'hi')
          Legion::LLM.chat(message: 'hi')
        end

        interactions = JSON.parse(File.read(path))
        expect(interactions.map { |i| i['method'] }).to eq(%w[ask chat])
      end

      it 'restores original methods after block completes' do
        cassette = build_cassette(record: :always)
        cassette.use { Legion::LLM.ask(message: 'test') }
        result = Legion::LLM.ask(message: 'after')
        expect(result).to eq('response for: after')
      end

      it 'restores original methods even when block raises' do
        cassette = build_cassette(record: :always)
        expect do
          cassette.use { raise 'boom' }
        end.to raise_error(RuntimeError, 'boom')

        result = Legion::LLM.ask(message: 'after error')
        expect(result).to eq('response for: after error')
      end
    end

    describe 'replaying' do
      before do
        interactions = [
          { 'request_hash' => described_class.hash_request(:ask, { message: 'hello' }),
            'method' => 'ask', 'response' => 'recorded response' },
          { 'request_hash' => described_class.hash_request(:embed, { input: 'text' }),
            'method' => 'embed', 'response' => [0.9, 0.8] }
        ]
        File.write(path, JSON.generate(interactions))
      end

      it 'returns recorded responses' do
        cassette = build_cassette(record: :once)
        result = nil
        cassette.use { result = Legion::LLM.ask(message: 'hello') }
        expect(result).to eq('recorded response')
      end

      it 'returns recorded embed response' do
        cassette = build_cassette(record: :once)
        result = nil
        cassette.use { result = Legion::LLM.embed(input: 'text') }
        expect(result).to eq([0.9, 0.8])
      end

      it 'raises CassettePlaybackError for unrecorded requests' do
        cassette = build_cassette(record: :once)
        expect do
          cassette.use { Legion::LLM.ask(message: 'not recorded') }
        end.to raise_error(Legion::Spec::Vcr::CassettePlaybackError)
      end

      it 'restores original methods after replay' do
        cassette = build_cassette(record: :once)
        cassette.use { Legion::LLM.ask(message: 'hello') }
        result = Legion::LLM.ask(message: 'live call')
        expect(result).to eq('response for: live call')
      end

      it 'replays the same interaction multiple times if recorded multiple times' do
        interactions = [
          { 'request_hash' => described_class.hash_request(:ask, { message: 'repeat' }),
            'method' => 'ask', 'response' => 'first' },
          { 'request_hash' => described_class.hash_request(:ask, { message: 'repeat' }),
            'method' => 'ask', 'response' => 'second' }
        ]
        File.write(path, JSON.generate(interactions))

        cassette = build_cassette(record: :once)
        results = []
        cassette.use do
          results << Legion::LLM.ask(message: 'repeat')
          results << Legion::LLM.ask(message: 'repeat')
        end
        expect(results).to eq(%w[first second])
      end
    end
  end

  describe Legion::Spec::Vcr::CassetteMissingError do
    it 'is a subclass of Legion::Spec::Vcr::Error' do
      expect(described_class.ancestors).to include(Legion::Spec::Vcr::Error)
    end

    it 'has a default message' do
      expect(described_class.new.message).to eq('Cassette file not found and record mode is :none')
    end

    it 'accepts a custom message' do
      error = described_class.new('custom message')
      expect(error.message).to eq('custom message')
    end
  end

  describe Legion::Spec::Vcr::CassettePlaybackError do
    it 'is a subclass of Legion::Spec::Vcr::Error' do
      expect(described_class.ancestors).to include(Legion::Spec::Vcr::Error)
    end

    it 'has a default message' do
      expect(described_class.new.message).to eq('No recorded interaction found for this request')
    end
  end
end
