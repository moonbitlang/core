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
/// Error type `Malformed`.
pub suberror Malformed {
  Malformed(BytesView)
} derive(@debug.Debug)

///|
/// The Unicode Replacement Character, which is used to replace invalid or unrecognized sequences during lossy decoding.
/// https://unicode.org/charts/nameslist/n_FFF0.html
const U_REP = '\u{FFFD}'

///|
/// Decode input bytes/text into structured output.
pub fn decode(
  bytes : BytesView,
  ignore_bom? : Bool = false,
  endianness? : Endian = Little,
) -> String raise Malformed {
  let bytes = if ignore_bom {
    if endianness is Little && bytes is [.. b"\xff\xfe", .. rest] {
      rest
    } else if endianness is Big && bytes is [.. b"\xfe\xff", .. rest] {
      rest
    } else {
      bytes
    }
  } else {
    bytes
  }
  if endianness is Little {
    // check the string
    for x = bytes {
      match x {
        [] => break
        [
          u16le(0xD800..=0xDBFF as higher),
          u16le(0xDC00..=0xDFFF as lower),
          .. rest,
        ] as bytes => {
          if ((higher.reinterpret_as_int() - 0xD800) << 10) +
            (lower.reinterpret_as_int() - 0xDC00) +
            0x10000 >
            0x10FFFF {
            raise Malformed(bytes)
          }
          continue rest
        }
        [u16le(0xD800..=0xDFFF), ..] as bytes => raise Malformed(bytes)
        [u16le(_), .. rest] => continue rest
        _ as bytes => raise Malformed(bytes)
      }
    }
    bytes
    .data()
    .to_unchecked_string(offset=bytes.start_offset(), length=bytes.length())
  } else {
    let string_bytes = FixedArray::make(bytes.length(), b'\x00')
    let mut i = 0
    for x = bytes {
      match x {
        [] => break
        [
          u16be(0xD800..=0xDBFF as higher),
          u16be(0xDC00..=0xDFFF as lower),
          .. rest,
        ] as bytes => {
          if ((higher.reinterpret_as_int() - 0xD800) << 10) +
            (lower.reinterpret_as_int() - 0xDC00) +
            0x10000 >
            0x10FFFF {
            raise Malformed(bytes)
          }
          string_bytes[i] = (higher & 0xFF).to_byte()
          string_bytes[i + 1] = (higher >> 8).to_byte()
          string_bytes[i + 2] = (lower & 0xFF).to_byte()
          string_bytes[i + 3] = (lower >> 8).to_byte()
          i += 4
          continue rest
        }
        [u16be(0xD800..=0xDFFF), ..] as bytes => raise Malformed(bytes)
        [u16be(code_unit), .. rest] => {
          string_bytes[i] = (code_unit & 0xFF).to_byte()
          string_bytes[i + 1] = (code_unit >> 8).to_byte()
          i += 2
          continue rest
        }
        _ as bytes => raise Malformed(bytes)
      }
    }
    string_bytes.unsafe_reinterpret_as_bytes().to_unchecked_string()
  }
}

///|
/// 
/// References : 
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
pub fn decode_lossy(
  bytes : BytesView,
  ignore_bom? : Bool = false,
  endianness? : Endian = Little,
) -> String {
  let bytes = if ignore_bom {
    if endianness is Little && bytes is [.. b"\xff\xfe", .. rest] {
      rest
    } else if endianness is Big && bytes is [.. b"\xfe\xff", .. rest] {
      rest
    } else {
      bytes
    }
  } else {
    bytes
  }
  let builder = StringBuilder::new(size_hint=bytes.length())
  if endianness is Little {
    for x = bytes {
      match x {
        [] => break
        [
          u16le(0xD800..=0xDBFF as higher),
          u16le(0xDC00..=0xDFFF as lower),
          .. rest,
        ] => {
          let ch = ((higher.reinterpret_as_int() - 0xD800) << 10) +
            (lower.reinterpret_as_int() - 0xDC00) +
            0x10000
          if ch > 0x10FFFF {
            builder.write_char(U_REP)
          } else {
            builder.write_char(ch.unsafe_to_char())
          }
          continue rest
        }
        [u16le(0xD800..=0xDFFF), .. rest] => {
          builder.write_char(U_REP)
          continue rest
        }
        [u16le(ch), .. rest] => {
          builder.write_char(ch.reinterpret_as_int().unsafe_to_char())
          continue rest
        }
        _ => {
          builder.write_char(U_REP)
          break
        }
      }
    }
  } else {
    for x = bytes {
      match x {
        [] => break
        [
          u16be(0xD800..=0xDBFF as higher),
          u16be(0xDC00..=0xDFFF as lower),
          .. rest,
        ] => {
          let ch = ((higher.reinterpret_as_int() - 0xD800) << 10) +
            (lower.reinterpret_as_int() - 0xDC00) +
            0x10000
          if ch > 0x10FFFF {
            builder.write_char(U_REP)
          } else {
            builder.write_char(ch.unsafe_to_char())
          }
          continue rest
        }
        [u16be(0xD800..=0xDFFF), .. rest] => {
          builder.write_char(U_REP)
          continue rest
        }
        [u16be(ch), .. rest] => {
          builder.write_char(ch.reinterpret_as_int().unsafe_to_char())
          continue rest
        }
        _ => {
          builder.write_char(U_REP)
          break
        }
      }
    }
  }
  builder.to_string()
}
