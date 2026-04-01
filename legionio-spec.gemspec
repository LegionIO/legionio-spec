# frozen_string_literal: true

require_relative 'lib/legion/spec/version'

Gem::Specification.new do |spec|
  spec.name          = 'legionio-spec'
  spec.version       = Legion::Spec::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Shared spec helpers for LegionIO — VCR cassettes, factories, matchers'
  spec.description   = 'Deterministic LLM integration testing via VCR-style cassettes that intercept Legion::LLM calls and replay recorded responses.'
  spec.homepage      = 'https://github.com/LegionIO/legionio-spec'
  spec.license       = 'Apache-2.0'

  spec.required_ruby_version = '>= 3.4'

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/main/CHANGELOG.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'documentation_uri' => "#{spec.homepage}#readme",
    'rubygems_mfa_required' => 'true'
  }

  spec.files = Dir['lib/**/*', 'README.md', 'LICENSE', 'CHANGELOG.md']

  spec.add_dependency 'json', '>= 2.0'
  spec.add_dependency 'rspec', '~> 3.0'
end
