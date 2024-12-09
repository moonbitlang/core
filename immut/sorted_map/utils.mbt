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

///| Create an empty map.
/// @alert deprecated "Use `new()` instead"
pub fn T::empty[K, V]() -> T[K, V] {
  Empty
}

///| Create an empty map.
pub fn T::new[K, V]() -> T[K, V] {
  Empty
}

///|
/// Create a map with a single key-value pair.
pub fn T::singleton[K, V](key : K, value : V) -> T[K, V] {
  Tree(key, value~, size=1, Empty, Empty)
}

///|
/// Check if the map contains a key.
/// O(log n).
pub fn contains[K : Compare, V](self : T[K, V], key : K) -> Bool {
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
pub fn size[K, V](self : T[K, V]) -> Int {
  match self {
    Empty => 0
    Tree(_) as t => t.size
  }
}

///|
pub fn is_empty[K, V](self : T[K, V]) -> Bool {
  self.size() == 0
}

///|
fn make_tree[K, V](key : K, value : V, l : T[K, V], r : T[K, V]) -> T[K, V] {
  let size = size(l) + size(r) + 1
  Tree(key, value~, size~, l, r)
}

///|
/// Get the value associated with a key.
/// O(log n).
pub fn lookup[K : Compare, V](self : T[K, V], key : K) -> V? {
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
pub fn op_get[K : Compare, V](self : T[K, V], key : K) -> V? {
  self.lookup(key)
}

///|
/// Iterate over the key-value pairs in the map.
pub fn each[K, V](self : T[K, V], f : (K, V) -> Unit) -> Unit {
  match self {
    Empty => ()
    Tree(k, value~, l, r, ..) => {
      each(l, f)
      f(k, value)
      each(r, f)
    }
  }
}

///|
/// Iterate over the key-value pairs with index.
pub fn eachi[K, V](self : T[K, V], f : (Int, K, V) -> Unit) -> Unit {
  fn do_eachi(m : T[K, V], f, i) {
    match m {
      Empty => ()
      Tree(k, value~, l, r, ..) => {
        do_eachi(l, f, i)
        f(size(l) + i, k, value)
        do_eachi(r, f, size(l) + i + 1)
      }
    }
  }

  do_eachi(self, f, 0)
}

///|
/// Ts over the values in the map.
pub fn map[K, X, Y](self : T[K, X], f : (X) -> Y) -> T[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, size~, l, r) =>
      Tree(k, value=f(value), size~, map(l, f), map(r, f))
  }
}

///|
/// Maps over the key-value pairs in the map.
pub fn map_with_key[K, X, Y](self : T[K, X], f : (K, X) -> Y) -> T[K, Y] {
  match self {
    Empty => Empty
    Tree(k, value~, l, r, size~) =>
      Tree(k, value=f(k, value), size~, map_with_key(l, f), map_with_key(r, f))
  }
}

///|
/// Fold the values in the map.
/// O(n).
pub fn fold[K, V, A](self : T[K, V], init~ : A, f : (A, V) -> A) -> A {
  foldl_with_key(self, fn(acc, _k, v) { f(acc, v) }, init~)
}

///|
/// Post-order fold.
/// O(n).
pub fn foldr_with_key[K, V, A](
  self : T[K, V],
  f : (A, K, V) -> A,
  init~ : A
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
pub fn foldl_with_key[K, V, A](
  self : T[K, V],
  f : (A, K, V) -> A,
  init~ : A
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
fn debug_tree[K : Show, V : Show](self : T[K, V]) -> String {
  match self {
    Empty => "_"
    Tree(k, value~, l, r, ..) => {
      let l = debug_tree(l)
      let r = debug_tree(r)
      "(\{k},\{value},\{l},\{r})"
    }
  }
}

///|
/// Build a map from an array of key-value pairs.
/// O(n*log n).
pub fn T::from_array[K : Compare, V](array : Array[(K, V)]) -> T[K, V] {
  for i = 0, mp = Empty; i < array.length(); {
    let (k, v) = array[i]
    continue i + 1, mp.add(k, v)
  } else {
    mp
  }
}

///|
pub fn iter[K, V](self : T[K, V]) -> Iter[(K, V)] {
  Iter::new(
    fn(yield_) {
      match self {
        Empty => IterContinue
        Tree(k, value~, l, r, ..) =>
          if l.iter().run(yield_) == IterEnd {
            IterEnd
          } else if yield_((k, value)) == IterEnd {
            IterEnd
          } else if r.iter().run(yield_) == IterEnd {
            IterEnd
          } else {
            IterContinue
          }
      }
    },
  )
}

///|
pub fn iter2[K, V](self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(
    fn(yield_) {
      match self {
        Empty => IterContinue
        Tree(k, value~, l, r, ..) =>
          if l.iter2().run(yield_) == IterEnd {
            IterEnd
          } else if yield_(k, value) == IterEnd {
            IterEnd
          } else if r.iter2().run(yield_) == IterEnd {
            IterEnd
          } else {
            IterContinue
          }
      }
    },
  )
}

///|
pub fn T::from_iter[K : Compare, V](iter : Iter[(K, V)]) -> T[K, V] {
  iter.fold(init=T::new(), fn(m, e) { m.add(e.0, e.1) })
}

///|
/// Return all keys of the map in ascending order.
pub fn keys[K, V](self : T[K, V]) -> Array[K] {
  self.iter().map(fn { (k, _) => k }).collect()
}

///|
/// Return all elements of the map in the ascending order of their keys.
pub fn elems[K, V](self : T[K, V]) -> Array[V] {
  self.iter().map(fn { (_, v) => v }).collect()
}

///|
pub fn T::of[K : Compare, V](array : FixedArray[(K, V)]) -> T[K, V] {
  for i = 0, mp = Empty; i < array.length(); {
    let (k, v) = array[i]
    continue i + 1, mp.add(k, v)
  } else {
    mp
  }
}

///|
pub fn to_json[K : Show, V : ToJson](self : T[K, V]) -> Json {
  ToJson::to_json(self)
}

///|
pub fn T::from_json[V : @json.FromJson](
  json : Json
) -> T[String, V]!@json.JsonDecodeError {
  @json.from_json!(json)
}
