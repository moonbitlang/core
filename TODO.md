# MoonBit 1.0 public API review

## Merged

- [x] **Buffer byte writes.** Use `Buffer::write_bytesview(BytesView)`, following `StringBuilder::write_stringview(StringView)`. Keep the one-argument `write_bytes` as a deprecated alias that `moon fix` can migrate. This leaves room for a future `write_bytes(bytes, start, len)`. [PR #4922](https://github.com/moonbitlang/core/pull/4922)
- [x] **Immutable sorted map keys.** `SortedMap::keys()` returns an `Iter[K]` in ascending order. Use `map.keys().to_array()` when an array is needed. `keys_as_iter()` remains a deprecated alias. [PR #4925](https://github.com/moonbitlang/core/pull/4925)

## In review

- [ ] **File descriptor methods.** Promote `Eq::equal` and `Hash::hash` on `Fd` where those impls exist. A caller should be able to pass `Fd::equal` as a function, just as they can pass `Addr::equal`. [PR #4923](https://github.com/moonbitlang/core/pull/4923) · [Socket interface](async/socket/pkg.generated.mbti)

## Release decisions, one at a time

- [ ] **Should mutable sorted ranges use named bounds?** Both immutable collections spell the inclusive range `range(low=a, high=b)`. The mutable versions spell the same query `range(a, b)`. Decide the call form for all four before migrating either mutable package. Include the mutable map's `rev_range` in that decision and check callers taking the method as a function. [Mutable map](sorted_map/pkg.generated.mbti) · [Mutable set](sorted_set/pkg.generated.mbti) · [Immutable map](immut/sorted_map/pkg.generated.mbti) · [Immutable set](immut/sorted_set/pkg.generated.mbti)
- [ ] **When can `List::add` mean concatenation?** The deprecated alias still takes *one element* and prepends it. The `Add` impl takes *another list* and concatenates it. Keep `prepend` and `concat` explicit until the old alias can be retired, then promote the operator method. [List interface](list/pkg.generated.mbti) · [Promotion policy](AGENTS.md)
- [ ] **Should a shell pipeline accept a slice of stages?** `Cmd` takes an `ArrayView[String]` of arguments, while `Pipeline` requires an `Array[Cmd]` and copies it. Review changing just the constructor input to `ArrayView[Cmd]`. Check a slice, an existing array call, and a stored constructor function against the proposed signature. [Shell interface](async/shell/pkg.generated.mbti)

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
