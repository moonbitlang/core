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
pub fn[A] new() -> T[A] {
  Empty
}

///|
/// Lookup a value from the hash set
pub fn[A : Eq + Hash] contains(self : T[A], key : A) -> Bool {
  loop (self, @path.of(key)) {
    (Empty, _) => false
    (Leaf(key1, bucket), _) => key == key1 || bucket.contains(key)
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
fn[A : Eq] add_with_path(self : T[A], key : A, path : Path) -> T[A] {
  fn make_leaf(key : A, path : Path) {
    // make sure leaf nodes always appear at the bottom of the tree
    if path.is_end() {
      Leaf(key, @list.empty())
    } else {
      let child = make_leaf(key, path.next())
      Branch(@sparse_array.singleton(path.idx(), child))
    }
  }

  match self {
    Empty => make_leaf(key, path)
    Leaf(key1, bucket) =>
      if key == key1 || bucket.contains(key) {
        self
      } else {
        Leaf(key, bucket.add(key1))
      }
    Branch(children) => {
      let idx = path.idx()
      match children[idx] {
        Some(child) => {
          let child = child.add_with_path(key, path.next())
          Branch(children.replace(idx, child))
        }
        None => {
          let child = make_leaf(key, path.next())
          Branch(children.add(idx, child))
        }
      }
    }
  }
}

///|
/// Add a key to the hashset.
pub fn[A : Eq + Hash] add(self : T[A], key : A) -> T[A] {
  self.add_with_path(key, @path.of(key))
}

///|
/// Remove an element from a set
pub fn[A : Eq + Hash] remove(self : T[A], key : A) -> T[A] {
  self.remove_with_path(key, @path.of(key))
}

///|
fn[A : Eq] remove_with_path(self : T[A], key : A, path : Path) -> T[A] {
  match self {
    Empty => self
    Leaf(key1, bucket) =>
      if key1 == key {
        match bucket {
          @list.Empty => Empty
          More(key2, tail=xs) => Leaf(key2, xs)
        }
      } else if bucket.find_index(key.op_equal(_)) is Some(index) {
        Leaf(key1, bucket.remove_at(index))
      } else {
        self
      }
    Branch(children) => {
      let idx = path.idx()
      match children[idx] {
        None => self
        Some(child) => {
          let new_child = child.remove_with_path(key, path.next())
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
pub fn[A] size(self : T[A]) -> Int {
  match self {
    Empty => 0
    Leaf(_, bucket) => 1 + bucket.length()
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
/// Union two hashsets
pub fn[K : Eq + Hash] T::union(self : T[K], other : T[K]) -> T[K] {
  match (self, other) {
    (_, Empty) => self
    (Empty, _) => other
    (Branch(sa1), Branch(sa2)) =>
      Branch(sa1.union(sa2, (m1, m2) => m1.union(m2)))
    (_, _) => self.iter().fold(init=other, (m, k) => m.add(k))
  }
}

///|
/// Intersect two hashsets
pub fn[K : Eq + Hash] T::intersection(self : T[K], other : T[K]) -> T[K] {
  self
  .iter()
  .fold(init=Empty, (m, k) => if other.contains(k) { m.add(k) } else { m })
}

///|
/// Difference of two hashsets: elements in `self` but not in `other`
pub fn[K : Eq + Hash] T::difference(self : T[K], other : T[K]) -> T[K] {
  self
  .iter()
  .fold(init=Empty, (m, k) => if other.contains(k) { m } else { m.add(k) })
}

///|
/// Returns true if the hash set is empty.
pub fn[A] is_empty(self : T[A]) -> Bool {
  self is Empty
}

///|
/// Iterate through the elements in a hash set
pub fn[A] each(self : T[A], f : (A) -> Unit raise?) -> Unit raise? {
  match self {
    Empty => ()
    Leaf(k, bucket) => {
      f(k)
      bucket.each(f)
    }
    Branch(children) => children.each(child => child.each(f))
  }
}

///|
/// Converted to Iter
pub fn[A] iter(self : T[A]) -> Iter[A] {
  match self {
    Empty => Iter::empty()
    Leaf(k, bucket) => Iter::singleton(k) + bucket.iter()
    Branch(children) => children.data.iter().flat_map(set => set.iter())
  }
}

///|
pub fn[A : Eq + Hash] from_iter(iter : Iter[A]) -> T[A] {
  iter.fold(init=new(), (s, e) => s.add(e))
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashset.of([", suffix="])")
}

///|
pub fn[A : Eq + Hash] from_array(arr : Array[A]) -> T[A] {
  loop (arr.length(), new()) {
    (0, set) => set
    (n, set) => {
      let k = arr[n - 1]
      continue (n - 1, set.add(k))
    }
  }
}

///|
pub fn[A : Eq + Hash] of(arr : FixedArray[A]) -> T[A] {
  loop (arr.length(), new()) {
    (0, set) => set
    (n, set) => {
      let k = arr[n - 1]
      continue (n - 1, set.add(k))
    }
  }
}

///|
pub impl[A : Hash] Hash for T[A] with hash_combine(self, hasher) {
  hasher.combine(self.iter().fold(init=0, (x, y) => x ^ y.hash()))
}

///|
pub impl[A : Eq] Eq for T[A] with op_equal(self, other) {
  match (self, other) {
    (Empty, Empty) => true
    (Leaf(x, xs), Leaf(y, ys)) =>
      xs.length() == ys.length() && xs.add(x).iter().all(ys.add(y).contains(_))
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
  assert_eq(Hash::hash(of([1, 2, 3, 4])), Hash::hash(of([3, 2]).add(1).add(4)))
  assert_not_eq(Hash::hash(of([1, 2, 3])), Hash::hash(of([1, 2, 4])))
}

///|
test "eq" {
  assert_eq(of([1, 2, 3, 4]), of([3, 2]).add(1).add(4))
  assert_not_eq(of([1, 2, 3]), of([1, 2, 4]))
}
