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

//
// An efficient implementation of Map. 
// Based on size balanced binary trees, described by:
// Stephen Adams, "Efficient sets: a balancing act" Journal of Functional Programming 3(4):553-562, October 1993
//

/// Immuatable map, consists of key-value pairs.
/// 
/// # Example
/// 
/// ```
/// let map1 = Map::[(3, "three"), (8, "eight"), (1, "one")]
/// let map2 = map1.insert(2, "two").remove(3)
/// println(map3.lookup(3)) // output: None
/// println(map3.lookup(2)) // output: Some("two")
/// let map3 = map2.insert(2, "updated")
/// println(map3.lookup(2)) // output: Some("updated")
/// ```
enum Map[K, V] {
  Empty
  Tree(K, V, Int, Map[K, V], Map[K, V])
}

/// Create an empty map.
pub fn empty[K, V]() -> Map[K, V] {
  Empty
}

/// Create a map with a single key-value pair. 
pub fn singleton[K, V](key : K, value : V) -> Map[K, V] {
  Tree(key, value, 1, Empty, Empty)
}

/// Check if the map contains a key.
/// O(log n).
pub fn member[K : Compare, V : Show](self : Map[K, V], key : K) -> Bool {
  loop self {
    Empty => false
    Tree(k, _, _, l, r) => {
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
    Tree(_, _, n, _, _) => n
  }
}

fn new[K, V](key : K, value : V, l : Map[K, V], r : Map[K, V]) -> Map[K, V] {
  let size = size(l) + size(r) + 1
  Tree(key, value, size, l, r)
}

/// Create a new map with a key-value pair inserted. 
/// O(log n).
pub fn insert[K : Compare, V](
  self : Map[K, V],
  key : K,
  value : V
) -> Map[K, V] {
  match self {
    Empty => singleton(key, value)
    Tree(k, v, _, l, r) =>
      match key.compare(k) {
        -1 => balance(k, v, insert(l, key, value), r)
        1 => balance(k, v, l, insert(r, key, value))
        _ => new(k, value, l, r)
      }
  }
}

fn split_max[K : Compare, V](self : Map[K, V]) -> (K, V, Map[K, V]) {
  match self {
    Tree(k, v, _, l, Empty) => (k, v, l)
    Tree(k, v, _, l, r) => {
      let (k1, v1, r) = split_max(r)
      (k1, v1, balance(k, v, l, r))
    }
    Empty => abort("Map::split_max error")
  }
}

fn split_min[K : Compare, V](self : Map[K, V]) -> (K, V, Map[K, V]) {
  match self {
    Tree(k, v, _, Empty, r) => (k, v, r)
    Tree(k, v, _, l, r) => {
      let (k1, v1, l) = split_min(l)
      (k1, v1, balance(k, v, l, r))
    }
    Empty => abort("Map::split_min error")
  }
}

fn glue[K : Compare, V](self : Map[K, V], other : Map[K, V]) -> Map[K, V] {
  match (self, other) {
    (Empty, r) => r
    (l, Empty) => l
    (l, r) =>
      if l.size() > r.size() {
        let (k, v, l) = split_max(l)
        balance(k, v, l, r)
      } else {
        let (k, v, r) = split_min(r)
        balance(k, v, l, r)
      }
  }
}

/// Create a new map with a key-value pair removed. O(log n). 
/// If the key is not a member or map, the original map is returned.
pub fn remove[K : Compare, V](self : Map[K, V], key : K) -> Map[K, V] {
  match self {
    Empty => Empty
    Tree(k, v, _, l, r) => {
      let c = key.compare(k)
      if c == 0 {
        glue(l, r)
      } else if c < 0 {
        balance(k, v, remove(l, key), r)
      } else {
        balance(k, v, l, remove(r, key))
      }
    }
  }
}

/// Get the value associated with a key. 
/// O(log n). 
pub fn lookup[K : Compare, V](self : Map[K, V], key : K) -> Option[V] {
  loop self {
    Empty => None
    Tree(k, v, _, l, r) => {
      let c = key.compare(k)
      if c == 0 {
        Some(v)
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
    Tree(k, v, _, l, r) => {
      iter(l, f)
      f(k, v)
      iter(r, f)
    }
  }
}

/// Iterate over the key-value pairs with index.
pub fn iteri[K, V](self : Map[K, V], f : (Int, K, V) -> Unit) -> Unit {
  fn do_iteri(m : Map[K, V], f, i) {
    match m {
      Empty => ()
      Tree(k, v, _, l, r) => {
        do_iteri(l, f, i)
        f(size(l) + i, k, v)
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
    Tree(k, v, s, l, r) => Tree(k, f(v), s, map(l, f), map(r, f))
  }
}

/// Maps over the key-value pairs in the map.
pub fn map_with_key[K, X, Y](self : Map[K, X], f : (K, X) -> Y) -> Map[K, Y] {
  match self {
    Empty => Empty
    Tree(k, v, s, l, r) =>
      Tree(k, f(k, v), s, map_with_key(l, f), map_with_key(r, f))
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
      Tree(k, v, _, l, r) => go(l, f(go(r, acc), k, v))
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
      Tree(k, v, _, l, r) => go(r, f(go(l, acc), k, v))
    }
  }

  go(self, init)
}

/// The ratio between the sizes of the left and right subtrees.
let ratio = 5

fn balance[K : Compare, V](
  key : K,
  value : V,
  l : Map[K, V],
  r : Map[K, V]
) -> Map[K, V] {
  //       1                   2
  //      / \                 / \
  //     x   2       --->    1   z
  //        / \             / \
  //       y   z           x   y
  fn single_l {
    k1, v1, x, Map::Tree(k2, v2, _, y, z) => new(k2, v2, new(k1, v1, x, y), z)
    _, _, _, _ => abort("single_l error")
  }

  fn single_r {
    k2, v2, Map::Tree(k1, v1, _, x, y), z => new(k1, v1, x, new(k2, v2, y, z))
    _, _, _, _ => abort("single_r error")
  }

  //      1                 2
  //     / \              /   \
  //    x   3            1     3
  //       / \    -->   / \   / \
  //      2   z        x  y1 y2  z
  //     / \
  //    y1 y2
  fn double_l {
    k1, v1, x, Map::Tree(k3, v3, _, Tree(k2, v2, _, y1, y2), z) =>
      new(k2, v2, new(k1, v1, x, y1), new(k3, v3, y2, z))
    _, _, _, _ => abort("double_l error")
  }

  //      3                 2
  //     / \              /   \
  //    1   z            1     3
  //   / \        -->   / \   / \
  //  x  2             x  y1 y2  z
  //    / \
  //   y1 y2
  fn double_r {
    k3, v3, Map::Tree(k1, v1, _, x, Tree(k2, v2, _, y1, y2)), z =>
      new(k2, v2, new(k1, v1, x, y1), new(k3, v3, y2, z))
    _, _, _, _ => abort("double_r error")
  }

  let ln = size(l)
  let rn = size(r)
  if ln + rn < 2 {
    new(key, value, l, r)
  } else if rn > ratio * ln {
    // right is too big
    let (rl, rr) = match r {
      Tree(_, _, _, rl, rr) => (rl, rr)
      Empty => abort("unreachable")
    }
    let rln = size(rl)
    let rrn = size(rr)
    if rln < rrn {
      single_l(key, value, l, r)
    } else {
      double_l(key, value, l, r)
    }
  } else if ln > ratio * rn {
    // left is too big
    let (ll, lr) = match l {
      Tree(_, _, _, ll, lr) => (ll, lr)
      Empty => abort("unreachable")
    }
    let lln = size(ll)
    let lrn = size(lr)
    if lrn < lln {
      single_r(key, value, l, r)
    } else {
      double_r(key, value, l, r)
    }
  } else {
    new(key, value, l, r)
  }
}

fn debug_tree[K : Show, V : Show](self : Map[K, V]) -> String {
  match self {
    Empty => "_"
    Tree(k, v, _, l, r) => {
      let l = debug_tree(l)
      let r = debug_tree(r)
      "(\(k),\(v),\(l),\(r))"
    }
  }
}

/// Build a map from an array of key-value pairs.
/// O(n*log n).
pub fn Map::from_array[K : Compare, V](array : Array[(K, V)]) -> Map[K, V] {
  loop 0, Map::Empty {
    i, mp =>
      if i < array.length() {
        let (k, v) = array[i]
        continue i + 1, mp.insert(k, v)
      } else {
        mp
      }
  }
}

test "from_array" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )?
}

test "insert" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one")]
  @assertion.assert_eq(m.debug_tree(), "(3,three,(1,one,_,_),(8,eight,_,_))")?
  let m = m.insert(5, "five").insert(2, "two").insert(0, "zero").insert(
    1, "one_updated",
  )
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one_updated,(0,zero,_,_),(2,two,_,_)),(8,eight,(5,five,_,_),_))",
  )?
}

test "remove" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )?
  let m = m.remove(1).remove(3)
  @assertion.assert_eq(m.debug_tree(), "(2,two,(0,zero,_,_),(8,eight,_,_))")?
}

test "lookup" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(m.lookup(8), Some("eight"))?
  @assertion.assert_eq(m.lookup(2), Some("two"))?
  @assertion.assert_eq(m.lookup(4), None)?
}

test "member" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )?
  @assertion.assert_eq(m.member(8), true)?
  @assertion.assert_eq(m.member(2), true)?
  @assertion.assert_eq(m.member(4), false)?
}

test "size" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(m.size(), 5)?
  let m = m.remove(1).remove(3)
  @assertion.assert_eq(m.size(), 3)?
}

test "iter" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  let mut s = ""
  m.iter(fn(k, v) { s = s + "(\(k),\(v))" })
  @assertion.assert_eq(s, "(0,zero)(1,one)(2,two)(3,three)(8,eight)")?
}

test "iteri" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  let mut s = ""
  m.iteri(fn(i, k, v) { s = s + "(\(i),\(k),\(v))" })
  @assertion.assert_eq(s, "(0,0,zero)(1,1,one)(2,2,two)(3,3,three)(4,8,eight)")?
}

test "map" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  let n = m.map(fn(v) { v + "X" })
  @assertion.assert_eq(
    n.debug_tree(),
    "(3,threeX,(1,oneX,(0,zeroX,_,_),(2,twoX,_,_)),(8,eightX,_,_))",
  )?
}

test "map_with_key" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  let n = m.map_with_key(fn(k, v) { "\(k)-\(v)" })
  @assertion.assert_eq(
    n.debug_tree(),
    "(3,3-three,(1,1-one,(0,0-zero,_,_),(2,2-two,_,_)),(8,8-eight,_,_))",
  )?
}

test "fold" {
  let m = Map::[("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)]
  @assertion.assert_eq(m.fold(fn(acc, v) { acc + v }, ~init=0), 15)?
}

test "foldl_with_key" {
  let m = Map::[("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)]
  @assertion.assert_eq(
    m.foldl_with_key(fn(acc, k, v) { acc + k + v.to_string() }, ~init=""),
    "a1b2c3d4e5",
  )?
}

test "foldr_with_key" {
  let m = Map::[("a", 1), ("b", 2), ("c", 3), ("d", 4), ("e", 5)]
  @assertion.assert_eq(
    m.foldr_with_key(fn(acc, k, v) { acc + k + v.to_string() }, ~init=""),
    "e5d4c3b2a1",
  )?
}

test "singleton" {
  let m = singleton(3, "three")
  @assertion.assert_eq(m.debug_tree(), "(3,three,_,_)")?
}

test "empty" {
  let m : Map[Int, Int] = empty()
  @assertion.assert_eq(m.debug_tree(), "_")?
}

test "split_max" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )?
  let (k, v, r) = m.split_max()
  @assertion.assert_eq(k, 8)?
  @assertion.assert_eq(v, "eight")?
  @assertion.assert_eq(
    r.debug_tree(),
    "(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )?
}

test "split_min" {
  let m = Map::[(3, "three"), (8, "eight"), (2, "two"), (1, "one"), (0, "zero")]
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )?
  let (k, v, r) = m.split_min()
  @assertion.assert_eq(k, 0)?
  @assertion.assert_eq(v, "zero")?
  @assertion.assert_eq(
    r.debug_tree(),
    "(3,three,(1,one,_,(2,two,_,_)),(8,eight,_,_))",
  )?
}

test "glue" {
  let m = Map::[(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")]
  @assertion.assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )?
  let (l, r) = match m {
    Tree(_, _, _, l, r) => (l, r)
    _ => abort("unreachable")
  }
  let m = l.glue(r)
  @assertion.assert_eq(
    m.debug_tree(),
    "(2,two,(1,one,(0,zero,_,_),_),(8,eight,_,_))",
  )?
}
