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

// Benchmarks for `String::escape`, which also backs the `Debug` rendering of
// strings (`@debug.to_string`, `debug_inspect`). On native and wasm, the
// search for the next escape runs one code unit at a time while fewer than 16
// code units remain; otherwise it checks the first unit and, if that one is
// not escaped, continues with the SIMD scan. js and wasm-gc always use the
// scalar loop.

///|
// Identifier-like input below the SIMD threshold.
let escape_bench_short_plain : String = "user_name_12"

///|
// Short input with an escape in the middle.
let escape_bench_short_escaped : String = "say \"hi\" now"

///|
// Exactly at the SIMD threshold, with no escape.
let escape_bench_threshold_plain : String = "content-type-hdr"

///|
// A 99-unit sentence with a single newline near the end.
let escape_bench_prose : String = "The quick brown fox jumps over the lazy dog while the cat watches from the window." +
  "\nIt did not move."

///|
// An escape at position 0 of a long string, followed by a plain run.
let escape_bench_escape_first : String = "\n" + "x".repeat(99)

///|
let escape_bench_long_plain : String = "The quick brown fox jumps over the lazy dog. ".repeat(
  91,
)

///|
// Every fourth code unit is a quote: the run scan restarts after each escape.
let escape_bench_long_dense : String = "abc\"".repeat(1024)

///|
// Every code unit is escaped.
let escape_bench_long_all : String = "\n".repeat(4096)

///|
// Non-ASCII text (CJK and surrogate pairs) with no escape.
let escape_bench_long_unicode : String = "中文字符😀🎉 ".repeat(512)

///|
test "bench String::escape short plain" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_short_plain.escape()) })
}

///|
test "bench String::escape short escaped" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_short_escaped.escape()) })
}

///|
test "bench String::escape threshold plain" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_threshold_plain.escape()) })
}

///|
test "bench String::escape prose" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_prose.escape()) })
}

///|
test "bench String::escape escape-first" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_escape_first.escape()) })
}

///|
test "bench String::escape long plain" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_long_plain.escape()) })
}

///|
test "bench String::escape long dense" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_long_dense.escape()) })
}

///|
test "bench String::escape long all-escaped" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_long_all.escape()) })
}

///|
test "bench String::escape long unicode" (it : @bench.T) {
  it.bench(fn() { it.keep(escape_bench_long_unicode.escape()) })
}

///|
test "bench StringView::escape long plain view" (it : @bench.T) {
  let view = escape_bench_long_plain.view(start_offset=1, end_offset=4000)
  it.bench(fn() { it.keep(view.escape()) })
}

///|
test "bench debug to_string short plain" (it : @bench.T) {
  it.bench(fn() { it.keep(@debug.to_string(escape_bench_short_plain)) })
}

///|
test "bench debug to_string prose" (it : @bench.T) {
  it.bench(fn() { it.keep(@debug.to_string(escape_bench_prose)) })
}

///|
test "bench debug to_string long plain" (it : @bench.T) {
  it.bench(fn() { it.keep(@debug.to_string(escape_bench_long_plain)) })
}
