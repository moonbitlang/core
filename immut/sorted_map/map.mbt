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
/// Create a new map with a key-value pair inserted.
/// O(log n).
///
#alias(insert, deprecated)
pub fn[K : Compare, V] SortedMap::add(
  self : SortedMap[K, V],
  key : K,
  value : V,
) -> SortedMap[K, V] {
  match self {
    Empty => singleton(key, value)
    Tree(k, value=v, l, r, ..) => {
      let c = key.compare(k)
      if c == 0 {
        make_tree(k, value, l, r)
      } else if c < 0 {
        balance(k, v, l.add(key, value), r)
      } else {
        balance(k, v, l, r.add(key, value))
      }
    }
  }
}

///|
fn[K, V] SortedMap::split_max(
  self : SortedMap[K, V],
) -> (K, V, SortedMap[K, V]) {
  match self {
    Tree(k, value=v, l, Empty, ..) => (k, v, l)
    Tree(k, value=v, l, r, ..) => {
      let (k1, v1, r) = r.split_max()
      (k1, v1, balance(k, v, l, r))
    }
    Empty => abort("Map::split_max error")
  }
}

///|
fn[K, V] SortedMap::split_min(
  self : SortedMap[K, V],
) -> (K, V, SortedMap[K, V]) {
  match self {
    Tree(k, value=v, Empty, r, ..) => (k, v, r)
    Tree(k, value=v, l, r, ..) => {
      let (k1, v1, l) = l.split_min()
      (k1, v1, balance(k, v, l, r))
    }
    Empty => abort("Map::split_min error")
  }
}

///|
fn[K, V] glue(l : SortedMap[K, V], r : SortedMap[K, V]) -> SortedMap[K, V] {
  match (l, r) {
    (Empty, r) => r
    (l, Empty) => l
    (l, r) =>
      if l.length() > r.length() {
        let (k, v, l) = l.split_max()
        balance(k, v, l, r)
      } else {
        let (k, v, r) = r.split_min()
        balance(k, v, l, r)
      }
  }
}

///|
/// Create a new map with a key-value pair removed. O(log n).
/// If the key is not a member or map, the original map is returned.
pub fn[K : Compare, V] SortedMap::remove(
  self : SortedMap[K, V],
  key : K,
) -> SortedMap[K, V] {
  match self {
    Empty => Empty
    Tree(k, value=v, l, r, ..) => {
      let c = key.compare(k)
      if c == 0 {
        glue(l, r)
      } else if c < 0 {
        balance(k, v, l.remove(key), r)
      } else {
        balance(k, v, l, r.remove(key))
      }
    }
  }
}

///|
/// Filter key-value pairs that satisfy the predicate
pub fn[K, V] SortedMap::filter_with_key(
  self : SortedMap[K, V],
  pred : (K, V) -> Bool raise?,
) -> SortedMap[K, V] raise? {
  match self {
    Empty => Empty
    Tree(k, value=v, l, r, ..) =>
      if pred(k, v) {
        balance(k, v, l.filter_with_key(pred), r.filter_with_key(pred))
      } else {
        glue(l.filter_with_key(pred), r.filter_with_key(pred))
      }
  }
}

///|
/// Convert to an array of key-value pairs.
pub fn[K, V] SortedMap::to_array(self : SortedMap[K, V]) -> Array[(K, V)] {
  let arr = []
  self.each((k, v) => arr.push((k, v)))
  arr
}

///|
/// Merges two immutable sorted maps into a new map. Returns a new map containing
/// all key-value pairs from both maps. When both maps contain the same key, the
/// value from `other` takes precedence.
///
/// This is a pure operation - it returns a new sorted map without modifying
/// either input.
///
/// Parameters:
///
/// * `self` : The first sorted map.
/// * `other` : The second sorted map whose values take precedence in case of key
/// conflicts.
///
/// Returns a new immutable sorted map containing all entries from both maps.
///
/// Example:
///
/// ```mbt check
/// test {
///   let map1 = @sorted_map.from_array([(1, "a"), (2, "b")])
///   let map2 = @sorted_map.from_array([(2, "c"), (3, "d")])
///   let merged = map1.merge(map2)
///   inspect(merged.get(1), content="Some(\"a\")")
///   inspect(merged.get(2), content="Some(\"c\")")
///   inspect(merged.get(3), content="Some(\"d\")")
/// }
/// ```
pub fn[K : Compare, V] SortedMap::merge(
  self : SortedMap[K, V],
  other : SortedMap[K, V],
) -> SortedMap[K, V] {
  let mut result = self
  other.each((k, v) => result = result.add(k, v))
  result
}

///|
/// The ratio between the sizes of the left and right subtrees.
let ratio = 5

///|
fn[K, V] balance(
  key : K,
  value : V,
  l : SortedMap[K, V],
  r : SortedMap[K, V],
) -> SortedMap[K, V] {
  //       1                   2
  //      / \                 / \
  //     x   2       --->    1   z
  //        / \             / \
  //       y   z           x   y
  fn single_l(k1, v1, x, r) {
    guard r is Tree(k2, value=v2, y, z, ..)
    make_tree(k2, v2, make_tree(k1, v1, x, y), z)
  }

  fn single_r(k2, v2, l, z) {
    guard l is Tree(k1, value=v1, x, y, ..)
    make_tree(k1, v1, x, make_tree(k2, v2, y, z))
  }

  //      1                 2
  //     / \              /   \
  //    x   3            1     3
  //       / \    -->   / \   / \
  //      2   z        x  y1 y2  z
  //     / \
  //    y1 y2
  fn double_l(k1, v1, x, r) {
    guard r is Tree(k3, value=v3, Tree(k2, value=v2, y1, y2, ..), z, ..)
    make_tree(k2, v2, make_tree(k1, v1, x, y1), make_tree(k3, v3, y2, z))
  }

  //      3                 2
  //     / \              /   \
  //    1   z            1     3
  //   / \        -->   / \   / \
  //  x  2             x  y1 y2  z
  //    / \
  //   y1 y2
  fn double_r(k3, v3, l, z) {
    guard l is Tree(k1, value=v1, x, Tree(k2, value=v2, y1, y2, ..), ..)
    make_tree(k2, v2, make_tree(k1, v1, x, y1), make_tree(k3, v3, y2, z))
  }

  let ln = l.length()
  let rn = r.length()
  if ln + rn < 2 {
    make_tree(key, value, l, r)
  } else if rn > ratio * ln {
    // right is too big
    guard r is Tree(_, rl, rr, ..)
    let rln = rl.length()
    let rrn = rr.length()
    if rln < rrn {
      single_l(key, value, l, r)
    } else {
      double_l(key, value, l, r)
    }
  } else if ln > ratio * rn {
    // left is too big
    guard l is Tree(_, ll, lr, ..)
    let lln = ll.length()
    let lrn = lr.length()
    if lrn < lln {
      single_r(key, value, l, r)
    } else {
      double_r(key, value, l, r)
    }
  } else {
    make_tree(key, value, l, r)
  }
}

///|
test "from_array" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )
}

///|
test "insert" {
  let m = from_array([(3, "three"), (8, "eight"), (1, "one")])
  inspect(m.debug_tree(), content="(3,three,(1,one,_,_),(8,eight,_,_))")
  let m = m.add(5, "five").add(2, "two").add(0, "zero").add(1, "one_updated")
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one_updated,(0,zero,_,_),(2,two,_,_)),(8,eight,(5,five,_,_),_))",
  )
}

///|
test "remove" {
  let m1 = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  inspect(
    m1.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )
  let m2 = m1.remove(1).remove(3)
  inspect(m2.debug_tree(), content="(2,two,(0,zero,_,_),(8,eight,_,_))")
  let m3 = m1.remove(8)
  inspect(
    m3.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )
  let e : SortedMap[Int, Int] = Empty
  inspect(e.remove(1).debug_tree(), content="_")
}

///|
test "contains" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )
  inspect(m.contains(8), content="true")
  inspect(m.contains(2), content="true")
  inspect(m.contains(4), content="false")
}

///|
test "map" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let n = m.map_with_key((_, v) => v + "X")
  assert_eq(
    n.debug_tree(),
    "(3,threeX,(1,oneX,(0,zeroX,_,_),(2,twoX,_,_)),(8,eightX,_,_))",
  )
}

///|
test "map_with_key" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let n = m.map_with_key((k, v) => "\{k}-\{v}")
  assert_eq(
    n.debug_tree(),
    "(3,3-three,(1,1-one,(0,0-zero,_,_),(2,2-two,_,_)),(8,8-eight,_,_))",
  )
}

///|
test "filter" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let fm = m.filter_with_key((_, v) => v.length() > 3)
  inspect(fm.debug_tree(), content="(3,three,(0,zero,_,_),(8,eight,_,_))")
}

///|
test "filter_with_key" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let fm = m.filter_with_key((k, v) => k > 3 && v.length() > 3)
  inspect(fm.debug_tree(), content="(8,eight,_,_)")
}

///|
test "singleton" {
  let m = singleton(3, "three")
  inspect(m.debug_tree(), content="(3,three,_,_)")
}

///|
test "empty" {
  let m : SortedMap[Int, Int] = new()
  inspect(m.debug_tree(), content="_")
}

///|
test "split_max" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )
  let (k, v, r) = m.split_max()
  inspect(k, content="8")
  inspect(v, content="eight")
  inspect(
    r.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )
}

///|
test "split_min" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (2, "two"),
    (1, "one"),
    (0, "zero"),
  ])
  assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )
  let (k, v, r) = m.split_min()
  inspect(k, content="0")
  inspect(v, content="zero")
  inspect(
    r.debug_tree(),
    content="(3,three,(1,one,_,(2,two,_,_)),(8,eight,_,_))",
  )
}

///|
test "glue" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  assert_eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )
  let (l, r) = match m {
    Tree(_, l, r, ..) => (l, r)
    _ => abort("unreachable")
  }
  let m = glue(l, r)
  inspect(
    m.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(8,eight,_,_))",
  )
}

///|
test "split_max with non-empty tree" {
  let m = from_array([
    (3, "three"),
    (8, "eight"),
    (1, "one"),
    (2, "two"),
    (0, "zero"),
  ])
  let (k, v, r) = m.split_max()
  inspect(k, content="8")
  inspect(v, content="eight")
  inspect(
    r.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )
}
