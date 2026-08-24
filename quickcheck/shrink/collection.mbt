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
pub impl[T : Shrink] Shrink for @list.List[T] with fn shrink(xs) {
  guard !xs.is_empty() else { return [||] }
  fn shr_sub_terms(lst : @list.List[T]) {
    match lst {
      Empty => [||]
      More(x, tail=xs) =>
        Shrink::shrink(x)
        .map(x_ => xs.add(x_))
        .concat(shr_sub_terms(xs).map(xs_ => xs_.add(x)))
    }
  }

  [|xs.take(0)|].concat(
    [|()|].flat_map(_ => {
      let n = xs.length()
      [
        for k = n / 2; k > 0; k = k / 2 => k
      ]
      .iter()
      .flat_map(k => removes_list(k, n, xs))
      .concat([|()|].flat_map(_ => shr_sub_terms(xs)))
    }),
  )
}

///|
pub impl[T : Shrink] Shrink for @queue.Queue[T] with fn shrink(xs) {
  Shrink::shrink(xs.iter().collect()).map(candidate => Queue(candidate))
}

///|
pub impl[T : Shrink] Shrink for @deque.Deque[T] with fn shrink(xs) {
  Shrink::shrink(xs.to_array()).map(candidate => Deque(candidate))
}

///|
pub impl[T : Shrink] Shrink for @immut_vector.Vector[T] with fn shrink(xs) {
  Shrink::shrink(xs.to_array()).map(candidate => Vector(candidate))
}

///|
pub impl[T : Shrink + Eq + Hash] Shrink for @hashset.HashSet[T] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.to_array()).map(candidate => HashSet(candidate))
}

///|
pub impl[T : Shrink + Compare] Shrink for @sorted_set.SortedSet[T] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.to_array()).map(candidate => SortedSet(candidate))
}

///|
pub impl[T : Shrink + Eq + Hash] Shrink for @immut_hashset.HashSet[T] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.iter().collect()).map(candidate => HashSet(candidate))
}

///|
pub impl[T : Shrink + Compare] Shrink for @immut_sorted_set.SortedSet[T] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.to_array()).map(candidate => SortedSet(candidate))
}

///|
pub impl[T : Shrink + Eq + Hash] Shrink for @set.Set[T] with fn shrink(xs) {
  Shrink::shrink(xs.to_array()).map(candidate => Set(candidate))
}

///|
pub impl[K : Shrink + Hash + Eq, V : Shrink] Shrink for Map[K, V] with fn shrink(
  xs,
) {
  let entries = xs.to_array()
  Shrink::shrink(entries).map(candidate => Map(candidate))
}

///|
pub impl[T : Shrink + Compare] Shrink for @priority_queue.PriorityQueue[T] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.to_array()).map(candidate => PriorityQueue(candidate))
}

///|
pub impl[T : Shrink + Compare] Shrink for @immut_priority_queue.PriorityQueue[T] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.to_array()).map(candidate => PriorityQueue(candidate))
}

///|
pub impl[K : Shrink + Hash + Eq, V : Shrink] Shrink for @hashmap.HashMap[K, V] with fn shrink(
  xs,
) {
  Shrink::shrink(xs.to_array()).map(candidate => HashMap(candidate))
}

///|
pub impl[K : Shrink + Compare, V : Shrink] Shrink for @sorted_map.SortedMap[
  K,
  V,
] with fn shrink(xs) {
  Shrink::shrink(xs.to_array()).map(candidate => SortedMap(candidate))
}

///|
pub impl[K : Shrink + Eq + Hash, V : Shrink] Shrink for @immut_hashmap.HashMap[
  K,
  V,
] with fn shrink(xs) {
  Shrink::shrink(xs.to_array()).map(candidate => HashMap(candidate))
}

///|
pub impl[K : Shrink + Compare, V : Shrink] Shrink for @immut_sorted_map.SortedMap[
  K,
  V,
] with fn shrink(xs) {
  Shrink::shrink(xs.to_array()).map(candidate => SortedMap(candidate))
}
