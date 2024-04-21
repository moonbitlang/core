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

/// A bucket is a non-empty linked list of key-value pair,
/// used to resolve hash collision in HAMT
priv enum Bucket[K, V] {
  Just_One(K, V) // must be non-empty
  More(K, V, Bucket[K, V])
}

/// Lookup a key from the bucket
fn find[K : Eq, V](self : Bucket[K, V], key : K) -> Option[V] {
  match self {
    Just_One(key1, value) => if key == key1 { Some(value) } else { None }
    More(key1, value, rest) =>
      if key == key1 {
        Some(value)
      } else {
        rest.find(key)
      }
  }
}

/// Add a new key-value pair to a bucket.
/// Replace the old entry if one with the same key already exists.
fn add[K : Eq, V](self : Bucket[K, V], key : K, value : V) -> Bucket[K, V] {
  match self {
    Just_One(key1, _) =>
      if key == key1 {
        Just_One(key, value)
      } else {
        More(key, value, self)
      }
    More(key1, value1, rest) =>
      if key == key1 {
        More(key, value, rest)
      } else {
        More(key1, value1, rest.add(key, value))
      }
  }
}

/// Remove a key from a bucket
fn remove[K : Eq, V](self : Bucket[K, V], key : K) -> Option[Bucket[K, V]] {
  match self {
    Just_One(old_key, _) => if key == old_key { None } else { Some(self) }
    More(old_key, old_value, rest) =>
      if key == old_key {
        Some(rest)
      } else {
        match rest.remove(key) {
          None => Some(Just_One(old_key, old_value))
          Some(rest) => Some(More(old_key, old_value, rest))
        }
      }
  }
}

/// Get the size of a bucket
fn size[K, V](self : Bucket[K, V]) -> Int {
  loop self, 1 {
    Just_One(_), acc => acc 
    More(_,_, rest), acc => continue rest, acc + 1
  }  
}

test "Bucket" {
  let b : Bucket[_] = Just_One(0, 0)
  @assertion.assert_eq(b.find(0), Some(0))?
  @assertion.assert_eq(b.find(1), None)?
  @assertion.assert_eq(b.size(), 1)?
  let b = b.add(1, 1)
  @assertion.assert_eq(b.find(0), Some(0))?
  @assertion.assert_eq(b.find(1), Some(1))?
  @assertion.assert_eq(b.size(), 2)?
  let b = b.add(0, 2)
  @assertion.assert_eq(b.find(0), Some(2))?
  @assertion.assert_eq(b.find(1), Some(1))?
  @assertion.assert_eq(b.size(), 2)?
  match b.remove(0) {
    None => @assertion.assert_true(false)?
    Some(b1) => {
      @assertion.assert_eq(b1.find(0), None)?
      @assertion.assert_eq(b1.find(1), Some(1))?
    }
  }
  match b.remove(1) {
    None => @assertion.assert_true(false)?
    Some(b1) => {
      @assertion.assert_eq(b1.find(0), Some(2))?
      @assertion.assert_eq(b1.find(1), None)?
    }
  }
}

/// Iterate through elements of a bucket
fn iter[K, V](self : Bucket[K, V], f : (K, V) -> Unit) -> Unit {
  loop self {
    Just_One(k, v) => f(k, v)
    More(k, v, rest) => {
      f(k, v)
      continue rest
    }
  }
}

test "Bucket::iter" {
  let b : Bucket[_] = More(0, 0, More(1, 1, Just_One(31, 31)))
  let buf = Buffer::make(0)
  let mut is_first = true
  b.iter(
    fn(k, v) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string("\(k) => \(v)")
    },
  )
  @assertion.assert_eq(buf.to_string(), "0 => 0, 1 => 1, 31 => 31")?
}
