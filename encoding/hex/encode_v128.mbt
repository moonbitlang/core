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

// Vectorized hexadecimal encoding for the linear-memory backends.
//
// Each iteration turns sixteen source bytes into thirty-two hex characters:
// split every byte into its high and low nibble, interleave the nibbles into
// output order, and convert each nibble to ASCII with a single register-
// resident table lookup (`i8x16_swizzle`). Because a MoonBit `String` is
// UTF-16, the thirty-two ASCII characters are widened to sixty-four bytes
// before being stored.

///|
/// V128 loads require `FixedArray[Byte]`; these types share a representation
/// on the linear-memory backends.
#cfg(any(target="native", target="wasm"))
fn unsafe_fixedarray_from_bytes(bytes : Bytes) -> FixedArray[Byte] = "%identity"

///|
/// The sixteen hex digits as swizzle-table lanes: lane `n` holds the ASCII
/// code of the lowercase digit for nibble value `n`.
#cfg(any(target="native", target="wasm"))
fn hex_digits_v128() -> V128 {
  @v128.i8x16_const(
    48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 97, 98, 99, 100, 101, 102,
  )
}

///|
/// Writes one ASCII character as a little-endian UTF-16 code unit.
#cfg(any(target="native", target="wasm"))
#inline
fn write_code_unit(out : FixedArray[Byte], offset : Int, code : Byte) -> Unit {
  out[offset] = code
  out[offset + 1] = 0
}

///|
#cfg(any(target="native", target="wasm"))
fn encode_v128(bytes : BytesView) -> String {
  let length = bytes.length()
  // The vector stores are not bounds checked, so the UTF-16 byte buffer
  // must be sized without wrapping. Its four bytes per source byte overflow
  // sooner than the string itself does, so the scalar encoder -- which
  // builds the string without ever materializing that buffer -- takes over
  // from here.
  guard length <= 0x1FFF_FFFF else { return encode_scalar(bytes) } // Int::MAX / 4
  // 2 output code units per byte, 2 bytes per UTF-16 code unit
  let out = FixedArray::make(length * 4, b'\x00')
  let src = unsafe_fixedarray_from_bytes(bytes.data())
  let base = bytes.start_offset()
  let end = base + length
  let table = hex_digits_v128()
  let mut index = base
  let mut written = 0
  // written as a subtraction so that a view sitting at the very end of a
  // large buffer cannot wrap the bound into accepting a short block
  while end - index >= 16 {
    let data = @v128.v128_load(src, index)
    let hi = @v128.i8x16_shr_u(data, 4)
    let lo = @v128.v128_and_(data, @v128.i8x16_splat(0x0F))
    // interleave: source byte k produces digits at output positions 2k
    // (high nibble) and 2k + 1 (low nibble)
    let first = @v128.i8x16_shuffle(
      hi, lo, 0, 16, 1, 17, 2, 18, 3, 19, 4, 20, 5, 21, 6, 22, 7, 23,
    )
    let second = @v128.i8x16_shuffle(
      hi, lo, 8, 24, 9, 25, 10, 26, 11, 27, 12, 28, 13, 29, 14, 30, 15, 31,
    )
    let d0 = @v128.i8x16_swizzle(table, first)
    let d1 = @v128.i8x16_swizzle(table, second)
    @v128.v128_store(out, written, @v128.i16x8_extend_low_i8x16_u(d0))
    @v128.v128_store(out, written + 16, @v128.i16x8_extend_high_i8x16_u(d0))
    @v128.v128_store(out, written + 32, @v128.i16x8_extend_low_i8x16_u(d1))
    @v128.v128_store(out, written + 48, @v128.i16x8_extend_high_i8x16_u(d1))
    index += 16
    written += 64
  }
  while index < end {
    let n = src[index].to_int()
    write_code_unit(out, written, HEX_DIGITS[(n >> 4) & 0x0F])
    write_code_unit(out, written + 2, HEX_DIGITS[n & 0x0F])
    index += 1
    written += 4
  }
  out.unsafe_reinterpret_as_bytes().to_unchecked_string()
}
