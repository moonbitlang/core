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
fn set_algebra_bench_strings(lo : Int, hi : Int) -> @hashset.HashSet[String] {
  @hashset.from_array(Array::makei(hi - lo, i => "key_number_\{lo + i}_suffix"))
}

///|
fn set_algebra_bench_ints(lo : Int, hi : Int) -> @hashset.HashSet[Int] {
  @hashset.from_array(Array::makei(hi - lo, i => lo + i))
}

///|
test "bench HashSet::union String 10k 50% overlap" (it : @bench.T) {
  let a = set_algebra_bench_strings(0, 10000)
  let b = set_algebra_bench_strings(5000, 15000)
  it.bench(fn() { it.keep(a.union(b).length()) })
}

///|
test "bench HashSet::union Int 10k 50% overlap" (it : @bench.T) {
  let a = set_algebra_bench_ints(0, 10000)
  let b = set_algebra_bench_ints(5000, 15000)
  it.bench(fn() { it.keep(a.union(b).length()) })
}

///|
test "bench HashSet::intersection String 10k 50% overlap" (it : @bench.T) {
  let a = set_algebra_bench_strings(0, 10000)
  let b = set_algebra_bench_strings(5000, 15000)
  it.bench(fn() { it.keep(a.intersection(b).length()) })
}

///|
test "bench HashSet::difference String 10k 50% overlap" (it : @bench.T) {
  let a = set_algebra_bench_strings(0, 10000)
  let b = set_algebra_bench_strings(5000, 15000)
  it.bench(fn() { it.keep(a.difference(b).length()) })
}

///|
test "bench HashSet::is_subset String 10k true" (it : @bench.T) {
  let a = set_algebra_bench_strings(0, 10000)
  let b = set_algebra_bench_strings(0, 10000)
  it.bench(fn() { it.keep(a.is_subset(b)) })
}

///|
test "bench HashSet == String 10k" (it : @bench.T) {
  let a = set_algebra_bench_strings(0, 10000)
  let b = set_algebra_bench_strings(0, 10000)
  it.bench(fn() { it.keep(a == b) })
}

///|
test "bench HashSet == Int 10k" (it : @bench.T) {
  let a = set_algebra_bench_ints(0, 10000)
  let b = set_algebra_bench_ints(0, 10000)
  it.bench(fn() { it.keep(a == b) })
}
