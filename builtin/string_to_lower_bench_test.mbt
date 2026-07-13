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

// Benchmarks for `to_lower`. The optimization only takes effect when the input
// contains an ASCII uppercase code unit (otherwise `to_lower` early-returns
// `self` with no allocation), so every input below has uppercase present.

///|
// Short header-like input: the per-call cost dominates, so this best exposes
// the dropped per-call `Iter` allocation on the native target.
let to_lower_bench_short : String = "Content-Type"

///|
// Longer mixed-case input with uppercase scattered throughout: also exercises
// the batched `write_substring` path across many segments.
let to_lower_bench_long : String = "The Quick Brown Fox Jumps Over The Lazy Dog. ".repeat(
  16,
)

///|
test "bench String::to_lower short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_short.to_lower()) })
}

///|
test "bench String::to_lower long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_long.to_lower()) })
}

///|
test "bench StringView::to_lower short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_short[:].to_lower()) })
}

///|
test "bench StringView::to_lower long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_long[:].to_lower()) })
}
