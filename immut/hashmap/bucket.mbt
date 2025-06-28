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

///|
/// Lookup a key from the bucket
fn[K : Eq, V] Bucket::find(self : Bucket[K, V], key : K) -> V? {
  match self {
    JustOne(key1, value) => if key == key1 { Some(value) } else { None }
    More(key1, value, rest) =>
      if key == key1 {
        Some(value)
      } else {
        rest.find(key)
      }
  }
}

///|
/// Add a new key-value pair to a bucket.
/// Replace the old entry if one with the same key already exists.
fn[K : Eq, V] Bucket::add(
  self : Bucket[K, V],
  key : K,
  value : V
) -> Bucket[K, V] {
  match self {
    JustOne(key1, _) =>
      if key == key1 {
        JustOne(key, value)
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

///|
/// Remove a key from a bucket
fn[K : Eq, V] Bucket::remove(self : Bucket[K, V], key : K) -> Bucket[K, V]? {
  match self {
    JustOne(old_key, _) => if key == old_key { None } else { Some(self) }
    More(old_key, old_value, rest) =>
      if key == old_key {
        Some(rest)
      } else {
        match rest.remove(key) {
          None => Some(JustOne(old_key, old_value))
          Some(rest) => Some(More(old_key, old_value, rest))
        }
      }
  }
}

///|
/// Get the size of a bucket
fn[K, V] Bucket::size(self : Bucket[K, V]) -> Int {
  loop (self, 1) {
    (JustOne(_), acc) => acc
    (More(_, _, rest), acc) => continue (rest, acc + 1)
  }
}

///|
/// Iterate through elements of a bucket
fn[K, V] Bucket::each(
  self : Bucket[K, V],
  f : (K, V) -> Unit raise?
) -> Unit raise? {
  loop self {
    JustOne(k, v) => f(k, v)
    More(k, v, rest) => {
      f(k, v)
      continue rest
    }
  }
}

///|
fn[K, V] Bucket::filter(
  self : Bucket[K, V],
  f : (V) -> Bool raise?
) -> Bucket[K, V]? raise? {
  match self {
    JustOne(k, v) => if f(v) { Some(JustOne(k, v)) } else { None }
    More(k, v, rest) => {
      let filtered = rest.filter(f)
      if f(v) {
        match filtered {
          None => Some(JustOne(k, v))
          Some(rest) => Some(More(k, v, rest))
        }
      } else {
        filtered
      }
    }
  }
}

///|
test "Bucket::filter" {
  let bucket = More(1, 1, More(2, 2, JustOne(3, 3)))
  let filtered = bucket.filter(v => v == 2)
  assert_eq(filtered.unwrap().find(1), None)
  assert_eq(filtered.unwrap().find(2), Some(2))
}

///|
fn[K, V] Bucket::iter(self : Bucket[K, V]) -> Iter[(K, V)] {
  Iter::new(f => loop self {
    JustOne(k, v) => f((k, v))
    More(k, v, rest) =>
      if f((k, v)) == IterContinue {
        continue rest
      } else {
        IterEnd
      }
  })
}

///|
test "Bucket" {
  let b0 : Bucket[_] = JustOne(0, 0)
  inspect((b0.find(0), b0.find(1), b0.size()), content="(Some(0), None, 1)")
  let b1 = b0.add(1, 1)
  inspect((b1.find(0), b1.find(1), b1.size()), content="(Some(0), Some(1), 2)")
  let b2 = b1.add(0, 2)
  inspect((b2.find(0), b2.find(1), b2.size()), content="(Some(2), Some(1), 2)")
  let b3 = b2.remove(0)
  {
    let b1 = b3.unwrap()
    inspect((b1.find(0), b1.find(1)), content="(None, Some(1))")
  }
  let b4 = b2.remove(1)
  let b1 = b4.unwrap() // b4 ? --> return Option instead of Result
  inspect((b1.find(0), b1.find(1)), content="(Some(2), None)")
}

///|
test "Bucket::iter" {
  let b : Bucket[_] = More(0, 0, More(1, 1, JustOne(31, 31)))
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  b.each((k, v) => {
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string("\{k} => \{v}")
  })
  inspect(buf.to_string(), content="0 => 0, 1 => 1, 31 => 31")
}

///|
test "Bucket::iter" {
  let b : Bucket[_] = More(0, 0, More(1, 1, JustOne(31, 31)))
  let buf = StringBuilder::new(size_hint=0)
  let mut is_first = true
  b
  .iter()
  .each(kv => {
    // weird syntax conventions that
    // braces needed here
    if is_first {
      is_first = false
    } else {
      buf.write_string(", ")
    }
    buf.write_string("\{kv.0} => \{kv.1}")
  })
  inspect(buf.to_string(), content="0 => 0, 1 => 1, 31 => 31")
}

///|
/// Fold over the bucket from left to right, applying a function to each key-value pair.
///
fn[K, V, A] Bucket::foldl_with_key(
  self : Bucket[K, V],
  f : (A, K, V) -> A raise?,
  init~ : A
) -> A raise? {
  match self {
    JustOne(k, v) => f(init, k, v)
    More(k, v, rest) => rest.foldl_with_key(init=f(init, k, v), f)
  }
}

///|
test "foldl_with_key" {
  let bucket = More("a", "a", More("b", "b", JustOne("c", "c")))
  let result = bucket.foldl_with_key(init="", (init, _k, v) => init + v)
  assert_eq(result, "abc")
}

///|
fn[K, V, A] Bucket::map_with_key(
  self : Bucket[K, V],
  f : (K, V) -> A raise?
) -> Bucket[K, A] raise? {
  match self {
    JustOne(k, v) => JustOne(k, f(k, v))
    More(k, v, rest) => More(k, f(k, v), rest.map_with_key(f))
  }
}

///|
test "Bucket::map_with_key" {
  let bucket = More(1, 10, More(2, 20, JustOne(3, 30)))
  let mapped = bucket.map_with_key((k, v) => "\{k}:\{v}")
  assert_eq(mapped.find(1), Some("1:10"))
  assert_eq(mapped.find(2), Some("2:20"))
  assert_eq(mapped.find(3), Some("3:30"))
}

///|
fn[K, V, A] Bucket::map(
  self : Bucket[K, V],
  f : (V) -> A raise?
) -> Bucket[K, A] raise? {
  self.map_with_key((_k, v) => f(v))
}

///|
test "Bucket::map" {
  let bucket = More(1, 10, More(2, 20, JustOne(3, 30)))
  let mapped = bucket.map(v => v * 2)
  assert_eq(mapped.find(1), Some(20))
  assert_eq(mapped.find(2), Some(40))
  assert_eq(mapped.find(3), Some(60))
}
