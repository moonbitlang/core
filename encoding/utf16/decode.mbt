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
#cfg(target="js")
#warnings("-unused_value")
fn suppress_unused_v128_import_on_js() -> Unit {
  ignore(@v128.i8x16_splat(0))
}

///|
#cfg(not(target="js"))
fn unsafe_fixedarray_from_bytes(bytes : Bytes) -> FixedArray[Byte] = "%identity"

///|
#cfg(not(target="js"))
fn is_utf16_surrogate(code_unit : UInt16) -> Bool {
  let code = code_unit.to_int()
  code >= 0xD800 && code <= 0xDFFF
}

///|
#cfg(not(target="js"))
fn utf16_swap_u16x8(value : V128) -> V128 {
  @v128.i8x16_shuffle(
    value, value, 1, 0, 3, 2, 5, 4, 7, 6, 9, 8, 11, 10, 13, 12, 15, 14,
  )
}

///|
#cfg(not(target="js"))
fn utf16_v128_has_surrogate(value : V128) -> Bool {
  let lower = @v128.i16x8_splat(0xD800)
  let upper = @v128.i16x8_splat(0xDFFF)
  @v128.i16x8_bitmask(
    @v128.v128_and_(
      @v128.i16x8_ge_u(value, lower),
      @v128.i16x8_le_u(value, upper),
    ),
  ) !=
  0
}

///|
#cfg(not(target="js"))
fn utf16_has_surrogate_le_v128(bytes : BytesView) -> Bool {
  if bytes.length() % 2 != 0 {
    return true
  }
  let src = bytes.data()
  if bytes.length() > 0 &&
    is_utf16_surrogate(src.unsafe_read_uint16_le(bytes.start_offset())) {
    return true
  }
  let src_bytes = unsafe_fixedarray_from_bytes(src)
  let end = bytes.start_offset() + bytes.length()
  let mut index = bytes.start_offset()
  while index + 16 <= end {
    if utf16_v128_has_surrogate(@v128.v128_load(src_bytes, index)) {
      return true
    }
    index = index + 16
  }
  while index < end {
    if is_utf16_surrogate(src.unsafe_read_uint16_le(index)) {
      return true
    }
    index = index + 2
  }
  false
}

///|
#cfg(not(target="js"))
fn utf16_has_surrogate_be_v128(bytes : BytesView) -> Bool {
  if bytes.length() % 2 != 0 {
    return true
  }
  let src = bytes.data()
  if bytes.length() > 0 &&
    is_utf16_surrogate(src.unsafe_read_uint16_be(bytes.start_offset())) {
    return true
  }
  let src_bytes = unsafe_fixedarray_from_bytes(src)
  let end = bytes.start_offset() + bytes.length()
  let mut index = bytes.start_offset()
  while index + 16 <= end {
    let swapped = utf16_swap_u16x8(@v128.v128_load(src_bytes, index))
    if utf16_v128_has_surrogate(swapped) {
      return true
    }
    index = index + 16
  }
  while index < end {
    if is_utf16_surrogate(src.unsafe_read_uint16_be(index)) {
      return true
    }
    index = index + 2
  }
  false
}

///|
#cfg(not(target="js"))
fn utf16_decode_be_no_surrogate_v128(bytes : BytesView) -> String {
  let src = bytes.data()
  let src_bytes = unsafe_fixedarray_from_bytes(src)
  let string_bytes = FixedArray::make(bytes.length(), b'\x00')
  let end = bytes.start_offset() + bytes.length()
  let mut index = bytes.start_offset()
  let mut written = 0
  while index + 16 <= end {
    let swapped = utf16_swap_u16x8(@v128.v128_load(src_bytes, index))
    @v128.v128_store(string_bytes, written, swapped)
    index = index + 16
    written = written + 16
  }
  while index < end {
    let code_unit = src.unsafe_read_uint16_be(index)
    string_bytes[written] = (code_unit & 0xFF).to_byte()
    string_bytes[written + 1] = (code_unit >> 8).to_byte()
    index = index + 2
    written = written + 2
  }
  string_bytes.unsafe_reinterpret_as_bytes().to_unchecked_string()
}

///|
#inline
fn drop_utf16_bom(
  bytes : BytesView,
  ignore_bom : Bool,
  endianness : Endian,
) -> BytesView {
  if ignore_bom {
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
}

///|
fn decode_scalar(
  bytes : BytesView,
  endianness : Endian,
) -> String raise Malformed {
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
/// Decode input bytes/text into structured output.
#cfg(target="js")
pub fn decode(
  bytes : BytesView,
  ignore_bom? : Bool = false,
  endianness? : Endian = Little,
) -> String raise Malformed {
  decode_scalar(drop_utf16_bom(bytes, ignore_bom, endianness), endianness)
}

///|
/// Decode input bytes/text into structured output.
#cfg(not(target="js"))
pub fn decode(
  bytes : BytesView,
  ignore_bom? : Bool = false,
  endianness? : Endian = Little,
) -> String raise Malformed {
  let bytes = drop_utf16_bom(bytes, ignore_bom, endianness)
  if endianness is Little {
    if !utf16_has_surrogate_le_v128(bytes) {
      return bytes
        .data()
        .to_unchecked_string(offset=bytes.start_offset(), length=bytes.length())
    }
  } else if !utf16_has_surrogate_be_v128(bytes) {
    return utf16_decode_be_no_surrogate_v128(bytes)
  }
  decode_scalar(bytes, endianness)
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
  let builder = StringBuilder(size_hint=bytes.length())
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
