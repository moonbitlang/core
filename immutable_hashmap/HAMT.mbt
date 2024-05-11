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
enum Map[K, V] {
  Empty
  Leaf(K, V) // optimize for the case of no collision
  Collision(Bucket[K, V]) // use a list of buckets to resolve collision
  Branch(SparseArray[Map[K, V]])
}

// The number of bits consumed at every [Branch] node
let segment_length : Int = 5

let segment_mask : Int = 0b11111

pub fn Map::make[K, V]() -> Map[K, V] {
  Empty
}

/// Lookup a key from a hash map
pub fn find[K : Eq + Hash, V](self : Map[K, V], key : K) -> Option[V] {
  loop self, key.hash() {
    Empty, _ => None
    Leaf(key1, value), _ => if key == key1 { Some(value) } else { None }
    Collision(bucket), _ => bucket.find(key)
    Branch(children), hash => {
      // get the first segment (lower 5 bits) of the hash value
      let idx = hash.land(segment_mask)
      match children[idx] {
        Some(child) =>
          // when searching recursively, drop the segment just used
          continue child, hash.lsr(segment_length)
        None => None
      }
    }
  }
}

fn add_with_hash[K : Eq, V](
  self : Map[K, V],
  key : K,
  depth : Int,
  hash : Int,
  value : V
) -> Map[K, V] {
  // make sure leaf nodes always appear at the bottom of the tree
  fn make_leaf(depth : Int, key : K, hash : Int, value : V) {
    if depth >= 32 {
      Map::Leaf(key, value)
    } else {
      let idx = hash.land(segment_mask)
      let child = make_leaf(
        depth + segment_length,
        key,
        hash.lsr(segment_length),
        value,
      )
      Map::Branch(singleton(idx, child))
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
pub fn add[K : Eq + Hash, V](self : Map[K, V], key : K, value : V) -> Map[K, V] {
  self.add_with_hash(key, 0, key.hash(), value)
}

/// Remove an element from a map
pub fn remove[K : Eq + Hash, V](self : Map[K, V], key : K) -> Map[K, V] {
  self.remove_with_hash(key, 0, key.hash())
}

fn remove_with_hash[K : Eq, V](
  self : Map[K, V],
  key : K,
  depth : Int,
  hash : Int
) -> Map[K, V] {
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
          if children.size() == 1 {
            match new_child {
              Empty => Empty
              _ => Branch(children.replace(idx, new_child))
            }
          } else {
            Branch(children.replace(idx, new_child))
          }
        }
      }
    }
  }
}

/// Calculate the size of a map.
///
/// WARNING: this operation is `O(N)` in map size
pub fn size[K, V](self : Map[K, V]) -> Int {
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
pub fn iter[K, V](self : Map[K, V], f : (K, V) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(k, v) => f(k, v)
    Collision(bucket) => bucket.iter(f)
    Branch(children) => children.iter(fn { child => child.iter(f) })
  }
}

pub fn debug_write[K : Debug, V : Debug](
  self : Map[K, V],
  buf : Buffer
) -> Unit {
  let mut is_first = true
  buf.write_string("@immutable_hashmap.Map::[")
  self.iter(
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

pub fn to_string[K : Debug, V : Debug](self : Map[K, V]) -> String {
  let buf = Buffer::make(0)
  self.debug_write(buf)
  buf.to_string()
}

test "HAMT::to_string" {
  let map = Map::make().add(1, 1).add(3, 3).add(0x0f_ff_ff_ff, 0x0f_ff_ff_ff).add(
    42, 42,
  )
  inspect(
    map,
    content="@immutable_hashmap.Map::[(1, 1), (3, 3), (42, 42), (268435455, 268435455)]",
  )?
}

pub fn Map::from_array[K : Eq + Hash, V](arr : Array[(K, V)]) -> Map[K, V] {
  loop arr.length(), Map::make() {
    0, map => map
    n, map => {
      let (k, v) = arr[n - 1]
      continue n - 1, map.add(k, v)
    }
  }
}

test "HAMT::from_array" {
  let map = Map::[(1, "1"), (2, "2"), (42, "42")]
  inspect((1, map.find(1)), content="(1, Some(1))")?
  inspect((2, map.find(2)), content="(2, Some(2))")?
  inspect((42, map.find(42)), content="(42, Some(42))")?
  inspect((43, map.find(43)), content="(43, None)")?
}
