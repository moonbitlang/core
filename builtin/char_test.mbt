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

///|
priv enum H {
  A(Char)
} derive(Debug)

///|
test "char nested" {
  debug_inspect(H::A('中'), content="A('中')")
  debug_inspect(H::A('\b'), content="A('\\b')")
  debug_inspect(H::A('\r'), content="A('\\r')")
  debug_inspect(H::A('\n'), content="A('\\n')")
  debug_inspect(H::A('\t'), content="A('\\t')")
  debug_inspect(H::A('\u0000'), content="A('\\u{00}')")
  debug_inspect(H::A('\u0001'), content="A('\\u{01}')")
  debug_inspect(H::A('\u0002'), content="A('\\u{02}')")
  // emoji
  debug_inspect(H::A('🚀'), content="A('🚀')")
}

///|
test "char show" {
  @test.assert_eq('\b'.to_string(), "\u0008")
  @test.assert_eq('\b'.to_string(), "\u{8}")
  inspect('\b', content="\u{8}")
  @test.assert_eq('\r'.to_string(), "\u000d")
  inspect('\r', content="\u{d}")
  @test.assert_eq('\n'.to_string(), "\u000a")
  inspect('\n', content="\u{a}")
  @test.assert_eq('\t'.to_string(), "\u0009")
  inspect('\t', content="\u{9}")
  @test.assert_eq('\u0000'.to_string(), "\u0000")
  @test.assert_eq('\u0001'.to_string(), "\u0001")
  @test.assert_eq('\u0002'.to_string(), "\u0002")
  @test.assert_eq('\b'.to_string().escape(), "\"\\b\"")
  inspect('中', content="中")
}

///|
test "char ascii classification" {
  inspect('A'.is_ascii(), content="true")
  inspect('Z'.is_ascii_alphabetic(), content="true")
  inspect('\u{00}'.is_ascii_control(), content="true")
  inspect('5'.is_ascii_digit(), content="true")
  inspect('!'.is_ascii_graphic(), content="true")
  inspect('f'.is_ascii_hexdigit(), content="true")
  inspect('g'.is_ascii_hexdigit(), content="false")
  inspect('a'.is_ascii_lowercase(), content="true")
  inspect('7'.is_ascii_octdigit(), content="true")
  inspect('!'.is_ascii_punctuation(), content="true")
  inspect('A'.is_ascii_uppercase(), content="true")
  inspect(' '.is_ascii_whitespace(), content="true")
}

///|
test "char digit and whitespace" {
  inspect('9'.is_digit(10U), content="true")
  inspect('a'.is_digit(16U), content="true")
  inspect('\u{00A0}'.is_whitespace(), content="true")
  inspect('9'.is_numeric(), content="true")
}

///|
test "char printable and ascii case" {
  inspect('A'.to_ascii_lowercase(), content="a")
  inspect('b'.to_ascii_uppercase(), content="B")
  inspect((0xD800).unsafe_to_char().is_printable(), content="false")
  inspect('\u{2028}'.is_printable(), content="false")
}

///|
test "Char::is_numeric at the edges of its number ranges" {
  // Each probe is paired with its Unicode 16.0 general category; the result
  // should be true exactly for Nd, Nl and No. The probes are the endpoints of
  // each over- or under-covered range and the neighbours just outside each
  // corrected range.
  // BUG: U+07CA, U+07F9, U+2183, U+2184, U+16D80, U+16E7F, U+1D2D4, U+1D2DF,
  // U+1ECAC, U+1ECB0 and U+1ED2E should be false, and U+109D2 and U+109FF
  // should be true.
  let probes : Array[(Char, String)] = [
    ('\u{07C9}', "Nd"),
    ('\u{07CA}', "Lo"),
    ('\u{07F9}', "Po"),
    ('\u{07FA}', "Lm"),
    ('\u{2182}', "Nl"),
    ('\u{2183}', "Lu"),
    ('\u{2184}', "Ll"),
    ('\u{2185}', "Nl"),
    ('\u{109CF}', "No"),
    ('\u{109D1}', "Cn"),
    ('\u{109D2}', "No"),
    ('\u{109FF}', "No"),
    ('\u{10A00}', "Lo"),
    ('\u{16D79}', "Nd"),
    ('\u{16D80}', "Cn"),
    ('\u{16E7F}', "Ll"),
    ('\u{16E80}', "No"),
    ('\u{16E96}', "No"),
    ('\u{16E97}', "Po"),
    ('\u{1D2D3}', "No"),
    ('\u{1D2D4}', "Cn"),
    ('\u{1D2DF}', "Cn"),
    ('\u{1D2E0}', "No"),
    ('\u{1ECAB}', "No"),
    ('\u{1ECAC}', "So"),
    ('\u{1ECAD}', "No"),
    ('\u{1ECAF}', "No"),
    ('\u{1ECB0}', "Sc"),
    ('\u{1ECB1}', "No"),
    ('\u{1ED2D}', "No"),
    ('\u{1ED2E}', "So"),
    ('\u{1ED2F}', "No"),
  ]
  let lines = probes.map(p => {
    let (c, category) = p
    "U+\{c.to_int().to_string(radix=16)} \{category} \{c.is_numeric()}"
  })
  inspect(
    lines.join("\n"),
    content=(
      #|U+7c9 Nd true
      #|U+7ca Lo true
      #|U+7f9 Po true
      #|U+7fa Lm false
      #|U+2182 Nl true
      #|U+2183 Lu true
      #|U+2184 Ll true
      #|U+2185 Nl true
      #|U+109cf No true
      #|U+109d1 Cn false
      #|U+109d2 No false
      #|U+109ff No false
      #|U+10a00 Lo false
      #|U+16d79 Nd true
      #|U+16d80 Cn true
      #|U+16e7f Ll true
      #|U+16e80 No true
      #|U+16e96 No true
      #|U+16e97 Po false
      #|U+1d2d3 No true
      #|U+1d2d4 Cn true
      #|U+1d2df Cn true
      #|U+1d2e0 No true
      #|U+1ecab No true
      #|U+1ecac So true
      #|U+1ecad No true
      #|U+1ecaf No true
      #|U+1ecb0 Sc true
      #|U+1ecb1 No true
      #|U+1ed2d No true
      #|U+1ed2e So true
      #|U+1ed2f No true
    ),
  )
}

///|
test "panic Char::is_digit invalid radix" {
  '0'.is_digit(1U) |> ignore
}
