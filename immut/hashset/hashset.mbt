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
  None
}

///|
pub fn[A : Hash] singleton(key : A) -> T[A] {
  Some(Flat(key, Path::of(key)))
}

///|
pub fn[A : Eq + Hash] of(arr : FixedArray[A]) -> T[A] {
  match arr {
    [] => None
    [x, ..] => {
      let mut acc = Flat(x, Path::of(x))
      for i in 1..<arr.length() {
        let k = arr[i]
        acc = acc.add_inplace(k, Path::of(k))
      }
      Some(acc)
    }
  }
}

///|
pub fn[A : Eq + Hash] from_array(arr : Array[A]) -> T[A] {
  match arr {
    [] => None
    [x, .. xs] =>
      xs.fold(init=Flat(x, Path::of(x)), fn(acc, y) {
        acc.add_inplace(y, Path::of(y))
      })
      |> Some
  }
}

///|
pub fn[A : Eq + Hash] from_iter(iter : Iter[A]) -> T[A] {
  iter.fold(init=new()._, fn {
    None, key => singleton(key)._
    Some(node), key => node.add_inplace(key, Path::of(key)) |> Some
  })
}

///|
pub fn[A] T::is_empty(self : T[A]) -> Bool {
  self._ is None
}

///|
/// O(n)
pub fn[A] T::size(self : T[A]) -> Int {
  let mut size = 0
  self.each(fn(_) { size += 1 })
  size
}

///|
pub fn[A : Eq + Hash] T::contains(self : T[A], key : A) -> Bool {
  self._ is Some(node) && node.contain(key, Path::of(key))
}

///|
pub fn[A : Eq + Hash] T::add(self : T[A], key : A) -> T[A] {
  match self._ {
    None => singleton(key)
    Some(node) => node.add(key, Path::of(key)) |> Some
  }
}

///|
pub fn[A : Eq + Hash] T::remove(self : T[A], key : A) -> T[A] {
  match self._ {
    None => None
    Some(node) => node.remove(key, Path::of(key))
  }
}

///|
pub fn[A] T::each(self : T[A], f : (A) -> Unit) -> Unit {
  if self._ is Some(node) {
    node.each(f)
  }
}

///|
pub fn[A] T::iter(self : T[A]) -> Iter[A] {
  match self._ {
    None => Iter::empty()
    Some(node) => node.iter()
  }
}

///|
pub fn[A : Eq] T::union(self : T[A], other : T[A]) -> T[A] {
  fn go(a : Node[A], b : Node[A]) -> Node[A] {
    match (a, b) {
      (node, Flat(k, path)) | (Flat(k, path), node) => node.add(k, path)
      (Branch(asa), Branch(bsa)) => Branch(asa.union(bsa, go))
      (Leaf(ka, ra), Leaf(kb, rb)) => {
        let la = ra
          .add(ka)
          .filter(fn(k) { not(k == kb || rb.any(k.op_equal(_))) })
        match la {
          Empty => b
          More(ka, tail~) => Leaf(kb, rb + tail.add(ka))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self._, other._) {
    (None, x) | (x, None) => x
    (Some(a), Some(b)) => Some(go(a, b))
  }
}

///|
pub fn[A : Eq] T::intersection(self : T[A], other : T[A]) -> T[A] {
  fn go(a : Node[A], b : Node[A]) -> Node[A]? {
    match (a, b) {
      (node, Flat(k, path) as f) | (Flat(k, path) as f, node) =>
        if node.contain(k, path) {
          Some(f)
        } else {
          None
        }
      (Branch(asa), Branch(bsa)) =>
        match asa.intersection(bsa, go) {
          None => None
          Some({ data: [Flat(k, next)] } as sa) =>
            Some(Flat(k, next.push(sa.first_index())))
          Some(sa) => Some(Branch(sa))
        }
      (Leaf(ka, ra), Leaf(kb, rb)) => {
        let la = ra.add(ka).filter(fn(k) { k == kb || rb.any(k.op_equal(_)) })
        match la {
          Empty => None
          More(ka, tail~) => Some(Leaf(ka, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self._, other._) {
    (None, _) | (_, None) => None
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
pub fn[A : Eq] T::difference(self : T[A], other : T[A]) -> T[A] {
  fn go(a : Node[A], b : Node[A]) -> Node[A]? {
    match (a, b) {
      (node, Flat(k, path)) => node.remove(k, path)
      (Flat(k, path) as f, node) =>
        if node.contain(k, path) {
          None
        } else {
          Some(f)
        }
      (Branch(asa), Branch(bsa)) =>
        match asa.difference(bsa, go) {
          None => None
          Some({ data: [Flat(k, next)] } as sa) =>
            Some(Flat(k, next.push(sa.first_index())))
          Some(sa) => Some(Branch(sa))
        }
      (Leaf(ka, ra), Leaf(kb, rb)) => {
        let la = ra
          .add(ka)
          .filter(fn(k) { not(k == kb || rb.any(k.op_equal(_))) })
        match la {
          Empty => None
          More(ka, tail~) => Some(Leaf(ka, tail))
        }
      }
      _ => abort("Unreachable")
    }
  }

  match (self._, other._) {
    (None, _) => None
    (_, None) => self
    (Some(a), Some(b)) => go(a, b)
  }
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/hashset.of([", suffix="])")
}

///|
pub impl[A : Eq + Hash + @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[A] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}

///|
pub fnalias T::(
  is_empty,
  size,
  contains,
  add,
  remove,
  each,
  iter,
  union,
  intersection,
  difference
)
