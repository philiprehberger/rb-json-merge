# frozen_string_literal: true

require_relative 'json_merge/version'
require_relative 'json_merge/merge_patch'
require_relative 'json_merge/json_patch'
require_relative 'json_merge/diff'

module Philiprehberger
  module JsonMerge
    class Error < StandardError; end

    # Apply an RFC 7396 merge patch to a target document
    #
    # @param target [Hash] the target document
    # @param patch [Hash] the merge patch
    # @return [Hash] the patched document
    def self.merge_patch(target, patch)
      MergePatch.call(target, patch)
    end

    # Apply an RFC 6902 JSON Patch to a target document
    #
    # @param target [Hash, Array] the target document
    # @param operations [Array<Hash>] array of patch operations
    # @return [Hash, Array] the patched document
    # @raise [Error] if an operation fails
    def self.apply(target, operations)
      JsonPatch.call(target, operations)
    end

    # Generate RFC 6902 patch operations that transform source into target
    #
    # @param source [Hash, Array] the source document
    # @param target [Hash, Array] the target document
    # @return [Array<Hash>] array of patch operations
    def self.diff(source, target)
      Diff.call(source, target)
    end

    # Generate an RFC 7396 merge patch that transforms source into target
    #
    # @param source [Hash] the source document
    # @param target [Hash] the target document
    # @return [Hash] the merge patch
    def self.merge_diff(source, target)
      MergePatch.generate(source, target)
    end
  end
end
