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
priv struct IntersectionCalls {
  mut calls : Int32
  mut comparisons : Int32
}

///|
priv struct IntersectionKey {
  rank : Int32
  label : Int32
  collisions : Bool
  counter : IntersectionCalls
}

///|
impl Eq for IntersectionKey with fn equal(self, other) {
  self.counter.comparisons += 1
  self.rank == other.rank && self.collisions == other.collisions
}

///|
impl Hash for IntersectionKey with fn hash_combine(self, hasher) {
  Hash::hash_combine(if self.collisions { 0 } else { self.rank }, hasher)
}

///|
impl Hash for IntersectionKey with fn hash(self) {
  self.counter.calls += 1
  Hash::hash(if self.collisions { 0 } else { self.rank })
}

///|
test "intersection of unequal tables bounds collision comparisons" {
  let counter = IntersectionCalls::{ calls: 0, comparisons: 0, }
  let left = HashSet(
    Array::makei(1024, rank => IntersectionKey::{
      rank,
      label: 1,
      collisions: true,
      counter,
    }),
  )
  let right = HashSet(
    Array::makei(8, rank => IntersectionKey::{
      rank,
      label: 2,
      collisions: true,
      counter,
    }),
  )
  counter.calls = 0
  counter.comparisons = 0
  let result = left.intersection(right)
  @test.assert_eq(result.length(), 8)
  @test.assert_eq(counter.calls, 0)
  @test.assert_eq(counter.comparisons <= 128, true)
}

///|
test "intersection preserves left key representatives and cached hashes" {
  for collisions in [false, true] {
    let counter = IntersectionCalls::{ calls: 0, comparisons: 0, }
    let large = HashSet(
      Array::makei(128, rank => IntersectionKey::{
        rank,
        label: 1,
        collisions,
        counter,
      }),
    )
    let small = HashSet(
      [3, 8, 127, 200].map(rank => IntersectionKey::{
        rank,
        label: 2,
        collisions,
        counter,
      }),
    )
    for (left, right) in [(large, small), (small, large)] {
      counter.calls = 0
      let expected = left
        .iter()
        .filter(k => {
          right.contains_with_hash(
            k,
            Hash::hash(if collisions { 0 } else { k.rank }),
          )
        })
        .map(k => (k.rank, k.label))
        .to_array()
      let actual = left
        .intersection(right)
        .iter()
        .map(k => (k.rank, k.label))
        .to_array()
      expected.sort()
      actual.sort()
      @test.assert_eq(actual, expected)
      @test.assert_eq(counter.calls, 0)
    }
  }
}

///|
test "intersection matches ordinary sets and returns an independent set" {
  for n in [0, 1, 3, 31, 128] {
    for m in [0, 1, 3, 31, 128] {
      for shift in [0, 1, n / 2, n, n + 10] {
        let left = HashSet(Array::makei(n, i => i))
        let right = HashSet(Array::makei(m, i => i + shift))
        let expected = left.to_array().filter(key => right.contains(key))
        let result = left.intersection(right)
        let actual = result.to_array()
        expected.sort()
        actual.sort()
        @test.assert_eq(actual, expected)
        result.add(-1)
        @test.assert_eq(left.contains(-1), false)
        @test.assert_eq(right.contains(-1), false)
      }
    }
  }
}

///|
test "intersection handles a sparse backing table" {
  let left = HashSet(Array::makei(1024, i => i))
  for i in 0..<1024 {
    if i != 5 && i != 10 {
      left.remove(i)
    }
  }
  let right = HashSet([5, 10, 11])
  let expected = left.to_array().filter(key => right.contains(key))
  let actual = left.intersection(right).to_array()
  expected.sort()
  actual.sort()
  @test.assert_eq(actual, expected)
}

///|
test "intersection breaks capacity ties by live size" {
  let counter = IntersectionCalls::{ calls: 0, comparisons: 0, }
  let dense = HashSet(
    Array::makei(128, rank => IntersectionKey::{
      rank,
      label: 1,
      collisions: true,
      counter,
    }),
  )
  let sparse = HashSet(
    Array::makei(128, rank => IntersectionKey::{
      rank,
      label: 2,
      collisions: true,
      counter,
    }),
  )
  for key in sparse.to_array() {
    if key.rank >= 8 {
      sparse.remove(key)
    }
  }
  inspect(dense.capacity == sparse.capacity, content="true")
  for (left, right, label) in [(dense, sparse, 1), (sparse, dense, 2)] {
    counter.calls = 0
    counter.comparisons = 0
    let result = left.intersection(right)
    @test.assert_eq(result.length(), 8)
    @test.assert_eq(counter.calls, 0)
    // Eight lookups and result insertions need at most 128 comparisons;
    // scanning the dense table instead needs over 1,000 comparisons.
    @test.assert_eq(counter.comparisons <= 128, true)
    @test.assert_eq(result.iter().all(key => key.label == label), true)
  }
}
