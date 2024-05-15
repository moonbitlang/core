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

/// Create an empty map.
pub fn empty[K, V]() -> Map[K, V] {
  Empty
}

/// Create a map with a single key-value pair.
pub fn singleton[K, V](key : K, value : V) -> Map[K, V] {
  Tree(key, ~value, size=1, Empty, Empty)
}

/// Check if the map contains a key.
/// O(log n).
pub fn member[K : Compare, V](self : Map[K, V], key : K) -> Bool {
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

/// Get the number of key-value pairs in the map.
pub fn size[K, V](self : Map[K, V]) -> Int {
  match self {
    Empty => 0
    Tree(_) as t => t.size
  }
}

pub fn is_empty[K, V](self : Map[K, V]) -> Bool {
  self.size() == 0
}

fn new[K, V](key : K, value : V, l : Map[K, V], r : Map[K, V]) -> Map[K, V] {
  let size = size(l) + size(r) + 1
  Tree(key, ~value, ~size, l, r)
}

/// Get the value associated with a key.
/// O(log n).
pub fn lookup[K : Compare, V](self : Map[K, V], key : K) -> Option[V] {
  loop self {
    Empty => None
    Tree(k, ~value, l, r, ..) => {
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

/// Iterate over the key-value pairs in the map.
pub fn iter[K, V](self : Map[K, V], f : (K, V) -> Unit) -> Unit {
  match self {
    Empty => ()
    Tree(k, ~value, l, r, ..) => {
      iter(l, f)
      f(k, value)
      iter(r, f)
    }
  }
}

/// Iterate over the key-value pairs with index.
pub fn iteri[K, V](self : Map[K, V], f : (Int, K, V) -> Unit) -> Unit {
  fn do_iteri(m : Map[K, V], f, i) {
    match m {
      Empty => ()
      Tree(k, ~value, l, r, ..) => {
        do_iteri(l, f, i)
        f(size(l) + i, k, value)
        do_iteri(r, f, size(l) + i + 1)
      }
    }
  }

  do_iteri(self, f, 0)
}

/// Maps over the values in the map.
pub fn map[K, X, Y](self : Map[K, X], f : (X) -> Y) -> Map[K, Y] {
  match self {
    Empty => Empty
    Tree(k, ~value, ~size, l, r) =>
      Tree(k, value=f(value), ~size, map(l, f), map(r, f))
  }
}

/// Maps over the key-value pairs in the map.
pub fn map_with_key[K, X, Y](self : Map[K, X], f : (K, X) -> Y) -> Map[K, Y] {
  match self {
    Empty => Empty
    Tree(k, ~value, l, r, ~size) =>
      Tree(k, value=f(k, value), ~size, map_with_key(l, f), map_with_key(r, f))
  }
}

/// Fold the values in the map.
/// O(n).
pub fn fold[K, V, T](self : Map[K, V], f : (T, V) -> T, ~init : T) -> T {
  foldl_with_key(self, fn(acc, _k, v) { f(acc, v) }, ~init)
}

/// Post-order fold.
/// O(n).
pub fn foldr_with_key[K, V, T](
  self : Map[K, V],
  f : (T, K, V) -> T,
  ~init : T
) -> T {
  fn go(m : Map[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, ~value, l, r, ..) => go(l, f(go(r, acc), k, value))
    }
  }

  go(self, init)
}

/// Pre-order fold.
/// O(n).
pub fn foldl_with_key[K, V, T](
  self : Map[K, V],
  f : (T, K, V) -> T,
  ~init : T
) -> T {
  fn go(m : Map[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, ~value, l, r, ..) => go(r, f(go(l, acc), k, value))
    }
  }

  go(self, init)
}

pub fn debug_write[K : Debug, V : Debug](
  self : Map[K, V],
  buffer : Buffer
) -> Unit {
  buffer.write_string("Map::[")
  let mut first = true
  self.iter(
    fn(k, v) {
      if not(first) {
        buffer.write_string(", ")
      }
      first = false
      buffer.write_string("(")
      k.debug_write(buffer)
      buffer.write_string(", ")
      v.debug_write(buffer)
      buffer.write_string(")")
    },
  )
  buffer.write_string("]")
}

fn debug_tree[K : Show, V : Show](self : Map[K, V]) -> String {
  match self {
    Empty => "_"
    Tree(k, ~value, l, r, ..) => {
      let l = debug_tree(l)
      let r = debug_tree(r)
      "(\(k),\(value),\(l),\(r))"
    }
  }
}

/// Build a map from an array of key-value pairs.
/// O(n*log n).
pub fn Map::from_array[K : Compare, V](array : Array[(K, V)]) -> Map[K, V] {
  for i = 0, mp = Map::Empty; i < array.length(); {
    let (k, v) = array[i]
    continue i + 1, mp.insert(k, v)
  } else {
    mp
  }
}
