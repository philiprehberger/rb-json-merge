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

    # Validate patch operations without modifying the target
    #
    # @param target [Hash, Array] the document to validate against
    # @param operations [Array<Hash>] RFC 6902 patch operations
    # @return [Hash] { valid: Boolean, errors: Array<String> }
    def self.validate(target, operations)
      errors = []
      operations.each_with_index do |op, idx|
        error = validate_operation(deep_clone(target), op, idx)
        errors << error if error
      end
      { valid: errors.empty?, errors: errors }
    end

    # Generate reverse operations that undo a given patch
    #
    # @param target [Hash, Array] the original document before patch
    # @param operations [Array<Hash>] RFC 6902 patch operations
    # @return [Array<Hash>] reverse operations
    def self.invert(target, operations)
      inverse = []
      current = deep_clone(target)
      operations.each do |op|
        inverse_op = build_inverse(current, op)
        inverse.unshift(inverse_op) if inverse_op
        current = apply(current, [op])
      end
      inverse
    end

    # Remove redundant operations from a patch
    #
    # @param operations [Array<Hash>] RFC 6902 patch operations
    # @return [Array<Hash>] optimized operations
    def self.compact(operations)
      result = []
      operations.each do |op|
        existing = result.rindex { |r| r['path'] == op['path'] }
        if existing && op['op'] == 'remove'
          result.delete_at(existing)
        elsif existing && %w[replace add].include?(op['op'])
          result[existing] = op
        else
          result << op
        end
      end
      result
    end

    def self.validate_operation(target, op, idx)
      JsonPatch.call(target, [op])
      nil
    rescue Error => e
      "Operation #{idx} (#{op['op']} #{op['path']}): #{e.message}"
    end
    private_class_method :validate_operation

    def self.build_inverse(current, op)
      case op['op']
      when 'add'
        { 'op' => 'remove', 'path' => op['path'] }
      when 'remove'
        value = resolve_path(current, op['path'])
        { 'op' => 'add', 'path' => op['path'], 'value' => value }
      when 'replace'
        value = resolve_path(current, op['path'])
        { 'op' => 'replace', 'path' => op['path'], 'value' => value }
      when 'move'
        { 'op' => 'move', 'path' => op['from'], 'from' => op['path'] }
      end
    end
    private_class_method :build_inverse

    def self.resolve_path(doc, path)
      keys = path.sub(%r{\A/}, '').split('/')
      keys.reduce(doc) do |obj, key|
        key = key.gsub('~1', '/').gsub('~0', '~')
        obj.is_a?(Array) ? obj[key.to_i] : obj[key]
      end
    end
    private_class_method :resolve_path

    def self.deep_clone(obj)
      case obj
      when Hash then obj.each_with_object({}) { |(k, v), h| h[k] = deep_clone(v) }
      when Array then obj.map { |v| deep_clone(v) }
      else obj
      end
    end
    private_class_method :deep_clone
  end
end
