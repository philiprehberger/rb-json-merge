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

    # List the distinct document paths touched by a patch sequence
    #
    # Collects the `path` from every operation. For `move` and `copy`
    # operations the `from` pointer is also included. Operations that are
    # missing a `path` (or `from` where applicable) are skipped silently;
    # this method does not validate op shape.
    #
    # @param operations [Array<Hash>] RFC 6902 patch operations
    # @return [Array<String>] sorted, deduplicated list of paths
    def self.paths(operations)
      result = []
      operations.each do |op|
        path = op['path'] || op[:path]
        result << path if path
        if %w[move copy].include?(op['op'] || op[:op])
          from = op['from'] || op[:from]
          result << from if from
        end
      end
      result.uniq.sort
    end

    # Read a value from a document via RFC 6901 JSON Pointer.
    #
    # @param doc [Hash, Array] the document to read from
    # @param path [String] JSON Pointer (e.g. `"/a/b/0"`); empty string returns the whole document
    # @param default [Object] value to return when the path does not resolve (default: `nil`)
    # @return [Object] the value at the path, or `default` when missing
    def self.read(doc, path, default: nil)
      tokens = parse_pointer(path)
      tokens.reduce(doc) do |obj, token|
        case obj
        when Hash
          return default unless obj.key?(token)

          obj[token]
        when Array
          return default unless token.match?(/\A\d+\z/)

          idx = token.to_i
          return default if idx >= obj.length

          obj[idx]
        else
          return default
        end
      end
    end

    # Write a value into a document at an RFC 6901 JSON Pointer.
    #
    # Intermediate hash containers are created as needed; the supplied
    # document is mutated and returned. Use `deep_clone` first if you need
    # to preserve the original.
    #
    # @param doc [Hash, Array] the document to write into
    # @param path [String] JSON Pointer (e.g. `"/a/b"`); empty string replaces the whole document
    # @param value [Object] the value to write
    # @return [Hash, Array] the mutated document
    # @raise [Error] if a pointer segment cannot be traversed
    def self.write(doc, path, value)
      tokens = parse_pointer(path)
      return value if tokens.empty?

      parent = tokens[0..-2].each_with_index.reduce(doc) do |obj, (token, _)|
        descend_for_write(obj, token)
      end

      last = tokens.last
      case parent
      when Hash
        parent[last] = value
      when Array
        raise Error, "Invalid array index: '#{last}'" unless last.match?(/\A\d+\z|\A-\z/)

        last == '-' ? parent.push(value) : parent[last.to_i] = value
      else
        raise Error, "Cannot write into #{parent.class}"
      end

      doc
    end

    def self.parse_pointer(path)
      return [] if path == ''
      raise Error, "Invalid JSON Pointer: '#{path}'" unless path.start_with?('/')

      path[1..].split('/', -1).map { |t| t.gsub('~1', '/').gsub('~0', '~') }
    end
    private_class_method :parse_pointer

    def self.descend_for_write(obj, token)
      case obj
      when Hash
        if obj.key?(token)
          child = obj[token]
          raise Error, "Cannot descend into #{child.class} at '#{token}'" unless child.is_a?(Hash) || child.is_a?(Array)

          child
        else
          obj[token] = {}
        end
      when Array
        raise Error, "Invalid array index: '#{token}'" unless token.match?(/\A\d+\z/)

        idx = token.to_i
        raise Error, "Index #{idx} out of bounds" if idx >= obj.length

        obj[idx]
      else
        raise Error, "Cannot traverse into #{obj.class}"
      end
    end
    private_class_method :descend_for_write

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
