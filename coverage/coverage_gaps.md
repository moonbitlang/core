# Coverage gaps (black-box only)

This note documents remaining uncovered lines after the black-box test pass and
why they are currently out of reach.

Last coverage run (wasm-gc):
- `moon coverage analyze -- -f summary`

## JS coverage blocked (compiler ICE)
Attempting JS coverage currently crashes the compiler:
- Command: `moon test --target js --enable-coverage`
- moonc: v0.6.37+0b3e4ae80
- Error: assertion failure in `moonc.ml` during link-core

This blocks coverage of JS-only code paths listed below.

## Target-specific or host-dependent
- JS-only functions or externs (blocked by JS ICE):
  - `builtin/fixedarray.mbt:1633` `FixedArray::copy` (#cfg target=js)
  - `builtin/hasher.mbt:85` `seed` via `random_seed()` (#cfg target=js)
  - `float/methods.mbt:886,927` JS conversions (#cfg target=js)
  - `int16/int16.mbt:213,219` JS conversions (#cfg target=js)
  - `builtin/to_string.mbt:339,353,699,717` JS wrappers (#cfg target=js)
- WASM host dependent:
  - `env/env_wasm.mbt:102` `current_dir_internal` returns `None` only if the
    host returns an empty string; not controllable from tests.

## Invariant / defensive branches (unreachable by design)
- `bigint/bigint_nonjs.mbt:1816` `len == 0` guard; BigInt invariants keep
  `len > 0` for public values.
- `encoding/utf16/decode.mbt:53,78,133,161` `ch > 0x10FFFF` is impossible for
  valid surrogate pairs; the guard is defensive.
- `builtin/to_string.mbt:204,216,436,448` `hex_count*`/`radix_count*` zero paths
  are bypassed by early return in `to_string` when value is zero.
- `string/regex/internal/regexp/internal/unicode/case_folding.mbt:27` odd-length
  DATA guard should be unreachable (data is even-length).
- `json/parse.mbt:61,86,89,114` `abort("unreachable")` arms in parser token
  state machine.
- `string/regex/internal/regexp/internal/vm/impl.mbt:201` panic for unexpected
  instruction; unreachable under valid compilation.

## Private helpers (not callable from black-box tests)
- `hashmap/utils.mbt:17-25` `_debug_entries` is private.
- `hashset/hashset.mbt:462-493` `_debug_entries` and `MyString` helpers are
  private to the package.
- `immut/array/tree.mbt` internal `abort` branches and helper paths.
- `immut/array/tree_utils.mbt` internal helpers.
- `immut/hashmap/HAMT.mbt` internal mutation paths.
- `immut/hashset/HAMT.mbt` internal mutation paths.
- `immut/priority_queue/priority_queue.mbt` internal rebalance paths.
- `immut/sorted_set/immutable_set.mbt` internal balancing paths.

## Algorithmic edge cases not hit by current black-box inputs
These are reachable in principle, but require very specific input patterns that
are hard to trigger without white-box hooks or dedicated generators:
- `builtin/array_sort_impl.mbt:253` heap sort fallback when quicksort limit
  reaches zero.
- `builtin/linked_hash_map.mbt:1004,1011,1021,1024` view comparison branches
  not hit by current `Map::get_from_string/get_from_bytes` cases.
- `builtin/string_methods.mbt:1215,1265` defensive break on final segment in
  `replace_all` loops.
- `double/internal/ryu/ryu.mbt:229,255,435` carry/rounding branches.
- `double/scalbn.mbt:17,20,23,26,29,32,35,38,42,43` extreme exponent scaling.
- `math/log_double_nonjs.mbt:256,264,266` edge-case log branches.
- `math/pow.mbt:229,231` subnormal base handling in float pow.
- `math/pow_double_nonjs.mbt:330,332` subnormal base handling in double pow.
- `math/prime.mbt:287,323` rare primality branches.
- `math/trig_double_nonjs.mbt:433,461,512,582,635,640,663,664,665,666,689,714,
  721,722,725,755,759,762,780,783,790,798,802,806,811,870,915,919,921,925`
  specialized rounding and edge-case paths.
- `quickcheck/splitmix/random.mbt:86-87` `next_positive_int` special cases for
  `-2147483648` and `0` need specific RNG states.
- `sorted_set/set.mbt:223,238,239,240,248` join/rotation variants.
- `strconv/decimal.mbt:282,359,360,483,484,497,498,506` rounding/truncation
  paths that require crafted decimal inputs.
- `list/list.mbt:242,279,376,555,722,735,777,878,929,967,980,1194,1258,1319,
  1370,1543,1578,1801` specialized list edge cases.
- `string/regex/internal/regexp/internal/parse/parse.mbt:495,583,624,625`
  parser error branches for specific invalid regex patterns.

## Follow-ups
- Once JS coverage works again, re-run `moon test --target js --enable-coverage`
  to cover JS-only branches.
- For the algorithmic edge cases, consider targeted property tests or
  generated inputs if white-box tests are allowed in the future.
