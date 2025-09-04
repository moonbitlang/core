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
pub suberror Malformed @bytes.View

///|
/// The Unicode Replacement Character, which is used to replace invalid or unrecognized sequences during lossy decoding.
/// https://unicode.org/charts/nameslist/n_FFF0.html
const U_REP = '\u{FFFD}'

///|
pub fn decode(
  bytes : @bytes.View,
  ignore_bom? : Bool = false,
) -> String raise Malformed {
  let bytes = if ignore_bom && bytes is [.. "\xef\xbb\xbf", .. rest] {
    rest
  } else {
    bytes
  }
  let builder = StringBuilder::new(size_hint=bytes.length())
  loop bytes {
    [] => ()
    [0..=0x7F as b, .. rest] => {
      builder.write_char(b.to_int().unsafe_to_char())
      continue rest
    }
    [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest] => {
      let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
    | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest] => {
      let ch = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [
      0xF0 as b0,
      0x90..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF4 as b0,
      0x80..=0x8F as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ] => {
      let ch = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    _ as bytes => raise Malformed(bytes)
  }
  builder.to_string()
}

///|
/// 
/// References : 
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-5/#G40630
pub fn decode_lossy(bytes : @bytes.View, ignore_bom? : Bool = false) -> String {
  let bytes = if ignore_bom && bytes is [.. "\xef\xbb\xbf", .. rest] {
    rest
  } else {
    bytes
  }
  let builder = StringBuilder::new(size_hint=bytes.length())
  loop bytes {
    [] => ()
    [0..=0x7F as b, .. rest] => {
      builder.write_char(b.to_int().unsafe_to_char())
      continue rest
    }
    [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest] => {
      let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
    | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
    | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest] => {
      let ch = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xE0, 0xA0..=0xBF, .. rest]
    | [0xE1..=0xEC, 0x80..=0xBF, .. rest]
    | [0xED, 0x80..=0x9F, .. rest]
    | [0xEE..=0xEF, 0x80..=0xBF, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
    [
      0xF0 as b0,
      0x90..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF1..=0xF3 as b0,
      0x80..=0xBF as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ]
    | [
      0xF4 as b0,
      0x80..=0x8F as b1,
      0x80..=0xBF as b2,
      0x80..=0xBF as b3,
      .. rest,
    ] => {
      let ch = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      builder.write_char(ch.unsafe_to_char())
      continue rest
    }
    [0xF0, 0x90..=0xBF, 0x80..=0xBF, .. rest]
    | [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF, .. rest]
    | [0xF4, 0x80..=0x8F, 0x80..=0xBF, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
    [0xF0, 0x90..=0xBF, .. rest]
    | [0xF1..=0xF3, 0x80..=0xBF, .. rest]
    | [0xF4, 0x80..=0x8F, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
    [_, .. rest] => {
      builder.write_char(U_REP)
      continue rest
    }
  }
  builder.to_string()
}
