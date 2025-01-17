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
pub typealias T[K] = Set[K]

///|
pub fn add[K : Hash + Eq](set : Set[K], k : K) -> Unit {
  set.add(k)
}

///|
pub fn add_and_check[K : Hash + Eq](set : Set[K], k : K) -> Bool {
  set.add_and_check(k)
}

///|
pub fn capacity[K](set : Set[K]) -> Int {
  set.capacity()
}

///|
pub fn clear[K](set : Set[K]) -> Unit {
  set.clear()
}

///|
pub fn contains[K : Hash + Eq](set : Set[K], k : K) -> Bool {
  set.contains(k)
}

///|
pub fn difference[K : Hash + Eq](s1 : Set[K], s2 : Set[K]) -> Set[K] {
  s1.difference(s2)
}

///|
pub fn each[K](set : Set[K], f : (K) -> Unit) -> Unit {
  set.each(f)
}

///|
pub fn eachi[K](set : Set[K], f : (Int, K) -> Unit) -> Unit {
  set.eachi(f)
}

///|
pub fn from_array[K : Hash + Eq](arr : Array[K]) -> Set[K] {
  Set::from_array(arr)
}

///|
pub fn from_iter[K : Hash + Eq](iter : Iter[K]) -> Set[K] {
  Set::from_iter(iter)
}

///|
pub fn intersection[K : Hash + Eq](s1 : Set[K], s2 : Set[K]) -> Set[K] {
  s1.intersection(s2)
}

///|
pub fn is_empty[K](set : Set[K]) -> Bool {
  set.is_empty()
}

///|
pub fn iter[K](set : Set[K]) -> Iter[K] {
  set.iter()
}

///|
pub fn new[K](capacity~ : Int = 8) -> Set[K] {
  Set::new(capacity~)
}

///|
pub fn of[K : Hash + Eq](arr : FixedArray[K]) -> Set[K] {
  Set::of(arr)
}

///|
pub fn remove[K : Hash + Eq](set : Set[K], k : K) -> Unit {
  set.remove(k)
}

///|
pub fn remove_and_check[K : Hash + Eq](set : Set[K], k : K) -> Bool {
  set.remove_and_check(k)
}

///|
pub fn size[K](set : Set[K]) -> Int {
  set.size()
}

///|
pub fn symmetric_difference[K : Hash + Eq](s1 : Set[K], s2 : Set[K]) -> Set[K] {
  s1.symmetric_difference(s2)
}

///|
pub fn to_array[K](set : Set[K]) -> Array[K] {
  set.to_array()
}

///|
pub fn to_json[X : ToJson](set : Set[X]) -> Json {
  set.to_json()
}

///|
pub fn union[K : Hash + Eq](s1 : Set[K], s2 : Set[K]) -> Set[K] {
  s1.union(s2)
}
