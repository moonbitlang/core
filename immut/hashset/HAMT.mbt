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

/// An immutable hash set data structure
enum Set[T] {
  Empty
  Leaf(T) // optimize for the case of no collision
  Collision(Bucket[T]) // use a list of buckets to resolve collision
  Branch(@sparse_array.SparseArray[Set[T]])
}

// The number of bits consumed at every [Branch] node
let segment_length : Int = 5

let segment_mask : Int = 0b11111

pub fn Set::new[T]() -> Set[T] {
  Empty
}

/// Lookup a value from the hash set
pub fn contains[T : Eq + Hash](self : Set[T], key : T) -> Bool {
  loop self, key.hash() {
    Empty, _ => false
    Leaf(key1), _ => key == key1
    Collision(bucket), _ => bucket.find(key)
    // get the first segment (lower 5 bits) of the hash value
    // inline the hot path of Sparse_array::op_get
    Branch(children), hash => {
      let idx = hash.land(segment_mask)
      if children.elem_info.has(idx) {
        let child = children.data[children.elem_info.index_of(idx)]
        continue child, hash.lsr(segment_length)
      }
      false
    }
  }
}

fn add_with_hash[T : Eq](
  self : Set[T],
  key : T,
  depth : Int,
  hash : Int
) -> Set[T] {
  fn make_leaf(depth : Int, key : T, hash : Int) {
    // make sure leaf nodes always appear at the bottom of the tree
    if depth >= 32 {
      Set::Leaf(key)
    } else {
      let idx = hash.land(segment_mask)
      let child = make_leaf(
        depth + segment_length,
        key,
        hash.lsr(segment_length),
      )
      Set::Branch(@sparse_array.SparseArray::singleton(idx, child))
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
      let idx = hash.land(segment_mask)
      match children[idx] {
        Some(child) => {
          let child = child.add_with_hash(
            key,
            depth + segment_length,
            hash.lsr(segment_length),
          )
          Branch(children.replace(idx, child))
        }
        None => {
          let child = make_leaf(
            depth + segment_length,
            key,
            hash.lsr(segment_length),
          )
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

/// Add a key to the hashset.
pub fn add[T : Eq + Hash](self : Set[T], key : T) -> Set[T] {
  self.add_with_hash(key, 0, key.hash())
}

/// Remove an element from a set
pub fn remove[T : Eq + Hash](self : Set[T], key : T) -> Set[T] {
  self.remove_with_hash(key, 0, key.hash())
}

fn remove_with_hash[T : Eq](
  self : Set[T],
  key : T,
  depth : Int,
  hash : Int
) -> Set[T] {
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

/// Calculate the size of a set.
///
/// WARNING: this operation is `O(N)` in set size
pub fn size[T](self : Set[T]) -> Int {
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

/// Returns true if the hash set is empty.
pub fn is_empty[T](self : Set[T]) -> Bool {
  match self {
    Empty => true
    _ => false
  }
}

/// Iterate through the elements in a hash set
pub fn iter[T](self : Set[T], f : (T) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(k) => f(k)
    Collision(bucket) => bucket.iter(f)
    Branch(children) => children.iter(fn { child => child.iter(f) })
  }
}

/// Converted to Iter
pub fn as_iter[T](self : Set[T]) -> Iter[T] {
  match self {
    Empty => Iter::empty()
    Leaf(k) => Iter::singleton(k)
    Collision(bucket) => bucket.as_iter()
    Branch(children) =>
      children.data.as_iter().flat_map(fn { set => set.as_iter() })
  }
}

pub fn debug_write[T : Debug](self : Set[T], buf : Buffer) -> Unit {
  let mut is_first = true
  buf.write_string("@immutable_hashset.Set::[")
  self.iter(
    fn(k) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      k.debug_write(buf)
    },
  )
  buf.write_string("]")
}

pub fn to_string[T : Debug](self : Set[T]) -> String {
  let buf = Buffer::make(0)
  self.debug_write(buf)
  buf.to_string()
}

pub fn Set::from_array[T : Eq + Hash](arr : Array[T]) -> Set[T] {
  loop arr.length(), Set::new() {
    0, set => set
    n, set => {
      let k = arr[n - 1]
      continue n - 1, set.add(k)
    }
  }
}
