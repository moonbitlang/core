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
/// Create an empty map.
#deprecated("Use `new()` instead")
#coverage.skip
pub fn[K, V] T::empty() -> T[K, V] {
  Empty
}

///|
/// Create an empty map.
pub fn[K, V] new() -> T[K, V] {
  Empty
}

///|
/// Create a map with a single key-value pair.
pub fn[K, V] singleton(key : K, value : V) -> T[K, V] {
  Tree(key, value~, size=1, Empty, Empty)
}

///|
/// Check if the map contains a key.
/// O(log n).
pub fn[K : Compare, V] contains(self : T[K, V], key : K) -> Bool {
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
pub fn[K, V] size(self : T[K, V]) -> Int {
  match self {
    Empty => 0
    Tree(_) as t => t.size
  }
}

///|
pub fn[K, V] is_empty(self : T[K, V]) -> Bool {
  self.size() == 0
}

///|
fn[K, V] make_tree(key : K, value : V, l : T[K, V], r : T[K, V]) -> T[K, V] {
  let size = l.size() + r.size() + 1
  Tree(key, value~, size~, l, r)
}

///|
/// Get the value associated with a key.
/// O(log n).
#deprecated("Use `get` instead")
#coverage.skip
pub fn[K : Compare, V] lookup(self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
/// Get the value associated with a key.
/// O(log n).
pub fn[K : Compare, V] get(self : T[K, V], key : K) -> V? {
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
pub fn[K : Compare, V] op_get(self : T[K, V], key : K) -> V {
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
pub fn[K, V] each(self : T[K, V], f : (K, V) -> Unit) -> Unit {
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
pub fn[K, V] eachi(self : T[K, V], f : (Int, K, V) -> Unit) -> Unit {
  fn do_eachi(m : T[K, V], f, i) {
    match m {
      Empty => ()
      Tree(k, value~, l, r, ..) => {
        do_eachi(l, f, i)
        f(l.size() + i, k, value)
        do_eachi(r, f, l.size() + i + 1)
      }
    }
  }

  do_eachi(self, f, 0)
}

///|
/// Ts over the values in the map.
pub fn[K, X, Y] map(self : T[K, X], f : (X) -> Y) -> T[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, size~, l, r) =>
      Tree(k, value=f(value), size~, l.map(f), r.map(f))
  }
}

///|
/// Maps over the key-value pairs in the map.
pub fn[K, X, Y] map_with_key(self : T[K, X], f : (K, X) -> Y) -> T[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, l, r, size~) =>
      Tree(k, value=f(k, value), size~, l.map_with_key(f), r.map_with_key(f))
  }
}

///|
/// Fold the values in the map.
/// O(n).
pub fn[K, V, A] fold(self : T[K, V], init~ : A, f : (A, V) -> A) -> A {
  self.foldl_with_key((acc, _k, v) => f(acc, v), init~)
}

///|
/// Post-order fold.
/// O(n).
pub fn[K, V, A] foldr_with_key(
  self : T[K, V],
  f : (A, K, V) -> A,
  init~ : A,
) -> A {
  fn go(m : T[K, V], acc) {
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
pub fn[K, V, A] foldl_with_key(
  self : T[K, V],
  f : (A, K, V) -> A,
  init~ : A,
) -> A {
  fn go(m : T[K, V], acc) {
    match m {
      Empty => acc
      Tree(k, value~, l, r, ..) => go(r, f(go(l, acc), k, value))
    }
  }

  go(self, init)
}

///|
fn[K : Show, V : Show] debug_tree(self : T[K, V]) -> String {
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
pub fn[K : Compare, V] from_array(array : Array[(K, V)]) -> T[K, V] {
  for i = 0, mp = Empty; i < array.length(); {
    let (k, v) = array[i]
    continue i + 1, mp.add(k, v)
  } else {
    mp
  }
}

///|
pub fn[K, V] iter(self : T[K, V]) -> Iter[(K, V)] {
  Iter::new(yield_ => {
    fn go(t) {
      match t {
        Empty => IterContinue
        Tree(k, value~, l, r, ..) =>
          if go(l) is IterEnd {
            IterEnd
          } else if yield_((k, value)) is IterEnd {
            IterEnd
          } else {
            go(r)
          }
      }
    }

    go(self)
  })
}

///|
pub fn[K, V] iter2(self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(yield_ => {
    fn go(t) {
      match t {
        Empty => IterContinue
        Tree(k, value~, l, r, ..) =>
          if go(l) is IterEnd {
            IterEnd
          } else if yield_(k, value) is IterEnd {
            IterEnd
          } else {
            go(r)
          }
      }
    }

    go(self)
  })
}

///|
pub fn[K : Compare, V] from_iter(iter : Iter[(K, V)]) -> T[K, V] {
  iter.fold(init=new(), (m, e) => m.add(e.0, e.1))
}

///|
/// Return all keys of the map in ascending order.
#deprecated("Use `keys_as_iter` instead. `keys` will return `Iter[K]` instead of `Array[K]` in the future.")
#coverage.skip
pub fn[K, V] keys(self : T[K, V]) -> Array[K] {
  self.iter().map(p => p.0).collect()
}

///|
/// Return all keys of the map in ascending order.
pub fn[K, V] keys_as_iter(self : T[K, V]) -> Iter[K] {
  self.iter().map(p => p.0)
}

///|
/// Return all elements of the map in the ascending order of their keys.
pub fn[K, V] values(self : T[K, V]) -> Iter[V] {
  self.iter().map(p => p.1)
}

///|
#deprecated("Use `values` instead")
#coverage.skip
pub fn[K, V] elems(self : T[K, V]) -> Array[V] {
  self.values().collect()
}

///|
pub fn[K : Compare, V] of(array : FixedArray[(K, V)]) -> T[K, V] {
  for i = 0, mp = Empty; i < array.length(); {
    let (k, v) = array[i]
    continue i + 1, mp.add(k, v)
  } else {
    mp
  }
}

///|
pub fn[K : Show, V : ToJson] to_json(self : T[K, V]) -> Json {
  ToJson::to_json(self)
}

///|
pub fn[V : @json.FromJson] from_json(
  json : Json,
) -> T[String, V] raise @json.JsonDecodeError {
  @json.from_json(json)
}
