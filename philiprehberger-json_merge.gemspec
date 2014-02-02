# frozen_string_literal: true

require_relative 'lib/philiprehberger/json_merge/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-json_merge'
  spec.version       = Philiprehberger::JsonMerge::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']
  spec.summary       = 'JSON Merge Patch (RFC 7396) and JSON Patch (RFC 6902) for Ruby'
  spec.description   = 'Apply and generate JSON patches using RFC 7396 Merge Patch and RFC 6902 JSON Patch. ' \
                       'Supports add, remove, replace, move, copy, and test operations.'
  spec.homepage      = 'https://github.com/philiprehberger/rb-json-merge'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['bug_tracker_uri']       = "#{spec.homepage}/issues"
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
