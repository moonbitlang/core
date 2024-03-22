// Copyright 2024 International Digital Economy Academy
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

/// This module implements mutable set as hashtable.

/// MutableSet is an open-addressing hashset based on robin hood hash.
pub struct MutableSet[T] {
  priv mut directory : @vec.Vec[Option[Item[T]]]
  priv mut real_size : Int
  priv mut effective_size : Int
}

priv struct Item[T] {
  mut key : T
  mut probe_length : Int
} derive(Debug, Show)

/// Initialize MutableSet by specifying initial capacity.
pub fn MutableSet::with_capacity[T](initial_capacity : Int) -> MutableSet[T] {
  let directory : @vec.Vec[Option[Item[T]]] = @vec.Vec::new()
  directory.resize(@math.maximum(1, initial_capacity), None)
  { directory, real_size: 0, effective_size: 0 }
}

/// Initialize MutableSet with default capacity 3.
pub fn MutableSet::new[T]() -> MutableSet[T] {
  MutableSet::with_capacity(3)
}

/// Initialize a MutableSet from array.
pub fn MutableSet::from_array[T : Hash + Eq](array : Array[T]) -> MutableSet[T] {
  let set = MutableSet::with_capacity(array.length())
  array.iter(fn(key : T) -> Unit { set.insert(key) })
  set
}

/// Convert MutableSet to Array.
/// 
/// # Example
/// 
/// ```
/// println(MutableSet::[1, 1, 2, 2, 3, 3].to_array())
/// // output: [1, 2, 3]
/// ```
pub fn to_array[T : Default](self : MutableSet[T]) -> Array[T] {
  // If Array has a filter method, we can implement it like this:
  // let array : Array[Option[T]] = @array.new(self.size(), fn () -> Option[T] { None })
  // let mut index = 0
  // self.iter(
  //   fn(key : T) -> Unit {
  //     array[index] = Some(key)
  //     index = index + 1
  //   },
  // )
  // array.filter(fn(item : Option[T]) -> Bool { item.is_empty() })
  self.to_list().to_array()
}

/// Initialize a MutableSet from list.
pub fn MutableSet::from_list[T : Hash + Eq](list : List[T]) -> MutableSet[T] {
  let set = MutableSet::with_capacity(list.length())
  list.iter(fn(key : T) -> Unit { set.insert(key) })
  set
}

/// Convert MutableSet to List.
/// 
/// # Example
/// 
/// ```
/// println(MutableSet::[1, 1, 2, 2, 3, 3].to_list())
/// // output: Cons(3, Cons(2, Cons(1, Nil)))
/// ```
pub fn to_list[T](self : MutableSet[T]) -> List[T] {
  self.fold(
    fn(key : T, list : List[T]) -> List[T] { Cons(key, list) },
    ~init=Nil,
  )
}

/// Remove all elements from MutableSet.
/// 
/// # Example
/// 
/// ```
/// let set = MutableSet::[1, 1, 2, 2, 3, 3]
/// set.clear()
/// println(set.to_list())
/// // output: Nil
/// ```
pub fn clear[T](self : MutableSet[T]) -> Unit {
  let mut index = 0
  while index < self.directory.length() {
    self.directory[index] = None
    index = index + 1
  }
  self.effective_size = 0
  self.real_size = 0
}

/// Returns a copy of MutableSet.
pub fn copy[T](self : MutableSet[T]) -> MutableSet[T] {
  {
    directory: self.directory,
    effective_size: self.effective_size,
    real_size: self.real_size,
  }
}

/// Iterates over the MutableSet.
/// 
/// ```
/// MutableSet::[1, 1, 2, 2, 3, 3].iter(fn(key) -> Unit { print(key) })
/// // output: 123
/// ```
pub fn iter[T](self : MutableSet[T], f : (T) -> Unit) -> Unit {
  self.directory.iter(
    fn {
      Some({ key, probe_length: _ }) => f(key)
      None => ()
    },
  )
}

/// Fold the MutableSet.
/// 
/// # Example
/// 
/// ```
/// println(
///    MutableSet::[1, 1, 2, 2, 3, 3].fold(
///      fn(key, sum) -> Int { sum + key },
///      ~init=0,
///    )
/// )
/// // output 5
/// ```
pub fn fold[T, U](self : MutableSet[T], f : (T, U) -> U, ~init : U) -> U {
  self.directory.fold(
    fn(item : Option[Item[T]], accu : U) -> U {
      match item {
        Some({ key, probe_length: _ }) => f(key, accu)
        None => accu
      }
    },
    ~init,
  )
}

/// Insert a key to MutableSet.
/// 
/// # Example
/// 
/// ```
/// let set = MutableSet::[1, 1, 2, 2, 3, 3]
/// set.insert(4)
/// println(set.to_array())
/// // output: [1, 2, 3, 4]
/// ```
pub fn insert[T : Hash + Eq](self : MutableSet[T], key : T) -> Unit {
  let _ = self.insert_item(key)

}

/// Try to get the key.
/// 
/// # Example
/// 
/// ```
/// println(MutableSet::[1, 1, 2, 2, 3, 3].get(2).unwrap())
/// // output: 2
/// ```
pub fn get[T : Hash + Eq](self : MutableSet[T], key : T) -> Option[T] {
  let num_slots = self.directory.length()
  let slot = key.hash() % num_slots
  let mut index = slot
  while not(self.directory[index].is_empty()) {
    match self.directory[index] {
      Some(item) =>
        if key == item.key {
          return Some(key)
        } else {
          index = (index + 1) % num_slots
          if index == slot {
            break None
          }
        }
      _ => break None
    }
  } else {
    None
  }
}

/// Return true if key exists in the MutableSet.
pub fn exists[T : Hash + Eq](self : MutableSet[T], key : T) -> Bool {
  not(self.get(key).is_empty())
}

/// Remove a key from MutableSet.
/// 
/// # Example
/// 
/// ```
/// let set = MutableSet::[1, 1, 2, 2, 3, 3]
/// println(set.remove(2))
/// // output: 2
/// 
/// println(set.to_array())
/// // output: [1, 3]
/// ```
pub fn remove[T : Hash + Eq](self : MutableSet[T], key : T) -> Option[T] {
  match
    self.index_of(key).bind(
      fn(index) -> Option[T] {
        let removed = self.directory[index]
        self.directory[index] = None
        removed.map(fn(item : Item[T]) -> T { item.key })
      },
    ) {
    Some(_) as removed => {
      self.real_size = self.real_size - 1
      removed
    }
    None => None
  }
}

/// Remove a key from MutableSet without return value.
/// 
/// # Example
/// 
/// ```
/// let set = MutableSet::[1, 1, 2, 2, 3, 3]
/// set.remove_without_return(2)
/// println(set.to_array())
/// // output: [1, 3]
/// ```
pub fn remove_without_return[T : Hash + Eq](
  self : MutableSet[T],
  key : T
) -> Unit {
  match
    self.index_of(key).bind(
      fn(index) -> Option[T] {
        let removed = self.directory[index]
        self.directory[index] = None
        removed.map(fn(item : Item[T]) -> T { item.key })
      },
    ) {
    Some(_) => self.real_size = self.real_size - 1
    None => ()
  }
}

/// Returns the actual number of keys.
pub fn size[T](self : MutableSet[T]) -> Int {
  self.real_size
}

/// Returns the intersection of self with other.
/// 
/// # Example
/// 
/// ```
/// println(MutableSet::[3, 4, 5].inter(MutableSet::[4, 5, 6]).to_array())
/// // output: [4, 5]
/// ```
pub fn intersection[T : Hash + Eq](
  self : MutableSet[T],
  other : MutableSet[T]
) -> MutableSet[T] {
  let res = MutableSet::with_capacity(@math.minimum(self.size(), other.size()))
  other.iter(fn(key : T) -> Unit { if self.exists(key) { res.insert(key) } })
  res
}

/// Returns the intersection of self with other, but store the result in `into`
/// 
/// # Example
/// 
/// ```
/// let res = MutableSet::[]
/// MutableSet::[3, 4, 5].inter_into(MutableSet::[4, 5, 6], res)
/// println(res.to_array()) // output: [5, 4]
/// ```
pub fn intersection_into[T : Hash + Eq](
  self : MutableSet[T],
  other : MutableSet[T],
  into : MutableSet[T]
) -> Unit {
  other.iter(fn(key : T) -> Unit { if self.exists(key) { into.insert(key) } })
}

/// Returns the union of self and other.
/// 
/// # Example
/// 
/// ```
/// let res = MutableSet::[3, 4, 5].union(MutableSet::[4, 5, 6]).to_array()
/// res.sort()
/// println(res) // output: [3, 4, 5, 6]
/// ```
pub fn union[T : Hash + Eq](
  self : MutableSet[T],
  other : MutableSet[T]
) -> MutableSet[T] {
  let res = self.copy()
  other.iter(fn(key : T) -> Unit { res.insert(key) })
  res
}

/// Returns the union of self and other, but store the result in `into`
/// 
/// # Example
/// 
/// ```
/// let into = MutableSet::[]
/// MutableSet::[3, 4, 5].union_into(MutableSet::[4, 5, 6], into)
/// let into = into.to_array()
/// into.sort()
/// println(res) //output: [3, 4, 5, 6]
/// ```
pub fn union_into[T : Hash + Eq](
  self : MutableSet[T],
  other : MutableSet[T],
  into : MutableSet[T]
) -> Unit {
  self.union(other).iter(fn(key : T) -> Unit { into.insert(key) })
}

/// Returns the difference between self and other.
/// 
/// # Example
/// 
/// ```
/// println(MutableSet::[1, 2, 3].diff(MutableSet::[4, 5, 1]).to_array())
/// // output: [3, 2]
/// ```
pub fn diff[T : Hash + Eq](
  self : MutableSet[T],
  other : MutableSet[T]
) -> MutableSet[T] {
  let res = self.copy()
  other.iter(fn(key : T) -> Unit { res.remove_without_return(key) })
  res
}

/// Returns the difference between self and other, but store the result in `into`
/// 
/// # Example
/// 
/// ```
/// let into = MutableSet::[]
/// MutableSet::[1, 2, 3].diff_into(MutableSet::[4, 5, 1], into)
/// println(into.to_array()) // output: [2, 3]
/// ```
pub fn diff_into[T : Hash + Eq](
  self : MutableSet[T],
  other : MutableSet[T],
  into : MutableSet[T]
) -> Unit {
  self.diff(other).iter(fn(key : T) -> Unit { into.insert(key) })
}

// The following are the helper functions used by the internal implementation of MutableSet:

fn Item::new[T](key : T) -> Item[T] {
  { key, probe_length: 0 }
}

fn insert_item[T : Hash + Eq](self : MutableSet[T], key : T) -> Int {
  match self.index_of(key) {
    Some(index) => {
      self.directory[index].unwrap().key = key
      index
    }
    None => {
      if self.effective_size == self.directory.length() {
        let set = MutableSet::with_capacity(self.real_size * 2)
        self.iter(fn(key : T) -> Unit { set.insert(key) })
        self.directory = set.directory
        self.effective_size = set.effective_size
        self.real_size = set.real_size
      }
      let num_slots = self.directory.length()
      let slot = key.hash() % num_slots
      let mut current_probe_length = 0
      let mut current_item = Item::new(key)
      let mut index = slot
      while not(self.directory[index].is_empty()) {
        let item = self.directory[index].unwrap()
        if current_probe_length > item.probe_length {
          current_item.probe_length = current_probe_length
          let replaced = self.directory[index].unwrap()
          self.directory[index] = Some(current_item)
          current_item = replaced
          current_probe_length = current_item.probe_length
        }
        index = (index + 1) % num_slots
        current_probe_length = current_probe_length + 1
      }
      current_item.probe_length = current_probe_length
      self.directory[index] = Some(current_item)
      self.real_size = self.real_size + 1
      self.effective_size = self.effective_size + 1
      index
    }
  }
}

fn index_of[T : Hash + Eq](self : MutableSet[T], key : T) -> Option[Int] {
  let hash = key.hash()
  let num_slots = self.directory.length()
  let slot = hash % num_slots
  let mut index = slot
  while true {
    match self.directory[index] {
      Some(item) => {
        if key == item.key {
          break Some(index)
        }
        index = (index + 1) % num_slots
        if index == slot {
          break None
        }
      }
      None => break None
    }
  } else {
    None
  }
}

test "from_array and to_array" {
  let set = MutableSet::[1, 1, 2, 2, 3, 3]
  @assertion.assert_eq(set.to_array(), [3, 2, 1])?
  @assertion.assert_eq(set.effective_size, 3)?
  @assertion.assert_eq(set.real_size, 3)?
}

test "from_list and to_list" {
  @assertion.assert_eq(
    MutableSet::from_list(List::[1, 1, 2, 2, 3, 3]).to_list(),
    List::[3, 2, 1],
  )?
}

test "clear" {
  let set = MutableSet::[1, 1, 2, 2, 3, 3]
  set.clear()
  @assertion.assert_eq(set.to_list(), Nil)?
  @assertion.assert_eq(set.effective_size, 0)?
  @assertion.assert_eq(set.real_size, 0)?
}

test "insert" {
  let set = MutableSet::[1, 1, 2, 2, 3, 3]
  set.insert(4)
  @assertion.assert_eq(set.to_array(), [4, 3, 2, 1])?
}

test "remove" {
  let set = MutableSet::[1, 1, 2, 2, 3, 3]
  @assertion.assert_true(set.remove(4).is_empty())?
  @assertion.assert_eq(set.to_array(), [3, 2, 1])?
  @assertion.assert_eq(2, set.remove(2).unwrap())?
  @assertion.assert_eq(set.to_array(), [3, 1])?
}

test "exists" {
  @assertion.assert_true(MutableSet::[1, 1, 2, 2, 3, 3].exists(2))?
  @assertion.assert_false(MutableSet::[1, 1, 2, 2, 3, 3].exists(4))?
}

test "get" {
  @assertion.assert_eq(2, MutableSet::[1, 1, 2, 2, 3, 3].get(2).unwrap())?
  @assertion.assert_true(MutableSet::[1, 1, 2, 2, 3, 3].get(4).is_empty())?
}

test "size" {
  @assertion.assert_eq(3, MutableSet::[1, 1, 2, 2, 3, 3].size())?
}

test "fold" {
  @assertion.assert_eq(
    MutableSet::[1, 1, 2, 2, 3, 3].fold(
      fn(key, sum) -> Int { sum + key },
      ~init=0,
    ),
    6,
  )?
}

test "iter" {
  let mut n = 0
  MutableSet::[1, 1, 2, 2, 3, 3].iter(fn(key) -> Unit { n = n + key })
  @assertion.assert_eq(n, 6)?
}

test "intersection" {
  @assertion.assert_eq(
    MutableSet::[3, 4, 5].intersection(MutableSet::[4, 5, 6]).to_array(),
    [5, 4],
  )?
}

test "intersection_into" {
  let res = MutableSet::[1, 2, 3]
  MutableSet::[3, 4, 5].intersection_into(MutableSet::[4, 5, 6], res)
  let res = res.to_array()
  res.sort()
  @assertion.assert_eq(res, [1, 2, 3, 4, 5])?
}

test "union" {
  let res = MutableSet::[3, 4, 5].union(MutableSet::[4, 5, 6]).to_array()
  res.sort()
  @assertion.assert_eq(res, [3, 4, 5, 6])?
}

test "union_into" {
  let res = MutableSet::[]
  MutableSet::[3, 4, 5].union_into(MutableSet::[4, 5, 6], res)
  let res = res.to_array()
  res.sort()
  @assertion.assert_eq(res, [3, 4, 5, 6])?
}

test "diff" {
  @assertion.assert_eq(
    MutableSet::[1, 2, 3].diff(MutableSet::[4, 5, 1]).to_array(),
    [2, 3],
  )?
}

test "diff_into" {
  let res = MutableSet::[]
  MutableSet::[1, 2, 3].diff_into(MutableSet::[4, 5, 1], res)
  let res = res.to_array()
  res.sort()
  @assertion.assert_eq(res, [2, 3])?
}
