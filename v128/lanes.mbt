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
fn u8_lane(value : V128, lane : Int) -> Byte {
  let word = if lane < 8 { lo(value) } else { hi(value) }
  ((word >> (lane % 8 * 8)) & 0xffUL).to_byte()
}

///|
fn u16_lane(value : V128, lane : Int) -> UInt16 {
  let word = if lane < 4 { lo(value) } else { hi(value) }
  ((word >> (lane % 4 * 16)) & 0xffffUL).to_uint16()
}

///|
fn u32_lane(value : V128, lane : Int) -> UInt {
  let word = if lane < 2 { lo(value) } else { hi(value) }
  ((word >> (lane % 2 * 32)) & 0xffffffffUL).to_uint()
}

///|
fn u64_lane(value : V128, lane : Int) -> UInt64 {
  if lane == 0 {
    lo(value)
  } else {
    hi(value)
  }
}

///|
fn pack_u8x16_by(f : (Int) -> Byte) -> V128 {
  let mut lo_word = 0UL
  for i in 0..<8 {
    lo_word = lo_word | (f(i).to_uint64() << (i * 8))
  }
  let mut hi_word = 0UL
  for i in 0..<8 {
    hi_word = hi_word | (f(i + 8).to_uint64() << (i * 8))
  }
  make(lo_word, hi_word)
}

///|
fn pack_u16x8_by(f : (Int) -> UInt16) -> V128 {
  let mut lo_word = 0UL
  for i in 0..<4 {
    lo_word = lo_word | (f(i).to_uint64() << (i * 16))
  }
  let mut hi_word = 0UL
  for i in 0..<4 {
    hi_word = hi_word | (f(i + 4).to_uint64() << (i * 16))
  }
  make(lo_word, hi_word)
}

///|
fn pack_u32x4_by(f : (Int) -> UInt) -> V128 {
  make(
    f(0).to_uint64() | (f(1).to_uint64() << 32),
    f(2).to_uint64() | (f(3).to_uint64() << 32),
  )
}

///|
fn pack_u64x2_by(f : (Int) -> UInt64) -> V128 {
  make(f(0), f(1))
}

///|
fn i8_signed(value : Byte) -> Int {
  let value = value.to_int()
  if value >= 128 {
    value - 256
  } else {
    value
  }
}

///|
fn i16_signed(value : UInt16) -> Int {
  Int16::reinterpret_from_uint16(value).to_int()
}

///|
fn bool_to_u8_mask(value : Bool) -> Byte {
  if value {
    0xff
  } else {
    0
  }
}

///|
fn bool_to_u16_mask(value : Bool) -> UInt16 {
  if value {
    0xffff
  } else {
    0
  }
}

///|
fn bool_to_u32_mask(value : Bool) -> UInt {
  if value {
    0xffffffff
  } else {
    0
  }
}

///|
fn bool_to_u64_mask(value : Bool) -> UInt64 {
  if value {
    0xffffffffffffffffUL
  } else {
    0UL
  }
}

///|
fn i8_abs(value : Byte) -> Byte {
  let value = i8_signed(value)
  if value < 0 {
    (-value).to_byte()
  } else {
    value.to_byte()
  }
}

///|
fn i16_abs(value : UInt16) -> UInt16 {
  Int16::abs(Int16::reinterpret_from_uint16(value)).reinterpret_as_uint16()
}

///|
fn i8_add_sat_s(a : Byte, b : Byte) -> Byte {
  let sum = i8_signed(a) + i8_signed(b)
  if sum > 127 {
    0x7f
  } else if sum < -128 {
    0x80
  } else {
    sum.to_byte()
  }
}

///|
fn i8_add_sat_u(a : Byte, b : Byte) -> Byte {
  let sum = a.to_uint() + b.to_uint()
  if sum > 255 {
    0xff
  } else {
    sum.to_byte()
  }
}

///|
fn i8_sub_sat_s(a : Byte, b : Byte) -> Byte {
  let diff = i8_signed(a) - i8_signed(b)
  if diff > 127 {
    0x7f
  } else if diff < -128 {
    0x80
  } else {
    diff.to_byte()
  }
}

///|
fn i8_sub_sat_u(a : Byte, b : Byte) -> Byte {
  if a < b {
    0
  } else {
    a - b
  }
}

///|
fn i8_min_s(a : Byte, b : Byte) -> Byte {
  if i8_signed(a) < i8_signed(b) {
    a
  } else {
    b
  }
}

///|
fn i8_max_s(a : Byte, b : Byte) -> Byte {
  if i8_signed(a) > i8_signed(b) {
    a
  } else {
    b
  }
}

///|
fn i8_avgr_u(a : Byte, b : Byte) -> Byte {
  ((a.to_uint() + b.to_uint() + 1) / 2).to_byte()
}

///|
fn i16_add_sat_s(a : UInt16, b : UInt16) -> UInt16 {
  let sum = i16_signed(a) + i16_signed(b)
  if sum > 32767 {
    0x7fff
  } else if sum < -32768 {
    0x8000
  } else {
    sum.to_uint16()
  }
}

///|
fn i16_add_sat_u(a : UInt16, b : UInt16) -> UInt16 {
  let sum = a.to_uint() + b.to_uint()
  if sum > 65535 {
    0xffff
  } else {
    sum.to_uint16()
  }
}

///|
fn i16_sub_sat_s(a : UInt16, b : UInt16) -> UInt16 {
  let diff = i16_signed(a) - i16_signed(b)
  if diff > 32767 {
    0x7fff
  } else if diff < -32768 {
    0x8000
  } else {
    diff.to_uint16()
  }
}

///|
fn i16_sub_sat_u(a : UInt16, b : UInt16) -> UInt16 {
  if a < b {
    0
  } else {
    a - b
  }
}

///|
fn i16_min_s(a : UInt16, b : UInt16) -> UInt16 {
  if i16_signed(a) < i16_signed(b) {
    a
  } else {
    b
  }
}

///|
fn i16_max_s(a : UInt16, b : UInt16) -> UInt16 {
  if i16_signed(a) > i16_signed(b) {
    a
  } else {
    b
  }
}

///|
fn i16_avgr_u(a : UInt16, b : UInt16) -> UInt16 {
  ((a.to_uint() + b.to_uint() + 1) / 2).to_uint16()
}
