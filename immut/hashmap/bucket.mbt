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
fn find[K : Eq, V](self : Bucket[K, V], key : K) -> V? {
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
fn remove[K : Eq, V](self : Bucket[K, V], key : K) -> Bucket[K, V]? {
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
    More(_, _, rest), acc => continue rest, acc + 1
  }
}

/// Iterate through elements of a bucket
fn each[K, V](self : Bucket[K, V], f : (K, V) -> Unit) -> Unit {
  loop self {
    Just_One(k, v) => f(k, v)
    More(k, v, rest) => {
      f(k, v)
      continue rest
    }
  }
}

fn iter[K, V](self : Bucket[K, V]) -> Iter[(K, V)] {
  Iter::_unstable_internal_make(
    fn {
      f =>
        loop self {
          Just_One(k, v) => f((k, v))
          More(k, v, rest) =>
            if f((k, v)) == IterContinue {
              continue rest
            } else {
              IterEnd
            }
        }
    },
  )
}
