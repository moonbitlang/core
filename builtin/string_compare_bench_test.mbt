// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Benchmarks for the code-unit ordering behind `Compare for String`,
// `Compare for StringView` and `StringView::lexical_compare`, from map-key
// sizes to 64K units. `lexical_compare_bench_test.mbt` covers n=256.
// Each case compares two distinct equal-length strings that differ at the last
// unit (full scan), at unit 0 (early exit), or not at all.

///|
fn scb_make(len : Int, diff_at? : Int = -1) -> String {
  let sb = StringBuilder(size_hint=len)
  for i in 0..<len {
    sb.write_char(
      Int::unsafe_to_char(if i == diff_at { '{' } else { 'a' + i % 26 }),
    )
  }
  sb.to_string()
}

///|
priv struct ScbCase {
  base : String
  diff_end : String
  diff_start : String
  equal : String
  // Views one unit into strings two units longer than `len`, so they start at
  // a non-zero offset and end before the backing string does.
  view_base : StringView
  view_diff_end : StringView
}

///|
fn scb_case(len : Int) -> ScbCase {
  let wide_base = "." + scb_make(len) + "."
  let wide_diff_end = "," + scb_make(len, diff_at=len - 1) + ","
  {
    base: scb_make(len),
    diff_end: scb_make(len, diff_at=len - 1),
    diff_start: scb_make(len, diff_at=0),
    equal: scb_make(len),
    view_base: wide_base.exact_view(start=1, end=len + 1),
    view_diff_end: wide_diff_end.exact_view(start=1, end=len + 1),
  }
}

///|
let scb_8 : ScbCase = scb_case(8)

///|
let scb_16 : ScbCase = scb_case(16)

///|
let scb_64 : ScbCase = scb_case(64)

///|
let scb_1024 : ScbCase = scb_case(1024)

///|
let scb_65536 : ScbCase = scb_case(65536)

///|
test "bench String::compare diff-end n=8" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_8.base.compare(scb_8.diff_end)) })
}

///|
test "bench String::compare diff-start n=8" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_8.base.compare(scb_8.diff_start)) })
}

///|
test "bench String::compare equal n=8" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_8.base.compare(scb_8.equal)) })
}

///|
test "bench String::compare diff-end n=16" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_16.base.compare(scb_16.diff_end)) })
}

///|
test "bench String::compare diff-start n=16" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_16.base.compare(scb_16.diff_start)) })
}

///|
test "bench String::compare equal n=16" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_16.base.compare(scb_16.equal)) })
}

///|
test "bench String::compare diff-end n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_64.base.compare(scb_64.diff_end)) })
}

///|
test "bench String::compare diff-start n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_64.base.compare(scb_64.diff_start)) })
}

///|
test "bench String::compare equal n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_64.base.compare(scb_64.equal)) })
}

///|
test "bench String::compare diff-end n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_1024.base.compare(scb_1024.diff_end)) })
}

///|
test "bench String::compare diff-start n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_1024.base.compare(scb_1024.diff_start)) })
}

///|
test "bench String::compare equal n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_1024.base.compare(scb_1024.equal)) })
}

///|
test "bench String::compare diff-end n=65536" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_65536.base.compare(scb_65536.diff_end)) })
}

///|
test "bench String::compare diff-start n=65536" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_65536.base.compare(scb_65536.diff_start)) })
}

///|
test "bench String::compare equal n=65536" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_65536.base.compare(scb_65536.equal)) })
}

///|
test "bench String::lexical_compare diff-end n=8" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_8.base.lexical_compare(scb_8.diff_end)) })
}

///|
test "bench String::lexical_compare diff-end n=16" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_16.base.lexical_compare(scb_16.diff_end)) })
}

///|
test "bench String::lexical_compare diff-end n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_64.base.lexical_compare(scb_64.diff_end)) })
}

///|
test "bench String::lexical_compare diff-end n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_1024.base.lexical_compare(scb_1024.diff_end)) })
}

///|
test "bench String::lexical_compare diff-end n=65536" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_65536.base.lexical_compare(scb_65536.diff_end)) })
}

///|
test "bench String::lexical_compare diff-start n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_1024.base.lexical_compare(scb_1024.diff_start)) })
}

///|
test "bench StringView::compare offset diff-end n=8" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_8.view_base.compare(scb_8.view_diff_end)) })
}

///|
test "bench StringView::compare offset diff-end n=16" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_16.view_base.compare(scb_16.view_diff_end)) })
}

///|
test "bench StringView::compare offset diff-end n=64" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_64.view_base.compare(scb_64.view_diff_end)) })
}

///|
test "bench StringView::compare offset diff-end n=1024" (it : @bench.T) {
  it.bench(fn() { it.keep(scb_1024.view_base.compare(scb_1024.view_diff_end)) })
}

///|
test "bench StringView::compare offset diff-end n=65536" (it : @bench.T) {
  it.bench(fn() {
    it.keep(scb_65536.view_base.compare(scb_65536.view_diff_end))
  })
}

///|
/// `n` distinct strings of equal length in scrambled order: a shared prefix of
/// `prefix_len` units followed by a 4-unit suffix, so every comparison scans
/// the whole prefix before it finds the difference.
fn scb_sort_data(n : Int, prefix_len : Int) -> Array[String] {
  let prefix = scb_make(prefix_len)
  Array::makei(n, i => {
    let k = i * 7919 % n
    let sb = StringBuilder(size_hint=prefix_len + 4)
    sb.write_string(prefix)
    for d in 0..<4 {
      sb.write_char(Int::unsafe_to_char('A' + (k >> (d * 4)) % 16))
    }
    sb.to_string()
  })
}

///|
let scb_sort_prefix_64 : Array[String] = scb_sort_data(1000, 64)

///|
// Map-key sized strings: guards the short-input path against regressions.
let scb_sort_prefix_4 : Array[String] = scb_sort_data(1000, 4)

///|
test "bench Array[String]::sort n=1000 common-prefix=64" (it : @bench.T) {
  it.bench(fn() {
    let a = scb_sort_prefix_64.copy()
    a.sort()
    it.keep(a)
  })
}

///|
test "bench Array[String]::sort n=1000 common-prefix=4" (it : @bench.T) {
  it.bench(fn() {
    let a = scb_sort_prefix_4.copy()
    a.sort()
    it.keep(a)
  })
}
