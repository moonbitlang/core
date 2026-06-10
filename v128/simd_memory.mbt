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
fn load_u16_le(bytes : FixedArray[Byte], offset : Int) -> UInt16 {
  bytes.unsafe_get(offset).to_uint16() |
  (bytes.unsafe_get(offset + 1).to_uint16() << 8)
}

///|
fn load_u32_le(bytes : FixedArray[Byte], offset : Int) -> UInt {
  bytes.unsafe_get(offset).to_uint() |
  (bytes.unsafe_get(offset + 1).to_uint() << 8) |
  (bytes.unsafe_get(offset + 2).to_uint() << 16) |
  (bytes.unsafe_get(offset + 3).to_uint() << 24)
}

///|
fn load_u64_le(bytes : FixedArray[Byte], offset : Int) -> UInt64 {
  let mut result = 0UL
  for i in 0..<8 {
    result = result | (bytes.unsafe_get(offset + i).to_uint64() << (i * 8))
  }
  result
}

///|
fn store_u16_le(bytes : FixedArray[Byte], offset : Int, value : UInt16) -> Unit {
  bytes.unsafe_set(offset, value.to_byte())
  bytes.unsafe_set(offset + 1, (value >> 8).to_byte())
}

///|
fn store_u32_le(bytes : FixedArray[Byte], offset : Int, value : UInt) -> Unit {
  bytes.unsafe_set(offset, value.to_byte())
  bytes.unsafe_set(offset + 1, (value >> 8).to_byte())
  bytes.unsafe_set(offset + 2, (value >> 16).to_byte())
  bytes.unsafe_set(offset + 3, (value >> 24).to_byte())
}

///|
fn store_u64_le(bytes : FixedArray[Byte], offset : Int, value : UInt64) -> Unit {
  for i in 0..<8 {
    bytes.unsafe_set(offset + i, (value >> (i * 8)).to_byte())
  }
}

///|
fn i8_extend_s(value : Byte) -> UInt16 {
  i8_signed(value).to_uint16()
}

///|
fn i16_extend_s(value : UInt16) -> UInt {
  i16_signed(value).reinterpret_as_uint()
}

///|
fn i32_extend_s(value : UInt) -> UInt64 {
  value.reinterpret_as_int().to_int64().reinterpret_as_uint64()
}

///|
#intrinsic("%v128.i8x16_swizzle")
pub fn i8x16_swizzle(value : V128, indices : V128) -> V128 {
  pack_u8x16_by(i => {
    let index = u8_lane(indices, i).to_int()
    if index < 16 {
      u8_lane(value, index)
    } else {
      0
    }
  })
}

///|
#intrinsic("%v128.i8x16_relaxed_swizzle")
pub fn i8x16_relaxed_swizzle(value : V128, indices : V128) -> V128 {
  i8x16_swizzle(value, indices)
}

///|
fn shuffle_lane(value : V128, other : V128, index : Int) -> Byte {
  if index < 16 {
    u8_lane(value, index)
  } else {
    u8_lane(other, index - 16)
  }
}

///|
#intrinsic("%v128.i8x16_shuffle")
pub fn i8x16_shuffle(
  value : V128,
  other : V128,
  i0 : Int,
  i1 : Int,
  i2 : Int,
  i3 : Int,
  i4 : Int,
  i5 : Int,
  i6 : Int,
  i7 : Int,
  i8 : Int,
  i9 : Int,
  i10 : Int,
  i11 : Int,
  i12 : Int,
  i13 : Int,
  i14 : Int,
  i15 : Int,
) -> V128 {
  pack_u8x16_by(fn(i) {
    match i {
      0 => shuffle_lane(value, other, i0)
      1 => shuffle_lane(value, other, i1)
      2 => shuffle_lane(value, other, i2)
      3 => shuffle_lane(value, other, i3)
      4 => shuffle_lane(value, other, i4)
      5 => shuffle_lane(value, other, i5)
      6 => shuffle_lane(value, other, i6)
      7 => shuffle_lane(value, other, i7)
      8 => shuffle_lane(value, other, i8)
      9 => shuffle_lane(value, other, i9)
      10 => shuffle_lane(value, other, i10)
      11 => shuffle_lane(value, other, i11)
      12 => shuffle_lane(value, other, i12)
      13 => shuffle_lane(value, other, i13)
      14 => shuffle_lane(value, other, i14)
      _ => shuffle_lane(value, other, i15)
    }
  })
}

///|
#intrinsic("%v128.v128_load")
pub fn v128_load(bytes : FixedArray[Byte], offset : Int) -> V128 {
  make(load_u64_le(bytes, offset), load_u64_le(bytes, offset + 8))
}

///|
#intrinsic("%v128.v128_load8x8_s")
pub fn v128_load8x8_s(bytes : FixedArray[Byte], offset : Int) -> V128 {
  pack_u16x8_by(i => i8_extend_s(bytes.unsafe_get(offset + i)))
}

///|
#intrinsic("%v128.v128_load8x8_u")
pub fn v128_load8x8_u(bytes : FixedArray[Byte], offset : Int) -> V128 {
  pack_u16x8_by(i => bytes.unsafe_get(offset + i).to_uint16())
}

///|
#intrinsic("%v128.v128_load16x4_s")
pub fn v128_load16x4_s(bytes : FixedArray[Byte], offset : Int) -> V128 {
  pack_u32x4_by(i => i16_extend_s(load_u16_le(bytes, offset + i * 2)))
}

///|
#intrinsic("%v128.v128_load16x4_u")
pub fn v128_load16x4_u(bytes : FixedArray[Byte], offset : Int) -> V128 {
  pack_u32x4_by(i => load_u16_le(bytes, offset + i * 2).to_uint())
}

///|
#intrinsic("%v128.v128_load32x2_s")
pub fn v128_load32x2_s(bytes : FixedArray[Byte], offset : Int) -> V128 {
  pack_u64x2_by(i => i32_extend_s(load_u32_le(bytes, offset + i * 4)))
}

///|
#intrinsic("%v128.v128_load32x2_u")
pub fn v128_load32x2_u(bytes : FixedArray[Byte], offset : Int) -> V128 {
  pack_u64x2_by(i => load_u32_le(bytes, offset + i * 4).to_uint64())
}

///|
#intrinsic("%v128.v128_load8_splat")
pub fn v128_load8_splat(bytes : FixedArray[Byte], offset : Int) -> V128 {
  i8x16_splat(bytes.unsafe_get(offset))
}

///|
#intrinsic("%v128.v128_load16_splat")
pub fn v128_load16_splat(bytes : FixedArray[Byte], offset : Int) -> V128 {
  i16x8_splat(load_u16_le(bytes, offset))
}

///|
#intrinsic("%v128.v128_load32_splat")
pub fn v128_load32_splat(bytes : FixedArray[Byte], offset : Int) -> V128 {
  i32x4_splat(load_u32_le(bytes, offset))
}

///|
#intrinsic("%v128.v128_load64_splat")
pub fn v128_load64_splat(bytes : FixedArray[Byte], offset : Int) -> V128 {
  i64x2_splat(load_u64_le(bytes, offset))
}

///|
#intrinsic("%v128.v128_load32_zero")
pub fn v128_load32_zero(bytes : FixedArray[Byte], offset : Int) -> V128 {
  i32x4_const(load_u32_le(bytes, offset), 0, 0, 0)
}

///|
#intrinsic("%v128.v128_load64_zero")
pub fn v128_load64_zero(bytes : FixedArray[Byte], offset : Int) -> V128 {
  make(load_u64_le(bytes, offset), 0UL)
}

///|
#intrinsic("%v128.v128_load8_lane")
pub fn v128_load8_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> V128 {
  i8x16_replace_lane(value, lane, bytes.unsafe_get(offset).to_uint())
}

///|
#intrinsic("%v128.v128_load16_lane")
pub fn v128_load16_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> V128 {
  i16x8_replace_lane(value, lane, load_u16_le(bytes, offset).to_uint())
}

///|
#intrinsic("%v128.v128_load32_lane")
pub fn v128_load32_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> V128 {
  i32x4_replace_lane(value, lane, load_u32_le(bytes, offset))
}

///|
#intrinsic("%v128.v128_load64_lane")
pub fn v128_load64_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> V128 {
  i64x2_replace_lane(value, lane, load_u64_le(bytes, offset))
}

///|
#intrinsic("%v128.v128_store")
pub fn v128_store(bytes : FixedArray[Byte], offset : Int, value : V128) -> Unit {
  store_u64_le(bytes, offset, lo(value))
  store_u64_le(bytes, offset + 8, hi(value))
}

///|
#intrinsic("%v128.v128_store8_lane")
pub fn v128_store8_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> Unit {
  bytes.unsafe_set(offset, u8_lane(value, lane))
}

///|
#intrinsic("%v128.v128_store16_lane")
pub fn v128_store16_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> Unit {
  store_u16_le(bytes, offset, u16_lane(value, lane))
}

///|
#intrinsic("%v128.v128_store32_lane")
pub fn v128_store32_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> Unit {
  store_u32_le(bytes, offset, u32_lane(value, lane))
}

///|
#intrinsic("%v128.v128_store64_lane")
pub fn v128_store64_lane(
  bytes : FixedArray[Byte],
  offset : Int,
  value : V128,
  lane : Int,
) -> Unit {
  store_u64_le(bytes, offset, u64_lane(value, lane))
}
