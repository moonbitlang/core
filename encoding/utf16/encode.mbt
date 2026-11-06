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
/// Encodes a string into a UTF-16 byte array.
/// 
/// Assuming the string is valid.
pub fn encode(
  str : StringView,
  bom~ : Bool = false,
  endianness~ : Endian = Little,
) -> Bytes {
  let bom_length = if bom { 2 } else { 0 }
  let arr = FixedArray::make(str.length() * 2 + bom_length, b'\x00')
  if endianness is Little {
    if bom {
      arr[0] = 0xFF
      arr[1] = 0xFE
    }
    arr.blit_from_string(
      bom_length,
      str.data(),
      str.start_offset(),
      str.length(),
    )
  } else {
    if bom {
      arr[0] = 0xFE
      arr[1] = 0xFF
    }
    encode_be_into(str, arr, bom_length)
  }
  arr.unsafe_reinterpret_as_bytes()
}

///|
#cfg(not(target="wasm"))
#inline
fn encode_be_into(
  str : StringView,
  out : FixedArray[Byte],
  offset : Int32,
) -> Unit {
  for code_unit in str.code_units(); i = offset {
    out[i] = (code_unit >> 8).to_byte()
    out[i + 1] = (code_unit & 0xFF).to_byte()
    continue i + 2
  }
}

///|
#cfg(target="wasm")
fn encode_be_into(
  str : StringView,
  out : FixedArray[Byte],
  offset : Int32,
) -> Unit {
  let length = str.length()
  let source = str.data()
  let base = str.start_offset()
  let mut index = 0
  while length - index >= 8 {
    let block = @v128.v128_load_i16x8(source, base + index)
    @v128.v128_store(out, offset + index * 2, utf16_swap_u16x8(block))
    index += 8
  }
  while index < length {
    let unit = str.unsafe_get(index)
    out[offset + index * 2] = (unit >> 8).to_byte()
    out[offset + index * 2 + 1] = (unit & 0xFF).to_byte()
    index += 1
  }
}
