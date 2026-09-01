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
let sorted_set_bench_n = 50000

///|
/// `to_array` materializes the in-order traversal. The Int and Ref variants
/// are both kept because the element type decides whether the per-element
/// store carries reference-counting traffic.
test "bench SortedSet::to_array Int n=50000" (it : @bench.T) {
  let s = @sorted_set.from_array(
    Array::makei(sorted_set_bench_n, i => i * 1103515245),
  )
  it.bench(fn() { it.keep(s.to_array()) })
}

///|
test "bench SortedSet::to_array Ref n=50000" (it : @bench.T) {
  let s = @sorted_set.from_array(
    Array::makei(sorted_set_bench_n, i => "value\{i}"),
  )
  it.bench(fn() { it.keep(s.to_array()) })
}
