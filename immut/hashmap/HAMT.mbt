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

// An implementation of HAMT (Hash Array Mapped Trie) in MoonBit.
//
// Hash-Array-Mapped-Trie (HAMT) is a persistent hash-table data structure.
// It is a trie over the hash of keys (i.e. strings of binary digits)
//
// Every level in a HAMT can have up to 32 branches (5 digits),
// so HAMT has a tree height of at most 7,
// and is more efficient compared to most other tree data structures.
//
// HAMT uses bitmap-based sparse array to avoid space waste
//
// Some references:
// - <https://handwiki.org/wiki/Hash%20array%20mapped%20trie>
// - <https://lampwww.epfl.ch/papers/idealhashtrees.pdf>

///|
pub fn[K, V] new() -> T[K, V] {
  None
}

///|
/// Create a map with a single key-value pair.
pub fn[K : Hash, V] singleton(key : K, value : V) -> T[K, V] {
  Some(Flat(key, value, @path.of(key)))
}

///|
/// Check if the map contains a key.
pub fn[K : Eq + Hash, V] contains(self : T[K, V], key : K) -> Bool {
  self.get(key) is Some(_)
}

///|
/// Lookup a key from a hash map
#deprecated("Use `get()` instead")
#coverage.skip
pub fn[K : Eq + Hash, V] find(self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
/// Lookup a key from a hash map
pub fn[K : Eq + Hash, V] get(self : T[K, V], key : K) -> V? {
  match self.inner() {
    None => None
    Some(node) => node.get_with_path(key, @path.of(key))
  }
}

///|
fn[K : Eq, V] Node::get_with_path(
  self : Node[K, V],
  key : K,
  path : Path,
) -> V? {
  loop (self, path) {
    (Leaf(key1, value1, bucket), _) =>
      if key == key1 {
        Some(value1)
      } else {
        bucket.lookup(key)
      }
    (Flat(key1, value1, path1), path) =>
      if path == path1 && key == key1 {
        Some(value1)
      } else {
        None
      }
    (Branch(children), path) => {
      let idx = path.idx()
      if children[idx] is Some(child) {
        continue (child, path.next())
      }
      None
    }
  }
}

///|
#deprecated("Use `get` instead. `op_get` will return `V` instead of `Option[V]` in the future.")
pub fn[K : Eq + Hash, V] op_get(self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
/// require: key1 != key2, path1 and path2 has the same length
fn[K, V] join_2(
  key1 : K,
  value1 : V,
  path1 : Path,
  key2 : K,
  value2 : V,
  path2 : Path,
) -> Node[K, V] {
  let idx1 = path1.idx()
  let idx2 = path2.idx()
  if idx1 == idx2 {
    let node = if path1.is_last() {
      Leaf(key2, value2, @list.singleton((key1, value1)))
    } else {
      join_2(key1, value1, path1.next(), key2, value2, path2.next())
    }
    Branch(@sparse_array.singleton(idx1, node))
  } else {
    let (node1, node2) = if path1.is_last() {
      (Leaf(key1, value1, @list.empty()), Leaf(key2, value2, @list.empty()))
    } else {
      (Flat(key1, value1, path1.next()), Flat(key2, value2, path2.next()))
    }
    Branch(@sparse_array.doubleton(idx1, node1, idx2, node2))
  }
}

///|
fn[K : Eq, V] add_with_path(
  self : Node[K, V],
  key : K,
  value : V,
  path : Path,
) -> Node[K, V] {
  match self {
    Leaf(key1, value1, bucket) =>
      if key == key1 {
        Leaf(key, value, bucket)
      } else {
        let new_bucket = match bucket.find_index(kv => kv.0 == key) {
          None => bucket
          Some(index) => bucket.remove_at(index)
        }
        Leaf(key, value, new_bucket.add((key1, value1)))
      }
    Flat(key1, value1, path1) =>
      if path == path1 && key == key1 {
        Flat(key1, value, path1)
      } else {
        join_2(key1, value1, path1, key, value, path)
      }
    Branch(children) => {
      let idx = path.idx()
      match children[idx] {
        Some(child) => {
          let child = child.add_with_path(key, value, path.next())
          Branch(children.replace(idx, child))
        }
        None => {
          let child = Flat(key, value, path.next())
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

///|
/// Filter values that satisfy the predicate
pub fn[K, V] filter(
  self : T[K, V],
  pred : (V) -> Bool raise?,
) -> T[K, V] raise? {
  fn go(node) raise? {
    match node {
      Leaf(key1, value1, bucket) => {
        let new_bucket = bucket.filter(kv => pred(kv.1))
        if pred(value1) {
          Some(Leaf(key1, value1, new_bucket))
        } else {
          match new_bucket {
            Empty => None
            More((k1, v1), tail~) => Some(Leaf(k1, v1, tail))
          }
        }
      }
      Flat(_, value1, _) => if pred(value1) { Some(node) } else { None }
      Branch(children) =>
        match children.filter(go) {
          None => None
          Some(new_children) => Some(Branch(new_children))
        }
    }
  }

  match self.inner() {
    None => None
    Some(node) => go(node)
  }
}

///|
/// Fold the values in the map
pub fn[K, V, A] fold(
  self : T[K, V],
  init~ : A,
  f : (A, V) -> A raise?,
) -> A raise? {
  self.fold_with_key((acc, _k, v) => f(acc, v), init~)
}

///|
/// Fold the values in the map with key
/// TODO: can not mark `f` as `#locals(f)` because 
/// it will be shadowed by the `f` in the `@list.T::fold` function
/// TO make it more useful in the future, we may need propagate
pub fn[K, V, A] fold_with_key(
  self : T[K, V],
  init~ : A,
  f : (A, K, V) -> A raise?,
) -> A raise? {
  fn go(acc, node) raise? {
    match node {
      Leaf(k, v, bucket) =>
        bucket.fold(init=f(acc, k, v), (acc, kv) => f(acc, kv.0, kv.1))
      Flat(k, v, _) => f(acc, k, v)
      Branch(children) => children.data.fold(init=acc, go)
    }
  }

  match self.inner() {
    None => init
    Some(node) => go(init, node)
  }
}

///|
/// Maps over the values in the map
pub fn[K, V, A] map(self : T[K, V], f : (V) -> A raise?) -> T[K, A] raise? {
  self.map_with_key((_k, v) => f(v))
}

///|
/// Maps over the key-value pairs in the map
pub fn[K, V, A] map_with_key(
  self : T[K, V],
  f : (K, V) -> A raise?,
) -> T[K, A] raise? {
  fn go(m : Node[K, V]) -> Node[K, A] raise? {
    match m {
      Leaf(k, v, bucket) =>
        Leaf(k, f(k, v), bucket.map(kv => (kv.0, f(kv.0, kv.1))))
      Flat(k, v, path) => Flat(k, f(k, v), path)
      Branch(children) => Branch(children.map(go))
    }
  }

  match self.inner() {
    None => None
    Some(node) => Some(go(node))
  }
}

///|
/// Add a key-value pair to the hashmap.
///
/// If a pair with the same key already exists, the old one is replaced
pub fn[K : Eq + Hash, V] add(self : T[K, V], key : K, value : V) -> T[K, V] {
  match self.inner() {
    None => Some(Flat(key, value, @path.of(key)))
    Some(node) => Some(node.add_with_path(key, value, @path.of(key)))
  }
}

///|
/// Remove an element from a map
pub fn[K : Eq + Hash, V] remove(self : T[K, V], key : K) -> T[K, V] {
  match self.inner() {
    None => None
    Some(node) => node.remove_with_path(key, @path.of(key))
  }
}

///|
fn[K : Eq, V] remove_with_path(
  self : Node[K, V],
  key : K,
  path : Path,
) -> Node[K, V]? {
  match self {
    Leaf(key1, value1, bucket) =>
      if key1 == key {
        match bucket {
          @list.Empty => None
          More((key2, value2), tail~) => Some(Leaf(key2, value2, tail))
        }
      } else if bucket.find_index(kv => kv.0 == key) is Some(index) {
        Some(Leaf(key1, value1, bucket.remove_at(index)))
      } else {
        Some(self)
      }
    Flat(key1, _, path1) =>
      if path == path1 && key == key1 {
        None
      } else {
        Some(self)
      }
    Branch(children) => {
      let idx = path.idx()
      match children[idx] {
        None => Some(self)
        Some(child) => {
          let new_child = child.remove_with_path(key, path.next())
          let new_children = match (children.size(), new_child) {
            (1, None) => return None
            (_, None) => children.remove(idx)
            (_, Some(new_child)) => children.replace(idx, new_child)
          }
          match new_children.data {
            [Flat(key1, value1, path1)] =>
              Some(
                Flat(
                  key1,
                  value1,
                  path1.push(new_children.elem_info.first_idx()),
                ),
              )
            _ => Some(Branch(new_children))
          }
        }
      }
    }
  }
}

///|
/// Calculate the size of a map.
///
/// WARNING: this operation is `O(N)` in map size
pub fn[K, V] size(self : T[K, V]) -> Int {
  fn node_size(node) {
    match node {
      Leaf(_, _, bucket) => 1 + bucket.length()
      Flat(_) => 1
      Branch(children) =>
        for i = 0, total_size = 0; i < children.data.length(); {
          continue i + 1, total_size + node_size(children.data[i])
        } else {
          total_size
        }
    }
  }

  match self.inner() {
    None => 0
    Some(node) => node_size(node)
  }
}

///|
/// Union two hashmaps, right-hand side element is prioritized
pub fn[K : Eq, V] T::union(self : T[K, V], other : T[K, V]) -> T[K, V] {
  fn go(node1 : Node[_], node2) {
    match (node1, node2) {
      (_, Flat(key2, value2, path2)) => node1.add_with_path(key2, value2, path2)
      (Flat(key1, value1, path1), _) =>
        match node2.get_with_path(key1, path1) {
          Some(_) => node2
          None => node2.add_with_path(key1, value1, path1)
        }
      (Branch(children1), Branch(children2)) =>
        Branch(children1.union(children2, go))
      (Leaf(key1, value1, bucket1), Leaf(key2, value2, bucket2)) => {
        let kvs1 = bucket1.add((key1, value1))
        let kvs2 = bucket2.add((key2, value2))
        match kvs1.filter(kv => kvs2.lookup(kv.0) is None) {
          Empty => node2
          More(head, tail~) => Leaf(key2, value2, bucket2 + tail.add(head))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.inner(), other.inner()) {
    (None, x) | (x, None) => x
    (Some(a), Some(b)) => Some(go(a, b))
  }
}

///|
/// Union two hashmaps with a function
pub fn[K : Eq, V] T::union_with(
  self : T[K, V],
  other : T[K, V],
  f : (K, V, V) -> V raise?,
) -> T[K, V] raise? {
  fn go(node1 : Node[_], node2) raise? {
    match (node1, node2) {
      (_, Flat(key2, value2, path2)) => {
        let new_value = match node1.get_with_path(key2, path2) {
          Some(value1) => f(key2, value1, value2)
          None => value2
        }
        node1.add_with_path(key2, new_value, path2)
      }
      (Flat(key1, value1, path1), _) => {
        let new_value = match node2.get_with_path(key1, path1) {
          Some(value2) => f(key1, value1, value2)
          None => value1
        }
        node2.add_with_path(key1, new_value, path1)
      }
      (Branch(children1), Branch(children2)) =>
        Branch(children1.union(children2, go))
      (Leaf(key1, value1, bucket1), Leaf(key2, value2, bucket2)) => {
        let kvs1 = bucket1.add((key1, value1))
        let kvs2 = bucket2.add((key2, value2))
        kvs1.union_with(kvs2, f)
      }
      _ => abort("Unreachable")
    }
  }

  match (self.inner(), other.inner()) {
    (None, x) | (x, None) => x
    (Some(a), Some(b)) => Some(go(a, b))
  }
}

///|
fn[K : Eq, V] @list.T::union_with(
  self : Self[(K, V)],
  other : Self[(K, V)],
  f : (K, V, V) -> V raise?,
) -> Node[K, V] raise? {
  let res = self.to_array()
  for kv2 in other {
    for i, kv1 in res {
      if kv1.0 == kv2.0 {
        res[i] = (kv1.0, f(kv1.0, kv1.1, kv2.1))
        break
      }
    } else {
      res.push(kv2)
    }
  }
  guard @list.from_array(res) is More((k, v), tail~)
  Leaf(k, v, tail)
}

///|
/// Intersect two hashmaps, right-hand side element is prioritized
pub fn[K : Eq, V] T::intersection(self : T[K, V], other : T[K, V]) -> T[K, V] {
  fn go(node1 : Node[_], node2) {
    match (node1, node2) {
      (_, Flat(key2, _, path2)) =>
        match node1.get_with_path(key2, path2) {
          Some(_) => Some(node2)
          None => None
        }
      (Flat(key1, _, path1), _) =>
        match node2.get_with_path(key1, path1) {
          Some(value2) => Some(Flat(key1, value2, path1))
          None => None
        }
      (Branch(children1), Branch(children2)) =>
        match children1.intersection(children2, go) {
          None => None
          Some({ data: [Flat(key, value, path)], elem_info }) =>
            Some(Flat(key, value, path.push(elem_info.first_idx())))
          Some(children) => Some(Branch(children))
        }
      (Leaf(key1, value1, bucket1), Leaf(key2, value2, bucket2)) => {
        let kvs1 = bucket1.add((key1, value1))
        let kvs2 = bucket2.add((key2, value2))
        match kvs2.filter(kv => kvs1.lookup(kv.0) is Some(_)) {
          Empty => None
          More(head, tail~) => Some(Leaf(head.0, head.1, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.inner(), other.inner()) {
    (None, _) | (_, None) => None
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
/// Intersection two hashmaps with a function
pub fn[K : Eq, V] T::intersection_with(
  self : T[K, V],
  other : T[K, V],
  f : (K, V, V) -> V raise?,
) -> T[K, V] raise? {
  fn go(node1 : Node[_], node2) raise? {
    match (node1, node2) {
      (_, Flat(key2, value2, path2)) =>
        match node1.get_with_path(key2, path2) {
          Some(value1) => Some(Flat(key2, f(key2, value1, value2), path2))
          None => None
        }
      (Flat(key1, value1, path1), _) =>
        match node2.get_with_path(key1, path1) {
          Some(value2) => Some(Flat(key1, f(key1, value1, value2), path1))
          None => None
        }
      (Branch(children1), Branch(children2)) =>
        match children1.intersection(children2, go) {
          None => None
          Some({ data: [Flat(key, value, path)], elem_info }) =>
            Some(Flat(key, value, path.push(elem_info.first_idx())))
          Some(children) => Some(Branch(children))
        }
      (Leaf(key1, value1, bucket1), Leaf(key2, value2, bucket2)) => {
        let kvs1 = bucket1.add((key1, value1))
        let kvs2 = bucket2.add((key2, value2))
        kvs1.intersection_with(kvs2, f)
      }
      _ => abort("Unreachable")
    }
  }

  match (self.inner(), other.inner()) {
    (None, _) | (_, None) => None
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
fn[K : Eq, V] @list.T::intersection_with(
  self : Self[(K, V)],
  other : Self[(K, V)],
  f : (K, V, V) -> V raise?,
) -> Node[K, V]? raise? {
  let res = []
  for kv1 in self {
    for kv2 in other {
      if kv1.0 == kv2.0 {
        res.push((kv1.0, f(kv1.0, kv1.1, kv2.1)))
        break
      }
    }
  }
  match @list.from_array(res) {
    Empty => None
    More((k, v), tail~) => Some(Leaf(k, v, tail))
  }
}

///|
/// Difference of two hashmaps: elements in `self` but not in `other`
pub fn[K : Eq, V] T::difference(self : T[K, V], other : T[K, V]) -> T[K, V] {
  fn go(node1 : Node[_], node2) {
    match (node1, node2) {
      (node, Flat(k, _, path)) => node.remove_with_path(k, path)
      (Flat(key, _, path), _) =>
        match node2.get_with_path(key, path) {
          Some(_) => None
          None => Some(node1)
        }
      (Branch(children1), Branch(children2)) =>
        match children1.difference(children2, go) {
          None => None
          Some({ data: [Flat(key, value, path)], elem_info }) =>
            Some(Flat(key, value, path.push(elem_info.first_idx())))
          Some(children) => Some(Branch(children))
        }
      (Leaf(key1, value1, bucket1), Leaf(key2, value2, bucket2)) => {
        let kvs1 = bucket1.add((key1, value1))
        let kvs2 = bucket2.add((key2, value2))
        match kvs1.filter(kv => not(kvs2.lookup(kv.0) is Some(_))) {
          Empty => None
          More(head, tail~) => Some(Leaf(head.0, head.1, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.inner(), other.inner()) {
    (None, _) => None
    (_, None) => self
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
/// Iterate through the elements in a hash map
pub fn[K, V] each(self : T[K, V], f : (K, V) -> Unit raise?) -> Unit raise? {
  fn go(node) raise? {
    match node {
      Leaf(k, v, bucket) => {
        f(k, v)
        bucket.each(kv => f(kv.0, kv.1))
      }
      Flat(k, v, _) => f(k, v)
      Branch(children) => children.each(go)
    }
  }

  match self.inner() {
    None => ()
    Some(node) => go(node)
  }
}

///|
/// Returns all keys of the map
pub fn[K, V] keys(self : T[K, V]) -> Iter[K] {
  self.iter().map(p => p.0)
}

///|
/// Returns all values of the map
pub fn[K, V] values(self : T[K, V]) -> Iter[V] {
  self.iter().map(p => p.1)
}

///|
#deprecated("Use `values` instead")
#coverage.skip
pub fn[K, V] elems(self : T[K, V]) -> Iter[V] {
  self.values()
}

///|
/// Converted to Iter
pub fn[K, V] iter(self : T[K, V]) -> Iter[(K, V)] {
  fn go(node) -> Iter[(K, V)] {
    match node {
      Leaf(k, v, bucket) => Iter::singleton((k, v)) + bucket.iter()
      Flat(k, v, _) => Iter::singleton((k, v))
      Branch(children) => children.data.iter().flat_map(go)
    }
  }

  match self.inner() {
    None => Iter::empty()
    Some(node) => go(node)
  }
}

///|
pub fn[K, V] iter2(self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(yield_ => for kv in self {
    guard yield_(kv.0, kv.1) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
pub fn[K : Eq + Hash, V] from_iter(iter : Iter[(K, V)]) -> T[K, V] {
  iter.fold(init=new(), (m, e) => m.add(e.0, e.1))
}

///|
pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashmap.of([", suffix="])")
}

///|
pub fn[K : Eq + Hash, V] from_array(arr : Array[(K, V)]) -> T[K, V] {
  loop (arr.length(), new()) {
    (0, map) => map
    (n, map) => {
      let (k, v) = arr[n - 1]
      continue (n - 1, map.add(k, v))
    }
  }
}

///|
/// Convert to an array of key-value pairs.
pub fn[K, V] to_array(self : T[K, V]) -> Array[(K, V)] {
  let arr = Array::new(capacity=self.size())
  self.each((k, v) => arr.push((k, v)))
  arr
}

///|
pub impl[K : Eq + Hash + @quickcheck.Arbitrary, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub fn[K : Eq + Hash, V] of(arr : FixedArray[(K, V)]) -> T[K, V] {
  loop (arr.length(), new()) {
    (0, map) => map
    (n, map) => {
      let (k, v) = arr[n - 1]
      continue (n - 1, map.add(k, v))
    }
  }
}

///|
impl[K : Eq, V : Eq] Eq for Node[K, V] with op_equal(self, other) {
  match (self, other) {
    (Flat(key1, value1, path1), Flat(key2, value2, path2)) =>
      path1 == path2 && key1 == key2 && value1 == value2
    (Branch(children1), Branch(children2)) => children1 == children2
    (Leaf(key1, value1, bucket1), Leaf(key2, value2, bucket2)) => {
      guard bucket1.length() == bucket2.length() else { return false }
      let kvs1 = bucket1.add((key1, value1))
      let kvs2 = bucket2.add((key2, value2))
      kvs1.all(kv => kvs2.lookup(kv.0) is Some(v) && kv.1 == v)
    }
    _ => false
  }
}

///|
pub impl[K : Hash, V : Hash] Hash for T[K, V] with hash_combine(self, hasher) {
  self.each((k, v) => hasher..combine(k)..combine(v))
}
