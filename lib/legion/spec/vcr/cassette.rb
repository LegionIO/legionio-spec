# frozen_string_literal: true

require 'digest'
require 'json'
require 'fileutils'

module Legion
  module Spec
    module Vcr
      class Cassette
        RECORDABLE_METHODS = %i[chat ask embed chat_direct].freeze

        attr_reader :name, :record_mode, :path

        def initialize(name:, record:, cassette_dir:)
          @name         = name
          @record_mode  = record
          @path         = File.join(cassette_dir, "#{name}.json")
          @interactions = []
          @replay_index = Hash.new(0)
        end

        def use(&)
          validate_mode!

          if replay?
            replay(&)
          else
            record(&)
          end
        end

        private

        def replay?
          record_mode == :once && File.exist?(path)
        end

        def validate_mode!
          return unless record_mode == :none && !File.exist?(path)

          raise CassetteMissingError,
                "Cassette not found: #{path} (record mode is :none)"
        end

        def record(&block)
          interactions = []
          originals    = patch_llm_for_recording(interactions)
          begin
            block.call
          ensure
            restore_llm(originals)
          end
          save(interactions)
        end

        def replay(&block)
          all_interactions = load_interactions
          originals        = patch_llm_for_replay(all_interactions)
          begin
            block.call
          ensure
            restore_llm(originals)
          end
        end

        def patch_llm_for_recording(interactions)
          llm = resolve_llm
          return {} unless llm

          originals = {}
          RECORDABLE_METHODS.each do |method_name|
            next unless llm.respond_to?(method_name)

            originals[method_name] = llm.method(method_name)
            llm_capture = interactions
            original_method = originals[method_name]

            llm.define_singleton_method(method_name) do |**kwargs, &blk|
              response = original_method.call(**kwargs, &blk)
              request_hash = Legion::Spec::Vcr::Cassette.hash_request(method_name, kwargs)
              llm_capture << { 'request_hash' => request_hash, 'method' => method_name.to_s, 'response' => response }
              response
            end
          end
          originals
        end

        def patch_llm_for_replay(all_interactions)
          llm = resolve_llm
          return {} unless llm

          indexed = build_replay_index(all_interactions)
          originals = {}
          RECORDABLE_METHODS.each do |method_name|
            next unless llm.respond_to?(method_name)

            originals[method_name] = llm.method(method_name)
            replay_index = indexed

            llm.define_singleton_method(method_name) do |**kwargs, &_blk|
              request_hash = Legion::Spec::Vcr::Cassette.hash_request(method_name, kwargs)
              queue = replay_index[request_hash]
              raise Legion::Spec::Vcr::CassettePlaybackError, "No recorded interaction for #{method_name} (hash=#{request_hash})" if queue.nil? || queue.empty?

              queue.shift
            end
          end
          originals
        end

        def restore_llm(originals)
          llm = resolve_llm
          return unless llm

          originals.each do |method_name, original_method|
            if original_method
              llm.define_singleton_method(method_name, original_method)
            else
              llm.singleton_class.remove_method(method_name)
            end
          end
        end

        def build_replay_index(all_interactions)
          index = Hash.new { |h, k| h[k] = [] }
          all_interactions.each do |interaction|
            index[interaction['request_hash']] << interaction['response']
          end
          index
        end

        def save(interactions)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, JSON.pretty_generate(interactions))
        end

        def load_interactions
          JSON.parse(File.read(path))
        end

        def resolve_llm
          defined?(::Legion::LLM) ? ::Legion::LLM : nil
        end

        class << self
          def hash_request(method_name, kwargs)
            payload = { 'method' => method_name.to_s }.merge(normalize_kwargs(kwargs))
            Digest::SHA256.hexdigest(JSON.generate(payload.sort_by { |k, _v| k.to_s }.to_h))
          end

          private

          def normalize_kwargs(kwargs)
            kwargs.transform_keys(&:to_s).transform_values do |v|
              v.is_a?(Hash) ? normalize_kwargs(v) : v
            end
          end
        end
      end
    end
  end
end
