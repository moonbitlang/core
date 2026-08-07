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
let string_equal_bench_size = 100_000

///|
fn make_string_equal_bench_string(diff_at? : Int = -1) -> String {
  let builder = StringBuilder(size_hint=string_equal_bench_size * 2)
  for i in 0..<string_equal_bench_size {
    builder.write_char(if i == diff_at { 'b' } else { 'a' })
  }
  builder.to_string()
}

///|
test "bench StringView::equal n=100000 equal" (it : @bench.T) {
  let left = make_string_equal_bench_string()[:]
  let right = make_string_equal_bench_string()[:]
  it.bench(fn() { it.keep(left == right) })
}

///|
test "bench StringView::equal n=100000 mismatch at end" (it : @bench.T) {
  let left = make_string_equal_bench_string()[:]
  let right = make_string_equal_bench_string(
      diff_at=string_equal_bench_size - 1,
    )[:]
  it.bench(fn() { it.keep(left == right) })
}

///|
test "bench StringView::equal_to_string n=100000 equal" (it : @bench.T) {
  let left = make_string_equal_bench_string()[:]
  let right = make_string_equal_bench_string()
  it.bench(fn() { it.keep(left.equal_to_string(right)) })
}
