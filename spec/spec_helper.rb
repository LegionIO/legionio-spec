# frozen_string_literal: true

begin
  require 'simplecov'
  SimpleCov.start do
    minimum_coverage 80
  end
rescue LoadError
  nil
end

require 'legionio-spec'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
