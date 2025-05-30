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
pub fn[K, V] new() -> T[K, V] {
  Empty
}

///|
/// Create a map with a single key-value pair.
pub fn[K, V] singleton(key : K, value : V) -> T[K, V] {
  Leaf(key, value)
}

///|
/// Check if the map contains a key.
pub fn[K : Eq + Hash, V] contains(self : T[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
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
#deprecated("Use `get` instead. `op_get` will return `V` instead of `Option[V]` in the future.")
pub fn[K : Eq + Hash, V] op_get(self : T[K, V], key : K) -> V? {
  self.get(key)
}

///|
fn[K : Eq, V] add_with_hash(
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
        Collision(More(key, value, JustOne(key1, value1)))
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
/// Filter values that satisfy the predicate
pub fn[K : Eq + Hash, V] filter(self : T[K, V], pred : (V) -> Bool) -> T[K, V] {
  match self {
    Empty => Empty
    Leaf(k, v) => if pred(v) { Leaf(k, v) } else { Empty }
    Collision(bucket) =>
      match bucket.filter(pred) {
        Some(JustOne(k, v)) => Leaf(k, v)
        Some(b) => Collision(b)
        None => Empty
      }
    Branch(children) => {
      let mut result = Empty
      children.each(fn {
        child =>
          child
          .filter(pred)
          .iter()
          .each(fn { (k, v) => result = result.add(k, v) })
      })
      result
    }
  }
}

///|
/// Fold the values in the map
pub fn[K, V, A] fold(self : T[K, V], init~ : A, f : (A, V) -> A) -> A {
  self.fold_with_key(fn(acc, _k, v) { f(acc, v) }, init~)
}

///|
/// Fold the values in the map with key
/// TODO: can not mark `f` as `#locals(f)` because 
/// it will be shadowed by the `f` in the `fold_with_key` function
/// TO make it more useful in the future, we may need propagate
pub fn[K, V, A] fold_with_key(
  self : T[K, V],
  init~ : A,
  f : (A, K, V) -> A
) -> A {
  loop @list.singleton((self, 0)), init {
    Empty, acc => acc
    More((node, index), tail~), acc =>
      match node {
        Empty => continue tail, acc
        Leaf(k, v) => continue tail, f(acc, k, v)
        Collision(bucket) => continue tail, bucket.foldl_with_key(init=acc, f)
        Branch(children) =>
          if index < children.data.length() {
            let child = children.data.unsafe_get(index)
            continue tail.add((node, index + 1)).add((child, 0)), acc
          } else {
            continue tail, acc
          }
      }
  }
}

///|
/// Maps over the values in the map
pub fn[K : Eq + Hash, V, A] map(self : T[K, V], f : (V) -> A) -> T[K, A] {
  self.map_with_key(fn(_k, v) { f(v) })
}

///|
/// Maps over the key-value pairs in the map
pub fn[K : Eq + Hash, V, A] map_with_key(
  self : T[K, V],
  f : (K, V) -> A
) -> T[K, A] {
  fn go(m : T[K, V]) {
    match m {
      Empty => Empty
      Leaf(k, v) => Leaf(k, f(k, v))
      Collision(bucket) => Collision(bucket.map_with_key(f))
      Branch(children) => {
        let result = []
        children.each(fn {
          child =>
            child.map_with_key(f).iter().each(fn { kv => result.push(kv) })
        })
        from_array(result)
      }
    }
  }

  go(self)
}

///|
/// Add a key-value pair to the hashmap.
///
/// If a pair with the same key already exists, the old one is replaced
pub fn[K : Eq + Hash, V] add(self : T[K, V], key : K, value : V) -> T[K, V] {
  self.add_with_hash(key, 0, key.hash(), value)
}

///|
/// Remove an element from a map
pub fn[K : Eq + Hash, V] remove(self : T[K, V], key : K) -> T[K, V] {
  self.remove_with_hash(key, 0, key.hash())
}

///|
fn[K : Eq, V] remove_with_hash(
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
        Some(JustOne(k, v)) => Leaf(k, v)
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
pub fn[K, V] size(self : T[K, V]) -> Int {
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
pub fn[K : Eq + Hash, V] T::union(self : T[K, V], other : T[K, V]) -> T[K, V] {
  match (self, other) {
    (_, Empty) => self
    (Empty, _) => other
    (_, Leaf(k, v)) => self.add(k, v)
    (Leaf(k, v), _) =>
      // right-hand side element is prioritized
      // like Clojure's merge
      match other.get(k) {
        Some(_) => other
        None => other.add(k, v)
      }
    (Branch(sa1), Branch(sa2)) =>
      Branch(sa1.union(sa2, fn(m1, m2) { m1.union(m2) }))
    (_, _) => self.iter().fold(init=other, fn(m, kv) { m.add(kv.0, kv.1) })
  }
}

///|
/// Union two hashmaps with a function
pub fn[K : Eq + Hash, V] T::union_with(
  self : T[K, V],
  other : T[K, V],
  f : (K, V, V) -> V
) -> T[K, V] {
  match (self, other) {
    (_, Empty) => self
    (Empty, _) => other
    (_, Leaf(k, v)) =>
      match self.get(k) {
        Some(v1) => self.add(k, f(k, v1, v))
        None => self.add(k, v)
      }
    (Leaf(k, v), _) =>
      match other.get(k) {
        Some(v2) => other.add(k, f(k, v, v2))
        None => other.add(k, v)
      }
    (Branch(sa1), Branch(sa2)) =>
      Branch(sa1.union(sa2, fn(m1, m2) { m1.union_with(m2, f) }))
    (_, _) =>
      self
      .iter()
      .fold(init=other, fn(m, kv) {
        match m.get(kv.0) {
          Some(v2) => m.add(kv.0, f(kv.0, kv.1, v2))
          None => m.add(kv.0, kv.1)
        }
      })
  }
}

///|
/// Intersect two hashmaps
pub fn[K : Eq + Hash, V] T::intersection(
  self : T[K, V],
  other : T[K, V]
) -> T[K, V] {
  match (self, other) {
    (_, Empty) => Empty
    (Empty, _) => Empty
    (Leaf(k, v), _) =>
      match other.get(k) {
        Some(_) => Leaf(k, v)
        None => Empty
      }
    (_, Leaf(k, _)) =>
      match self.get(k) {
        Some(v) => Leaf(k, v)
        None => Empty
      }
    (Branch(sa1), Branch(sa2)) =>
      Branch(sa1.intersection(sa2, fn(m1, m2) { m1.intersection(m2) }))
    (_, _) =>
      self
      .iter()
      .fold(init=Empty, fn(m, kv) {
        if other.get(kv.0) is Some(_) {
          m.add(kv.0, kv.1)
        } else {
          m
        }
      })
  }
}

///|
/// Intersection two hashmaps with a function
pub fn[K : Eq + Hash, V] T::intersection_with(
  self : T[K, V],
  other : T[K, V],
  f : (K, V, V) -> V
) -> T[K, V] {
  match (self, other) {
    (_, Empty) => Empty
    (Empty, _) => Empty
    (Leaf(k, v), _) =>
      match other.get(k) {
        Some(v2) => Leaf(k, f(k, v, v2))
        None => Empty
      }
    (_, Leaf(k, v2)) =>
      match self.get(k) {
        Some(v1) => Leaf(k, f(k, v1, v2))
        None => Empty
      }
    (Branch(sa1), Branch(sa2)) =>
      Branch(sa1.intersection(sa2, fn(m1, m2) { m1.intersection_with(m2, f) }))
    (_, _) =>
      self
      .iter()
      .fold(init=Empty, fn(m, kv) {
        match other.get(kv.0) {
          Some(v2) => m.add(kv.0, f(kv.0, kv.1, v2))
          None => m
        }
      })
  }
}

///|
/// Difference of two hashmaps: elements in `self` but not in `other`
pub fn[K : Eq + Hash, V] T::difference(
  self : T[K, V],
  other : T[K, V]
) -> T[K, V] {
  match (self, other) {
    (Empty, _) => Empty
    (_, Empty) => self
    (Leaf(k, v), _) =>
      match other.get(k) {
        Some(_) => Empty
        None => Leaf(k, v)
      }
    (Branch(sa1), Branch(sa2)) => Branch(sa1.difference(sa2))
    (_, _) =>
      self
      .iter()
      .fold(init=Empty, fn(m, kv) {
        if other.get(kv.0) is None {
          m.add(kv.0, kv.1)
        } else {
          m
        }
      })
  }
}

///|
/// Iterate through the elements in a hash map
pub fn[K, V] each(self : T[K, V], f : (K, V) -> Unit) -> Unit {
  match self {
    Empty => ()
    Leaf(k, v) => f(k, v)
    Collision(bucket) => bucket.each(f)
    Branch(children) => children.each(fn { child => child.each(f) })
  }
}

///|
/// Returns all keys of the map
pub fn[K, V] keys(self : T[K, V]) -> Iter[K] {
  self.iter().map(fn { (k, _) => k })
}

///|
/// Returns all values of the map
pub fn[K, V] values(self : T[K, V]) -> Iter[V] {
  self.iter().map(fn { (_, v) => v })
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
  match self {
    Empty => Iter::empty()
    Leaf(k, v) => Iter::singleton((k, v))
    Collision(bucket) => bucket.iter()
    Branch(children) => children.data.iter().flat_map(fn { map => map.iter() })
  }
}

///|
pub fn[K, V] iter2(self : T[K, V]) -> Iter2[K, V] {
  Iter2::new(fn(yield_) {
    for kv in self {
      guard yield_(kv.0, kv.1) is IterContinue else { break IterEnd }
    } else {
      IterContinue
    }
  })
}

///|
pub fn[K : Eq + Hash, V] from_iter(iter : Iter[(K, V)]) -> T[K, V] {
  iter.fold(init=new(), fn(m, e) { m.add(e.0, e.1) })
}

///|
pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashmap.of([", suffix="])")
}

///|
pub fn[K : Eq + Hash, V] from_array(arr : Array[(K, V)]) -> T[K, V] {
  loop arr.length(), new() {
    0, map => map
    n, map => {
      let (k, v) = arr[n - 1]
      continue n - 1, map.add(k, v)
    }
  }
}

///|
/// Convert to an array of key-value pairs.
pub fn[K, V] to_array(self : T[K, V]) -> Array[(K, V)] {
  let arr = Array::new(capacity=self.size())
  self.each(fn(k, v) { arr.push((k, v)) })
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
    guard other.get(kv.0) is Some(v) && v == kv.1 else { return false }
  }
  true
}

///|
pub impl[K : Hash, V : Hash] Hash for T[K, V] with hash_combine(self, hasher) {
  self.each(fn(k, v) { hasher..combine(k)..combine(v) })
}
