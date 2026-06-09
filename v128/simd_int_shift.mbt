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
pub fn i8x16_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 8
  pack_u8x16_by(i => (u8_lane(value, i).to_uint() << shift).to_byte())
}

///|
pub fn i8x16_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 8
  pack_u8x16_by(i => (u8_lane(value, i).to_uint() >> shift).to_byte())
}

///|
pub fn i8x16_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 8
  pack_u8x16_by(i => (i8_signed(u8_lane(value, i)) >> shift).to_byte())
}

///|
pub fn i16x8_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 16
  pack_u16x8_by(i => (u16_lane(value, i).to_uint() << shift).to_uint16())
}

///|
pub fn i16x8_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 16
  pack_u16x8_by(i => (u16_lane(value, i).to_uint() >> shift).to_uint16())
}

///|
pub fn i16x8_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 16
  pack_u16x8_by(i => (i16_signed(u16_lane(value, i)) >> shift).to_uint16())
}

///|
pub fn i32x4_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 32
  pack_u32x4_by(i => u32_lane(value, i) << shift)
}

///|
pub fn i32x4_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 32
  pack_u32x4_by(i => u32_lane(value, i) >> shift)
}

///|
pub fn i32x4_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 32
  pack_u32x4_by(i => {
    (u32_lane(value, i).reinterpret_as_int() >> shift).reinterpret_as_uint()
  })
}

///|
pub fn i64x2_shl(value : V128, shift : Int) -> V128 {
  let shift = shift % 64
  make(lo(value) << shift, hi(value) << shift)
}

///|
pub fn i64x2_shr_u(value : V128, shift : Int) -> V128 {
  let shift = shift % 64
  make(lo(value) >> shift, hi(value) >> shift)
}

///|
pub fn i64x2_shr_s(value : V128, shift : Int) -> V128 {
  let shift = shift % 64
  pack_u64x2_by(i => {
    (u64_lane(value, i).reinterpret_as_int64() >> shift).reinterpret_as_uint64()
  })
}

///|
pub fn i8x16_all_true(value : V128) -> Bool {
  for i in 0..<16 {
    if u8_lane(value, i) == 0 {
      return false
    }
  }
  true
}

///|
pub fn i16x8_all_true(value : V128) -> Bool {
  for i in 0..<8 {
    if u16_lane(value, i) == 0 {
      return false
    }
  }
  true
}

///|
pub fn i32x4_all_true(value : V128) -> Bool {
  for i in 0..<4 {
    if u32_lane(value, i) == 0 {
      return false
    }
  }
  true
}

///|
pub fn i64x2_all_true(value : V128) -> Bool {
  lo(value) != 0UL && hi(value) != 0UL
}

///|
pub fn i8x16_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<16 {
    result = result | (((u8_lane(value, i).to_int() >> 7) & 1) << i)
  }
  result
}

///|
pub fn i16x8_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<8 {
    result = result | (((u16_lane(value, i).to_int() >> 15) & 1) << i)
  }
  result
}

///|
pub fn i32x4_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<4 {
    result = result |
      ((u32_lane(value, i).reinterpret_as_int() >> 31) & (1 << i))
  }
  result
}

///|
pub fn i64x2_bitmask(value : V128) -> Int {
  let mut result = 0
  for i in 0..<2 {
    result = result | ((u64_lane(value, i) >> 63).to_int() << i)
  }
  result
}
