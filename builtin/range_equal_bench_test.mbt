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

// Benchmarks for the views backed by `String::unsafe_range_equal` and
// `Bytes::unsafe_range_equal`, across lengths. Views start at offset 1 of
// separately allocated buffers so neither side is aligned or aliased.

///|
/// An `n`-unit view at offset 1; `diff_at` in `0..<n` changes that unit.
fn range_equal_bench_view(n : Int, diff_at? : Int = -1) -> StringView {
  let builder = StringBuilder(size_hint=(n + 2) * 2)
  builder.write_char('<')
  for i in 0..<n {
    builder.write_char(if i == diff_at { '!' } else { 'a' })
  }
  builder.write_char('>')
  builder.to_string()[1:n + 1]
}

///|
/// An `n`-byte view at offset 1; `diff_at` in `0..<n` changes that byte.
fn range_equal_bench_bytes_view(n : Int, diff_at? : Int = -1) -> BytesView {
  let arr = Array::make(n + 2, b'a')
  if diff_at >= 0 {
    arr[diff_at + 1] = b'!'
  }
  Bytes::from_array(arr)[1:n + 1]
}

///|
fn bench_string_view_equal(it : @bench.T, n : Int, diff_at? : Int = -1) -> Unit {
  let left = range_equal_bench_view(n)
  let right = range_equal_bench_view(n, diff_at~)
  it.bench(fn() { it.keep(left == right) })
}

///|
fn bench_bytes_view_equal(it : @bench.T, n : Int, diff_at? : Int = -1) -> Unit {
  let left = range_equal_bench_bytes_view(n)
  let right = range_equal_bench_bytes_view(n, diff_at~)
  it.bench(fn() { it.keep(left == right) })
}

///|
test "bench range_equal StringView== n=4 equal" (it : @bench.T) {
  bench_string_view_equal(it, 4)
}

///|
test "bench range_equal StringView== n=8 equal" (it : @bench.T) {
  bench_string_view_equal(it, 8)
}

///|
test "bench range_equal StringView== n=8 mismatch at end" (it : @bench.T) {
  bench_string_view_equal(it, 8, diff_at=7)
}

///|
test "bench range_equal StringView== n=16 equal" (it : @bench.T) {
  bench_string_view_equal(it, 16)
}

///|
test "bench range_equal StringView== n=16 mismatch at end" (it : @bench.T) {
  bench_string_view_equal(it, 16, diff_at=15)
}

///|
test "bench range_equal StringView== n=15 equal" (it : @bench.T) {
  bench_string_view_equal(it, 15)
}

///|
test "bench range_equal StringView== n=64 equal" (it : @bench.T) {
  bench_string_view_equal(it, 64)
}

///|
test "bench range_equal StringView== n=64 mismatch at end" (it : @bench.T) {
  bench_string_view_equal(it, 64, diff_at=63)
}

///|
test "bench range_equal StringView== n=1024 equal" (it : @bench.T) {
  bench_string_view_equal(it, 1024)
}

///|
test "bench range_equal StringView== n=1024 mismatch at end" (it : @bench.T) {
  bench_string_view_equal(it, 1024, diff_at=1023)
}

///|
test "bench range_equal StringView== n=1024 mismatch at 0" (it : @bench.T) {
  bench_string_view_equal(it, 1024, diff_at=0)
}

///|
test "bench range_equal StringView== n=65536 equal" (it : @bench.T) {
  bench_string_view_equal(it, 65536)
}

///|
test "bench range_equal StringView== n=65536 mismatch at end" (it : @bench.T) {
  bench_string_view_equal(it, 65536, diff_at=65535)
}

///|
test "bench range_equal BytesView== n=4 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 4)
}

///|
test "bench range_equal BytesView== n=8 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 8)
}

///|
test "bench range_equal BytesView== n=8 mismatch at end" (it : @bench.T) {
  bench_bytes_view_equal(it, 8, diff_at=7)
}

///|
test "bench range_equal BytesView== n=16 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 16)
}

///|
test "bench range_equal BytesView== n=16 mismatch at end" (it : @bench.T) {
  bench_bytes_view_equal(it, 16, diff_at=15)
}

///|
test "bench range_equal BytesView== n=31 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 31)
}

///|
test "bench range_equal BytesView== n=64 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 64)
}

///|
test "bench range_equal BytesView== n=64 mismatch at end" (it : @bench.T) {
  bench_bytes_view_equal(it, 64, diff_at=63)
}

///|
test "bench range_equal BytesView== n=1024 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 1024)
}

///|
test "bench range_equal BytesView== n=1024 mismatch at end" (it : @bench.T) {
  bench_bytes_view_equal(it, 1024, diff_at=1023)
}

///|
test "bench range_equal BytesView== n=1024 mismatch at 0" (it : @bench.T) {
  bench_bytes_view_equal(it, 1024, diff_at=0)
}

///|
test "bench range_equal BytesView== n=65536 equal" (it : @bench.T) {
  bench_bytes_view_equal(it, 65536)
}

///|
test "bench range_equal BytesView== n=65536 mismatch at end" (it : @bench.T) {
  bench_bytes_view_equal(it, 65536, diff_at=65535)
}

///|
test "bench range_equal StringView::has_prefix prefix=32 hit" (it : @bench.T) {
  let text = range_equal_bench_view(1024)
  let prefix = range_equal_bench_view(32).to_owned()
  it.bench(fn() { it.keep(text.has_prefix(prefix)) })
}

///|
test "bench range_equal StringView::has_prefix prefix=32 miss at end" (
  it : @bench.T,
) {
  let text = range_equal_bench_view(1024)
  let prefix = range_equal_bench_view(32, diff_at=31).to_owned()
  it.bench(fn() { it.keep(text.has_prefix(prefix)) })
}
