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
priv enum Bucket[T] {
  Just_One(T) // must be non-empty
  More(T, Bucket[T])
}

/// Lookup a key from the bucket
fn find[T : Eq](self : Bucket[T], key : T) -> Bool {
  match self {
    Just_One(key1) => key == key1
    More(key1, rest) => if key == key1 { true } else { rest.find(key) }
  }
}

/// Add a new key-value pair to a bucket.
/// Replace the old entry if one with the same key already exists.
fn add[T : Eq](self : Bucket[T], key : T) -> Bucket[T] {
  match self {
    Just_One(key1) => if key == key1 { self } else { More(key, self) }
    More(key1, rest) =>
      if key == key1 {
        self
      } else {
        More(key1, rest.add(key))
      }
  }
}

/// Remove a key from a bucket
fn remove[T : Eq](self : Bucket[T], key : T) -> Bucket[T]? {
  match self {
    Just_One(old_key) => if key == old_key { None } else { Some(self) }
    More(old_key, rest) =>
      if key == old_key {
        Some(rest)
      } else {
        match rest.remove(key) {
          None => Some(Just_One(old_key))
          Some(rest) => Some(More(old_key, rest))
        }
      }
  }
}

/// Get the size of a bucket
fn size[T](self : Bucket[T]) -> Int {
  loop self, 1 {
    Just_One(_), acc => acc
    More(_, rest), acc => continue rest, acc + 1
  }
}

/// Iterate through elements of a bucket
fn each[T](self : Bucket[T], f : (T) -> Unit) -> Unit {
  loop self {
    Just_One(k) => f(k)
    More(k, rest) => {
      f(k)
      continue rest
    }
  }
}

fn iter[T](self : Bucket[T]) -> Iter[T] {
  Iter::new(
    fn {
      f =>
        loop self {
          Just_One(k) => f(k)
          More(k, rest) =>
            if f(k) == IterContinue {
              continue rest
            } else {
              IterEnd
            }
        }
    },
  )
}
