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

///|
let string_char_set_bench_size = 100_000

///|
let string_char_set_bench_ascii_set = "z \t\n\r"

///|
let string_char_set_bench_contains_miss : String = "a".repeat(
  string_char_set_bench_size,
)

///|
let string_char_set_bench_contains_match_at_end : String = "a".repeat(
    string_char_set_bench_size - 1,
  ) +
  "z"

///|
let string_char_set_bench_trim_start : String = " ".repeat(
    string_char_set_bench_size,
  ) +
  "x"

///|
let string_char_set_bench_trim_end : String = "x" +
  " ".repeat(string_char_set_bench_size)

///|
test "bench StringView::contains_any ASCII miss n=100000" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      string_char_set_bench_contains_miss.contains_any(
        chars=string_char_set_bench_ascii_set,
      ),
    )
  })
}

///|
test "bench StringView::contains_any ASCII match at end n=100000" (
  it : @bench.T,
) {
  it.bench(fn() {
    it.keep(
      string_char_set_bench_contains_match_at_end.contains_any(
        chars=string_char_set_bench_ascii_set,
      ),
    )
  })
}

///|
test "bench StringView::trim_start ASCII n=100000" (it : @bench.T) {
  it.bench(fn() {
    it.keep(string_char_set_bench_trim_start.trim_start().length())
  })
}

///|
test "bench StringView::trim_end ASCII n=100000" (it : @bench.T) {
  it.bench(fn() { it.keep(string_char_set_bench_trim_end.trim_end().length()) })
}

///|
test "bench StringView::trim ASCII n=100000" (it : @bench.T) {
  let input = string_char_set_bench_trim_start +
    " ".repeat(string_char_set_bench_size)
  it.bench(fn() { it.keep(input.trim().length()) })
}
