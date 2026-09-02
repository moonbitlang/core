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
fn unsafe_fixedarray_uint16_to_string(buffer : FixedArray[UInt16]) -> String = "%string.unsafe_from_uint16_fixedarray"

///|
#cfg(target="js")
#warnings("-unused_value")
fn suppress_unused_v128_import_on_js() -> Unit {
  ignore(@v128.i8x16_splat(0))
}

///|
fn finish_string(buffer : FixedArray[UInt16], len : Int) -> String {
  if len == buffer.length() {
    unsafe_fixedarray_uint16_to_string(buffer)
  } else {
    let data = FixedArray::make(len, (Default::default() : UInt16))
    data.unsafe_blit(0, buffer, 0, len)
    unsafe_fixedarray_uint16_to_string(data)
  }
}

///|
#cfg(not(target="js"))
#inline
fn decode_scalar(bytes : BytesView) -> String raise Malformed {
  let t : FixedArray[UInt16] = FixedArray::make(bytes.length(), 0)
  let tlen = for tlen = 0, bs = bytes {
    match (tlen, bs) {
      (tlen, []) => break tlen
      (tlen, [0..=0x7F as b, .. rest]) => {
        t.unsafe_set(tlen, b.to_uint16())
        continue tlen + 1, rest
      }
      (_, _ as bytes) => raise Malformed(bytes)
    }
  }
  finish_string(t, tlen)
}

///|
#cfg(not(target="js"))
fn decode_v128(bytes : BytesView) -> String raise Malformed {
  let length = bytes.length()
  let result = FixedArray::make(length * 2, b'\x00')
  for rest = bytes, result_offset = 0 {
    match rest {
      [v128le(block), .. tail] => {
        let non_ascii = @v128.i8x16_bitmask(block)
        if non_ascii != 0 {
          raise Malformed(bytes[result_offset / 2 + non_ascii.ctz():])
        }
        @v128.v128_store(
          result,
          result_offset,
          @v128.i16x8_extend_low_i8x16_u(block),
        )
        @v128.v128_store(
          result,
          result_offset + 16,
          @v128.i16x8_extend_high_i8x16_u(block),
        )
        continue tail, result_offset + 32
      }
      [0..=0x7F as byte, .. tail] => {
        result.unsafe_set(result_offset, byte)
        result.unsafe_set(result_offset + 1, b'\x00')
        continue tail, result_offset + 2
      }
      [] => break
      _ => raise Malformed(bytes[result_offset / 2:])
    }
  }
  result.unsafe_reinterpret_as_bytes().to_unchecked_string()
}

///|
/// Decodes an ASCII byte array into a string.
///
/// Raises `Malformed` if any byte is outside the ASCII range.
#cfg(not(target="js"))
#inline
pub fn decode(bytes : BytesView) -> String raise Malformed {
  // The scalar loop is faster below this crossover point on supported targets.
  if bytes.length() >= 64 {
    decode_v128(bytes)
  } else {
    decode_scalar(bytes)
  }
}

///|
/// Decodes an ASCII byte array into a string.
///
/// Raises `Malformed` if any byte is outside the ASCII range.
#cfg(target="js")
pub fn decode(bytes : BytesView) -> String raise Malformed {
  let t : FixedArray[UInt16] = FixedArray::make(bytes.length(), 0)
  let tlen = for tlen = 0, bs = bytes {
    match (tlen, bs) {
      (tlen, []) => break tlen
      (tlen, [0..=0x7F as b, .. rest]) => {
        t.unsafe_set(tlen, b.to_uint16())
        continue tlen + 1, rest
      }
      (_, _ as bytes) => raise Malformed(bytes)
    }
  }
  finish_string(t, tlen)
}

///|
/// Decodes ASCII bytes into a string, replacing non-ASCII bytes with U+FFFD.
pub fn decode_lossy(bytes : BytesView) -> String {
  let t : FixedArray[UInt16] = FixedArray::make(bytes.length(), 0)
  let tlen = for tlen = 0, bs = bytes {
    match (tlen, bs) {
      (tlen, []) => break tlen
      (tlen, [0..=0x7F as b, .. rest]) => {
        t.unsafe_set(tlen, b.to_uint16())
        continue tlen + 1, rest
      }
      (tlen, [_, .. rest]) => {
        t.unsafe_set(tlen, 0xFFFD)
        continue tlen + 1, rest
      }
    }
  }
  finish_string(t, tlen)
}
