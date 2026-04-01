# frozen_string_literal: true

require_relative 'vcr/errors'
require_relative 'vcr/cassette'

module Legion
  module Spec
    module Vcr
      DEFAULT_CASSETTE_DIR = 'spec/fixtures/cassettes'

      class << self
        attr_writer :cassette_dir

        def cassette_dir
          @cassette_dir ||= DEFAULT_CASSETTE_DIR
        end

        def use_cassette(name, record: :once, &)
          Cassette.new(
            name: name,
            record: record,
            cassette_dir: cassette_dir
          ).use(&)
        end

        def configure
          yield self
        end
      end
    end
  end
end
