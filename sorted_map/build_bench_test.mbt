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
test "bench SortedMap build ascending n=10000" (it : @bench.T) {
  let entries = Array::makei(10000, i => (i, i))
  it.bench(() => it.keep(@sorted_map.SortedMap(entries)))
}

///|
test "bench SortedMap build ascending n=100000" (it : @bench.T) {
  let entries = Array::makei(100000, i => (i, i))
  it.bench(() => it.keep(@sorted_map.SortedMap(entries)))
}

///|
test "bench SortedMap build descending n=100000" (it : @bench.T) {
  let entries = Array::makei(100000, i => (99999 - i, i))
  it.bench(() => it.keep(@sorted_map.SortedMap(entries)))
}

///|
test "bench SortedMap build shuffled n=100000" (it : @bench.T) {
  let entries = Array::makei(100000, i => (i * 8191 % 100000, i))
  it.bench(() => it.keep(@sorted_map.SortedMap(entries)))
}

///|
test "bench SortedMap merge disjoint n=10000+10000" (it : @bench.T) {
  let left = @sorted_map.SortedMap(Array::makei(10000, i => (i, i)))
  let right = @sorted_map.SortedMap(Array::makei(10000, i => (10000 + i, -i)))
  it.bench(() => it.keep(left.merge(right)))
}

///|
test "bench SortedMap merge overlapping n=10000+10000" (it : @bench.T) {
  let left = @sorted_map.SortedMap(Array::makei(10000, i => (i, i)))
  let right = @sorted_map.SortedMap(Array::makei(10000, i => (5000 + i, -i)))
  it.bench(() => it.keep(left.merge(right)))
}

///|
fn insertion_map(
  start : Int32,
  size : Int32,
) -> @sorted_map.SortedMap[Int32, Int32] {
  let map = @sorted_map.SortedMap([])
  for i in 0..<size {
    map.set(start + i, i)
  }
  map
}

///|
test "bench insertion-built merge disjoint" (it : @bench.T) {
  let left = insertion_map(0, 10000)
  let right = insertion_map(10000, 10000)
  it.bench(() => it.keep(left.merge(right)))
}

///|
test "bench insertion-built merge overlapping" (it : @bench.T) {
  let left = insertion_map(0, 10000)
  let right = insertion_map(5000, 10000)
  it.bench(() => it.keep(left.merge(right)))
}

///|
test "bench build and merge disjoint" (it : @bench.T) {
  let a = Array::makei(10000, i => (i, i))
  let b = Array::makei(10000, i => (10000 + i, -i))
  it.bench(() => {
    let left = @sorted_map.SortedMap(a)
    let right = @sorted_map.SortedMap(b)
    it.keep(left.merge(right))
  })
}
