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
/// Create an empty map.
#as_free_fn
#alias(empty, deprecated)
pub fn[K, V] SortedMap::new() -> SortedMap[K, V] {
  Empty
}

///|
/// Create a map with a single key-value pair.
#as_free_fn
pub fn[K, V] SortedMap::singleton(key : K, value : V) -> SortedMap[K, V] {
  Tree(key, value~, size=1, Empty, Empty)
}

///|
/// Check if the map contains a key.
/// O(log n).
pub fn[K : Compare, V] SortedMap::contains(
  self : SortedMap[K, V],
  key : K,
) -> Bool {
  loop self {
    Empty => false
    Tree(k, l, r, ..) => {
      let c = key.compare(k)
      if c == 0 {
        true
      } else if c < 0 {
        continue l
      } else {
        continue r
      }
    }
  }
}

///|
/// Get the number of key-value pairs in the map.
#alias(size, deprecated)
pub fn[K, V] SortedMap::length(self : SortedMap[K, V]) -> Int {
  match self {
    Empty => 0
    Tree(_) as t => t.size
  }
}

///|
pub fn[K, V] SortedMap::is_empty(self : SortedMap[K, V]) -> Bool {
  self.length() == 0
}

///|
fn[K, V] make_tree(
  key : K,
  value : V,
  l : SortedMap[K, V],
  r : SortedMap[K, V],
) -> SortedMap[K, V] {
  let size = l.length() + r.length() + 1
  Tree(key, value~, size~, l, r)
}

///|
/// Get the value associated with a key.
/// O(log n).
#alias(lookup, deprecated)
pub fn[K : Compare, V] SortedMap::get(self : SortedMap[K, V], key : K) -> V? {
  loop self {
    Empty => None
    Tree(k, value~, l, r, ..) => {
      let c = key.compare(k)
      if c == 0 {
        Some(value)
      } else if c < 0 {
        continue l
      } else {
        continue r
      }
    }
  }
}

///|
/// Get the value associated with a key.
/// O(log n).
#alias("_[_]")
pub fn[K : Compare, V] SortedMap::at(self : SortedMap[K, V], key : K) -> V {
  loop self {
    Empty => panic()
    Tree(k, value~, l, r, ..) => {
      let c = key.compare(k)
      if c == 0 {
        value
      } else if c < 0 {
        continue l
      } else {
        continue r
      }
    }
  }
}

///|
/// Iterate over the key-value pairs in the map.
pub fn[K, V] SortedMap::each(
  self : SortedMap[K, V],
  f : (K, V) -> Unit,
) -> Unit {
  match self {
    Empty => ()
    Tree(k, value~, l, r, ..) => {
      l.each(f)
      f(k, value)
      r.each(f)
    }
  }
}

///|
/// Iterate over the key-value pairs with index.
pub fn[K, V] SortedMap::eachi(
  self : SortedMap[K, V],
  f : (Int, K, V) -> Unit,
) -> Unit {
  fn do_eachi(m : SortedMap[K, V], f, i) {
    match m {
      Empty => ()
      Tree(k, value~, l, r, ..) => {
        do_eachi(l, f, i)
        f(l.length() + i, k, value)
        do_eachi(r, f, l.length() + i + 1)
      }
    }
  }

  do_eachi(self, f, 0)
}

///|
/// Maps over the key-value pairs in the map.
pub fn[K, X, Y] SortedMap::map_with_key(
  self : SortedMap[K, X],
  f : (K, X) -> Y,
) -> SortedMap[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, l, r, size~) =>
      Tree(k, value=f(k, value), size~, l.map_with_key(f), r.map_with_key(f))
  }
}

///|
/// Post-order fold.
/// O(n).
#alias(foldr_with_key)
pub fn[K, V, A] SortedMap::rev_fold(
  self : SortedMap[K, V],
  f : (A, K, V) -> A,
  init~ : A,
) -> A {
  fn go(m : SortedMap[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, value~, l, r, ..) => go(l, f(go(r, acc), k, value))
    }
  }

  go(self, init)
}

///|
/// Pre-order fold.
/// O(n).
pub fn[K, V, A] SortedMap::foldl_with_key(
  self : SortedMap[K, V],
  f : (A, K, V) -> A,
  init~ : A,
) -> A {
  fn go(m : SortedMap[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, value~, l, r, ..) => go(r, f(go(l, acc), k, value))
    }
  }

  go(self, init)
}

///|
fn[K : Show, V : Show] SortedMap::debug_tree(self : SortedMap[K, V]) -> String {
  match self {
    Empty => "_"
    Tree(k, value~, l, r, ..) => {
      let l = l.debug_tree()
      let r = r.debug_tree()
      "(\{k},\{value},\{l},\{r})"
    }
  }
}

///|
/// Build a map from an array of key-value pairs.
/// O(n*log n).
#as_free_fn
#alias(of, deprecated="Use from_array instead")
#as_free_fn(of, deprecated="Use from_array instead")
pub fn[K : Compare, V] SortedMap::from_array(
  array : ArrayView[(K, V)],
) -> SortedMap[K, V] {
  for i = 0, mp = Empty; i < array.length(); {
    let (k, v) = array[i]
    continue i + 1, mp.add(k, v)
  } else {
    mp
  }
}

///|
#alias(iterator, deprecated)
pub fn[K, V] SortedMap::iter(self : SortedMap[K, V]) -> Iter[(K, V)] {
  let mut curr_node = self
  let parents = []
  Iter::new(fn() {
    loop curr_node {
      Tree(k, value~, Empty, r, ..) => {
        curr_node = r
        Some((k, value))
      }
      Tree(k, value~, l, r, ..) => {
        parents.push((k, value, r))
        continue l
      }
      Empty if parents.pop() is Some((k, v, r)) => {
        curr_node = r
        Some((k, v))
      }
      Empty => None
    }
  })
}

///|
#alias(iterator2, deprecated)
pub fn[K, V] SortedMap::iter2(self : SortedMap[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Compare, V] SortedMap::from_iter(
  iter : Iter[(K, V)],
) -> SortedMap[K, V] {
  iter.fold(init=new(), (m, e) => m.add(e.0, e.1))
}

///|
/// Return all keys of the map in ascending order.
pub fn[K, V] SortedMap::keys_as_iter(self : SortedMap[K, V]) -> Iter[K] {
  self.iter().map(p => p.0)
}

///|
/// Return all elements of the map in the ascending order of their keys.
pub fn[K, V] SortedMap::values(self : SortedMap[K, V]) -> Iter[V] {
  self.iter().map(p => p.1)
}

///|
/// Return all keys of the map in descending order.
///
/// # Example
///
/// ```mbt check
/// test {
///   let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
///   let keys = map.rev_keys().collect()
///   assert_eq(keys, ["c", "b", "a"])
/// }
/// ```
pub fn[K, V] SortedMap::rev_keys(self : SortedMap[K, V]) -> Iter[K] {
  let mut curr_node = self
  let parents = []
  Iter::new(fn() {
    loop curr_node {
      Tree(k, l, Empty, ..) => {
        curr_node = l
        Some(k)
      }
      Tree(k, l, r, ..) => {
        parents.push((k, l))
        continue r
      }
      Empty if parents.pop() is Some((k, l)) => {
        curr_node = l
        Some(k)
      }
      Empty => None
    }
  })
}

///|
/// Return all values of the map in descending order of their keys.
///
/// # Example
///
/// ```mbt
///   let map = @sorted_map.from_array([("a", 1), ("b", 2), ("c", 3)])
///   let values = map.rev_values().collect()
///   assert_eq(values, [3, 2, 1])
/// ```
pub fn[K, V] SortedMap::rev_values(self : SortedMap[K, V]) -> Iter[V] {
  let mut curr_node = self
  let parents = []
  Iter::new(fn() {
    loop curr_node {
      Tree(_k, value~, l, Empty, ..) => {
        curr_node = l
        Some(value)
      }
      Tree(_k, value~, l, r, ..) => {
        parents.push((value, l))
        continue r
      }
      Empty if parents.pop() is Some((v, l)) => {
        curr_node = l
        Some(v)
      }
      Empty => None
    }
  })
}

///|
pub fn[K : Show, V : ToJson] SortedMap::to_json(self : SortedMap[K, V]) -> Json {
  ToJson::to_json(self)
}
