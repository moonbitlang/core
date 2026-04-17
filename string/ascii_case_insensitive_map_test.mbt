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
// Sketch: ASCII case-insensitive key wrapper for `Map`.
//
// Instead of wrapping the whole Map, we wrap only the *key* type by providing
// custom `Hash` and `Eq` that fold ASCII letters.  Then `Map[AsciiCaseInsensitiveString, V]`
// gives us O(1) case-insensitive lookup for free.
//
// This is the same pattern as Rust's `unicase::Ascii` or .NET's
// `StringComparer.OrdinalIgnoreCase`.
//
// This sketch is intentionally private; it lives in a test file to verify the
// design works.
// ----------------------------------------------------------------------------

///|
/// A newtype wrapper around `String` whose `Hash` and `Eq` implementations fold
/// ASCII uppercase letters to lowercase. Use as `Map[AsciiCaseInsensitiveString, V]`
/// to get an O(1) ASCII-case-insensitive hash map with no additional wrapper code.
priv struct AsciiCaseInsensitiveString {
  raw : String
}

///|
fn AsciiCaseInsensitiveString::new(s : String) -> AsciiCaseInsensitiveString {
  { raw: s }
}

///|
/// Hash the folded (ASCII-lowered) code units so that "Foo" and "FOO" land in
/// the same bucket.
impl Hash for AsciiCaseInsensitiveString with hash_combine(self, hasher) {
  let s = self.raw
  for i in 0..<s.length() {
    let mut c = s.unsafe_get(i)
    // Fold ASCII 'A'..'Z' (0x41..0x5A) to 'a'..'z' (0x61..0x7A).
    if c >= ('A' : UInt16) && c <= ('Z' : UInt16) {
      c = c + (32 : UInt16)
    }
    hasher.combine_uint(c.to_int().reinterpret_as_uint())
  }
}

///|
/// Two keys are equal iff they are equal under ASCII case folding.
impl Eq for AsciiCaseInsensitiveString with equal(self, other) {
  self.raw.equal_ignore_ascii_case(other.raw)
}

// ---------------------------------------------------------------------------
// Tests — the point of this file.
// ---------------------------------------------------------------------------

///|
test "AsciiCaseInsensitiveString basic insert and lookup" {
  let m : Map[AsciiCaseInsensitiveString, Int] = {}
  let key = AsciiCaseInsensitiveString::new
  m[key("Content-Type")] = 1
  m[key("Content-Length")] = 2
  m[key("Host")] = 3

  // All three keys present, regardless of lookup casing
  inspect(m.length(), content="3")
  debug_inspect(m.get(key("Content-Type")), content="Some(1)")
  debug_inspect(m.get(key("content-type")), content="Some(1)")
  debug_inspect(m.get(key("CONTENT-TYPE")), content="Some(1)")
  debug_inspect(m.get(key("cOnTeNt-TyPe")), content="Some(1)")
  debug_inspect(m.get(key("Content-Length")), content="Some(2)")
  debug_inspect(m.get(key("CONTENT-LENGTH")), content="Some(2)")
  debug_inspect(m.get(key("HOST")), content="Some(3)")

  // Misses
  debug_inspect(m.get(key("Accept")), content="None")
  debug_inspect(m.get(key("Content")), content="None")
  inspect(m.contains(key("CONTENT-TYPE")), content="true")
  inspect(m.contains(key("Accept")), content="false")
}

///|
test "AsciiCaseInsensitiveString update overrides under any casing" {
  let m : Map[AsciiCaseInsensitiveString, String] = {}
  let key = AsciiCaseInsensitiveString::new
  m[key("Accept")] = "first"
  m[key("ACCEPT")] = "second"
  m[key("accept")] = "third"

  // All three inserts collapse to one entry
  inspect(m.length(), content="1")
  debug_inspect(m.get(key("Accept")), content="Some(\"third\")")
  debug_inspect(m.get(key("accept")), content="Some(\"third\")")
  debug_inspect(m.get(key("ACCEPT")), content="Some(\"third\")")
}

///|
test "AsciiCaseInsensitiveString remove respects case-insensitivity" {
  let m : Map[AsciiCaseInsensitiveString, Int] = {}
  let key = AsciiCaseInsensitiveString::new
  m[key("X-Custom-Header")] = 42
  inspect(m.contains(key("x-custom-header")), content="true")
  m.remove(key("X-CUSTOM-HEADER"))
  inspect(m.contains(key("X-Custom-Header")), content="false")
  inspect(m.length(), content="0")
}

///|
test "AsciiCaseInsensitiveString respects ASCII-only fold semantics" {
  let m : Map[AsciiCaseInsensitiveString, Int] = {}
  let key = AsciiCaseInsensitiveString::new

  // Non-ASCII letters are NOT folded, matching `equal_ignore_ascii_case`.
  m[key("Ä")] = 1
  m[key("ä")] = 2
  // Two distinct entries
  inspect(m.length(), content="2")
  debug_inspect(m.get(key("Ä")), content="Some(1)")
  debug_inspect(m.get(key("ä")), content="Some(2)")

  // Mixed ASCII + non-ASCII: ASCII parts fold, non-ASCII parts don't
  let m2 : Map[AsciiCaseInsensitiveString, Int] = {}
  m2[key("CaféAU")] = 1
  debug_inspect(m2.get(key("caféau")), content="Some(1)")
  debug_inspect(m2.get(key("CAFÉAU")), content="None") // É != é
}

///|
test "AsciiCaseInsensitiveString agrees with equal_ignore_ascii_case" {
  // Contract: two keys collide in the map iff they are
  // equal_ignore_ascii_case-equal.
  let key = AsciiCaseInsensitiveString::new
  let key_pairs = [
    ("Content-Type", "content-type"),
    ("HOST", "host"),
    ("X-1", "x-1"),
    ("foo_bar", "FOO_BAR"),
    ("Content-Type", "Content-Length"),
    ("Ä", "ä"),
    ("café", "CAFé"),
    ("café", "CAFÉ"),
    ("a🤣", "A🤣"),
    ("", ""),
    ("", "x"),
  ]
  for pair in key_pairs {
    let (k1, k2) = pair
    let m : Map[AsciiCaseInsensitiveString, Int] = {}
    m[key(k1)] = 1
    let map_says_same = m.contains(key(k2))
    let api_says_same = k1.equal_ignore_ascii_case(k2)
    assert_eq(map_says_same, api_says_same)
  }
}
