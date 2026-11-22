# MoonBit 1.0 public API review

## Merged

- [x] **Buffer byte writes.** Use `Buffer::write_bytesview(BytesView)`, following `StringBuilder::write_stringview(StringView)`. Keep the one-argument `write_bytes` as a deprecated alias that `moon fix` can migrate. This leaves room for a future `write_bytes(bytes, start, len)`. [PR #4922](https://github.com/moonbitlang/core/pull/4922)
- [x] **File descriptor methods.** On native and Wasm, callers can pass `Fd::equal` and `Fd::hash` as functions. [PR #4923](https://github.com/moonbitlang/core/pull/4923) · [Socket interface](async/socket/pkg.generated.mbti)
- [x] **Immutable sorted map keys.** `SortedMap::keys()` returns an `Iter[K]` in ascending order. Use `map.keys().to_array()` when an array is needed. `keys_as_iter()` remains a deprecated alias. [PR #4925](https://github.com/moonbitlang/core/pull/4925)
- [x] **Shell pipeline stages.** `Pipeline` accepts `ArrayView[Cmd]` and copies the selected stages in order. [PR #4926](https://github.com/moonbitlang/core/pull/4926)
- [x] **Inclusive sorted ranges.** Mutable and immutable sorted maps and sets now use `range(low=a, high=b)`. On the mutable types, positional bounds still compile with deprecation warnings. [PR #4927](https://github.com/moonbitlang/core/pull/4927)
- [x] **Reverse sorted map ranges.** `rev_range(low=a, high=b)` visits the same inclusive interval as `range(low=a, high=b)` in descending key order. Positional bounds still compile with deprecation warnings. [PR #4928](https://github.com/moonbitlang/core/pull/4928)
- [x] **Collection and ZIP insertion.** Use `insert` for entries and elements. Mutable `Set` and `HashSet` also expose `insert_and_check` to report whether membership changed. The old public spellings remain deprecated aliases. [PR #4930](https://github.com/moonbitlang/core/pull/4930)
- [x] **Indexed list search.** `List::find_with_index` passes the index first, like `eachi`. The deprecated `findi` still passes the element first. [PR #4931](https://github.com/moonbitlang/core/pull/4931)
- [x] **Joining deque elements.** `Deque::join` accepts elements implementing `ToStringView`, matching `Iter::join`. [PR #4932](https://github.com/moonbitlang/core/pull/4932)

## 1.0 compatibility decisions

- [x] **List insertion and concatenation.** Keep the deprecated `xs.add(x)` alias for `xs.prepend(x)` through 1.0. This preserves the meaning of calls such as `xs.add(Empty)` on nested lists. `List` already implements `Add`, so callers can concatenate with `xs + ys` or `xs.concat(ys)`. Revisit the named concatenation method after retiring the alias. [Deprecation #4281](https://github.com/moonbitlang/core/pull/4281) · [Deferred PR #4929](https://github.com/moonbitlang/core/pull/4929)
- [x] **Empty mutable hash maps.** Keep `HashMap([], capacity=n)` as the migration from `HashMap::new(capacity=n)` for 1.0. Generic callers must supply the same `K : Hash + Eq` bounds that key insertion and lookup require. [HashMap interface](hashmap/pkg.generated.mbti)

## Awaiting merge

- [ ] **HTTP request headers.** Default `headers` to an empty map in the free `request_text` and `request_json` functions, matching `request_binary`. [PR #4933](https://github.com/moonbitlang/core/pull/4933)
- [ ] **QuickCheck range endpoints.** Introduce an explicit `inclusive` label on both generators. Omitted labels warn and preserve the old endpoint conventions during migration. [PR #4934](https://github.com/moonbitlang/core/pull/4934)

## Third review candidates

- [ ] **Timestamp units.** Consider `Timestamp::subsec_nanos()` for the nanosecond component, retaining `nsec()` as a deprecated alias. Its siblings `sec()` and `msec()` return totals since the Unix epoch. [Accessors](async/fs/timestamp.mbt)

## After 1.0

- **QuickCheck outcomes.** Revisit a typed `outcome()` accessor when a caller needs to distinguish the four documented results programmatically. Adding a method to the abstract `QuickCheckReport` type is compatible with existing callers. [Report documentation](quickcheck/README.mbt.md)

## Coverage

Reviewed the 143 tracked `pkg.generated.mbti` files. The comparison covered exported names and aliases, parameter labels and views, return types, and trait methods. Counts below include empty interfaces.

| Packages | Interfaces | Comparison |
| --- | ---: | --- |
| Core packages outside async and the groups below | 74 | Builtin methods and scalar facades, mutable and immutable collections, text and byte views, codecs, compression, paths, and utility packages |
| Async, outside the groups below | 20 | Method families on readers and writers, constructors, socket and process types, and backend-specific exports |
| Paths containing `internal/`, plus `async/runtime_internal` | 38 | Checked for implementation types appearing in public package interfaces |
| `async/test_programs/*` and `compress/flate/inspect_test` | 11 | Checked generated interfaces for exported declarations |

Two more package manifests have no tracked interface. `async/test_programs/find_ipv6_test_interface` is a native test executable. `async/raw_fd/internal/raw_fd_test_util` exports native helpers for socket tests.

The text and byte regex interfaces agree on `execute(..., last_index?)` and the five match accessors. UTF-8 and UTF-16 agree on `bom?` for encoding and `ignore_bom?` for decoding. The gzip and zlib wrappers both use `max_output_bytes?` and re-export the same four DEFLATE types. These families already give callers consistent spellings. [String](string/pkg.generated.mbti) · [Bytes](bytes/pkg.generated.mbti) · [UTF-8](encoding/utf8/pkg.generated.mbti) · [UTF-16](encoding/utf16/pkg.generated.mbti) · [gzip](compress/gzip/pkg.generated.mbti) · [zlib](compress/zlib/pkg.generated.mbti)
