# frozen_string_literal: true

module Philiprehberger
  module JsonMerge
    # RFC 6902 JSON Patch implementation
    #
    # Supports add, remove, replace, move, copy, and test operations.
    # Paths use JSON Pointer (RFC 6901) syntax.
    module JsonPatch
      # Apply an array of RFC 6902 operations to a target document
      #
      # @param target [Hash, Array] the target document
      # @param operations [Array<Hash>] array of patch operations
      # @return [Hash, Array] the patched document
      # @raise [JsonMerge::Error] if an operation fails
      def self.call(target, operations)
        result = deep_clone(target)

        operations.each_with_index do |operation, index|
          op = (operation['op'] || operation[:op]).to_s

          result = case op
                   when 'add'    then apply_add(result, operation, index)
                   when 'remove' then apply_remove(result, operation, index)
                   when 'replace' then apply_replace(result, operation, index)
                   when 'move'   then apply_move(result, operation, index)
                   when 'copy'   then apply_copy(result, operation, index)
                   when 'test'   then apply_test(result, operation, index)
                   else
                     raise Error, "Unknown operation '#{op}' at index #{index}"
                   end
        end

        result
      end

      class << self
        private

        def resolve_path(operation, key)
          operation[key.to_s] || operation[key.to_sym]
        end

        def resolve_value(operation)
          if operation.key?('value')
            operation['value']
          elsif operation.key?(:value)
            operation[:value]
          else
            :no_value
          end
        end

        def parse_pointer(pointer)
          return [] if pointer.empty?

          raise Error, "Invalid JSON Pointer: '#{pointer}'" unless pointer.start_with?('/')

          pointer[1..].split('/', -1).map do |token|
            token.gsub('~1', '/').gsub('~0', '~')
          end
        end

        def get_value(doc, tokens)
          current = doc

          tokens.each do |token|
            current = case current
                      when Hash
                        raise Error, "Key '#{token}' not found" unless current.key?(token)

                        current[token]
                      when Array
                        idx = array_index(current, token)
                        raise Error, "Index #{token} out of bounds" if idx >= current.length

                        current[idx]
                      else
                        raise Error, "Cannot traverse into #{current.class}"
                      end
          end

          current
        end

        def set_value(doc, tokens, value)
          return value if tokens.empty?

          parent_tokens = tokens[0..-2]
          last_token = tokens[-1]
          parent = tokens.length == 1 ? doc : get_value(doc, parent_tokens)

          case parent
          when Hash
            parent[last_token] = value
          when Array
            if last_token == '-'
              parent.push(value)
            else
              idx = array_index(parent, last_token)
              raise Error, "Index #{idx} out of bounds for add" if idx > parent.length

              parent.insert(idx, value)
            end
          else
            raise Error, "Cannot set value on #{parent.class}"
          end

          doc
        end

        def remove_value(doc, tokens)
          raise Error, 'Cannot remove root document' if tokens.empty?

          parent_tokens = tokens[0..-2]
          last_token = tokens[-1]
          parent = tokens.length == 1 ? doc : get_value(doc, parent_tokens)

          case parent
          when Hash
            raise Error, "Key '#{last_token}' not found for remove" unless parent.key?(last_token)

            parent.delete(last_token)
          when Array
            idx = array_index(parent, last_token)
            raise Error, "Index #{idx} out of bounds for remove" if idx >= parent.length

            parent.delete_at(idx)
          else
            raise Error, "Cannot remove from #{parent.class}"
          end

          doc
        end

        def array_index(_array, token)
          raise Error, "Invalid array index: '#{token}'" unless token.match?(/\A\d+\z/)

          token.to_i
        end

        def apply_add(doc, operation, index)
          path = resolve_path(operation, :path)
          value = resolve_value(operation)
          raise Error, "Missing 'path' in add operation at index #{index}" if path.nil?
          raise Error, "Missing 'value' in add operation at index #{index}" if value == :no_value

          tokens = parse_pointer(path)
          return deep_clone(value) if tokens.empty?

          set_value(doc, tokens, deep_clone(value))
        end

        def apply_remove(doc, operation, index)
          path = resolve_path(operation, :path)
          raise Error, "Missing 'path' in remove operation at index #{index}" if path.nil?

          tokens = parse_pointer(path)
          remove_value(doc, tokens)
        end

        def apply_replace(doc, operation, index)
          path = resolve_path(operation, :path)
          value = resolve_value(operation)
          raise Error, "Missing 'path' in replace operation at index #{index}" if path.nil?
          raise Error, "Missing 'value' in replace operation at index #{index}" if value == :no_value

          tokens = parse_pointer(path)
          return deep_clone(value) if tokens.empty?

          # Verify the target exists before replacing
          get_value(doc, tokens)
          remove_value(doc, tokens)
          set_value(doc, tokens, deep_clone(value))
        end

        def apply_move(doc, operation, index)
          path = resolve_path(operation, :path)
          from = resolve_path(operation, :from)
          raise Error, "Missing 'path' in move operation at index #{index}" if path.nil?
          raise Error, "Missing 'from' in move operation at index #{index}" if from.nil?

          from_tokens = parse_pointer(from)
          value = get_value(doc, from_tokens)
          doc = remove_value(doc, from_tokens)

          to_tokens = parse_pointer(path)
          set_value(doc, to_tokens, value)
        end

        def apply_copy(doc, operation, index)
          path = resolve_path(operation, :path)
          from = resolve_path(operation, :from)
          raise Error, "Missing 'path' in copy operation at index #{index}" if path.nil?
          raise Error, "Missing 'from' in copy operation at index #{index}" if from.nil?

          from_tokens = parse_pointer(from)
          value = deep_clone(get_value(doc, from_tokens))

          to_tokens = parse_pointer(path)
          set_value(doc, to_tokens, value)
        end

        def apply_test(doc, operation, index)
          path = resolve_path(operation, :path)
          value = resolve_value(operation)
          raise Error, "Missing 'path' in test operation at index #{index}" if path.nil?
          raise Error, "Missing 'value' in test operation at index #{index}" if value == :no_value

          tokens = parse_pointer(path)
          actual = get_value(doc, tokens)

          unless actual == value
            raise Error, "Test failed at '#{path}': expected #{value.inspect}, got #{actual.inspect}"
          end

          doc
        end

        def deep_clone(obj)
          case obj
          when Hash
            obj.each_with_object({}) { |(k, v), h| h[k] = deep_clone(v) }
          when Array
            obj.map { |v| deep_clone(v) }
          else
            obj
          end
        end
      end
    end
  end
end
