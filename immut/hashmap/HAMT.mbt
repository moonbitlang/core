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
pub fn new[K, V]() -> T[K, V] {
  Empty
}

///|
/// Lookup a key from a hash map
pub fn find[K : Eq + Hash, V](self : T[K, V], key : K) -> V? {
  loop self, key.hash() {
    Empty, _ => None
    Leaf(key1, value), _ => if key == key1 { Some(value) } else { None }
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
      None
    }
  }
}

///|
pub fn op_get[K : Eq + Hash, V](self : T[K, V], key : K) -> V? {
  self.find(key)
}

///|
fn add_with_hash[K : Eq, V](
  self : T[K, V],
  key : K,
  depth : Int,
  hash : Int,
  value : V
) -> T[K, V] {
  // make sure leaf nodes always appear at the bottom of the tree
  fn make_leaf(depth : Int, key : K, hash : Int, value : V) {
    if depth >= 32 {
      T::Leaf(key, value)
    } else {
      let idx = hash & segment_mask
      let child = make_leaf(
        depth + segment_length,
        key,
        (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
        value,
      )
      T::Branch(@sparse_array.singleton(idx, child))
    }
  }

  match self {
    Empty => make_leaf(depth, key, hash, value)
    Leaf(key1, value1) =>
      if key == key1 {
        Leaf(key, value)
      } else {
        Collision(More(key, value, Just_One(key1, value1)))
      }
    Collision(bucket) => Collision(bucket.add(key, value))
    Branch(children) => {
      let idx = hash & segment_mask
      match children[idx] {
        Some(child) => {
          let child = child.add_with_hash(
            key,
            depth + segment_length,
            (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
            value,
          )
          Branch(children.replace(idx, child))
        }
        None => {
          let child = make_leaf(
            depth + segment_length,
            key,
            (hash.reinterpret_as_uint() >> segment_length).reinterpret_as_int(),
            value,
          )
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

///|
/// Add a key-value pair to the hashmap.
///
/// If a pair with the same key already exists, the old one is replaced
pub fn add[K : Eq + Hash, V](self : T[K, V], key : K, value : V) -> T[K, V] {
  self.add_with_hash(key, 0, key.hash(), value)
}

///|
/// Remove an element from a map
pub fn remove[K : Eq + Hash, V](self : T[K, V], key : K) -> T[K, V] {
  self.remove_with_hash(key, 0, key.hash())
}

///|
fn remove_with_hash[K : Eq, V](
  self : T[K, V],
  key : K,
  depth : Int,
  hash : Int
) -> T[K, V] {
  match self {
    Empty => self
    Leaf(old_key, _) => if key == old_key { Empty } else { self }
    Collision(bucket) =>
      match bucket.remove(key) {
        None => Empty
        Some(Just_One(k, v)) => Leaf(k, v)
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
/// Calculate the size of a map.
///
/// WARNING: this operation is `O(N)` in map size
pub fn size[K, V](self : T[K, V]) -> Int {
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
/// Union two hashmaps
pub fn union[K : Eq + Hash, V](self : T[K, V], other : T[K, V]) -> T[K, V] {
  match (self, other) {
    (_, Empty) => self
    (Empty, _) => other
    (_, Leaf(k, v)) => self.add(k, v)
    (Leaf(k, v), _) =>
      // right-hand side element is prioritized
      // like Clojure's merge
      match other.find(k) {
        Some(_) => other
        None => other.add(k, v)
      }
    (Branch(sa1), Branch(sa2)) =>
      Branch(sa1.union(sa2, fn(m1, m2) { m1.union(m2) }))
    (_, _) => self.iter().fold(init=other, fn(m, kv) { m.add(kv.0, kv.1) })
  }
}

///|
/// Iterate through the elements in a hash map
pub fn each[K, V](self : T[K, V], f : (K, V) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(k, v) => f(k, v)
    Collision(bucket) => bucket.each(f)
    Branch(children) => children.each(fn { child => child.each(f) })
  }
}

///|
/// Converted to Iter
pub fn iter[K, V](self : T[K, V]) -> Iter[(K, V)] {
  match self {
    Empty => Iter::empty()
    Leaf(k, v) => Iter::singleton((k, v))
    Collision(bucket) => bucket.iter()
    Branch(children) => children.data.iter().flat_map(fn { map => map.iter() })
  }
}

///|
pub fn iter2[K, V](self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    for kv in self {
      guard yield_(kv.0, kv.1) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
pub fn from_iter[K : Eq + Hash, V](iter : Iter[(K, V)]) -> T[K, V] {
  iter.fold(init=new(), fn(m, e) { m.add(e.0, e.1) })
}

///|
pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashmap.of([", suffix="])")
}

///|
pub fn from_array[K : Eq + Hash, V](arr : Array[(K, V)]) -> T[K, V] {
  loop arr.length(), new() {
    0, map => map
    n, map => {
      let (k, v) = arr[n - 1]
      continue n - 1, map.add(k, v)
    }
  }
}

///|
pub impl[K : Eq + Hash + @quickcheck.Arbitrary, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub fn of[K : Eq + Hash, V](arr : FixedArray[(K, V)]) -> T[K, V] {
  loop arr.length(), new() {
    0, map => map
    n, map => {
      let (k, v) = arr[n - 1]
      continue n - 1, map.add(k, v)
    }
  }
}

///|
pub impl[K : Eq + Hash, V : Eq] Eq for T[K, V] with op_equal(self, other) {
  guard self.size() == other.size() else { return false }
  for kv in self {
    guard other.find(kv.0) is Some(v) && v == kv.1 else { return false }

  }
  true
}

///|
pub impl[K : Hash, V : Hash] Hash for T[K, V] with hash_combine(self, hasher) {
  self.each(fn(k, v) { hasher..combine(k).combine(v) })
}
