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

// Vectorized hexadecimal decoding for the linear-memory backends.
//
// A MoonBit `String` is UTF-16, so a block loads four vectors of eight code
// units and narrows them to thirty-two ASCII characters, which decode to
// sixteen bytes. The narrow reads its lanes as signed and saturates, so a
// code unit in `0x0100..=0x7FFF` becomes 255 and one in `0x8000..=0xFFFF`
// -- surrogate halves included -- becomes 0. Neither is a hex digit, so the
// validity check rejects both and no non-ASCII code unit can masquerade as
// a hex digit by way of its low byte.
//
// The fast path only handles even-length input made of hex digits. Anything
// else defers to `decode_scalar`, which remains the single definition of the
// `Malformed` rules.

///|
/// True when every lane holds an ASCII hex digit (`0-9`, `a-f`, `A-F`).
#cfg(any(target="native", target="wasm"))
fn hex_valid_v128(ascii : V128) -> Bool {
  let digit = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'0')),
    @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'9')),
  )
  let lower = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'a')),
    @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'f')),
  )
  let upper = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'A')),
    @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'F')),
  )
  @v128.i8x16_all_true(@v128.v128_or_(digit, @v128.v128_or_(lower, upper)))
}

///|
/// Maps sixteen ASCII hex digits to their nibble values. Only meaningful
/// after `hex_valid_v128` accepted the lanes: `- '0'` handles digits, and a
/// further masked `- 39` (lowercase) or `- 7` (uppercase) shifts the letter
/// ranges onto 10..=15. The adjustments are wrapping adds of the two's
/// complements because `i8x16_add` wraps.
#cfg(any(target="native", target="wasm"))
fn hex_nibbles_v128(ascii : V128) -> V128 {
  let lower = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'a')),
    @v128.i8x16_splat(217), // -39 mod 256
  )
  let upper = @v128.v128_and_(
    @v128.v128_and_(
      @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'A')),
      @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'F')),
    ),
    @v128.i8x16_splat(249), // -7 mod 256
  )
  @v128.i8x16_add(
    @v128.i8x16_add(ascii, @v128.i8x16_splat(208)), // -48 mod 256
    @v128.v128_or_(lower, upper),
  )
}

///|
/// Decodes even-length all-hex text. Returns `None` when the fast path does
/// not apply (short, odd-length, or invalid input), in which case the caller
/// must use the scalar decoder.
#cfg(any(target="native", target="wasm"))
fn decode_v128(text : StringView) -> Bytes? {
  let length = text.length()
  // Below one full block the scalar decoder wins outright.
  guard length >= 32 && length % 2 == 0 else { return None }
  let out = FixedArray::make(length / 2, b'\x00')
  let src = text.data()
  let base = text.start_offset()
  let mut index = 0
  let mut written = 0
  // subtraction, so that the bound cannot wrap on a very long input
  while length - index >= 32 {
    let offset = base + index
    let ascii0 = @v128.i8x16_narrow_i16x8_u(
      @v128.v128_load_i16x8(src, offset),
      @v128.v128_load_i16x8(src, offset + 8),
    )
    let ascii1 = @v128.i8x16_narrow_i16x8_u(
      @v128.v128_load_i16x8(src, offset + 16),
      @v128.v128_load_i16x8(src, offset + 24),
    )
    guard hex_valid_v128(ascii0) && hex_valid_v128(ascii1) else { return None }
    let n0 = hex_nibbles_v128(ascii0)
    let n1 = hex_nibbles_v128(ascii1)
    // high nibbles sit in the even lanes, low nibbles in the odd lanes
    let hi = @v128.i8x16_shuffle(
      n0, n1, 0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30,
    )
    let lo = @v128.i8x16_shuffle(
      n0, n1, 1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25, 27, 29, 31,
    )
    @v128.v128_store(out, written, @v128.v128_or_(@v128.i8x16_shl(hi, 4), lo))
    index += 32
    written += 16
  }
  while index < length {
    let hi = hex_value(text.unsafe_get(index).to_int())
    let lo = hex_value(text.unsafe_get(index + 1).to_int())
    guard hi >= 0 && lo >= 0 else { return None }
    out[written] = ((hi << 4) | lo).to_byte()
    index += 2
    written += 1
  }
  Some(out.unsafe_reinterpret_as_bytes())
}
