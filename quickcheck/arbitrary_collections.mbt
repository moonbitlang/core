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
pub impl[X : Arbitrary] Arbitrary for @list.List[X] with fn arbitrary(size, rs) {
  let values : Array[X] = Arbitrary::arbitrary(size, rs)
  List(values)
}

///|
pub impl[X : Arbitrary] Arbitrary for @queue.Queue[X] with fn arbitrary(
  size,
  rs,
) {
  let values : Iter[X] = Arbitrary::arbitrary(size, rs)
  @queue.Queue::from_iter(values)
}

///|
pub impl[K : Arbitrary + Hash + Eq, V : Arbitrary] Arbitrary for @hashmap.HashMap[
  K,
  V,
] with fn arbitrary(size, rs) {
  let values : Iter[(K, V)] = Arbitrary::arbitrary(size, rs)
  @hashmap.HashMap::from_iter(values)
}

///|
pub impl[X : Arbitrary + Eq + Hash] Arbitrary for @hashset.HashSet[X] with fn arbitrary(
  size,
  rs,
) {
  let values : Iter[X] = Arbitrary::arbitrary(size, rs)
  @hashset.HashSet::from_iter(values)
}

///|
pub impl[K : Arbitrary + Compare, V : Arbitrary] Arbitrary for @sorted_map.SortedMap[
  K,
  V,
] with fn arbitrary(size, rs) {
  let values : Iter[(K, V)] = Arbitrary::arbitrary(size, rs)
  @sorted_map.SortedMap::from_iter(values)
}

///|
pub impl[X : Arbitrary + Compare] Arbitrary for @sorted_set.SortedSet[X] with fn arbitrary(
  size,
  rs,
) {
  let values : Iter[X] = Arbitrary::arbitrary(size, rs)
  @sorted_set.SortedSet::from_iter(values)
}

///|
pub impl[X : Arbitrary + Compare] Arbitrary for @priority_queue.PriorityQueue[X] with fn arbitrary(
  size,
  rs,
) {
  let len = if size == 0 { 0 } else { rs.next_positive_int() % size }
  let queue : @priority_queue.PriorityQueue[X] = PriorityQueue([])
  for i in 0..<len {
    queue.push(Arbitrary::arbitrary(i, rs))
  }
  queue
}

///|
#warnings("-deprecated")
pub impl[X : Arbitrary] Arbitrary for @immut_array.T[X] with fn arbitrary(
  size,
  rs,
) {
  let values : Array[X] = Arbitrary::arbitrary(size, rs)
  @immut_array.T::from_array(values)
}

///|
pub impl[X : Arbitrary] Arbitrary for @immut_vector.Vector[X] with fn arbitrary(
  size,
  rs,
) {
  let values : Array[X] = Arbitrary::arbitrary(size, rs)
  Vector(values)
}

///|
pub impl[X : Arbitrary + Compare] Arbitrary for @immut_priority_queue.PriorityQueue[
  X,
] with fn arbitrary(size, rs) {
  let values : Array[X] = Arbitrary::arbitrary(size, rs)
  PriorityQueue(values)
}

///|
pub impl[K : Eq + Hash + Arbitrary, V : Arbitrary] Arbitrary for @immut_hashmap.HashMap[
  K,
  V,
] with fn arbitrary(size, rs) {
  let values : Array[(K, V)] = Arbitrary::arbitrary(size, rs)
  HashMap(values)
}

///|
pub impl[K : Eq + Hash + Arbitrary] Arbitrary for @immut_hashset.HashSet[K] with fn arbitrary(
  size,
  rs,
) {
  let values : Array[K] = Arbitrary::arbitrary(size, rs)
  HashSet(values)
}

///|
pub impl[K : Arbitrary + Compare, V : Arbitrary] Arbitrary for @immut_sorted_map.SortedMap[
  K,
  V,
] with fn arbitrary(size, rs) {
  let values : Array[(K, V)] = Arbitrary::arbitrary(size, rs)
  SortedMap(values)
}

///|
pub impl[X : Arbitrary + Compare] Arbitrary for @immut_sorted_set.SortedSet[X] with fn arbitrary(
  size,
  rs,
) {
  let values : Array[X] = Arbitrary::arbitrary(size, rs)
  SortedSet(values)
}
