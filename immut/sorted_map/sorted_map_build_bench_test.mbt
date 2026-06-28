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
let sorted_map_build_bench_size = 10_000

///|
fn make_sorted_map_ordered_pairs() -> Array[(Int, Int)] {
  Array::makei(sorted_map_build_bench_size, i => (i, i))
}

///|
fn make_sorted_map_reverse_pairs() -> Array[(Int, Int)] {
  Array::makei(sorted_map_build_bench_size, i => {
    let k = sorted_map_build_bench_size - i - 1
    (k, k)
  })
}

///|
fn make_sorted_map_almost_ordered_pairs() -> Array[(Int, Int)] {
  Array::makei(sorted_map_build_bench_size, i => {
    let k = if i == sorted_map_build_bench_size - 2 {
      sorted_map_build_bench_size - 1
    } else if i == sorted_map_build_bench_size - 1 {
      sorted_map_build_bench_size - 2
    } else {
      i
    }
    (k, k)
  })
}

///|
fn make_sorted_map_random_pairs() -> Array[(Int, Int)] {
  Array::makei(sorted_map_build_bench_size, i => {
    let k = (i * 1103515245 + 12345) & 0x7fffffff
    (k, k)
  })
}

///|
test "bench SortedMap::from_sorted_array n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_ordered_pairs()
  it.bench(fn() { it.keep(@sorted_map.from_sorted_array(pairs)) })
}

///|
test "bench SortedMap constructor reverse n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_reverse_pairs()
  it.bench(fn() { it.keep(@sorted_map.SortedMap(pairs)) })
}

///|
test "bench SortedMap::from_iter ordered n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_ordered_pairs()
  it.bench(fn() { it.keep(@sorted_map.from_iter(pairs.iter())) })
}

///|
test "bench SortedMap::from_iter almost ordered n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_almost_ordered_pairs()
  it.bench(fn() { it.keep(@sorted_map.from_iter(pairs.iter())) })
}

///|
test "bench SortedMap::from_iter random n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_random_pairs()
  it.bench(fn() { it.keep(@sorted_map.from_iter(pairs.iter())) })
}

///|
test "bench SortedMap constructor ordered n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_ordered_pairs()
  it.bench(fn() { it.keep(@sorted_map.SortedMap(pairs)) })
}

///|
test "bench SortedMap constructor almost ordered n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_almost_ordered_pairs()
  it.bench(fn() { it.keep(@sorted_map.SortedMap(pairs)) })
}

///|
test "bench SortedMap constructor random n=10000" (it : @bench.T) {
  let pairs = make_sorted_map_random_pairs()
  it.bench(fn() { it.keep(@sorted_map.SortedMap(pairs)) })
}
