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

// `String::escape` / `StringView::escape` against a per-code-unit model. On
// native and wasm, while 16 or more code units remain, the search for the
// next escape checks the first unit and, if that unit does not need escaping,
// continues with the SIMD scan. The sweeps below cover every lane of several
// blocks, the scalar tail, runs of consecutive escapes, views at non-zero
// offsets, and lone surrogates next to block boundaries.
//
// Code units are held in `Array[Int]` rather than `Array[UInt16]`: release
// builds of moonc 0.10.14 miscompile element stores into `Array[UInt16]`.

///|
/// Builds a string from raw UTF-16 code units; lone surrogates stay lone.
fn escape_units_to_string(units : ArrayView[Int]) -> String {
  let buf = StringBuilder(size_hint=units.length())
  for u in units {
    buf.write_char(u.unsafe_to_char())
  }
  buf.to_string()
}

///|
fn escape_string_units(s : StringView) -> Array[Int] {
  let units = []
  for i in 0..<s.length() {
    units.push(s.unsafe_get(i).to_int())
  }
  units
}

///|
fn escape_push_ascii(out : Array[Int], s : String) -> Unit {
  for i in 0..<s.length() {
    out.push(s.unsafe_get(i).to_int())
  }
}

///|
/// Reference model of the escape rules, one code unit at a time.
fn escape_model(units : ArrayView[Int], quote : Bool) -> Array[Int] {
  let out : Array[Int] = []
  if quote {
    out.push(0x22)
  }
  let hex = "0123456789abcdef"
  for u in units {
    match u {
      0x22 => escape_push_ascii(out, "\\\"")
      0x5C => escape_push_ascii(out, "\\\\")
      0x0A => escape_push_ascii(out, "\\n")
      0x0D => escape_push_ascii(out, "\\r")
      0x08 => escape_push_ascii(out, "\\b")
      0x09 => escape_push_ascii(out, "\\t")
      c if c < 0x20 => {
        escape_push_ascii(out, "\\u{")
        out.push(hex.unsafe_get(c >> 4).to_int())
        out.push(hex.unsafe_get(c & 0xF).to_int())
        out.push(0x7D)
      }
      _ => out.push(u)
    }
  }
  if quote {
    out.push(0x22)
  }
  out
}

///|
/// Checks `String::escape` and `StringView::escape` (both `quote` settings)
/// on `units`, and on a view of `units` embedded between `prefix` and
/// `suffix`.
fn escape_check(
  units : Array[Int],
  prefix : Array[Int],
  suffix : Array[Int],
) -> Unit raise {
  let s = escape_units_to_string(units)
  let full = escape_units_to_string([..prefix, ..units, ..suffix])
  let view = full.view(
    start_offset=prefix.length(),
    end_offset=prefix.length() + units.length(),
  )
  for quote in [true, false] {
    let expected = escape_model(units, quote)
    assert_eq(escape_string_units(s.escape(quote~)), expected)
    assert_eq(escape_string_units(s[:].escape(quote~)), expected)
    assert_eq(escape_string_units(view.escape(quote~)), expected)
  }
}

///|
/// The quote, the backslash, every control character with a named escape and
/// a sample of the `\u{hex}` ones, plus unescaped neighbours of escaped values
/// (`0x20`, `0x21`, `0x23`, `0x5B`, `0x5D`, `0x7F`). The test
/// "every code unit below 0x80" covers the remaining control characters.
let escape_probe_units : Array[Int] = [
  0x22, 0x5C, 0x0A, 0x0D, 0x08, 0x09, 0x00, 0x01, 0x07, 0x0B, 0x0C, 0x1B, 0x1F, 0x20,
  0x21, 0x23, 0x5B, 0x5D, 0x7F,
]

///|
test "escape: probe unit at every position" {
  // Prefix and suffix start with escaped units, so a scan that treated units
  // outside the view as part of it would produce different output.
  let prefix = [0x22, 0x0A, 0x70]
  let suffix = [0x5C, 0x01]
  for probe in escape_probe_units {
    for len in [1, 7, 8, 9, 15, 16, 17, 24, 31, 32, 33, 41] {
      for pos in 0..<len {
        let units = Array::make(len, 0x61)
        units[pos] = probe
        escape_check(units, prefix, suffix)
      }
    }
  }
}

///|
test "escape: two escaped units in one string" {
  // A second escape after the first exercises the scan resuming mid-block.
  for first in 0..<40 {
    for second in (first + 1)..<41 {
      let units = Array::make(41, 0x78)
      units[first] = 0x22
      units[second] = 0x1F
      escape_check(units, [], [])
    }
  }
}

///|
test "escape: views at every start offset inside a larger buffer" {
  let backing = Array::makei(96, i => {
    match i % 11 {
      0 => 0x22
      3 => 0x5C
      5 => 0x09
      7 => 0x02
      _ => 0x41 + i % 26
    }
  })
  let full = escape_units_to_string(backing)
  for start in 0..<24 {
    for end in start..<=backing.length() {
      let expected = escape_model(backing[start:end], true)
      let view = full.view(start_offset=start, end_offset=end)
      assert_eq(escape_string_units(view.escape()), expected)
    }
  }
}

///|
test "escape: surrogates around block boundaries are copied verbatim" {
  let pieces = [
    [0xD83D, 0xDE00], // a valid pair
    [0xD800], // lone leading
    [0xDC00], // lone trailing
    [0xDFFF, 0xD800], // reversed pair
    [0xFFFF],
  ]
  for piece in pieces {
    for len in [16, 17, 23, 24, 25, 40] {
      for pos in 0..<=(len - piece.length()) {
        let units = Array::make(len, 0x62)
        for k, u in piece {
          units[pos + k] = u
        }
        // When the view starts with a trailing or ends with a leading surrogate,
        // its boundary splits a pair of the backing string.
        escape_check(units, [0xD83D], [0xDE00])
        // An escaped unit right after the surrogate(s).
        let after = pos + piece.length()
        if after < len {
          units[after] = 0x5C
          escape_check(units, [0xDC00], [0xD800])
        }
        // An escaped unit right before the surrogate(s).
        if pos > 0 {
          units[pos - 1] = 0x0A
          escape_check(units, [], [])
        }
      }
    }
  }
}

///|
test "escape: every code unit below 0x80" {
  // Named escapes and `\u{hex}` for each control character, verbatim ASCII
  // otherwise, in a string long enough for the vector scan.
  escape_check(Array::makei(0x80, i => i), [], [])
  inspect(
    escape_units_to_string([
      0x00, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0D, 0x1F, 0x22, 0x5C, 0x20, 0x41, 0x42,
      0x43, 0x44, 0x45,
    ]).escape(),
    content=(
      #|"\u{00}\u{07}\b\t\n\u{0b}\r\u{1f}\"\\ ABCDE"
    ),
  )
}

///|
test "escape: long strings" {
  let plain = "The quick brown fox jumps over the lazy dog. ".repeat(100)
  inspect(plain.escape() == "\"" + plain + "\"", content="true")
  let dense = "ab\"c".repeat(1024)
  inspect(dense.escape(quote=false) == "ab\\\"c".repeat(1024), content="true")
  let all_escapes = "\n".repeat(100)
  inspect(all_escapes.escape(quote=false) == "\\n".repeat(100), content="true")
}

///|
/// Maps a seed to a code unit: escaped units, near misses, non-ASCII BMP, and
/// surrogate halves (paired or not, depending on neighbours).
fn escape_seed_unit(seed : Int) -> Int {
  match seed & 0xF {
    0 => 0x22
    1 => 0x5C
    2 => 0x0A
    3 => 0x09
    4 => 0x00
    5 => 0x1F
    6 => 0x20
    7 => 0x7F
    8 => 0x4E2D
    9 => 0xD83D
    10 => 0xDE00
    _ => 0x21 + ((seed >> 4) & 0x3F)
  }
}

///|
test "quickcheck: escape agrees with the per-code-unit model" {
  @quickcheck.check(count=300, (input : (Array[Int], Int, Int)) => {
    let (seeds, pre, post) = input
    // Each seed yields four code units, so most inputs reach the vector loop.
    let units = []
    for seed in seeds {
      for k in 0..<4 {
        units.push(escape_seed_unit(seed >> (k * 7)))
      }
    }
    let prefix = Array::make(pre & 7, 0x22)
    let suffix = Array::make(post & 7, 0x0A)
    escape_check(units, prefix, suffix) catch {
      _ => return false
    }
    true
  })
}
