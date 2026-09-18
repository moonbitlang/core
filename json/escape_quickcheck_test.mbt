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

// Property-based tests for `Json::stringify`: string escaping must agree
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
/// Per-code-unit model of escaping, written directly from the JSON string
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
test "quickcheck: stringify escaping matches the per-code-unit model" {
  fn actual(str : String, escape_slash : Bool) -> String {
    let quoted = Json::string(str).stringify(escape_slash~)
    quoted[1:quoted.length() - 1].to_owned()
  }
  @quickcheck.check(count=300, (input : (Array[Int], Bool)) => {
    let (seeds, escape_slash) = input
    let str = adversarial_string(seeds, allow_surrogates=true)
    actual(str, escape_slash) == model_escape(str, escape_slash)
  })
  @quickcheck.check(count=300, (input : (String, Bool)) => {
    let (str, escape_slash) = input
    actual(str, escape_slash) == model_escape(str, escape_slash)
  })
}

///|
/// Roundtrip through the real parser, whose string lexer is an independent
/// implementation of the same grammar. Surrogate halves are excluded because
/// well-formed MoonBit strings contain no unpaired surrogates.
test "quickcheck: stringify/parse roundtrip on adversarial strings" {
  @quickcheck.check(count=300, (input : (Array[Int], Bool)) => {
    let (seeds, escape_slash) = input
    let json = Json(adversarial_string(seeds, allow_surrogates=false))
    @json.parse(json.stringify(escape_slash~)) == json
  })
}
