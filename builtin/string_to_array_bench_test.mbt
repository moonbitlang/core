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
let string_to_array_bench_ascii : String = "The quick brown fox jumps over the lazy dog, twice!"

///|
let string_to_array_bench_mixed : String = "héllo wörld 🌍 — naïve café 🚀 ".repeat(
  32,
)

///|
test "bench String::to_array ASCII 51 chars" (it : @bench.T) {
  it.bench(fn() { it.keep(string_to_array_bench_ascii.to_array()) })
}

///|
test "bench String::to_array mixed 1KB" (it : @bench.T) {
  it.bench(fn() { it.keep(string_to_array_bench_mixed.to_array()) })
}

///|
test "bench StringView::to_array mixed 1KB" (it : @bench.T) {
  let view = string_to_array_bench_mixed[1:]
  it.bench(fn() { it.keep(view.to_array()) })
}
