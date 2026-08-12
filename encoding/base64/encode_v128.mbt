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

// Vectorized Base64 encoding for the linear-memory backends, after
// Wojciech Muła's SSE implementation
// (http://0x80.pl/notesen/2016-01-12-sse-base64-encoding.html).
//
// Each iteration loads sixteen source bytes, consumes twelve of them, and
// emits sixteen Base64 characters. Because a MoonBit `String` is UTF-16,
// those sixteen characters are widened to thirty-two bytes before being
// stored.

///|
/// V128 loads require `FixedArray[Byte]`; these types share a representation
/// on the linear-memory backends.
#cfg(any(target="native", target="wasm"))
fn unsafe_fixedarray_from_bytes(bytes : Bytes) -> FixedArray[Byte] = "%identity"

///|
/// Per-class offsets added to a sextet to reach its Base64 character, indexed
/// by the class computed in `encode_block_v128`:
/// 0 -> lowercase, 1..=10 -> digits, 11 -> `+`, 12 -> `/`, 13 -> uppercase.
/// Values are stored modulo 256 because `i8x16_add` wraps.
#cfg(any(target="native", target="wasm"))
fn encode_offsets_v128() -> V128 {
  @v128.i8x16_const(
    71, 252, 252, 252, 252, 252, 252, 252, 252, 252, 252, 237, 240, 65, 0, 0,
  )
}

///|
/// Turns twelve source bytes (the low twelve lanes of `data`) into sixteen
/// Base64 characters, one per lane.
#cfg(any(target="native", target="wasm"))
fn encode_block_v128(data : V128) -> V128 {
  // Spread each three-byte group across one 32-bit lane so that the lane,
  // read as a little-endian integer, holds `b0 << 16 | b1 << 8 | b2`. Lane
  // byte three is taken from the zero vector.
  let zero = @v128.i8x16_splat(0)
  let groups = @v128.i8x16_shuffle(
    data, zero, 2, 1, 0, 16, 5, 4, 3, 16, 8, 7, 6, 16, 11, 10, 9, 16,
  )

  // Slice each group into four sextets, positioned so that lane byte `k`
  // holds the `k`-th output character. `i16x8`-style multiply tricks are not
  // available on SIMD128, but uniform shifts are, and they are cheap.
  let sextets = @v128.v128_or_(
    @v128.v128_or_(
      @v128.v128_and_(
        @v128.i32x4_shr_u(groups, 18),
        @v128.i32x4_splat(0x0000003F),
      ),
      @v128.v128_and_(
        @v128.i32x4_shr_u(groups, 4),
        @v128.i32x4_splat(0x00003F00),
      ),
    ),
    @v128.v128_or_(
      @v128.v128_and_(
        @v128.i32x4_shl(groups, 10),
        @v128.i32x4_splat(0x003F0000),
      ),
      @v128.v128_and_(
        @v128.i32x4_shl(groups, 24),
        @v128.i32x4_splat(0x3F000000),
      ),
    ),
  )

  // Classify each sextet, then look its offset up in a register-resident
  // table. Saturating subtraction collapses 0..=51 to class zero and maps
  // 52..=63 to 1..=12; the separate `< 26` test splits uppercase off as
  // class thirteen.
  let class = @v128.v128_or_(
    @v128.i8x16_sub_sat_u(sextets, @v128.i8x16_splat(51)),
    @v128.v128_and_(
      @v128.i8x16_lt_u(sextets, @v128.i8x16_splat(26)),
      @v128.i8x16_splat(13),
    ),
  )
  @v128.i8x16_add(sextets, @v128.i8x16_swizzle(encode_offsets_v128(), class))
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
fn encode_v128(bytes : BytesView, padding : Bool) -> String {
  let length = bytes.length()
  let full_groups = length / 3
  let remainder = length % 3
  let mut char_count = full_groups * 4
  if remainder != 0 {
    char_count += if padding { 4 } else { remainder + 1 }
  }
  let out = FixedArray::make(char_count * 2, b'\x00')
  let src = unsafe_fixedarray_from_bytes(bytes.data())
  let end = bytes.start_offset() + length
  let mut index = bytes.start_offset()
  let mut written = 0
  // The load reads sixteen bytes but only twelve are consumed, so the loop
  // stops four bytes short of the end and the tail is encoded scalar.
  while index + 16 <= end {
    let chars = encode_block_v128(@v128.v128_load(src, index))
    @v128.v128_store(out, written, @v128.i16x8_extend_low_i8x16_u(chars))
    @v128.v128_store(out, written + 16, @v128.i16x8_extend_high_i8x16_u(chars))
    index += 12
    written += 32
  }
  while index + 3 <= end {
    let n = (src[index].to_int() << 16) |
      (src[index + 1].to_int() << 8) |
      src[index + 2].to_int()
    write_code_unit(out, written, BASE64_STD[(n >> 18) & 0x3F])
    write_code_unit(out, written + 2, BASE64_STD[(n >> 12) & 0x3F])
    write_code_unit(out, written + 4, BASE64_STD[(n >> 6) & 0x3F])
    write_code_unit(out, written + 6, BASE64_STD[n & 0x3F])
    index += 3
    written += 8
  }
  let rest = end - index
  if rest != 0 {
    let mut n = src[index].to_int() << 16
    if rest == 2 {
      n = n | (src[index + 1].to_int() << 8)
    }
    write_code_unit(out, written, BASE64_STD[(n >> 18) & 0x3F])
    write_code_unit(out, written + 2, BASE64_STD[(n >> 12) & 0x3F])
    if rest == 2 {
      write_code_unit(out, written + 4, BASE64_STD[(n >> 6) & 0x3F])
      if padding {
        write_code_unit(out, written + 6, b'=')
      }
    } else if padding {
      write_code_unit(out, written + 4, b'=')
      write_code_unit(out, written + 6, b'=')
    }
  }
  out.unsafe_reinterpret_as_bytes().to_unchecked_string()
}
