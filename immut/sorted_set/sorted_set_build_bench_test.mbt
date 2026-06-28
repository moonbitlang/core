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
let sorted_set_build_bench_size = 10_000

///|
fn make_sorted_set_ordered_values() -> Array[Int] {
  Array::makei(sorted_set_build_bench_size, i => i)
}

///|
fn make_sorted_set_reverse_values() -> Array[Int] {
  Array::makei(sorted_set_build_bench_size, i => {
    sorted_set_build_bench_size - i - 1
  })
}

///|
fn make_sorted_set_almost_ordered_values() -> Array[Int] {
  Array::makei(sorted_set_build_bench_size, i => {
    if i == sorted_set_build_bench_size - 2 {
      sorted_set_build_bench_size - 1
    } else if i == sorted_set_build_bench_size - 1 {
      sorted_set_build_bench_size - 2
    } else {
      i
    }
  })
}

///|
fn make_sorted_set_random_values() -> Array[Int] {
  Array::makei(sorted_set_build_bench_size, i => {
    (i * 1103515245 + 12345) & 0x7fffffff
  })
}

///|
test "bench SortedSet::from_sorted_array n=10000" (it : @bench.T) {
  let values = make_sorted_set_ordered_values()
  it.bench(fn() { it.keep(@sorted_set.from_sorted_array(values)) })
}

///|
test "bench SortedSet constructor reverse n=10000" (it : @bench.T) {
  let values = make_sorted_set_reverse_values()
  it.bench(fn() { it.keep(@sorted_set.SortedSet(values)) })
}

///|
test "bench SortedSet::from_iter ordered n=10000" (it : @bench.T) {
  let values = make_sorted_set_ordered_values()
  it.bench(fn() { it.keep(@sorted_set.from_iter(values.iter())) })
}

///|
test "bench SortedSet::from_iter almost ordered n=10000" (it : @bench.T) {
  let values = make_sorted_set_almost_ordered_values()
  it.bench(fn() { it.keep(@sorted_set.from_iter(values.iter())) })
}

///|
test "bench SortedSet::from_iter rev almost ordered n=10000" (it : @bench.T) {
  let values = make_sorted_set_almost_ordered_values()
  it.bench(fn() { it.keep(@sorted_set.from_iter(values.rev_iter())) })
}

///|
test "bench SortedSet::from_iter random n=10000" (it : @bench.T) {
  let values = make_sorted_set_random_values()
  it.bench(fn() { it.keep(@sorted_set.from_iter(values.iter())) })
}

///|
test "bench SortedSet constructor ordered n=10000" (it : @bench.T) {
  let values = make_sorted_set_ordered_values()
  it.bench(fn() { it.keep(@sorted_set.SortedSet(values)) })
}

///|
test "bench SortedSet constructor almost ordered n=10000" (it : @bench.T) {
  let values = make_sorted_set_almost_ordered_values()
  it.bench(fn() { it.keep(@sorted_set.SortedSet(values)) })
}

///|
test "bench SortedSet constructor random n=10000" (it : @bench.T) {
  let values = make_sorted_set_random_values()
  it.bench(fn() { it.keep(@sorted_set.SortedSet(values)) })
}
