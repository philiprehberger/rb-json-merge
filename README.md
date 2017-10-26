# philiprehberger-json_merge

[![Tests](https://github.com/philiprehberger/rb-json-merge/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-json-merge/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-json_merge.svg)](https://rubygems.org/gems/philiprehberger-json_merge)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-json-merge)](https://github.com/philiprehberger/rb-json-merge/commits/main)

JSON Merge Patch (RFC 7396) and JSON Patch (RFC 6902) for Ruby

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-json_merge"
```

Or install directly:

```bash
gem install philiprehberger-json_merge
```

## Usage

```ruby
require "philiprehberger/json_merge"
```

### RFC 7396 Merge Patch

```ruby
target = { "a" => 1, "b" => 2 }
patch  = { "b" => 3, "c" => 4 }

Philiprehberger::JsonMerge.merge_patch(target, patch)
# => {"a"=>1, "b"=>3, "c"=>4}
```

Remove keys with `nil`:

```ruby
Philiprehberger::JsonMerge.merge_patch({ "a" => 1, "b" => 2 }, { "b" => nil })
# => {"a"=>1}
```

### RFC 6902 JSON Patch

```ruby
doc = { "name" => "Alice", "age" => 30 }
ops = [
  { "op" => "replace", "path" => "/name", "value" => "Bob" },
  { "op" => "add", "path" => "/active", "value" => true },
  { "op" => "remove", "path" => "/age" }
]

Philiprehberger::JsonMerge.apply(doc, ops)
# => {"name"=>"Bob", "active"=>true}
```

### Generate Patches

RFC 6902 diff:

```ruby
source = { "a" => 1, "b" => 2 }
target = { "a" => 1, "b" => 3, "c" => 4 }

Philiprehberger::JsonMerge.diff(source, target)
# => [{"op"=>"replace", "path"=>"/b", "value"=>3}, {"op"=>"add", "path"=>"/c", "value"=>4}]
```

RFC 7396 merge diff:

```ruby
Philiprehberger::JsonMerge.merge_diff(source, target)
# => {"b"=>3, "c"=>4}
```

## API

| Method | Description |
|--------|-------------|
| `JsonMerge.merge_patch(target, patch)` | Apply RFC 7396 merge patch |
| `JsonMerge.apply(target, operations)` | Apply RFC 6902 JSON Patch |
| `JsonMerge.diff(source, target)` | Generate RFC 6902 patch operations |
| `JsonMerge.merge_diff(source, target)` | Generate RFC 7396 merge patch |

## Development

```bash
bundle install
bundle exec rspec      # Run tests
bundle exec rubocop    # Check code style
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-json-merge)

🐛 [Report issues](https://github.com/philiprehberger/rb-json-merge/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-json-merge/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
