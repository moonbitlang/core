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
priv struct StableInt(Int) derive(Eq)

///|
impl Hash for StableInt with fn hash_combine(self, hasher) {
  hasher.combine_int(self.0)
}

///|
impl Hash for StableInt with fn hash(self) {
  self.0
}

///|
impl @debug.Debug for StableInt with fn to_repr(self) {
  Repr(self.0)
}

///|
impl @shrink.Shrink for StableInt with fn shrink(self) {
  @shrink.Shrink::shrink(self.0).map(value => StableInt(value))
}

///|
test "shrink int list" {
  let il : @list.List[Int] = List([1, 2, 3, 4, 5, 6])
  debug_inspect(
    @shrink.Shrink::shrink(il).collect(),
    content=(
      #|[
      #|  <List: [1, 2, 3, 4, 5]>,
      #|  <List: [1, 2, 3, 4, 6]>,
      #|  <List: [1, 2, 3, 5, 6]>,
      #|  <List: [1, 2, 4, 5, 6]>,
      #|  <List: [1, 3, 4, 5, 6]>,
      #|  <List: [2, 3, 4, 5, 6]>,
      #|  <List: [1, 2, 3]>,
      #|  <List: [4, 5, 6]>,
      #|  <List: [0, 2, 3, 4, 5, 6]>,
      #|  <List: [1, 0, 3, 4, 5, 6]>,
      #|  <List: [1, 1, 3, 4, 5, 6]>,
      #|  <List: [1, 2, 0, 4, 5, 6]>,
      #|  <List: [1, 2, 2, 4, 5, 6]>,
      #|  <List: [1, 2, 3, 0, 5, 6]>,
      #|  <List: [1, 2, 3, 2, 5, 6]>,
      #|  <List: [1, 2, 3, 3, 5, 6]>,
      #|  <List: [1, 2, 3, 4, 0, 6]>,
      #|  <List: [1, 2, 3, 4, 3, 6]>,
      #|  <List: [1, 2, 3, 4, 4, 6]>,
      #|  <List: [1, 2, 3, 4, 5, 0]>,
      #|  <List: [1, 2, 3, 4, 5, 3]>,
      #|  <List: [1, 2, 3, 4, 5, 5]>,
      #|]
    ),
  )
}

///|
test "shrink queue" {
  let input = @queue.Queue([true, false, true])
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <Queue: []>,
      #|  <Queue: [false, true]>,
      #|  <Queue: [true, true]>,
      #|  <Queue: [true, false]>,
      #|  <Queue: [false, false, true]>,
      #|  <Queue: [true, false, false]>,
      #|]
    ),
  )
}

///|
test "shrink immutable vector" {
  let input = @immut_vector.Vector([2, 4])
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <Vector: []>,
      #|  <Vector: [4]>,
      #|  <Vector: [2]>,
      #|  <Vector: [0, 4]>,
      #|  <Vector: [1, 4]>,
      #|  <Vector: [2, 0]>,
      #|  <Vector: [2, 2]>,
      #|  <Vector: [2, 3]>,
      #|]
    ),
  )
}

///|
test "shrink mutable hash set" {
  let input = @hashset.HashSet([StableInt(4), StableInt(10)])
  let table = @shrink.Shrink::shrink(input).collect()
  debug_inspect(
    table,
    content=(
      #|[
      #|  <HashSet: []>,
      #|  <HashSet: [4]>,
      #|  <HashSet: [10]>,
      #|  <HashSet: [0, 4]>,
      #|  <HashSet: [4, 5]>,
      #|  <HashSet: [8, 4]>,
      #|  <HashSet: [9, 4]>,
      #|  <HashSet: [0, 10]>,
      #|  <HashSet: [10, 2]>,
      #|  <HashSet: [10, 3]>,
      #|]
    ),
  )
}

///|
test "shrink mutable sorted set" {
  let input = @sorted_set.SortedSet([2, 4])
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <SortedSet: []>,
      #|  <SortedSet: [4]>,
      #|  <SortedSet: [2]>,
      #|  <SortedSet: [0, 4]>,
      #|  <SortedSet: [1, 4]>,
      #|  <SortedSet: [0, 2]>,
      #|  <SortedSet: [2]>,
      #|  <SortedSet: [2, 3]>,
      #|]
    ),
  )
}

///|
test "shrink immutable hash set" {
  let input = @immut_hashset.HashSet([StableInt(3), StableInt(7)])
  let table = @shrink.Shrink::shrink(input).collect()
  debug_inspect(
    table,
    content=(
      #|[
      #|  <HashSet: []>,
      #|  <HashSet: [7]>,
      #|  <HashSet: [3]>,
      #|  <HashSet: [0, 7]>,
      #|  <HashSet: [2, 7]>,
      #|  <HashSet: [0, 3]>,
      #|  <HashSet: [3, 4]>,
      #|  <HashSet: [3, 6]>,
      #|]
    ),
  )
}

///|
test "shrink immutable sorted set" {
  let input = @immut_sorted_set.SortedSet([2, 5])
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <SortedSet: []>,
      #|  <SortedSet: [5]>,
      #|  <SortedSet: [2]>,
      #|  <SortedSet: [0, 5]>,
      #|  <SortedSet: [1, 5]>,
      #|  <SortedSet: [0, 2]>,
      #|  <SortedSet: [2, 3]>,
      #|  <SortedSet: [2, 4]>,
      #|]
    ),
  )
}

///|
test "shrink builtin map" {
  let input : Map[StableInt, Bool] = Map([
    (StableInt(2), true),
    (StableInt(1), false),
  ])
  let candidates = @shrink.Shrink::shrink(input).map(Map::to_array).collect()
  debug_inspect(
    candidates,
    content=(
      #|[
      #|  [],
      #|  [(1, false)],
      #|  [(2, true)],
      #|  [(0, true), (1, false)],
      #|  [(1, false)],
      #|  [(2, false), (1, false)],
      #|  [(2, true), (0, false)],
      #|]
    ),
  )
}

///|
test "shrink linked set" {
  let input = @set.Set([StableInt(2), StableInt(1)])
  let candidates = @shrink.Shrink::shrink(input)
    .map(@set.Set::to_array)
    .collect()
  debug_inspect(
    candidates,
    content=(
      #|[[], [1], [2], [0, 1], [1], [2, 0]]
    ),
  )
}

///|
test "shrink deque" {
  let input = @deque.Deque([2, 1])
  let candidates = @shrink.Shrink::shrink(input)
    .map(@deque.Deque::to_array)
    .collect()
  debug_inspect(
    candidates,
    content=(
      #|[[], [1], [2], [0, 1], [1, 1], [2, 0]]
    ),
  )
}

///|
test "shrink mutable priority queue" {
  let input = @priority_queue.PriorityQueue([2, 4])
  let candidates = @shrink.Shrink::shrink(input)
    .map(@priority_queue.PriorityQueue::to_array)
    .collect()
  debug_inspect(
    candidates,
    content=(
      #|[[], [2], [4], [2, 0], [2, 2], [3, 2], [4, 0], [4, 1]]
    ),
  )
}

///|
test "shrink immutable priority queue" {
  let input = @immut_priority_queue.PriorityQueue([2, 4])
  let candidates = @shrink.Shrink::shrink(input)
    .map(@immut_priority_queue.PriorityQueue::to_array)
    .collect()
  debug_inspect(
    candidates,
    content=(
      #|[[], [2], [4], [2, 0], [2, 2], [3, 2], [4, 0], [4, 1]]
    ),
  )
}

///|
test "shrink mutable hash map" {
  let input = @hashmap.HashMap([(StableInt(2), true), (StableInt(1), false)])
  let table = @shrink.Shrink::shrink(input).collect()
  debug_inspect(
    table,
    content=(
      #|[
      #|  <HashMap: {}>,
      #|  <HashMap: { 2: true }>,
      #|  <HashMap: { 1: false }>,
      #|  <HashMap: { 0: false, 2: true }>,
      #|  <HashMap: { 0: true, 1: false }>,
      #|  <HashMap: { 1: true }>,
      #|  <HashMap: { 1: false, 2: false }>,
      #|]
    ),
  )
}

///|
test "shrink mutable sorted map" {
  let input = @sorted_map.SortedMap([(false, 2), (true, 1)])
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <SortedMap: {}>,
      #|  <SortedMap: { true: 1 }>,
      #|  <SortedMap: { false: 2 }>,
      #|  <SortedMap: { false: 0, true: 1 }>,
      #|  <SortedMap: { false: 1, true: 1 }>,
      #|  <SortedMap: { false: 1 }>,
      #|  <SortedMap: { false: 2, true: 0 }>,
      #|]
    ),
  )
}

///|
test "shrink immutable hash map" {
  let input = @immut_hashmap.HashMap([(StableInt(4), 2), (StableInt(3), 7)])
  let table = @shrink.Shrink::shrink(input).collect()
  debug_inspect(
    table,
    content=(
      #|[
      #|  <HashMap: {}>,
      #|  <HashMap: { 4: 2 }>,
      #|  <HashMap: { 3: 7 }>,
      #|  <HashMap: { 0: 7, 4: 2 }>,
      #|  <HashMap: { 2: 7, 4: 2 }>,
      #|  <HashMap: { 3: 0, 4: 2 }>,
      #|  <HashMap: { 3: 4, 4: 2 }>,
      #|  <HashMap: { 3: 6, 4: 2 }>,
      #|  <HashMap: { 0: 2, 3: 7 }>,
      #|  <HashMap: { 2: 2, 3: 7 }>,
      #|  <HashMap: { 3: 7 }>,
      #|  <HashMap: { 3: 7, 4: 0 }>,
      #|  <HashMap: { 3: 7, 4: 1 }>,
      #|]
    ),
  )
}

///|
test "shrink immutable sorted map" {
  let input = @immut_sorted_map.SortedMap([(1, false), (3, true)])
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <SortedMap: {}>,
      #|  <SortedMap: { 3: true }>,
      #|  <SortedMap: { 1: false }>,
      #|  <SortedMap: { 0: false, 3: true }>,
      #|  <SortedMap: { 0: true, 1: false }>,
      #|  <SortedMap: { 1: false, 2: true }>,
      #|  <SortedMap: { 1: false, 3: false }>,
      #|]
    ),
  )
}
