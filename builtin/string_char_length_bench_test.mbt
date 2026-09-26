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

// Benchmarks for `char_length`, `char_length_eq` and `char_length_ge`.

///|
// Below the SIMD threshold: guards against short-input regressions.
let char_length_bench_ascii_8 : String = "abcdefgh"

///|
let char_length_bench_ascii_16 : String = "Content-Type: ab"

///|
let char_length_bench_ascii_100 : String = "The quick brown fox jumps over the lazy dog. ".repeat(
  3,
)[:100].to_owned()

///|
let char_length_bench_ascii_4k : String = "abcdefgh".repeat(512)

///|
let char_length_bench_ascii_64k : String = "abcdefgh".repeat(8192)

///|
// BMP text without surrogates: every block is skipped with one compare.
let char_length_bench_cjk_4k : String = "中文字符测试文本".repeat(512)

///|
// Every block contains leading surrogates: the pair-validating path.
let char_length_bench_emoji_4k : String = "😀🎉🚀🌍".repeat(512)

///|
// Mostly ASCII with an emoji every 32 units: some blocks take the
// pair-validating path, some are skipped.
let char_length_bench_mixed_4k : String = ("abcdefghijklmnopqrstuvwxyz中文" +
"😀" +
"ab").repeat(128)

///|
test "bench char_length ascii 8" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_8.char_length()) })
}

///|
test "bench char_length ascii 16" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_16.char_length()) })
}

///|
test "bench char_length ascii 100" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_100.char_length()) })
}

///|
test "bench char_length ascii 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_4k.char_length()) })
}

///|
test "bench char_length ascii 64k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_64k.char_length()) })
}

///|
test "bench char_length cjk 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_cjk_4k.char_length()) })
}

///|
test "bench char_length emoji 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_emoji_4k.char_length()) })
}

///|
test "bench char_length mixed 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_mixed_4k.char_length()) })
}

///|
test "bench StringView::char_length ascii 4k unaligned" (it : @bench.T) {
  let view = char_length_bench_ascii_4k[3:4093]
  it.bench(fn() { it.keep(view.char_length()) })
}

///|
test "bench char_length_eq ascii 16" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_16.char_length_eq(16)) })
}

///|
test "bench char_length_eq ascii 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_4k.char_length_eq(4096)) })
}

///|
test "bench char_length_eq emoji 4k" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_emoji_4k.char_length_eq(2048)) })
}

///|
test "bench char_length_eq mixed 4k" (it : @bench.T) {
  let n = char_length_bench_mixed_4k.char_length()
  it.bench(fn() { it.keep(char_length_bench_mixed_4k.char_length_eq(n)) })
}

///|
// Small `len`: stays on the scalar walk and stops after a few units.
test "bench char_length_ge ascii 4k len 3" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_4k.char_length_ge(3)) })
}

///|
test "bench char_length_ge ascii 4k len 2000" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_ascii_4k.char_length_ge(2000)) })
}

///|
test "bench char_length_ge cjk 4k len 4096" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_cjk_4k.char_length_ge(4096)) })
}

///|
test "bench char_length_ge emoji 4k len 2048" (it : @bench.T) {
  it.bench(fn() { it.keep(char_length_bench_emoji_4k.char_length_ge(2048)) })
}
