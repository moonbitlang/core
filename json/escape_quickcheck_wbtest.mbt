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

// Property-based tests for the `Json::stringify` escape fast path: the SIMD
// `need_escape` must agree with the scalar reference, and `escape` must agree
// with a straightforward per-code-unit model and with the real parser,
// including at SIMD block boundaries and on surrogate halves.

///|
/// Builds a string whose code units are biased toward everything the escaper
/// branches on: quotes, backslashes, slashes, control characters, both sides
/// of the 0x20 boundary, and surrogate halves (whose high bit set exercises
/// the unsigned SIMD comparisons). With `allow_surrogates=false` the
/// surrogate range is remapped so the string is well-formed UTF-16.
fn adversarial_string(seeds : Array[Int], allow_surrogates~ : Bool) -> String {
  let buf = StringBuilder(size_hint=seeds.length())
  for seed in seeds {
    let code : UInt16 = match seed & 0xF {
      0 => '"'
      1 => '\\'
      2 => '/'
      3 => '\n'
      4 => 0x1F
      5 => ' '
      6 => 0x0C
      7 => 0xD800
      8 => 0xDFFF
      9 => 0xFFFF
      10 => 'a'
      _ => ((seed >> 4) & 0xFFFF).to_uint16()
    }
    let code = if !allow_surrogates && code is (0xD800..=0xDFFF) {
      code ^ 0x2000
    } else {
      code
    }
    buf.write_char(code.unsafe_to_char())
  }
  buf.to_string()
}

///|
/// Per-code-unit model of `escape`, written directly from the JSON string
/// grammar with no fast path and no SIMD.
fn model_escape(str : String, escape_slash : Bool) -> String {
  let buf = StringBuilder(size_hint=str.length())
  for code in str.code_units() {
    match code.to_int() {
      0x22 => buf.write_string("\\\"")
      0x5C => buf.write_string("\\\\")
      0x2F => buf.write_string(if escape_slash { "\\/" } else { "/" })
      0x08 => buf.write_string("\\b")
      0x09 => buf.write_string("\\t")
      0x0A => buf.write_string("\\n")
      0x0C => buf.write_string("\\f")
      0x0D => buf.write_string("\\r")
      c =>
        if c < 0x20 {
          buf.write_string("\\u00")
          buf.write_string(c.to_byte().to_hex())
        } else {
          buf.write_char(code.unsafe_to_char())
        }
    }
  }
  buf.to_string()
}

///|
test "quickcheck: need_escape agrees with the scalar reference" {
  @quickcheck.check(count=300, (input : (Array[Int], Bool)) => {
    let (seeds, escape_slash) = input
    let str = adversarial_string(seeds, allow_surrogates=true)
    need_escape(str, escape_slash) ==
    need_escape_scalar(str, escape_slash, 0, str.length())
  })
  // Also over ordinary ASCII-biased Unicode strings, which cover other
  // lengths and multi-code-unit characters.
  @quickcheck.check(count=300, (input : (String, Bool)) => {
    let (str, escape_slash) = input
    need_escape(str, escape_slash) ==
    need_escape_scalar(str, escape_slash, 0, str.length())
  })
}

///|
test "quickcheck: escape matches the per-code-unit model" {
  @quickcheck.check(count=300, (input : (Array[Int], Bool)) => {
    let (seeds, escape_slash) = input
    let str = adversarial_string(seeds, allow_surrogates=true)
    guard escape(str, escape_slash~) == model_escape(str, escape_slash) else {
      return false
    }
    // The no-copy fast path must fire exactly when nothing is escapable.
    (escape(str, escape_slash~) == str) ==
    !need_escape_scalar(str, escape_slash, 0, str.length())
  })
  @quickcheck.check(count=300, (input : (String, Bool)) => {
    let (str, escape_slash) = input
    escape(str, escape_slash~) == model_escape(str, escape_slash)
  })
}

///|
/// Roundtrip through the real parser, whose string lexer is an independent
/// implementation of the same grammar. Surrogate halves are excluded because
/// well-formed MoonBit strings contain no unpaired surrogates.
test "quickcheck: stringify/parse roundtrip on adversarial strings" {
  @quickcheck.check(count=300, (input : (Array[Int], Bool)) => {
    let (seeds, escape_slash) = input
    let json = Json::string(adversarial_string(seeds, allow_surrogates=false))
    parse(json.stringify(escape_slash~)) == json
  })
}

///|
/// Exhaustively places each escapable code unit at every position of an
/// otherwise clean string, for every length spanning several 8-unit SIMD
/// blocks, so block starts, block interiors, and the scalar tail are all
/// covered for both `escape_slash` values.
test "need_escape boundary sweep" {
  let specials : Array[UInt16] = ['"', '\\', '\n', 0x00, 0x1F]
  fn place(len : Int, pos : Int, special : UInt16) -> String {
    let buf = StringBuilder(size_hint=len)
    for i in 0..<len {
      if i == pos {
        buf.write_char(special.unsafe_to_char())
      } else {
        buf.write_char('a')
      }
    }
    buf.to_string()
  }

  for len in 0..<=24 {
    let clean = "a".repeat(len)
    assert_false(need_escape(clean, false))
    assert_false(need_escape(clean, true))
    for pos in 0..<len {
      for special in specials {
        assert_true(need_escape(place(len, pos, special), false))
        assert_true(need_escape(place(len, pos, special), true))
      }
      let with_slash = place(len, pos, '/')
      assert_false(need_escape(with_slash, false))
      assert_true(need_escape(with_slash, true))
    }
  }
}
