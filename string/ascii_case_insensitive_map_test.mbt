// Copyright 2026 International Digital Economy Academy
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

// ----------------------------------------------------------------------------
// Sketch: ASCII case-insensitive map built on top of `String::to_lower`.
//
// This is intentionally NOT a public API. It lives in a test file to
// demonstrate one way to layer ASCII-case-insensitive lookup on top of the
// existing `Map[String, V]` and the new `*_ignore_ascii_case` primitives,
// without paying an O(n) scan per lookup.
//
// Design notes
// ------------
// - Keys are folded to ASCII lowercase at insert time and at lookup time. The
//   wrapper stores the *original* (un-folded) key alongside the value so
//   iteration can return what the caller actually inserted.
// - Lookups stay O(1) because the underlying `Map` hashes the folded form.
// - Equality of two keys (after fold) is verified to agree with
//   `String::equal_ignore_ascii_case`, which is the contract this map relies
//   on. If that contract ever broke, the cross-check tests below would fail.
// - This sketch uses `String::to_lower` for folding because, as of writing,
//   `String::to_lower` is itself ASCII-only in moonbitlang/core (see the
//   TODO in builtin/string.mbt). If `to_lower` is ever upgraded to full
//   Unicode case folding, this sketch would silently change semantics — a
//   real production version should fold using a dedicated ASCII-only helper.
// ----------------------------------------------------------------------------

///|
priv struct AsciiCaseInsensitiveMap[V] {
  // folded_key -> (original_key, value)
  inner : Map[String, (String, V)]
}

///|
fn[V] AsciiCaseInsensitiveMap::new() -> AsciiCaseInsensitiveMap[V] {
  { inner: Map::new() }
}

///|
fn[V] AsciiCaseInsensitiveMap::set(
  self : AsciiCaseInsensitiveMap[V],
  key : String,
  value : V,
) -> Unit {
  self.inner[key.to_lower()] = (key, value)
}

///|
fn[V] AsciiCaseInsensitiveMap::get(
  self : AsciiCaseInsensitiveMap[V],
  key : String,
) -> V? {
  match self.inner.get(key.to_lower()) {
    Some((_, v)) => Some(v)
    None => None
  }
}

///|
fn[V] AsciiCaseInsensitiveMap::contains(
  self : AsciiCaseInsensitiveMap[V],
  key : String,
) -> Bool {
  self.inner.contains(key.to_lower())
}

///|
fn[V] AsciiCaseInsensitiveMap::length(self : AsciiCaseInsensitiveMap[V]) -> Int {
  self.inner.length()
}

///|
fn[V] AsciiCaseInsensitiveMap::remove(
  self : AsciiCaseInsensitiveMap[V],
  key : String,
) -> Unit {
  self.inner.remove(key.to_lower())
}

///|
test "AsciiCaseInsensitiveMap basic insert and lookup" {
  let m : AsciiCaseInsensitiveMap[Int] = AsciiCaseInsensitiveMap::new()
  m.set("Content-Type", 1)
  m.set("Content-Length", 2)
  m.set("Host", 3)

  // All three keys present, regardless of casing on the lookup side
  inspect(m.length(), content="3")
  inspect(m.get("Content-Type"), content="Some(1)")
  inspect(m.get("content-type"), content="Some(1)")
  inspect(m.get("CONTENT-TYPE"), content="Some(1)")
  inspect(m.get("cOnTeNt-TyPe"), content="Some(1)")
  inspect(m.get("Content-Length"), content="Some(2)")
  inspect(m.get("CONTENT-LENGTH"), content="Some(2)")
  inspect(m.get("HOST"), content="Some(3)")

  // Misses
  inspect(m.get("Accept"), content="None")
  inspect(m.get("Content"), content="None")
  inspect(m.contains("CONTENT-TYPE"), content="true")
  inspect(m.contains("Accept"), content="false")
}

///|
test "AsciiCaseInsensitiveMap update overrides existing entry under any casing" {
  let m : AsciiCaseInsensitiveMap[String] = AsciiCaseInsensitiveMap::new()
  m.set("Accept", "first")
  m.set("ACCEPT", "second")
  m.set("accept", "third")

  // All three inserts collapse to the same folded key, so only one entry exists
  inspect(m.length(), content="1")
  inspect(m.get("Accept"), content="Some(\"third\")")
  inspect(m.get("accept"), content="Some(\"third\")")
  inspect(m.get("ACCEPT"), content="Some(\"third\")")
}

///|
test "AsciiCaseInsensitiveMap remove respects case-insensitivity" {
  let m : AsciiCaseInsensitiveMap[Int] = AsciiCaseInsensitiveMap::new()
  m.set("X-Custom-Header", 42)
  inspect(m.contains("x-custom-header"), content="true")
  m.remove("X-CUSTOM-HEADER")
  inspect(m.contains("X-Custom-Header"), content="false")
  inspect(m.length(), content="0")
}

///|
test "AsciiCaseInsensitiveMap respects ASCII-only fold semantics" {
  // Non-ASCII letters are NOT folded, matching `equal_ignore_ascii_case`.
  let m : AsciiCaseInsensitiveMap[Int] = AsciiCaseInsensitiveMap::new()
  m.set("Ä", 1)
  m.set("ä", 2)
  // Two distinct entries because Ä and ä are different under ASCII fold
  inspect(m.length(), content="2")
  inspect(m.get("Ä"), content="Some(1)")
  inspect(m.get("ä"), content="Some(2)")

  // Mixed ASCII + non-ASCII: ASCII parts fold, non-ASCII parts don't
  let m2 : AsciiCaseInsensitiveMap[Int] = AsciiCaseInsensitiveMap::new()
  m2.set("CaféAU", 1)
  inspect(m2.get("caféau"), content="Some(1)")
  inspect(m2.get("CAFÉAU"), content="None") // É != é
}

///|
test "AsciiCaseInsensitiveMap agrees with equal_ignore_ascii_case" {
  // Contract: two keys hit the same map entry iff they are
  // equal_ignore_ascii_case-equal. This is the critical invariant the map
  // relies on; if it broke, the wrapper would either lose entries or
  // collide incorrectly.
  let key_pairs = [
    ("Content-Type", "content-type"), // ASCII fold
    ("HOST", "host"), // ASCII fold
    ("X-1", "x-1"), // digits unaffected
    ("foo_bar", "FOO_BAR"), // underscore unaffected
    ("Content-Type", "Content-Length"), // genuine difference
    ("Ä", "ä"), // non-ASCII NOT folded
    ("café", "CAFé"), // partial fold
    ("café", "CAFÉ"), // É != é
    ("a🤣", "A🤣"), // surrogate pair preserved
    ("", ""), // empty
    ("", "x"), // empty vs non-empty
  ]
  for pair in key_pairs {
    let (k1, k2) = pair
    let m : AsciiCaseInsensitiveMap[Int] = AsciiCaseInsensitiveMap::new()
    m.set(k1, 1)
    let map_says_same = m.contains(k2)
    let api_says_same = k1.equal_ignore_ascii_case(k2)
    assert_eq(map_says_same, api_says_same)
  }
}
