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
let string_methods_bench_size = 100_000

///|
let string_methods_bench_needle_size = 128

///|
let string_methods_bench_haystack : String = "a".repeat(
  string_methods_bench_size,
)

///|
let string_methods_bench_match : String = "a".repeat(
  string_methods_bench_needle_size,
)

///|
let string_methods_bench_mismatch : String = "b" +
  "a".repeat(string_methods_bench_needle_size - 1)

///|
test "bench StringView::has_prefix match n=100000 needle=128" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      string_methods_bench_haystack.has_prefix(string_methods_bench_match),
    )
  })
}

///|
test "bench StringView::has_prefix mismatch n=100000 needle=128" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      string_methods_bench_haystack.has_prefix(string_methods_bench_mismatch),
    )
  })
}

///|
test "bench StringView::has_suffix match n=100000 needle=128" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      string_methods_bench_haystack.has_suffix(string_methods_bench_match),
    )
  })
}

///|
test "bench StringView::has_suffix mismatch n=100000 needle=128" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      string_methods_bench_haystack.has_suffix(string_methods_bench_mismatch),
    )
  })
}
