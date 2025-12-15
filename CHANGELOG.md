# Changelog

## [Unreleased]

### Added

- `String::fold` `String::rev_fold` `StringView::fold` `StringView::rev_fold`
  now supports error polymorphism (#3034)

- `ArrayView::get` is added (#3025)

### Deprecated

- `Result::or` `Result::or_else` are deprecated in favor of `Result::unwrap_or`
  `Result::unwrap_or_else` (#3031)
- Passing `max_nesting_depth` to `@json.parse` is deprecated. (#3028)
