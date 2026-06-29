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
priv enum CurrNode[K, V] {
  Tree(Node[K, V])
  Bucket(@list.List[(K, V)])
}

///|
priv struct BuildEntry[K, V] {
  key : K
  value : V
  path : @path.Path
}

///|
let bulk_build_threshold = 64

///|
/// Create a new instance.
#as_free_fn
pub fn[K, V] HashMap::new() -> HashMap[K, V] {
  { data: None }
}

///|
/// Create a map with a single key-value pair.
#as_free_fn
pub fn[K : Hash, V] HashMap::singleton(key : K, value : V) -> HashMap[K, V] {
  { data: Some(Flat(key, value, @path.of(key))) }
}

///|
/// Check if the map contains a key.
pub fn[K : Eq + Hash, V] HashMap::contains(
  self : HashMap[K, V],
  key : K,
) -> Bool {
  self.get(key) is Some(_)
}

///|
/// Lookup a key from a hash map
#alias(find, deprecated)
pub fn[K : Eq + Hash, V] HashMap::get(self : HashMap[K, V], key : K) -> V? {
  match self.data {
    None => None
    Some(node) => node.get_with_path(key, @path.of(key))
  }
}

///|
/// Get value with `at` access semantics.
#alias("_[_]")
pub fn[K : Eq + Hash, V] HashMap::at(self : HashMap[K, V], key : K) -> V {
  guard self.data is Some(node)
  node.get_with_path(key, @path.of(key)).unwrap()
}

///|
fn[K : Eq, V] Node::get_with_path(
  self : Node[K, V],
  key : K,
  path : @path.Path,
) -> V? {
  for node = self, path = path {
    match (node, path) {
      (Leaf(key1, value1, bucket), _) =>
        break if key == key1 { Some(value1) } else { bucket.lookup(key) }
      (Flat(key1, value1, path1), path) =>
        break if path == path1 && key == key1 { Some(value1) } else { None }
      (Branch(children), path) => {
        let idx = path.idx()
        if children.get(idx) is Some(child) {
          continue child, path.next()
        }
        break None
      }
    }
  }
}

///|
/// require: key1 != key2, path1 and path2 has the same length
fn[K, V] join_2(
  key1 : K,
  value1 : V,
  path1 : @path.Path,
  key2 : K,
  value2 : V,
  path2 : @path.Path,
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
fn[K : Eq, V] Node::add_with_path(
  self : Node[K, V],
  key : K,
  value : V,
  path : @path.Path,
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
      match children.get(idx) {
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
fn[K : Eq, V] BuildEntry::add_to_node(
  self : BuildEntry[K, V],
  node : Node[K, V]?,
) -> Node[K, V] {
  match node {
    None => Flat(self.key, self.value, self.path)
    Some(node) => node.add_with_path(self.key, self.value, self.path)
  }
}

///|
fn[K : Eq, V] build_hashmap_node_by_add(
  entries : Array[BuildEntry[K, V]],
  start : Int,
  end : Int,
  reverse : Bool,
) -> Node[K, V] {
  if reverse {
    for i = end, node = (None : Node[K, V]?) {
      if i == start {
        break node.unwrap()
      }
      let node = entries[i - 1].add_to_node(node)
      continue i - 1, Some(node)
    }
  } else {
    for i = start, node = (None : Node[K, V]?) {
      if i == end {
        break node.unwrap()
      }
      let node = entries[i].add_to_node(node)
      continue i + 1, Some(node)
    }
  }
}

///|
fn[K : Eq, V] build_hashmap_node_range(
  entries : Array[BuildEntry[K, V]],
  start : Int,
  end : Int,
  reverse : Bool,
) -> Node[K, V] {
  if end - start == 1 {
    let entry = entries[start]
    return Flat(entry.key, entry.value, entry.path)
  }
  if entries[start].path.is_last() {
    return build_hashmap_node_by_add(entries, start, end, reverse)
  }
  let starts = FixedArray::make(32, 0)
  for i = start; i < end; i = i + 1 {
    starts[entries[i].path.idx()] += 1
  }
  let nexts = FixedArray::make(32, 0)
  for idx = 0, offset = 0; idx < 32; {
    let count = starts[idx]
    starts[idx] = offset
    nexts[idx] = offset
    continue idx + 1, offset + count
  }
  let first = entries[start]
  let partitioned = Array::make(end - start, first)
  for i = start; i < end; i = i + 1 {
    let entry = entries[i]
    let idx = entry.path.idx()
    let offset = nexts[idx]
    partitioned[offset] = {
      key: entry.key,
      value: entry.value,
      path: entry.path.next(),
    }
    nexts[idx] = offset + 1
  }
  let mut child_count = 0
  for idx = 0; idx < 32; idx = idx + 1 {
    if nexts[idx] != starts[idx] {
      child_count += 1
    }
  }
  let mut first_idx = 0
  while nexts[first_idx] == starts[first_idx] {
    first_idx += 1
  }
  let first_child = build_hashmap_node_range(
    partitioned,
    starts[first_idx],
    nexts[first_idx],
    reverse,
  )
  if child_count == 1 {
    return match first_child {
      Flat(key, value, path) => Flat(key, value, path.push(first_idx))
      _ => Branch(@sparse_array.singleton(first_idx, first_child))
    }
  }
  let indices = FixedArray::make(child_count, first_idx)
  let children = FixedArray::make(child_count, first_child)
  for idx = first_idx + 1, out = 1; idx < 32; {
    if nexts[idx] == starts[idx] {
      continue idx + 1, out
    }
    indices[out] = idx
    children[out] = build_hashmap_node_range(
      partitioned,
      starts[idx],
      nexts[idx],
      reverse,
    )
    continue idx + 1, out + 1
  }
  Branch(@sparse_array.from_sorted_fixed_array(indices, children))
}

///|
fn[K : Eq + Hash, V] hash_map_from_iter_by_add(
  iter : Iter[(K, V)],
) -> HashMap[K, V] {
  iter.fold(init=new(), (m, e) => m.add(e.0, e.1))
}

///|
fn[K : Eq + Hash, V] hash_map_from_array_by_add(
  arr : ArrayView[(K, V)],
) -> HashMap[K, V] {
  for n = arr.length(), map = new() {
    match (n, map) {
      (0, map) => break map
      (n, map) => {
        let (k, v) = arr[n - 1]
        continue n - 1, map.add(k, v)
      }
    }
  }
}

///|
fn[K : Eq + Hash, V] hash_map_from_array(
  arr : ArrayView[(K, V)],
) -> HashMap[K, V] {
  if arr.length() <= bulk_build_threshold {
    return hash_map_from_array_by_add(arr)
  }
  let entries = Array::makei(arr.length(), i => {
    let kv = arr[i]
    let (k, v) = kv
    { key: k, value: v, path: @path.of(k) }
  })
  { data: Some(build_hashmap_node_range(entries, 0, entries.length(), true)) }
}

///|
/// Filter entries that satisfy the predicate
#alias(filter_with_key, deprecated)
pub fn[K, V] HashMap::filter(
  self : HashMap[K, V],
  pred : (K, V) -> Bool raise?,
) -> HashMap[K, V] raise? {
  fn go(node) raise? {
    match node {
      Leaf(key1, value1, bucket) => {
        let new_bucket = bucket.filter(kv => pred(kv.0, kv.1))
        if pred(key1, value1) {
          Some(Leaf(key1, value1, new_bucket))
        } else {
          match new_bucket {
            Empty => None
            More((k1, v1), tail~) => Some(Leaf(k1, v1, tail))
          }
        }
      }
      Flat(key1, value1, _) =>
        if pred(key1, value1) {
          Some(node)
        } else {
          None
        }
      Branch(children) =>
        match children.filter(go) {
          None => None
          Some(new_children) => Some(Branch(new_children))
        }
    }
  }

  {
    data: match self.data {
      None => None
      Some(node) => go(node)
    },
  }
}

///|
/// Fold the values in the map with key
/// TODO: can not mark `f` as `#locals(f)` because 
/// it will be shadowed by the `f` in the `@list.List::fold` function
/// TO make it more useful in the future, we may need propagate
#alias(fold_with_key, deprecated)
pub fn[K, V, A] HashMap::fold(
  self : HashMap[K, V],
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

  match self.data {
    None => init
    Some(node) => go(init, node)
  }
}

///|
/// Maps over the key-value pairs in the map
#alias(map_with_key, deprecated)
pub fn[K, V, A] HashMap::map(
  self : HashMap[K, V],
  f : (K, V) -> A raise?,
) -> HashMap[K, A] raise? {
  fn go(m : Node[K, V]) -> Node[K, A] raise? {
    match m {
      Leaf(k, v, bucket) =>
        Leaf(k, f(k, v), bucket.map(kv => (kv.0, f(kv.0, kv.1))))
      Flat(k, v, path) => Flat(k, f(k, v), path)
      Branch(children) => Branch(children.map(go))
    }
  }

  {
    data: match self.data {
      None => None
      Some(node) => Some(go(node))
    },
  }
}

///|
/// Add a key-value pair to the hashmap.
///
/// If a pair with the same key already exists, the old one is replaced
pub fn[K : Eq + Hash, V] HashMap::add(
  self : HashMap[K, V],
  key : K,
  value : V,
) -> HashMap[K, V] {
  {
    data: match self.data {
      None => Some(Flat(key, value, @path.of(key)))
      Some(node) => Some(node.add_with_path(key, value, @path.of(key)))
    },
  }
}

///|
/// Remove an element from a map
pub fn[K : Eq + Hash, V] HashMap::remove(
  self : HashMap[K, V],
  key : K,
) -> HashMap[K, V] {
  {
    data: match self.data {
      None => None
      Some(node) => node.remove_with_path(key, @path.of(key))
    },
  }
}

///|
fn[K : Eq, V] Node::remove_with_path(
  self : Node[K, V],
  key : K,
  path : @path.Path,
) -> Node[K, V]? {
  match self {
    Leaf(key1, value1, bucket) =>
      if key1 == key {
        match bucket {
          Empty => None
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
      match children.get(idx) {
        None => Some(self)
        Some(child) => {
          let new_child = child.remove_with_path(key, path.next())
          let new_children = match (children.length(), new_child) {
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
#alias(size, deprecated)
pub fn[K, V] HashMap::length(self : HashMap[K, V]) -> Int {
  fn node_size(node) {
    match node {
      Leaf(_, _, bucket) => 1 + bucket.length()
      Flat(_) => 1
      Branch(children) =>
        for child in children.data; total_size = 0 {
          continue total_size + node_size(child)
        } nobreak {
          total_size
        }
    }
  }

  match self.data {
    None => 0
    Some(node) => node_size(node)
  }
}

///|
/// Union two hashmaps, right-hand side element is prioritized
#alias(merge)
pub fn[K : Eq, V] HashMap::union(
  self : HashMap[K, V],
  other : HashMap[K, V],
) -> HashMap[K, V] {
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

  {
    data: match (self.data, other.data) {
      (None, x) | (x, None) => x
      (Some(a), Some(b)) => Some(go(a, b))
    },
  }
}

///|
/// Union two hashmaps with a function
pub fn[K : Eq, V] HashMap::union_with(
  self : HashMap[K, V],
  other : HashMap[K, V],
  f : (K, V, V) -> V raise?,
) -> HashMap[K, V] raise? {
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

  {
    data: match (self.data, other.data) {
      (None, x) | (x, None) => x
      (Some(a), Some(b)) => Some(go(a, b))
    },
  }
}

///|
fn[K : Eq, V] @list.List::union_with(
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
    } nobreak {
      res.push(kv2)
    }
  }
  guard @list.List(res) is More((k, v), tail~)
  Leaf(k, v, tail)
}

///|
/// Intersect two hashmaps, right-hand side element is prioritized
pub fn[K : Eq, V] HashMap::intersection(
  self : HashMap[K, V],
  other : HashMap[K, V],
) -> HashMap[K, V] {
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

  {
    data: match (self.data, other.data) {
      (None, _) | (_, None) => None
      (Some(a), Some(b)) => go(a, b)
    },
  }
}

///|
/// Intersection two hashmaps with a function
pub fn[K : Eq, V] HashMap::intersection_with(
  self : HashMap[K, V],
  other : HashMap[K, V],
  f : (K, V, V) -> V raise?,
) -> HashMap[K, V] raise? {
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

  {
    data: match (self.data, other.data) {
      (None, _) | (_, None) => None
      (Some(a), Some(b)) => go(a, b)
    },
  }
}

///|
fn[K : Eq, V] @list.List::intersection_with(
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
  match @list.List(res) {
    Empty => None
    More((k, v), tail~) => Some(Leaf(k, v, tail))
  }
}

///|
/// Difference of two hashmaps: elements in `self` but not in `other`
pub fn[K : Eq, V] HashMap::difference(
  self : HashMap[K, V],
  other : HashMap[K, V],
) -> HashMap[K, V] {
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
        match kvs1.filter(kv => !(kvs2.lookup(kv.0) is Some(_))) {
          Empty => None
          More(head, tail~) => Some(Leaf(head.0, head.1, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.data, other.data) {
    (None, _) => { data: None }
    (_, None) => self
    (Some(a), Some(b)) => { data: go(a, b) }
  }
}

///|
/// Iterate through the elements in a hash map
pub fn[K, V] HashMap::each(
  self : HashMap[K, V],
  f : (K, V) -> Unit raise?,
) -> Unit raise? {
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

  if self.data is Some(node) {
    go(node)
  }
}

///|
/// Returns all keys of the map
pub fn[K, V] HashMap::keys(self : HashMap[K, V]) -> Iter[K] {
  self.iter().map(p => p.0)
}

///|
/// Returns all values of the map
#alias(elems, deprecated="Use `values` instead")
pub fn[K, V] HashMap::values(self : HashMap[K, V]) -> Iter[V] {
  self.iter().map(p => p.1)
}

///|
/// Converted to Iter
#alias(iterator, deprecated)
pub fn[K, V] HashMap::iter(self : HashMap[K, V]) -> Iter[(K, V)] {
  let empty = Bucket(@list.new())
  let mut curr_node = match self.data {
    Some(tree) => Tree(tree)
    None => empty
  }
  let mut curr_index = 0
  let parents = []
  Iter::new(fn() {
    for cn = curr_node {
      match cn {
        Tree(Flat(k, v, _)) => {
          curr_node = empty
          break Some((k, v))
        }
        Tree(Leaf(k, v, bucket)) => {
          curr_node = Bucket(bucket)
          break Some((k, v))
        }
        Bucket(More(pair, tail~)) => {
          curr_node = Bucket(tail)
          break Some(pair)
        }
        Tree(Branch(children)) as n if curr_index < children.length() => {
          let child = children.data[curr_index]
          parents.push((n, curr_index + 1))
          curr_index = 0
          continue Tree(child)
        }
        Bucket(Empty) | Tree(Branch(_)) if parents.pop()
          is Some((parent, parent_index)) => {
          curr_node = parent
          curr_index = parent_index
          continue parent
        }
        Bucket(Empty) | Tree(Branch(_)) => break None
      }
    }
  })
}

///|
/// Returns a two-element iterator over key-value pairs.
#alias(iterator2, deprecated)
pub fn[K, V] HashMap::iter2(self : HashMap[K, V]) -> Iter2[K, V] {
  self.iter()
}

///|
/// Creates a hash map from an iterator of key-value pairs.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Eq + Hash, V] HashMap::from_iter(
  iter : Iter[(K, V)],
) -> HashMap[K, V] {
  if iter.size_hint() is Some(len) && len <= bulk_build_threshold {
    return hash_map_from_iter_by_add(iter)
  }
  let entries = match iter.size_hint() {
    Some(len) => Array::new(capacity=len)
    None => []
  }
  iter.each(e => entries.push({ key: e.0, value: e.1, path: @path.of(e.0) }))
  if entries.length() == 0 {
    new()
  } else {
    {
      data: Some(build_hashmap_node_range(entries, 0, entries.length(), false)),
    }
  }
}

///|
#deprecated("Use @debug.Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl[K : Show, V : Show] Show for HashMap[K, V]

///|
#warnings("-deprecated")
pub impl[K : Show, V : Show] Show for HashMap[K, V] with fn output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/hashmap.from_array([",
    suffix="])",
  )
}

///|
/// Creates a hash map from an array of key-value pairs.
#as_free_fn(deprecated="Use @immut/hashmap.HashMap([...]) instead")
#alias(of, deprecated="Use @immut/hashmap.HashMap([...]) instead")
#as_free_fn(of, deprecated="Use @immut/hashmap.HashMap([...]) instead")
#deprecated("Use @immut/hashmap.HashMap([...]) instead")
pub fn[K : Eq + Hash, V] HashMap::from_array(
  arr : ArrayView[(K, V)],
) -> HashMap[K, V] {
  hash_map_from_array(arr)
}

///|
/// Creates a hash map from an array of key-value pairs.
///
/// # Example
///
/// ```mbt check
/// test {
///   let m = @hashmap.HashMap([(1, "one"), (2, "two")])
///   @test.assert_eq(m.get(1), Some("one"))
///   @test.assert_eq(m.get(2), Some("two"))
/// }
/// ```
pub fn[K : Eq + Hash, V] HashMap::HashMap(
  arr : ArrayView[(K, V)],
) -> HashMap[K, V] {
  hash_map_from_array(arr)
}

///|
/// Returns an array of all key-value pairs.
pub fn[K, V] HashMap::to_array(self : HashMap[K, V]) -> Array[(K, V)] {
  [
    for k, v in self => (k, v)
  ]
}

///|
pub impl[K : Eq + Hash + @quickcheck.Arbitrary, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for HashMap[
  K,
  V,
] with fn arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> HashMap
}

///|
impl[K : Eq, V : Eq] Eq for Node[K, V] with fn equal(self, other) {
  if physical_equal(self, other) {
    return true
  }
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
pub impl[K : Hash, V : Hash] Hash for HashMap[K, V] with fn hash_combine(
  self,
  hasher,
) {
  hasher.combine(
    self.fold(init=0, (acc, k, v) => {
      let h = Hasher()
      h.combine((k, v))
      acc ^ h.finalize()
    }),
  )
}
