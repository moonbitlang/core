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
// The number of bits consumed at every [Branch] node
let segment_length : Int = 5

///|
let segment_mask : Int = 0b11111

///|
pub fn new[A]() -> T[A] {
  Empty
}

///|
/// Lookup a value from the hash set
pub fn contains[A : Eq + Hash](self : T[A], key : A) -> Bool {
  loop self, key.hash() {
    Empty, _ => false
    Leaf(key1), _ => key == key1
    Collision(bucket), _ => bucket.find(key)
    // get the first segment (lower 5 bits) of the hash value
    // inline the hot path of Sparse_array::op_get
    Branch(children), hash => {
      let idx = hash & segment_mask
      if children.elem_info.has(idx) {
        let child = children.data[children.elem_info.index_of(idx)]
        continue child,
          (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int()
      }
      false
    }
  }
}

///|
fn add_with_hash[A : Eq](self : T[A], key : A, depth : Int, hash : Int) -> T[A] {
  fn make_leaf(depth : Int, key : A, hash : Int) {
    // make sure leaf nodes always appear at the bottom of the tree
    if depth >= 32 {
      Leaf(key)
    } else {
      let idx = hash & segment_mask
      let child = make_leaf(
        depth + segment_length,
        key,
        (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
      )
      Branch(@sparse_array.singleton(idx, child))
    }
  }

  match self {
    Empty => make_leaf(depth, key, hash)
    Leaf(key1) =>
      if key == key1 {
        Leaf(key)
      } else {
        Collision(More(key, Just_One(key1)))
      }
    Collision(bucket) => Collision(bucket.add(key))
    Branch(children) => {
      let idx = hash & segment_mask
      match children[idx] {
        Some(child) => {
          let child = child.add_with_hash(
            key,
            depth + segment_length,
            (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
          )
          Branch(children.replace(idx, child))
        }
        None => {
          let child = make_leaf(
            depth + segment_length,
            key,
            (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
          )
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

///|
/// Add a key to the hashset.
pub fn add[A : Eq + Hash](self : T[A], key : A) -> T[A] {
  self.add_with_hash(key, 0, key.hash())
}

///|
/// Remove an element from a set
pub fn remove[A : Eq + Hash](self : T[A], key : A) -> T[A] {
  self.remove_with_hash(key, 0, key.hash())
}

///|
fn remove_with_hash[A : Eq](
  self : T[A],
  key : A,
  depth : Int,
  hash : Int
) -> T[A] {
  match self {
    Empty => self
    Leaf(old_key) => if key == old_key { Empty } else { self }
    Collision(bucket) =>
      match bucket.remove(key) {
        None => Empty
        Some(Just_One(k)) => Leaf(k)
        Some(new_bucket) => Collision(new_bucket)
      }
    Branch(children) => {
      let idx = hash & segment_mask
      match children[idx] {
        None => self
        Some(child) => {
          let new_child = child.remove_with_hash(
            key,
            depth + segment_length,
            (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
          )
          match (children.size(), new_child) {
            (1, Empty) => Empty
            (_, _) => Branch(children.replace(idx, new_child))
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
pub fn size[A](self : T[A]) -> Int {
  match self {
    Empty => 0
    Leaf(_) => 1
    Collision(bucket) => bucket.size()
    Branch(children) =>
      for i = 0, total_size = 0 {
        if i < children.data.length() {
          continue i + 1, total_size + children.data[i].size()
        } else {
          break total_size
        }
      }
  }
}

///|
/// Returns true if the hash set is empty.
pub fn is_empty[A](self : T[A]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

///|
/// Iterate through the elements in a hash set
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(k) => f(k)
    Collision(bucket) => bucket.each(f)
    Branch(children) => children.each(fn { child => child.each(f) })
  }
}

///|
/// Converted to Iter
pub fn iter[A](self : T[A]) -> Iter[A] {
  match self {
    Empty => Iter::empty()
    Leaf(k) => Iter::singleton(k)
    Collision(bucket) => bucket.iter()
    Branch(children) => children.data.iter().flat_map(fn { set => set.iter() })
  }
}

///|
pub fn from_iter[A : Eq + Hash](iter : Iter[A]) -> T[A] {
  iter.fold(init=new(), fn(s, e) { s.add(e) })
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashset.of([", suffix="])")
}

///|
pub fn from_array[A : Eq + Hash](arr : Array[A]) -> T[A] {
  loop arr.length(), new() {
    0, set => set
    n, set => {
      let k = arr[n - 1]
      continue n - 1, set.add(k)
    }
  }
}

///|
pub fn of[A : Eq + Hash](arr : FixedArray[A]) -> T[A] {
  loop arr.length(), new() {
    0, set => set
    n, set => {
      let k = arr[n - 1]
      continue n - 1, set.add(k)
    }
  }
}

///|
pub impl[A : Hash] Hash for T[A] with hash_combine(self, hasher) {
  hasher.combine(self.iter().fold(init=0, fn(x, y) { x ^ y.hash() }))
}

///|
pub impl[A : Eq] Eq for T[A] with op_equal(self, other) {
  match (self, other) {
    (Empty, Empty) => true
    (Leaf(x), Leaf(y)) => x == y
    (Collision(xs), Collision(ys)) =>
      xs.size() == ys.size() && xs.iter().all(fn(x) { ys.find(x) })
    (Branch(xs), Branch(ys)) => xs == ys
    _ => false
  }
}

///|
pub impl[K : Eq + Hash + @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[K] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
test "hash" {
  assert_eq!(Hash::hash(of([1, 2, 3, 4])), Hash::hash(of([3, 2]).add(1).add(4)))
  assert_not_eq!(Hash::hash(of([1, 2, 3])), Hash::hash(of([1, 2, 4])))
}

///|
test "eq" {
  assert_eq!(of([1, 2, 3, 4]), of([3, 2]).add(1).add(4))
  assert_not_eq!(of([1, 2, 3]), of([1, 2, 4]))
}
