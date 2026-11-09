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
test "capacity hint reserves room for that many entries" {
  for n in [0, 1, 2, 3, 6, 7, 12, 13, 14, 16, 100, 1000] {
    let m : HashMap[Int32, Int32] = HashMap([], capacity=n)
    let buckets = m.capacity
    for i in 0..<n {
      m.set(i, i)
    }
    assert_true(m.capacity == buckets)
  }
}

///|
test "capacity hint counts the initial entries" {
  for n in [1, 2, 13, 16, 100] {
    // One entry comes from the array, so n - 1 more fit without growing.
    let m : HashMap[Int32, Int32] = HashMap([(-1, -1)], capacity=n)
    let buckets = m.capacity
    for i in 0..<(n - 1) {
      m.set(i, i)
    }
    assert_true(m.capacity == buckets)
  }
}

///|
test "panic HashMap capacity hint exceeds the maximum entry count" {
  // One more than 2^30 / 2 entries; reject before allocating.
  let _ : HashMap[Int32, Int32] = HashMap([], capacity=0x20000001)
}
