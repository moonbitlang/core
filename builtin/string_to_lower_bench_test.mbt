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

// Benchmarks for the changed-input conversion path and the allocation-free
// no-change search path in `to_lower`.

///|
// Short header-like input: the per-call cost dominates, so this best exposes
// the dropped per-call `Iter` allocation on the native target.
let to_lower_bench_short : String = "Content-Type"

///|
// Longer mixed-case input with uppercase scattered throughout: exercises the
// whole-view copy and in-place patch path.
let to_lower_bench_long : String = "The Quick Brown Fox Jumps Over The Lazy Dog. ".repeat(
  16,
)

///|
// A single uppercase code unit followed by a long unchanged suffix. This
// checks that the whole-view copy retains the benefit of large batches.
let to_lower_bench_sparse : String = "A" + "x".repeat(719)

///|
// A single uppercase code unit at the end. This exercises the SIMD pre-scan
// before the exact-size output buffer is allocated.
let to_lower_bench_late_uppercase : String = "x".repeat(719) + "A"

///|
// Every unchanged run has length one. This guards against reintroducing the
// per-run overhead that motivated the whole-view copy.
let to_lower_bench_one_unit_runs : String = "Ax".repeat(360)

///|
// Every code unit is rewritten after the initial copy. This exposes the
// worst-case cost of patching the copied buffer.
let to_lower_bench_all_uppercase : String = "A".repeat(720)

///|
// No conversion is needed. These inputs exercise the allocation-free search
// and should return the original string or view.
let to_lower_bench_no_change_short : String = "content-type"

///|
let to_lower_bench_no_change_long : String = "the quick brown fox jumps over the lazy dog. ".repeat(
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
test "bench String::to_lower sparse" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_sparse.to_lower()) })
}

///|
test "bench String::to_lower late-uppercase" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_late_uppercase.to_lower()) })
}

///|
test "bench String::to_lower one-unit runs" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_one_unit_runs.to_lower()) })
}

///|
test "bench String::to_lower all-uppercase" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_all_uppercase.to_lower()) })
}

///|
test "bench String::to_lower no-change short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_no_change_short.to_lower()) })
}

///|
test "bench String::to_lower no-change long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_no_change_long.to_lower()) })
}

///|
test "bench StringView::to_lower short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_short[:].to_lower()) })
}

///|
test "bench StringView::to_lower long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_long[:].to_lower()) })
}

///|
test "bench StringView::to_lower no-change long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_lower_bench_no_change_long[:].to_lower()) })
}
