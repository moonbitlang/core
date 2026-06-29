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
let priority_queue_build_bench_size = 10_000

///|
fn make_priority_queue_ordered_values() -> Array[Int] {
  Array::makei(priority_queue_build_bench_size, i => i)
}

///|
fn make_priority_queue_reverse_values() -> Array[Int] {
  Array::makei(priority_queue_build_bench_size, i => {
    priority_queue_build_bench_size - i - 1
  })
}

///|
fn make_priority_queue_random_values() -> Array[Int] {
  Array::makei(priority_queue_build_bench_size, i => {
    (i * 1103515245 + 12345) & 0x7fffffff
  })
}

///|
test "bench PriorityQueue::from_array ordered n=10000" (it : @bench.T) {
  let values = make_priority_queue_ordered_values()
  it.bench(fn() { it.keep(@priority_queue.from_array(values)) })
}

///|
test "bench PriorityQueue::from_array reverse n=10000" (it : @bench.T) {
  let values = make_priority_queue_reverse_values()
  it.bench(fn() { it.keep(@priority_queue.from_array(values)) })
}

///|
test "bench PriorityQueue::from_array random n=10000" (it : @bench.T) {
  let values = make_priority_queue_random_values()
  it.bench(fn() { it.keep(@priority_queue.from_array(values)) })
}

///|
test "bench PriorityQueue::from_iter random n=10000" (it : @bench.T) {
  let values = make_priority_queue_random_values()
  it.bench(fn() { it.keep(@priority_queue.from_iter(values.iter())) })
}
