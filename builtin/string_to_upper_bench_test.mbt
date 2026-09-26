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
// no-change search path in `to_upper`.

///|
// Short header-like input below the SIMD search threshold: the per-call cost
// dominates.
let to_upper_bench_short : String = "cONTENT-tYPE"

///|
// Longer mixed-case input with lowercase scattered throughout: exercises the
// whole-view copy and in-place patch path.
let to_upper_bench_long : String = "tHE qUICK bROWN fOX jUMPS oVER tHE lAZY dOG. ".repeat(
  16,
)

///|
// A single lowercase code unit followed by a long unchanged suffix. This
// checks that the whole-view copy retains the benefit of large batches.
let to_upper_bench_sparse : String = "a" + "X".repeat(719)

///|
// A single lowercase code unit at the end. This exercises the SIMD pre-scan
// before the exact-size output buffer is allocated.
let to_upper_bench_late_lowercase : String = "X".repeat(719) + "a"

///|
// Every unchanged run has length one. This guards against reintroducing the
// per-run overhead that motivated the whole-view copy.
let to_upper_bench_one_unit_runs : String = "aX".repeat(360)

///|
// Every code unit is rewritten after the initial copy. This exposes the
// worst-case cost of patching the copied buffer.
let to_upper_bench_all_lowercase : String = "a".repeat(720)

///|
// No conversion is needed. These inputs exercise the allocation-free search
// and should return the original string or view.
let to_upper_bench_no_change_short : String = "CONTENT-TYPE"

///|
let to_upper_bench_no_change_long : String = "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. ".repeat(
  16,
)

///|
test "bench String::to_upper short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_short.to_upper()) })
}

///|
test "bench String::to_upper long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_long.to_upper()) })
}

///|
test "bench String::to_upper sparse" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_sparse.to_upper()) })
}

///|
test "bench String::to_upper late-lowercase" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_late_lowercase.to_upper()) })
}

///|
test "bench String::to_upper one-unit runs" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_one_unit_runs.to_upper()) })
}

///|
test "bench String::to_upper all-lowercase" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_all_lowercase.to_upper()) })
}

///|
test "bench String::to_upper no-change short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_no_change_short.to_upper()) })
}

///|
test "bench String::to_upper no-change long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_no_change_long.to_upper()) })
}

///|
test "bench StringView::to_upper short" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_short[:].to_upper()) })
}

///|
test "bench StringView::to_upper long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_long[:].to_upper()) })
}

///|
test "bench StringView::to_upper no-change long" (it : @bench.T) {
  it.bench(fn() { it.keep(to_upper_bench_no_change_long[:].to_upper()) })
}
