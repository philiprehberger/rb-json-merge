# Changelog

All notable changes to this gem will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-05-12

### Added
- `JsonMerge.delete(doc, path)` removes the value at an RFC 6901 JSON Pointer and returns the removed value; returns `nil` (and does not mutate) when the path is missing

## [0.4.0] - 2026-04-30

### Added
- `JsonMerge.read(doc, path, default:)` — read a value from a document via RFC 6901 JSON Pointer; returns `default` when the path is missing
- `JsonMerge.write(doc, path, value)` — write a value at an RFC 6901 JSON Pointer, creating intermediate hashes as needed; supports the `-` array-append token

### Changed
- README Development section trimmed to match the standard template (removed inline `# Run tests` / `# Check code style` comments)

## [0.3.0] - 2026-04-17

### Added
- `JsonMerge.paths(operations)` returns the sorted, deduplicated list of paths a JSON Patch sequence would touch (includes `from` for move/copy)

## [0.2.0] - 2026-04-01

### Added
- `JsonMerge.validate(target, ops)` for dry-run patch validation
- `JsonMerge.invert(target, ops)` for generating reverse operations
- `JsonMerge.compact(ops)` for removing redundant operations

## [0.1.3] - 2026-03-31

### Added
- Add GitHub issue templates, dependabot config, and PR template

## [0.1.2] - 2026-03-31

### Changed
- Standardize README badges, support section, and license format

## [0.1.1] - 2026-03-26

### Changed

- Fix README compliance (sponsor badge format, license link)

## [0.1.0] - 2026-03-26

### Added
- Initial release
- RFC 7396 JSON Merge Patch with recursive deep merge and nil key removal
- RFC 6902 JSON Patch with add, remove, replace, move, copy, and test operations
- Diff generation for both RFC 6902 and RFC 7396 patch formats
- JSON Pointer (RFC 6901) path resolution with tilde escaping
