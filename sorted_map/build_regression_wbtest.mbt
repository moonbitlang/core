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
priv struct BuildCounter {
  mut calls : Int32
}

///|
priv struct BuildKey {
  rank : Int32
  tag : Int32
  counter : BuildCounter
}

///|
impl Eq for BuildKey with fn equal(self, other) {
  self.rank == other.rank
}

///|
impl Compare for BuildKey with fn compare(self, other) {
  self.counter.calls += 1
  self.rank.compare(other.rank)
}

///|
test "ordered construction uses a linear number of comparisons" {
  let size = 1024
  for descending in [false, true] {
    let counter = BuildCounter::{ calls: 0, }
    let entries = Array::makei(size, i => {
      let rank = if descending { size - 1 - i } else { i }
      (BuildKey::{ rank, tag: i, counter, }, rank)
    })
    let map = SortedMap(entries)
    @test.assert_eq(map.length(), size)
    @test.assert_eq(counter.calls <= 2 * size, true)
  }
}

///|
test "ordered construction preserves AVL invariants after mutations" {
  for size in [0, 1, 2, 3, 7, 31, 32, 33, 127, 1024] {
    for descending in [false, true] {
      let entries = Array::makei(size, i => {
        let key = if descending { size - 1 - i } else { i }
        (key * 2, key)
      })
      let map = SortedMap(entries)
      check_invariants(map)
      @test.assert_eq(map.length(), size)
      for i in 0..<size {
        @test.assert_eq(map.get(i * 2), Some(i))
      }
      map.set(-1, -1)
      map.set(1, -2)
      map.remove(size)
      check_invariants(map)
    }
  }
}

///|
test "unordered and duplicate inputs match repeated insertion" {
  for
    entries in [
      [(0, 1), (0, 2), (1, 3), (1, 4)],
      [(2, 1), (2, 2), (1, 3), (0, 4)],
      [(3, 1), (1, 2), (4, 3), (2, 4), (1, 5)],
    ] {
    let expected : SortedMap[Int32, Int32] = new_sorted_map()
    for (key, value) in entries {
      expected.set(key, value)
    }
    let actual = SortedMap(entries)
    @test.assert_eq(actual.to_array(), expected.to_array())
    check_invariants(actual)
  }
}

///|
test "construction copies sliced input independently" {
  for
    entries in [
      [(99, 99), (1, 10), (2, 20), (3, 30), (-99, -99)],
      [(99, 99), (3, 30), (2, 20), (1, 10), (-99, -99)],
    ] {
    let map = SortedMap(entries[1:4])
    entries[2] = (100, 100)
    @test.assert_eq(map.to_array(), [(1, 10), (2, 20), (3, 30)])
    map.set(2, 200)
    @test.assert_eq(entries[2], (100, 100))
  }
}

///|
test "construction retains the first equal key and last value" {
  for
    keys in [
      [0, 1, 2],
      [2, 1, 0],
      [0, 0, 1, 1, 2],
      [2, 1, 1, 0, 0],
      [1, 0, 2, 1],
      [0, 1, 2, 3, 4, 2, 5, 0],
      [4, 3, 2, 1, 0, 2, 5, 4],
    ] {
    let counter = BuildCounter::{ calls: 0, }
    let entries = keys.mapi((i, rank) => {
      (BuildKey::{ rank, tag: i, counter, }, i)
    })
    let expected = new_sorted_map()
    for (key, value) in entries {
      expected.set(key, value)
    }
    let actual = SortedMap(entries)
    @test.assert_eq(
      actual.to_array().map(entry => (entry.0.rank, entry.0.tag, entry.1)),
      expected.to_array().map(entry => (entry.0.rank, entry.0.tag, entry.1)),
    )
    let replacement = BuildKey::{ rank: 1, tag: 999, counter, }
    actual.set(replacement, 999)
    expected.set(replacement, 999)
    @test.assert_eq(
      actual.to_array().map(entry => (entry.0.rank, entry.0.tag, entry.1)),
      expected.to_array().map(entry => (entry.0.rank, entry.0.tag, entry.1)),
    )
  }
}

///|
test "ordered construction honors reversed key comparison" {
  for size in [0, 1, 2, 31, 32, 33, 127] {
    for descending in [false, true] {
      let entries = Array::makei(size, i => {
        let rank = if descending { size - 1 - i } else { i }
        (@cmp.Reverse(rank), rank)
      })
      let map = SortedMap(entries)
      @test.assert_eq(
        map.values().to_array(),
        Array::makei(size, i => size - 1 - i),
      )
      for rank in 0..<size {
        @test.assert_eq(map.get(Reverse(rank)), Some(rank))
      }
    }
  }
}

///|
test "signed zeros and numerical extremes preserve insertion behavior" {
  let infinity = 1.0 / 0.0
  let subnormal = 1L.reinterpret_as_double()
  for
    keys in [
      [-infinity, 1.0, 2.0],
      [1.0, subnormal, 2.0],
      [2.0, 1.0, -subnormal],
      [-0.0, 0.0, 1.0],
      [0.0, 1.0, 2.0, 3.0, 4.0, infinity],
      [4.0, 3.0, 2.0, 1.0, 0.0, infinity],
      [0.0, 1.0, 2.0, 3.0, 4.0, 2.0, infinity, 6.0],
      [4.0, 3.0, 2.0, 1.0, 0.0, 2.0, infinity, 6.0],
      [-2.0, -1.0, -0.0, 0.0, 1.0],
      [2.0, 1.0, 0.0, -0.0, -1.0],
    ] {
    let entries = keys.mapi((i, key) => (key, i))
    let expected : SortedMap[Double, Int32] = new_sorted_map()
    for (key, value) in entries {
      expected.set(key, value)
    }
    let actual = SortedMap(entries)
    @test.assert_eq(actual.length(), expected.length())
    @test.assert_eq(actual.values().to_array(), expected.values().to_array())
    @test.assert_eq(
      actual.keys().map(key => key.reinterpret_as_int64()).to_array(),
      expected.keys().map(key => key.reinterpret_as_int64()).to_array(),
    )
    for key in [infinity, -0.0, 0.0, 1.0, 2.0] {
      @test.assert_eq(actual.get(key), expected.get(key))
    }
  }
}

///|
test "long ordered prefixes retain linear construction work" {
  let size = 1024
  for descending in [false, true] {
    for duplicate in [false, true] {
      let counter = BuildCounter::{ calls: 0, }
      let entries = Array::makei(size, i => {
        let rank = if descending { size - 1 - i } else { i }
        (BuildKey::{ rank, tag: i, counter, }, i)
      })
      let rank = if duplicate {
        size / 2
      } else if descending {
        size
      } else {
        -1
      }
      entries.push(({ rank, tag: size, counter, }, size))
      let map = SortedMap(entries)
      @test.assert_eq(map.length(), if duplicate { size } else { size + 1 })
      @test.assert_eq(counter.calls <= 2 * entries.length(), true)
      @test.assert_eq(map.get({ rank, tag: -1, counter, }), Some(size))
    }
  }
}

///|
test "ordered prefixes and mixed suffixes preserve AVL invariants" {
  for size in [1, 2, 3, 4, 7, 8, 31, 32, 33, 127] {
    for descending in [false, true] {
      let entries = Array::makei(size, i => {
        let rank = if descending { size - 1 - i } else { i }
        (rank * 2, rank)
      })
      let rng = Rand::{ state: 4367UL, }
      for i in 0..<128 {
        entries.push((rng.below(4 * size) - size, -i))
      }
      let expected = new_sorted_map()
      for (key, value) in entries {
        expected.set(key, value)
      }
      let actual = SortedMap(entries)
      @test.assert_eq(actual.to_array(), expected.to_array())
      check_invariants(actual)
      for key in -size..<(3 * size) {
        actual.remove(key)
        expected.remove(key)
        check_invariants(actual)
        @test.assert_eq(actual.to_array(), expected.to_array())
      }
    }
  }
}

///|
test "ordered prefixes respect slices and reversed comparison" {
  for keys in [[0, 1, 2, 3, 4, 2, -1], [4, 3, 2, 1, 0, 2, 5]] {
    let entries = keys.mapi((i, key) => (@cmp.Reverse(key), i))
    entries.insert(0, (Reverse(99), -1))
    entries.push((Reverse(-99), -1))
    let view = entries[1:entries.length() - 1]
    let expected = new_sorted_map()
    for (key, value) in view {
      expected.set(key, value)
    }
    let actual = SortedMap(view)
    entries[2] = (Reverse(999), 999)
    @test.assert_eq(actual.to_array(), expected.to_array())
  }
}
