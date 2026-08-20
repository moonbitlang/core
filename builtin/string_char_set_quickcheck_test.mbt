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

// Property-based tests for the character-set paths of `contains_any` and
// `trim`/`trim_start`/`trim_end`: the bitmap and SIMD scans must agree with a
// straightforward character-by-character model, on strings and on views with
// non-zero offsets, for ASCII sets of every size class (SIMD-broadcast,
// bitmap-only, and the non-ASCII fallback).

///|
/// Characters a haystack is built from: mostly ASCII (including every member
/// of the generated sets and both sides of the 0x20 boundary), plus non-ASCII
/// BMP and non-BMP characters so surrogate pairs appear.
fn haystack_char(seed : Int) -> Char {
  match seed & 0xF {
    0 => ' '
    1 => '\t'
    2 => '\n'
    3 => '\r'
    4 => ','
    5 => ';'
    6 => 'z'
    7 => 'a'
    8 => '\u{00}'
    9 => '\u{1F}'
    10 => '\u{7F}'
    11 => '中'
    12 => '😀'
    _ => (0x20 + ((seed >> 4) & 0x3F)).unsafe_to_char()
  }
}

///|
/// Set members: mostly ASCII delimiters; occasionally non-ASCII, which sends
/// the whole set down the fallback path.
fn set_char(seed : Int) -> Char {
  match seed & 0xF {
    0 => ' '
    1 => '\t'
    2 => '\n'
    3 => '\r'
    4 => ','
    5 => ';'
    6 => '/'
    7 => 'z'
    8 => '0'
    9 => '\u{00}'
    10 => '\u{7F}'
    11 => '中'
    12 => '😀'
    _ => 'a'
  }
}

///|
fn chars_to_string(chars : Array[Char]) -> String {
  let buf = StringBuilder(size_hint=chars.length())
  for c in chars {
    buf.write_char(c)
  }
  buf.to_string()
}

///|
fn model_member(chars : String, c : Char) -> Bool {
  for d in chars {
    if c == d {
      return true
    }
  }
  false
}

///|
fn model_contains_any(s : String, chars : String) -> Bool {
  for c in s {
    if model_member(chars, c) {
      return true
    }
  }
  false
}

///|
fn model_trim_start(s : String, chars : String) -> String {
  let arr = s.to_array()
  let mut start = 0
  while start < arr.length() && model_member(chars, arr[start]) {
    start += 1
  }
  chars_to_string(arr[start:].to_owned())
}

///|
fn model_trim_end(s : String, chars : String) -> String {
  let arr = s.to_array()
  let mut end = arr.length()
  while end > 0 && model_member(chars, arr[end - 1]) {
    end -= 1
  }
  chars_to_string(arr[:end].to_owned())
}

///|
/// Embeds `middle` between `prefix`/`suffix` and returns the view covering
/// exactly `middle`, so the scans see non-zero view offsets.
fn embedded_view(
  prefix : String,
  middle : String,
  suffix : String,
) -> StringView {
  let full = prefix + middle + suffix
  full[prefix.length():prefix.length() + middle.length()]
}

///|
test "quickcheck: contains_any agrees with the character model" {
  @quickcheck.check(count=300, (input : (Array[Int], Array[Int])) => {
    let (hay_seeds, set_seeds) = input
    let hay = chars_to_string(hay_seeds.map(haystack_char))
    let set = chars_to_string(set_seeds.map(set_char))
    // The set is passed as a view with non-zero offsets, so a scan that read
    // beyond the set view would see the sentinel characters instead.
    let set_view = embedded_view("Q", set, "Q")
    let expected = model_contains_any(hay, set)
    guard hay.contains_any(chars=set_view) == expected else { return false }
    // The same scan through a haystack view with non-zero offsets.
    embedded_view("ab", hay, "yz").contains_any(chars=set_view) == expected
  })
}

///|
test "quickcheck: trims agree with the character model" {
  @quickcheck.check(count=300, (input : (Array[Int], Array[Int])) => {
    let (hay_seeds, set_seeds) = input
    let hay = chars_to_string(hay_seeds.map(haystack_char))
    let set = chars_to_string(set_seeds.map(set_char))
    let view = embedded_view(" 😀", hay, "😀 ")
    let set_view = embedded_view("Q", set, "Q")
    guard view.trim_start(chars=set_view).to_owned() ==
      model_trim_start(hay, set) else {
      return false
    }
    guard view.trim_end(chars=set_view).to_owned() == model_trim_end(hay, set) else {
      return false
    }
    // The fused trim must agree with composing the two one-sided trims.
    view.trim(chars=set_view).to_owned() ==
    model_trim_end(model_trim_start(hay, set), set)
  })
}

///|
/// Exhaustively places a set member at every position of an otherwise clean
/// string for every length spanning several 8-unit SIMD blocks, for a
/// SIMD-broadcast-sized set, a bitmap-only-sized set, and the default
/// whitespace set.
test "char set boundary sweep" {
  let sets = [" \t\n\r", ",;:.!?", "abcdefghij"]
  for set in sets {
    let probe = set[0:1].to_owned()
    for len in 0..<=24 {
      let clean = "x".repeat(len)
      assert_false(clean.contains_any(chars=set))
      assert_eq(clean.trim(chars=set).to_owned(), clean)
      for pos in 0..<len {
        let s = clean[0:pos].to_owned() +
          probe +
          clean[0:len - pos - 1].to_owned()
        assert_true(s.contains_any(chars=set))
      }
    }
  }
  for lead in 0..<=17 {
    for tail in 0..<=17 {
      let s = " ".repeat(lead) + "core" + "\t".repeat(tail)
      assert_eq(s.trim().to_owned(), "core")
      assert_eq(s.trim_start().to_owned(), "core" + "\t".repeat(tail))
      assert_eq(s.trim_end().to_owned(), " ".repeat(lead) + "core")
    }
  }
  for n in 0..<=20 {
    assert_eq(" \t".repeat(n).trim().to_owned(), "")
  }
}

///|
/// An empty set trims and matches nothing — including an empty view whose
/// backing string continues past the view, where an out-of-view read would
/// wrongly treat the backing character as a set member.
test "char set empty set" {
  let empty_view = "b"[0:0]
  let bs = "b".repeat(8) + "x"
  let sb = "x" + "b".repeat(8)
  assert_eq(bs.trim_start(chars=empty_view).to_owned(), bs)
  assert_eq(sb.trim_end(chars=empty_view).to_owned(), sb)
  assert_eq(bs.trim(chars=empty_view).to_owned(), bs)
  assert_false(bs.contains_any(chars=empty_view))
  assert_eq(bs.trim_start(chars="").to_owned(), bs)
  assert_eq(sb.trim_end(chars="").to_owned(), sb)
  assert_eq(bs.trim(chars="").to_owned(), bs)
}

///|
/// A lone surrogate is never a member of an ASCII set, and trimming stops at
/// it without touching it.
test "char set lone surrogates" {
  let lone = String::from_array([(0xD800).unsafe_to_char()])
  let s = "  " + lone + "  "
  assert_false(s.contains_any(chars="az"))
  assert_true(s.contains_any(chars="a "))
  assert_eq(s.trim().to_owned(), lone)
  assert_eq(s.trim_start().to_owned(), lone + "  ")
  assert_eq(s.trim_end().to_owned(), "  " + lone)
}
