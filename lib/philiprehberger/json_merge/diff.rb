# frozen_string_literal: true

module Philiprehberger
  module JsonMerge
    # Generate RFC 6902 JSON Patch operations from two documents
    module Diff
      # Generate an array of RFC 6902 operations that transform source into target
      #
      # @param source [Hash, Array, Object] the source document
      # @param target [Hash, Array, Object] the target document
      # @param path [String] the current JSON Pointer path prefix
      # @return [Array<Hash>] array of patch operations
      def self.call(source, target, path = '')
        return [] if source == target

        operations = []

        if source.is_a?(Hash) && target.is_a?(Hash)
          diff_hashes(source, target, path, operations)
        elsif source.is_a?(Array) && target.is_a?(Array)
          diff_arrays(source, target, path, operations)
        else
          operations << { 'op' => 'replace', 'path' => path, 'value' => target }
        end

        operations
      end

      class << self
        private

        def diff_hashes(source, target, path, operations)
          # Removed keys
          source.each_key do |key|
            operations << { 'op' => 'remove', 'path' => "#{path}/#{escape_pointer(key)}" } unless target.key?(key)
          end

          # Added or changed keys
          target.each do |key, value|
            escaped = escape_pointer(key)
            if source.key?(key)
              operations.concat(call(source[key], value, "#{path}/#{escaped}"))
            else
              operations << { 'op' => 'add', 'path' => "#{path}/#{escaped}", 'value' => value }
            end
          end
        end

        def diff_arrays(source, target, path, operations)
          # Simple approach: compare element by element
          max_len = [source.length, target.length].max

          removes = 0
          max_len.times do |i|
            if i < source.length && i < target.length
              operations.concat(call(source[i], target[i], "#{path}/#{i}"))
            elsif i >= source.length
              operations << { 'op' => 'add', 'path' => "#{path}/#{i}", 'value' => target[i] }
            else
              # Remove from the end to avoid index shifting issues
              operations << { 'op' => 'remove', 'path' => "#{path}/#{source.length - 1 - removes}" }
              removes += 1
            end
          end
        end

        def escape_pointer(token)
          token.to_s.gsub('~', '~0').gsub('/', '~1')
        end
      end
    end
  end
end
