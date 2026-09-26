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

// Differential and boundary tests for the SIMD search and in-place patch
// paths of `to_upper` and `to_lower`: every result must agree with a
// code-unit-by-code-unit model, on strings and on views with non-zero
// offsets whose backing string continues past the view.

///|
/// Code units the generated strings are built from: both ASCII letter ranges
/// and their neighbours (`@`, `[`, `` ` ``, `{`), non-ASCII code units whose
/// low byte is an ASCII letter (U+0161, U+FF41, U+8041, U+8061; the last two
/// are also negative as signed 16-bit lanes), surrogate pairs and lone
/// surrogates.
fn case_code_unit(seed : Int) -> UInt16 {
  match seed & 0x1F {
    0 => 'a'
    1 => 'z'
    2 => 'A'
    3 => 'Z'
    4 => '@'
    5 => '['
    6 => '`'
    7 => '{'
    8 => 0x0161
    9 => 0xFF41
    10 => 0x8041
    11 => 0x8061
    12 => 0xD83D
    13 => 0xDE00
    14 => 0xD800
    15 => 0xDC00
    16 => 0
    17 => 0xFFFF
    _ => (0x20 + ((seed >> 5) & 0x5F)).to_uint16()
  }
}

///|
fn case_code_units_to_string(units : Array[UInt16]) -> String {
  String::from_array(units.map(u => u.to_int().unsafe_to_char()))
}

///|
/// Builds a string of at least 40 code units from non-empty seeds (and the
/// empty string from empty seeds), so the SIMD search and patch loops can be
/// reached. The index is mixed into each seed because generated arrays often
/// repeat small values.
fn case_input(seeds : Array[Int]) -> String {
  let units : Array[UInt16] = []
  let n = if seeds.is_empty() {
    0
  } else if seeds.length() > 40 {
    seeds.length()
  } else {
    40
  }
  for i in 0..<n {
    units.push(case_code_unit(seeds[i % seeds.length()] ^ (i * 0x9E37)))
  }
  case_code_units_to_string(units)
}

///|
fn model_case_map(
  s : StringView,
  first : UInt16,
  last : UInt16,
  delta : Int,
) -> String {
  let units : Array[UInt16] = []
  for u in s.code_units() {
    units.push(
      if u >= first && u <= last {
        (u.to_int() + delta).to_uint16()
      } else {
        u
      },
    )
  }
  case_code_units_to_string(units)
}

///|
fn model_to_upper(s : StringView) -> String {
  model_case_map(s, 'a', 'z', -32)
}

///|
fn model_to_lower(s : StringView) -> String {
  model_case_map(s, 'A', 'Z', 32)
}

///|
test "quickcheck: to_upper and to_lower agree with the code-unit model" {
  @quickcheck.check(count=300, (input : (Array[Int], Int, Int)) => {
    let (seeds, lead, trail) = input
    let s = case_input(seeds)
    guard s.to_upper() == model_to_upper(s) else { return false }
    guard s.to_lower() == model_to_lower(s) else { return false }
    // The same conversions through a view with non-zero offsets. The padding
    // contains letters of both cases, so a scan or patch that crossed the
    // view bounds would change the result.
    let pad = "aZ"
    let lead_pad = pad.repeat((lead & 0xFFFF) % 9)
    let trail_pad = pad.repeat((trail & 0xFFFF) % 9)
    let full = lead_pad + s + trail_pad
    let view = full[lead_pad.length():lead_pad.length() + s.length()]
    guard view.to_upper() == model_to_upper(s) else { return false }
    view.to_lower() == model_to_lower(s)
  })
}

///|
/// Places a single lowercase letter at every position of every length up to
/// 40 code units, inside views at several offsets whose backing string has
/// lowercase letters on both sides of the view.
test "to_upper boundary sweep over view offsets" {
  for offset in [0, 1, 3, 7, 8] {
    for len in 0..<=40 {
      let upper = "X".repeat(len)
      let lead = "b".repeat(offset)
      let trail = "b".repeat(9)
      let clean = (lead + upper + trail)[offset:offset + len]
      assert_true(clean.to_upper() == upper)
      for pos in 0..<len {
        let middle = "X".repeat(pos) + "a" + "X".repeat(len - pos - 1)
        let view = (lead + middle + trail)[offset:offset + len]
        assert_eq(
          view.to_upper().to_owned(),
          upper[0:pos].to_owned() + "A" + upper[pos + 1:].to_owned(),
        )
      }
    }
  }
}

///|
/// Non-ASCII code units whose low byte is an ASCII lowercase letter, or whose
/// high bit is set, must never be converted, at any lane position.
test "to_upper leaves non-ASCII code units unchanged" {
  let tricky = String::from_array([
    (0x0161).unsafe_to_char(),
    (0xFF41).unsafe_to_char(),
    (0x8061).unsafe_to_char(),
    (0xD800).unsafe_to_char(),
  ])
  for pos in 0..<40 {
    let base = "`{".repeat(20)
    let s = base[0:pos].to_owned() + tricky + base[pos:].to_owned()
    assert_true(physical_equal(s.to_upper(), s))
    let with_letter = s + "q"
    assert_eq(with_letter.to_upper(), s + "Q")
    let leading_letter = "q" + s
    assert_eq(leading_letter.to_upper(), "Q" + s)
  }
}

///|
/// Surrogate pairs straddling every 8-unit block boundary are copied intact
/// while the letters around them are converted.
test "to_upper surrogate pairs at block boundaries" {
  for pos in 0..<40 {
    let s = "x".repeat(pos) + "😀" + "y".repeat(40 - pos)
    assert_eq(s.to_upper(), "X".repeat(pos) + "😀" + "Y".repeat(40 - pos))
    let view = ("z" + s + "z")[1:s.length() + 1]
    assert_eq(
      view.to_upper().to_owned(),
      "X".repeat(pos) + "😀" + "Y".repeat(40 - pos),
    )
  }
}

///|
test "to_upper returns the input when nothing changes" {
  let long = "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG. ".repeat(4)
  assert_true(physical_equal(long.to_upper(), long))
  let view = ("a" + long + "a")[1:long.length() + 1]
  let converted = view.to_upper()
  assert_true(physical_equal(converted.data(), view.data()))
  assert_eq(converted.start_offset(), 1)
}
