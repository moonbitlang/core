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
#as_free_fn
pub fn[A] HashSet::new() -> HashSet[A] {
  None
}

///|
/// Lookup a value from the hash set
pub fn[A : Eq + Hash] contains(self : HashSet[A], key : A) -> Bool {
  self.0 is Some(node) && node.contains(key, @path.of(key))
}

///|
fn[A : Eq] Node::contains(self : Node[A], key : A, path : Path) -> Bool {
  loop (self, path) {
    (Leaf(key1, bucket), _) => key == key1 || bucket.contains(key)
    (Flat(key1, path1), path) => path == path1 && key == key1
    (Branch(children), path) => {
      let idx = path.idx()
      if children[idx] is Some(child) {
        continue (child, path.next())
      }
      false
    }
  }
}

///|
/// require: key1 != key2, path1 and path2 has the same length
fn[A] join_2(key1 : A, path1 : Path, key2 : A, path2 : Path) -> Node[A] {
  let idx1 = path1.idx()
  let idx2 = path2.idx()
  if idx1 == idx2 {
    let node = if path1.is_last() {
      Leaf(key2, @list.singleton(key1))
    } else {
      join_2(key1, path1.next(), key2, path2.next())
    }
    Branch(@sparse_array.singleton(idx1, node))
  } else {
    let (node1, node2) = if path1.is_last() {
      (Leaf(key1, @list.empty()), Leaf(key2, @list.empty()))
    } else {
      (Flat(key1, path1.next()), Flat(key2, path2.next()))
    }
    Branch(@sparse_array.doubleton(idx1, node1, idx2, node2))
  }
}

///|
fn[A : Eq] add_with_path(self : Node[A], key : A, path : Path) -> Node[A] {
  match self {
    Leaf(key1, bucket) =>
      if key == key1 || bucket.contains(key) {
        self
      } else {
        Leaf(key, bucket.add(key1))
      }
    Flat(key1, path1) =>
      if path == path1 && key == key1 {
        self
      } else {
        join_2(key1, path1, key, path)
      }
    Branch(children) => {
      let idx = path.idx()
      match children[idx] {
        Some(child) => {
          let child = child.add_with_path(key, path.next())
          Branch(children.replace(idx, child))
        }
        None => {
          let child = Flat(key, path.next())
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

///|
/// Add a key to the hashset.
pub fn[A : Eq + Hash] add(self : HashSet[A], key : A) -> HashSet[A] {
  match self.0 {
    None => Some(Flat(key, @path.of(key)))
    Some(node) => Some(node.add_with_path(key, @path.of(key)))
  }
}

///|
/// Remove an element from a set
pub fn[A : Eq + Hash] remove(self : HashSet[A], key : A) -> HashSet[A] {
  match self.0 {
    None => None
    Some(node) => node.remove_with_path(key, @path.of(key))
  }
}

///|
fn[A : Eq] remove_with_path(self : Node[A], key : A, path : Path) -> Node[A]? {
  match self {
    Leaf(key1, bucket) =>
      if key1 == key {
        match bucket {
          @list.Empty => None
          More(key2, tail=xs) => Some(Leaf(key2, xs))
        }
      } else if bucket.find_index(key.op_equal(_)) is Some(index) {
        Some(Leaf(key1, bucket.remove_at(index)))
      } else {
        Some(self)
      }
    Flat(key1, path1) =>
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
            [Flat(key1, path1)] =>
              Some(Flat(key1, path1.push(new_children.elem_info.first_idx())))
            _ => Some(Branch(new_children))
          }
        }
      }
    }
  }
}

///|
/// Calculate the size of a set.
///
/// WARNING: this operation is `O(N)` in set size
pub fn[A] size(self : HashSet[A]) -> Int {
  fn node_size(node) {
    match node {
      Leaf(_, bucket) => 1 + bucket.length()
      Flat(_) => 1
      Branch(children) =>
        for i = 0, total_size = 0; i < children.data.length(); {
          continue i + 1, total_size + node_size(children.data[i])
        } else {
          total_size
        }
    }
  }

  match self.0 {
    None => 0
    Some(node) => node_size(node)
  }
}

///|
/// Union two hashsets
pub fn[K : Eq] HashSet::union(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  fn go(node1, node2) {
    match (node1, node2) {
      (node, Flat(key, path)) | (Flat(key, path), node) =>
        node.add_with_path(key, path)
      (Branch(children1), Branch(children2)) =>
        Branch(children1.union(children2, go))
      (Leaf(key1, bucket1), Leaf(key2, bucket2)) => {
        let keys1 = bucket1.add(key1)
        let keys2 = bucket2.add(key2)
        match keys1.filter(k => !keys2.contains(k)) {
          Empty => node2
          More(head, tail~) => Leaf(key2, bucket2 + tail.add(head))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.0, other.0) {
    (None, x) | (x, None) => x
    (Some(a), Some(b)) => Some(go(a, b))
  }
}

///|
/// Intersect two hashsets
pub fn[K : Eq] HashSet::intersection(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  fn go(node1, node2) {
    match (node1, node2) {
      (node, Flat(key, path) as flat) | (Flat(key, path) as flat, node) =>
        if node.contains(key, path) {
          Some(flat)
        } else {
          None
        }
      (Branch(children1), Branch(children2)) =>
        match children1.intersection(children2, go) {
          None => None
          Some({ data: [Flat(key, path)], elem_info }) =>
            Some(Flat(key, path.push(elem_info.first_idx())))
          Some(children) => Some(Branch(children))
        }
      (Leaf(key1, bucket1), Leaf(key2, bucket2)) => {
        let keys1 = bucket1.add(key1)
        let keys2 = bucket2.add(key2)
        match keys1.filter(keys2.contains(_)) {
          Empty => None
          More(head, tail~) => Some(Leaf(head, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.0, other.0) {
    (None, _) | (_, None) => None
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
/// Difference of two hashsets: elements in `self` but not in `other`
pub fn[K : Eq] HashSet::difference(
  self : HashSet[K],
  other : HashSet[K],
) -> HashSet[K] {
  fn go(node1 : Node[_], node2) {
    match (node1, node2) {
      (node, Flat(k, path)) => node.remove_with_path(k, path)
      (Flat(key, path) as flat, node) =>
        if node.contains(key, path) {
          None
        } else {
          Some(flat)
        }
      (Branch(children1), Branch(children2)) =>
        match children1.difference(children2, go) {
          None => None
          Some({ data: [Flat(key, path)], elem_info }) =>
            Some(Flat(key, path.push(elem_info.first_idx())))
          Some(children) => Some(Branch(children))
        }
      (Leaf(key1, bucket1), Leaf(key2, bucket2)) => {
        let keys1 = bucket1.add(key1)
        let keys2 = bucket2.add(key2)
        match keys1.filter(k => !keys2.contains(k)) {
          Empty => None
          More(head, tail~) => Some(Leaf(head, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self.0, other.0) {
    (None, _) => None
    (_, None) => self
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
/// Returns true if the hash set is empty.
pub fn[A] is_empty(self : HashSet[A]) -> Bool {
  self.0 is None
}

///|
/// Iterate through the elements in a hash set
pub fn[A] each(self : HashSet[A], f : (A) -> Unit raise?) -> Unit raise? {
  fn go(node) raise? {
    match node {
      Leaf(k, bucket) => {
        f(k)
        bucket.each(f)
      }
      Flat(k, _) => f(k)
      Branch(children) => children.each(go)
    }
  }

  match self.0 {
    None => ()
    Some(node) => go(node)
  }
}

///|
/// Converted to Iter
pub fn[A] iter(self : HashSet[A]) -> Iter[A] {
  fn go(node) -> Iter[A] {
    match node {
      Leaf(k, bucket) => Iter::singleton(k) + bucket.iter()
      Flat(k, _) => Iter::singleton(k)
      Branch(children) => children.data.iter().flat_map(go)
    }
  }

  match self.0 {
    None => Iter::empty()
    Some(node) => go(node)
  }
}

///|
#as_free_fn
pub fn[A : Eq + Hash] HashSet::from_iter(iter : Iter[A]) -> HashSet[A] {
  iter.fold(init=new(), (s, e) => s.add(e))
}

///|
pub impl[A : Show] Show for HashSet[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashset.of([", suffix="])")
}

///|
#as_free_fn
pub fn[A : Eq + Hash] HashSet::from_array(arr : Array[A]) -> HashSet[A] {
  loop (arr.length(), new()) {
    (0, set) => set
    (n, set) => {
      let k = arr[n - 1]
      continue (n - 1, set.add(k))
    }
  }
}

///|
#as_free_fn
pub fn[A : Eq + Hash] HashSet::of(arr : FixedArray[A]) -> HashSet[A] {
  loop (arr.length(), new()) {
    (0, set) => set
    (n, set) => {
      let k = arr[n - 1]
      continue (n - 1, set.add(k))
    }
  }
}

///|
pub impl[A : Hash] Hash for HashSet[A] with hash_combine(self, hasher) {
  hasher.combine(self.iter().fold(init=0, (x, y) => x ^ y.hash()))
}

///|
impl[A : Eq] Eq for Node[A] with equal(self, other) {
  match (self, other) {
    (Leaf(x, xs), Leaf(y, ys)) =>
      xs.length() == ys.length() &&
      {
        let keys1 = xs.add(x)
        let keys2 = ys.add(y)
        keys1.iter().all(keys2.contains(_))
      }
    (Flat(x, pathx), Flat(y, pathy)) => pathx == pathy && x == y
    (Branch(xs), Branch(ys)) => xs == ys
    _ => false
  }
}

///|
pub impl[K : Eq + Hash + @quickcheck.Arbitrary] @quickcheck.Arbitrary for HashSet[
  K,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
test "hash" {
  assert_eq(Hash::hash(of([1, 2, 3, 4])), Hash::hash(of([3, 2]).add(1).add(4)))
  assert_not_eq(Hash::hash(of([1, 2, 3])), Hash::hash(of([1, 2, 4])))
}

///|
test "eq" {
  assert_eq(of([1, 2, 3, 4]), of([3, 2]).add(1).add(4))
  assert_not_eq(of([1, 2, 3]), of([1, 2, 4]))
}
