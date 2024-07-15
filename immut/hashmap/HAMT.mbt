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

/// An immutable hash-map data structure
enum T[K, V] {
  Empty
  Leaf(K, V) // optimize for the case of no collision
  Collision(Bucket[K, V]) // use a list of buckets to resolve collision
  Branch(@sparse_array.SparseArray[T[K, V]])
}

// The number of bits consumed at every [Branch] node
let segment_length : Int = 5

let segment_mask : Int = 0b11111

pub fn T::new[K, V]() -> T[K, V] {
  Empty
}

/// Lookup a key from a hash map
pub fn find[K : Eq + Hash, V](self : T[K, V], key : K) -> V? {
  loop self, key.hash() {
    Empty, _ => None
    Leaf(key1, value), _ => if key == key1 { Some(value) } else { None }
    Collision(bucket), _ => bucket.find(key)
    // get the first segment (lower 5 bits) of the hash value
    // inline the hot path of Sparse_array::op_get
    Branch(children), hash => {
      let idx = hash.land(segment_mask)
      if children.elem_info.has(idx) {
        let child = children.data[children.elem_info.index_of(idx)]
        continue child, hash.lsr(segment_length)
      }
      None
    }
  }
}

pub fn op_get[K : Eq + Hash, V](self : T[K, V], key : K) -> V? {
  self.find(key)
}

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
      let idx = hash.land(segment_mask)
      let child = make_leaf(
        depth + segment_length,
        key,
        hash.lsr(segment_length),
        value,
      )
      T::Branch(@sparse_array.SparseArray::singleton(idx, child))
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
      let idx = hash.land(segment_mask)
      match children[idx] {
        Some(child) => {
          let child = child.add_with_hash(
            key,
            depth + segment_length,
            hash.lsr(segment_length),
            value,
          )
          Branch(children.replace(idx, child))
        }
        None => {
          let child = make_leaf(
            depth + segment_length,
            key,
            hash.lsr(segment_length),
            value,
          )
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

/// Add a key-value pair to the hashmap.
///
/// If a pair with the same key already exists, the old one is replaced
pub fn add[K : Eq + Hash, V](self : T[K, V], key : K, value : V) -> T[K, V] {
  self.add_with_hash(key, 0, key.hash(), value)
}

/// Remove an element from a map
pub fn remove[K : Eq + Hash, V](self : T[K, V], key : K) -> T[K, V] {
  self.remove_with_hash(key, 0, key.hash())
}

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
      let idx = hash.land(segment_mask)
      match children[idx] {
        None => self
        Some(child) => {
          let new_child = child.remove_with_hash(
            key,
            depth + segment_length,
            hash.lsr(segment_length),
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

/// Iterate through the elements in a hash map
pub fn each[K, V](self : T[K, V], f : (K, V) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(k, v) => f(k, v)
    Collision(bucket) => bucket.each(f)
    Branch(children) => children.each(fn { child => child.each(f) })
  }
}

/// Converted to Iter
pub fn iter[K, V](self : T[K, V]) -> Iter[(K, V)] {
  match self {
    Empty => Iter::empty()
    Leaf(k, v) => Iter::singleton((k, v))
    Collision(bucket) => bucket.iter()
    Branch(children) => children.data.iter().flat_map(fn { map => map.iter() })
  }
}

pub fn debug_write[K : Debug, V : Debug](
  self : T[K, V],
  buf : Buffer
) -> Unit {
  let mut is_first = true
  buf.write_string("@immutable_hashmap.Map::[")
  self.each(
    fn(k, v) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string("(")
      k.debug_write(buf)
      buf.write_string(", ")
      v.debug_write(buf)
      buf.write_string(")")
    },
  )
  buf.write_string("]")
}

pub fn to_string[K : Debug, V : Debug](self : T[K, V]) -> String {
  let buf = Buffer::new(size_hint=0)
  self.debug_write(buf)
  buf.to_string()
}

pub fn T::from_array[K : Eq + Hash, V](arr : Array[(K, V)]) -> T[K, V] {
  loop arr.length(), T::new() {
    0, map => map
    n, map => {
      let (k, v) = arr[n - 1]
      continue n - 1, map.add(k, v)
    }
  }
}

pub fn T::of[K : Eq + Hash, V](arr : FixedArray[(K, V)]) -> T[K, V] {
  loop arr.length(), T::new() {
    0, map => map
    n, map => {
      let (k, v) = arr[n - 1]
      continue n - 1, map.add(k, v)
    }
  }
}
