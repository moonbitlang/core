// Copyright 2025 International Digital Economy Academy
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
pub typealias T[K, V] = Map[K, V]

///|
pub fn capacity[K, V](map : Map[K, V]) -> Int {
  map.capacity()
}

///|
pub fn clear[K, V](map : Map[K, V]) -> Unit {
  map.clear()
}

///|
pub fn contains[K : Hash + Eq, V](map : Map[K, V], k : K) -> Bool {
  map.contains(k)
}

///|
pub fn default[K, V]() -> Map[K, V] {
  Map::default()
}

///|
pub fn each[K, V](map : Map[K, V], f : (K, V) -> Unit) -> Unit {
  map.each(f)
}

///|
pub fn eachi[K, V](map : Map[K, V], f : (Int, K, V) -> Unit) -> Unit {
  map.eachi(f)
}

///|
pub fn from_array[K : Hash + Eq, V](arr : Array[(K, V)]) -> Map[K, V] {
  Map::from_array(arr)
}

///|
pub fn from_iter[K : Hash + Eq, V](iter : Iter[(K, V)]) -> Map[K, V] {
  Map::from_iter(iter)
}

///|
pub fn get[K : Hash + Eq, V](map : Map[K, V], k : K) -> V? {
  map.get(k)
}

///|
pub fn get_or_default[K : Hash + Eq, V](
  map : Map[K, V],
  k : K,
  default : V
) -> V {
  map.get_or_default(k, default)
}

///|
pub fn get_or_init[K : Hash + Eq, V](
  map : Map[K, V],
  k : K,
  init : () -> V
) -> V {
  map.get_or_init(k, init)
}

///|
pub fn is_empty[K, V](map : Map[K, V]) -> Bool {
  map.is_empty()
}

///|
pub fn iter[K, V](map : Map[K, V]) -> Iter[(K, V)] {
  map.iter()
}

///|
pub fn iter2[K, V](map : Map[K, V]) -> Iter2[K, V] {
  map.iter2()
}

///|
pub fn keys[K, V](map : Map[K, V]) -> Iter[K] {
  map.keys()
}

///|
pub fn new[K, V](capacity~ : Int = 8) -> Map[K, V] {
  Map::new(capacity~)
}

///|
pub fn of[K : Hash + Eq, V](arr : FixedArray[(K, V)]) -> Map[K, V] {
  Map::of(arr)
}

///|
pub fn remove[K : Hash + Eq, V](map : Map[K, V], k : K) -> Unit {
  map.remove(k)
}

///|
pub fn set[K : Hash + Eq, V](map : Map[K, V], k : K, v : V) -> Unit {
  map.set(k, v)
}

///|
pub fn size[K, V](map : Map[K, V]) -> Int {
  map.size()
}

///|
pub fn to_array[K, V](map : Map[K, V]) -> Array[(K, V)] {
  map.to_array()
}

///|
pub fn to_json[K : Show, V : ToJson](map : Map[K, V]) -> Json {
  map.to_json()
}

///|
pub fn values[K, V](map : Map[K, V]) -> Iter[V] {
  map.values()
}
