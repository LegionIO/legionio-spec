# frozen_string_literal: true

module Legion
  module Spec
    module Vcr
      class Error < StandardError; end

      class CassetteMissingError < Error
        def initialize(msg = 'Cassette file not found and record mode is :none')
          super
        end
      end

      class CassettePlaybackError < Error
        def initialize(msg = 'No recorded interaction found for this request')
          super
        end
      end
    end
  end
end
