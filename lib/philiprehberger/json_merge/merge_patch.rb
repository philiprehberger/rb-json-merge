# frozen_string_literal: true

module Philiprehberger
  module JsonMerge
    # RFC 7396 JSON Merge Patch implementation
    #
    # Recursively merges a patch into a target document.
    # Hash values are deep merged, nil values remove keys.
    module MergePatch
      # Apply a merge patch to a target document
      #
      # @param target [Hash, Object] the target document
      # @param patch [Hash, Object] the merge patch to apply
      # @return [Hash, Object] the patched document
      def self.call(target, patch)
        return patch unless patch.is_a?(Hash)

        result = target.is_a?(Hash) ? target.dup : {}

        patch.each do |key, value|
          if value.nil?
            result.delete(key)
          elsif value.is_a?(Hash)
            existing = result[key]
            result[key] = call(existing.is_a?(Hash) ? existing : {}, value)
          else
            result[key] = value
          end
        end

        result
      end

      # Generate a merge patch that transforms source into target
      #
      # @param source [Hash, Object] the source document
      # @param target [Hash, Object] the target document
      # @return [Hash, nil] the merge patch, or nil if documents are equal
      def self.generate(source, target)
        return target unless source.is_a?(Hash) && target.is_a?(Hash)

        patch = {}

        # Keys removed or changed in target
        source.each do |key, value|
          if target.key?(key)
            if value.is_a?(Hash) && target[key].is_a?(Hash)
              sub_patch = generate(value, target[key])
              patch[key] = sub_patch unless sub_patch.nil? || (sub_patch.is_a?(Hash) && sub_patch.empty?)
            elsif value != target[key]
              patch[key] = target[key]
            end
          else
            patch[key] = nil
          end
        end

        # Keys added in target
        target.each do |key, value|
          patch[key] = value unless source.key?(key)
        end

        patch.empty? ? {} : patch
      end
    end
  end
end
