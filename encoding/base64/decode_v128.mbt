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

// Vectorized Base64 decoding for the linear-memory backends. The character
// classification uses the perfect hash on the high nibble described in
// https://mcyoung.xyz/2023/11/27/simd-base64/.
//
// A MoonBit `String` is UTF-16, so a block loads two vectors of eight code
// units to obtain sixteen characters, which yield twelve decoded bytes.
//
// The fast path only handles canonical input: no whitespace, a length that is
// a multiple of four, and characters drawn from the Base64 alphabet. Anything
// else defers to `decode_scalar`, which remains the single definition of the
// padding and trailing-bit rules.

///|
/// Offsets added to a Base64 character to reach its sextet, indexed by the
/// perfect hash `(c >> 4) - (c == '/')`: 1 -> `/`, 2 -> `+`, 3 -> digits,
/// 4..=5 -> uppercase, 6..=7 -> lowercase. Values are modulo 256 because
/// `i8x16_add` wraps.
#cfg(any(target="native", target="wasm"))
fn decode_offsets_v128() -> V128 {
  @v128.i8x16_const(0, 16, 19, 4, 191, 191, 185, 185, 0, 0, 0, 0, 0, 0, 0, 0)
}

///|
/// True when every lane holds a character of the standard Base64 alphabet.
/// Padding and whitespace deliberately fail this test so the caller falls
/// back to the scalar decoder.
#cfg(any(target="native", target="wasm"))
fn decode_valid_v128(ascii : V128) -> Bool {
  let upper = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'A')),
    @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'Z')),
  )
  let lower = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'a')),
    @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'z')),
  )
  let digit = @v128.v128_and_(
    @v128.i8x16_ge_u(ascii, @v128.i8x16_splat(b'0')),
    @v128.i8x16_le_u(ascii, @v128.i8x16_splat(b'9')),
  )
  let plus = @v128.i8x16_eq(ascii, @v128.i8x16_splat(b'+'))
  let slash = @v128.i8x16_eq(ascii, @v128.i8x16_splat(b'/'))
  @v128.i8x16_all_true(
    @v128.v128_or_(
      @v128.v128_or_(upper, lower),
      @v128.v128_or_(digit, @v128.v128_or_(plus, slash)),
    ),
  )
}

///|
/// Turns sixteen Base64 characters into twelve decoded bytes, held in the low
/// twelve lanes of the result.
#cfg(any(target="native", target="wasm"))
fn decode_block_v128(ascii : V128) -> V128 {
  // `i8x16_eq` yields all-ones, i.e. -1, so adding it subtracts one for '/'.
  let hash = @v128.i8x16_add(
    @v128.i8x16_shr_u(ascii, 4),
    @v128.i8x16_eq(ascii, @v128.i8x16_splat(b'/')),
  )
  let sextets = @v128.i8x16_add(
    ascii,
    @v128.i8x16_swizzle(decode_offsets_v128(), hash),
  )
  // Fuse each group of four sextets into a 24-bit value held in the low three
  // bytes of its 32-bit lane.
  let groups = @v128.v128_or_(
    @v128.v128_or_(
      @v128.i32x4_shl(
        @v128.v128_and_(sextets, @v128.i32x4_splat(0x0000003F)),
        18,
      ),
      @v128.i32x4_shl(
        @v128.v128_and_(sextets, @v128.i32x4_splat(0x00003F00)),
        4,
      ),
    ),
    @v128.v128_or_(
      @v128.i32x4_shr_u(
        @v128.v128_and_(sextets, @v128.i32x4_splat(0x003F0000)),
        10,
      ),
      @v128.i32x4_shr_u(
        @v128.v128_and_(sextets, @v128.i32x4_splat(0x3F000000)),
        24,
      ),
    ),
  )
  // Emit each lane's three payload bytes most-significant first.
  @v128.i8x16_shuffle(
    groups, groups, 2, 1, 0, 6, 5, 4, 10, 9, 8, 14, 13, 12, 0, 0, 0, 0,
  )
}

///|
/// Decodes canonical Base64 text. Returns `None` when the input is not
/// canonical, in which case the caller must use the scalar decoder.
#cfg(any(target="native", target="wasm"))
fn decode_v128(text : StringView) -> Bytes? {
  let length = text.length()
  // Below this the scalar decoder wins outright: one block needs sixteen
  // characters plus a four-character tail group.
  guard length >= 32 && length % 4 == 0 else { return None }
  let padding = if text.unsafe_get(length - 1) != b'='.to_uint16() {
    0
  } else if text.unsafe_get(length - 2) != b'='.to_uint16() {
    1
  } else {
    2
  }
  let out = FixedArray::make(length / 4 * 3 - padding, b'\x00')
  let src = text.data()
  // The final group may carry padding, so it is always left to the scalar
  // decoder; everything before it must be plain alphabet.
  let body = length - 4
  let base = text.start_offset()
  let mut index = 0
  let mut written = 0
  while body - index >= 16 && out.length() - written >= 16 {
    let offset = base + index
    let ascii = @v128.i8x16_narrow_i16x8_u(
      @v128.v128_load_i16x8(src, offset),
      @v128.v128_load_i16x8(src, offset + 8),
    )
    guard decode_valid_v128(ascii) else { return None }
    @v128.v128_store(out, written, decode_block_v128(ascii))
    index += 16
    written += 12
  }
  // Remaining whole groups of the body, still guaranteed padding-free.
  while index < body {
    let mut group = 0
    for lane in 0..<4 {
      let value = base64_value(text.unsafe_get(index + lane).to_int())
      guard value >= 0 else { return None }
      group = (group << 6) | value
    }
    out[written] = (group >> 16).to_byte()
    out[written + 1] = (group >> 8).to_byte()
    out[written + 2] = group.to_byte()
    index += 4
    written += 3
  }
  // Reuse the scalar decoder for the final group so the padding and
  // trailing-bit rules live in exactly one place.
  let tail_bytes = decode_scalar(text[body:], false) catch { _ => return None }
  guard tail_bytes.length() == out.length() - written else { return None }
  for i, byte in tail_bytes {
    out[written + i] = byte
  }
  Some(out.unsafe_reinterpret_as_bytes())
}
