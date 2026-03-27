# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::JsonMerge do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  describe '.merge_patch' do
    it 'adds new keys' do
      target = { 'a' => 1 }
      patch = { 'b' => 2 }
      expect(described_class.merge_patch(target, patch)).to eq('a' => 1, 'b' => 2)
    end

    it 'replaces existing keys' do
      target = { 'a' => 1 }
      patch = { 'a' => 2 }
      expect(described_class.merge_patch(target, patch)).to eq('a' => 2)
    end

    it 'removes keys with nil values' do
      target = { 'a' => 1, 'b' => 2 }
      patch = { 'b' => nil }
      expect(described_class.merge_patch(target, patch)).to eq('a' => 1)
    end

    it 'deep merges nested hashes' do
      target = { 'a' => { 'b' => 1, 'c' => 2 } }
      patch = { 'a' => { 'b' => 3, 'd' => 4 } }
      expect(described_class.merge_patch(target, patch)).to eq('a' => { 'b' => 3, 'c' => 2, 'd' => 4 })
    end

    it 'removes nested keys with nil' do
      target = { 'a' => { 'b' => 1, 'c' => 2 } }
      patch = { 'a' => { 'c' => nil } }
      expect(described_class.merge_patch(target, patch)).to eq('a' => { 'b' => 1 })
    end

    it 'replaces non-hash target with hash patch' do
      target = { 'a' => 'string' }
      patch = { 'a' => { 'b' => 1 } }
      expect(described_class.merge_patch(target, patch)).to eq('a' => { 'b' => 1 })
    end

    it 'replaces arrays entirely' do
      target = { 'a' => [1, 2, 3] }
      patch = { 'a' => [4, 5] }
      expect(described_class.merge_patch(target, patch)).to eq('a' => [4, 5])
    end

    it 'returns patch when target is not a hash' do
      expect(described_class.merge_patch('string', { 'a' => 1 })).to eq('a' => 1)
    end

    it 'returns non-hash patch directly' do
      expect(described_class.merge_patch({ 'a' => 1 }, 'string')).to eq('string')
    end

    it 'handles empty patch' do
      target = { 'a' => 1 }
      expect(described_class.merge_patch(target, {})).to eq('a' => 1)
    end

    it 'handles empty target' do
      expect(described_class.merge_patch({}, { 'a' => 1 })).to eq('a' => 1)
    end

    it 'does not modify the original target' do
      target = { 'a' => 1 }
      described_class.merge_patch(target, { 'b' => 2 })
      expect(target).to eq('a' => 1)
    end
  end

  describe '.apply' do
    describe 'add operation' do
      it 'adds a new key to an object' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'add', 'path' => '/b', 'value' => 2 }]
        expect(described_class.apply(doc, ops)).to eq('a' => 1, 'b' => 2)
      end

      it 'adds a nested key' do
        doc = { 'a' => { 'b' => 1 } }
        ops = [{ 'op' => 'add', 'path' => '/a/c', 'value' => 2 }]
        expect(described_class.apply(doc, ops)).to eq('a' => { 'b' => 1, 'c' => 2 })
      end

      it 'inserts into an array by index' do
        doc = { 'a' => [1, 2, 3] }
        ops = [{ 'op' => 'add', 'path' => '/a/1', 'value' => 99 }]
        expect(described_class.apply(doc, ops)).to eq('a' => [1, 99, 2, 3])
      end

      it 'appends to an array with -' do
        doc = { 'a' => [1, 2] }
        ops = [{ 'op' => 'add', 'path' => '/a/-', 'value' => 3 }]
        expect(described_class.apply(doc, ops)).to eq('a' => [1, 2, 3])
      end

      it 'replaces the root document with empty path' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'add', 'path' => '', 'value' => { 'b' => 2 } }]
        expect(described_class.apply(doc, ops)).to eq('b' => 2)
      end
    end

    describe 'remove operation' do
      it 'removes a key from an object' do
        doc = { 'a' => 1, 'b' => 2 }
        ops = [{ 'op' => 'remove', 'path' => '/b' }]
        expect(described_class.apply(doc, ops)).to eq('a' => 1)
      end

      it 'removes a nested key' do
        doc = { 'a' => { 'b' => 1, 'c' => 2 } }
        ops = [{ 'op' => 'remove', 'path' => '/a/c' }]
        expect(described_class.apply(doc, ops)).to eq('a' => { 'b' => 1 })
      end

      it 'removes an array element' do
        doc = { 'a' => [1, 2, 3] }
        ops = [{ 'op' => 'remove', 'path' => '/a/1' }]
        expect(described_class.apply(doc, ops)).to eq('a' => [1, 3])
      end

      it 'raises for non-existent key' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'remove', 'path' => '/b' }]
        expect { described_class.apply(doc, ops) }.to raise_error(described_class::Error)
      end
    end

    describe 'replace operation' do
      it 'replaces an existing value' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'replace', 'path' => '/a', 'value' => 99 }]
        expect(described_class.apply(doc, ops)).to eq('a' => 99)
      end

      it 'replaces a nested value' do
        doc = { 'a' => { 'b' => 1 } }
        ops = [{ 'op' => 'replace', 'path' => '/a/b', 'value' => 2 }]
        expect(described_class.apply(doc, ops)).to eq('a' => { 'b' => 2 })
      end

      it 'raises for non-existent key' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'replace', 'path' => '/b', 'value' => 2 }]
        expect { described_class.apply(doc, ops) }.to raise_error(described_class::Error)
      end
    end

    describe 'move operation' do
      it 'moves a value to a new location' do
        doc = { 'a' => 1, 'b' => 2 }
        ops = [{ 'op' => 'move', 'from' => '/a', 'path' => '/c' }]
        expect(described_class.apply(doc, ops)).to eq('b' => 2, 'c' => 1)
      end

      it 'moves a nested value' do
        doc = { 'a' => { 'b' => 1 }, 'c' => {} }
        ops = [{ 'op' => 'move', 'from' => '/a/b', 'path' => '/c/d' }]
        expect(described_class.apply(doc, ops)).to eq('a' => {}, 'c' => { 'd' => 1 })
      end
    end

    describe 'copy operation' do
      it 'copies a value to a new location' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'copy', 'from' => '/a', 'path' => '/b' }]
        expect(described_class.apply(doc, ops)).to eq('a' => 1, 'b' => 1)
      end

      it 'deep copies objects' do
        doc = { 'a' => { 'x' => 1 } }
        ops = [{ 'op' => 'copy', 'from' => '/a', 'path' => '/b' }]
        result = described_class.apply(doc, ops)
        expect(result['b']).to eq('x' => 1)
        # Verify deep copy - modifying copy does not affect original
        result['b']['x'] = 99
        expect(result['a']['x']).to eq(1)
      end
    end

    describe 'test operation' do
      it 'passes when values match' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'test', 'path' => '/a', 'value' => 1 }]
        expect(described_class.apply(doc, ops)).to eq('a' => 1)
      end

      it 'raises when values do not match' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'test', 'path' => '/a', 'value' => 2 }]
        expect { described_class.apply(doc, ops) }.to raise_error(described_class::Error, /Test failed/)
      end

      it 'tests nested values' do
        doc = { 'a' => { 'b' => [1, 2, 3] } }
        ops = [{ 'op' => 'test', 'path' => '/a/b', 'value' => [1, 2, 3] }]
        expect(described_class.apply(doc, ops)).to eq('a' => { 'b' => [1, 2, 3] })
      end
    end

    describe 'multiple operations' do
      it 'applies operations in sequence' do
        doc = { 'a' => 1 }
        ops = [
          { 'op' => 'add', 'path' => '/b', 'value' => 2 },
          { 'op' => 'remove', 'path' => '/a' },
          { 'op' => 'add', 'path' => '/c', 'value' => 3 }
        ]
        expect(described_class.apply(doc, ops)).to eq('b' => 2, 'c' => 3)
      end
    end

    describe 'symbol keys' do
      it 'works with symbol keys in operations' do
        doc = { 'a' => 1 }
        ops = [{ op: 'add', path: '/b', value: 2 }]
        expect(described_class.apply(doc, ops)).to eq('a' => 1, 'b' => 2)
      end
    end

    describe 'error handling' do
      it 'raises for unknown operation' do
        doc = { 'a' => 1 }
        ops = [{ 'op' => 'invalid', 'path' => '/a' }]
        expect { described_class.apply(doc, ops) }.to raise_error(described_class::Error, /Unknown operation/)
      end
    end

    it 'does not modify the original document' do
      doc = { 'a' => 1 }
      ops = [{ 'op' => 'add', 'path' => '/b', 'value' => 2 }]
      described_class.apply(doc, ops)
      expect(doc).to eq('a' => 1)
    end
  end

  describe '.diff' do
    it 'returns empty array for equal documents' do
      doc = { 'a' => 1, 'b' => 2 }
      expect(described_class.diff(doc, doc)).to eq([])
    end

    it 'detects added keys' do
      source = { 'a' => 1 }
      target = { 'a' => 1, 'b' => 2 }
      ops = described_class.diff(source, target)
      expect(ops).to include('op' => 'add', 'path' => '/b', 'value' => 2)
    end

    it 'detects removed keys' do
      source = { 'a' => 1, 'b' => 2 }
      target = { 'a' => 1 }
      ops = described_class.diff(source, target)
      expect(ops).to include('op' => 'remove', 'path' => '/b')
    end

    it 'detects replaced values' do
      source = { 'a' => 1 }
      target = { 'a' => 2 }
      ops = described_class.diff(source, target)
      expect(ops).to include('op' => 'replace', 'path' => '/a', 'value' => 2)
    end

    it 'detects nested changes' do
      source = { 'a' => { 'b' => 1 } }
      target = { 'a' => { 'b' => 2 } }
      ops = described_class.diff(source, target)
      expect(ops).to include('op' => 'replace', 'path' => '/a/b', 'value' => 2)
    end

    it 'generates a valid patch that transforms source to target' do
      source = { 'a' => 1, 'b' => { 'c' => 3 }, 'd' => 4 }
      target = { 'a' => 2, 'b' => { 'c' => 3, 'e' => 5 } }
      ops = described_class.diff(source, target)
      result = described_class.apply(source, ops)
      expect(result).to eq(target)
    end

    it 'handles array changes' do
      source = { 'a' => [1, 2, 3] }
      target = { 'a' => [1, 4, 3] }
      ops = described_class.diff(source, target)
      result = described_class.apply(source, ops)
      expect(result).to eq(target)
    end

    it 'handles type changes' do
      source = { 'a' => 'string' }
      target = { 'a' => 42 }
      ops = described_class.diff(source, target)
      expect(ops).to include('op' => 'replace', 'path' => '/a', 'value' => 42)
    end
  end

  describe '.merge_diff' do
    it 'returns empty hash for equal documents' do
      doc = { 'a' => 1 }
      expect(described_class.merge_diff(doc, doc)).to eq({})
    end

    it 'detects added keys' do
      source = { 'a' => 1 }
      target = { 'a' => 1, 'b' => 2 }
      expect(described_class.merge_diff(source, target)).to eq('b' => 2)
    end

    it 'detects removed keys as nil' do
      source = { 'a' => 1, 'b' => 2 }
      target = { 'a' => 1 }
      expect(described_class.merge_diff(source, target)).to eq('b' => nil)
    end

    it 'detects changed values' do
      source = { 'a' => 1 }
      target = { 'a' => 2 }
      expect(described_class.merge_diff(source, target)).to eq('a' => 2)
    end

    it 'handles nested changes' do
      source = { 'a' => { 'b' => 1, 'c' => 2 } }
      target = { 'a' => { 'b' => 1, 'c' => 3 } }
      expect(described_class.merge_diff(source, target)).to eq('a' => { 'c' => 3 })
    end

    it 'generates a valid merge patch' do
      source = { 'a' => 1, 'b' => { 'c' => 3 }, 'd' => 4 }
      target = { 'a' => 2, 'b' => { 'c' => 3, 'e' => 5 } }
      patch = described_class.merge_diff(source, target)
      result = described_class.merge_patch(source, patch)
      expect(result).to eq(target)
    end

    it 'returns target when source is not a hash' do
      expect(described_class.merge_diff('string', { 'a' => 1 })).to eq('a' => 1)
    end
  end

  describe 'edge cases' do
    it 'handles JSON Pointer escaping with tildes' do
      doc = { 'a/b' => 1 }
      ops = [{ 'op' => 'replace', 'path' => '/a~1b', 'value' => 2 }]
      expect(described_class.apply(doc, ops)).to eq('a/b' => 2)
    end

    it 'handles JSON Pointer escaping with tildes in tilde' do
      doc = { 'a~b' => 1 }
      ops = [{ 'op' => 'replace', 'path' => '/a~0b', 'value' => 2 }]
      expect(described_class.apply(doc, ops)).to eq('a~b' => 2)
    end

    it 'handles deeply nested operations' do
      doc = { 'a' => { 'b' => { 'c' => { 'd' => 1 } } } }
      ops = [{ 'op' => 'replace', 'path' => '/a/b/c/d', 'value' => 99 }]
      expect(described_class.apply(doc, ops)).to eq('a' => { 'b' => { 'c' => { 'd' => 99 } } })
    end

    it 'handles merge patch with deeply nested nil removal' do
      target = { 'a' => { 'b' => { 'c' => 1, 'd' => 2 } } }
      patch = { 'a' => { 'b' => { 'c' => nil } } }
      expect(described_class.merge_patch(target, patch)).to eq('a' => { 'b' => { 'd' => 2 } })
    end

    it 'roundtrips through diff and apply' do
      source = { 'name' => 'Alice', 'age' => 30, 'tags' => %w[a b] }
      target = { 'name' => 'Bob', 'age' => 30, 'tags' => %w[a c], 'active' => true }
      ops = described_class.diff(source, target)
      expect(described_class.apply(source, ops)).to eq(target)
    end

    it 'roundtrips through merge_diff and merge_patch' do
      source = { 'x' => 1, 'y' => 2, 'z' => 3 }
      target = { 'x' => 1, 'y' => 99, 'w' => 4 }
      patch = described_class.merge_diff(source, target)
      expect(described_class.merge_patch(source, patch)).to eq(target)
    end
  end
end
