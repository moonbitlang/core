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

// The 128-bit vector operations used by the SIMD byte and UTF-16 scanners in
// `bytes_find.mbt` and `string_find_code_unit.mbt`. `builtin` cannot import
// `moonbitlang/core/v128` (that would be a cycle), so the few ops the scanners
// need are hosted here directly.
//
// Scanner-only operations are gated to the linear-memory backends that use
// them. `v128_make` and `v128_load` also support aligned bitstring extraction,
// so they remain available on every backend with portable fallback bodies.

///|
fn v128_make(lo : UInt64, hi : UInt64) -> V128 = "%v128.make"

///|
#cfg(any(target="native", target="wasm"))
fn v128_lo(value : V128) -> UInt64 = "%v128.lo"

///|
#cfg(any(target="native", target="wasm"))
fn v128_hi(value : V128) -> UInt64 = "%v128.hi"

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.i8x16_splat")
fn i8x16_splat(value : Byte) -> V128 {
  let lane = value.to_uint64() * (0x0101010101010101 : UInt64)
  v128_make(lane, lane)
}

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.i16x8_splat")
fn i16x8_splat(value : UInt16) -> V128 {
  let lane = value.to_uint64() * (0x0001000100010001 : UInt64)
  v128_make(lane, lane)
}

///|
#borrow(bytes)
#intrinsic("%v128.v128_load")
fn v128_load(bytes : FixedArray[Byte], offset : Int) -> V128 {
  v128_make(
    fixedarray_read_uint64_le(bytes, offset),
    fixedarray_read_uint64_le(bytes, offset + 8),
  )
}

///|
// Loads eight consecutive UTF-16 code units beginning at `offset`. The caller
// must ensure `offset + 8 <= str.length()`.
#borrow(str)
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.v128_load_i16x8")
fn v128_load_i16x8(str : String, offset : Int) -> V128 {
  let lo = for i in 0..<4; word = (0 : UInt64) {
    continue word | (str.unsafe_get(offset + i).to_uint64() << (16 * i))
  } nobreak {
    word
  }
  let hi = for i in 0..<4; word = (0 : UInt64) {
    continue word | (str.unsafe_get(offset + 4 + i).to_uint64() << (16 * i))
  } nobreak {
    word
  }
  v128_make(lo, hi)
}

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.v128_and")
fn v128_and(a : V128, b : V128) -> V128 {
  v128_make(v128_lo(a) & v128_lo(b), v128_hi(a) & v128_hi(b))
}

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.i8x16_eq")
fn i8x16_eq(a : V128, b : V128) -> V128 {
  v128_make(
    u64_byte_eq_mask(v128_lo(a), v128_lo(b)),
    u64_byte_eq_mask(v128_hi(a), v128_hi(b)),
  )
}

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.i16x8_eq")
fn i16x8_eq(a : V128, b : V128) -> V128 {
  v128_make(
    u64_u16_eq_mask(v128_lo(a), v128_lo(b)),
    u64_u16_eq_mask(v128_hi(a), v128_hi(b)),
  )
}

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.i8x16_bitmask")
fn i8x16_bitmask(value : V128) -> Int {
  u64_high_bits(v128_lo(value)) | (u64_high_bits(v128_hi(value)) << 8)
}

///|
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.i16x8_bitmask")
fn i16x8_bitmask(value : V128) -> Int {
  u64_u16_high_bits(v128_lo(value)) | (u64_u16_high_bits(v128_hi(value)) << 4)
}

///|
// Per-byte equality mask over the eight bytes of a `UInt64`: each byte becomes
// `0xFF` when the operands' bytes match, `0x00` otherwise.
#cfg(any(target="native", target="wasm"))
fn u64_byte_eq_mask(a : UInt64, b : UInt64) -> UInt64 {
  for i in 0..<8; result = (0 : UInt64) {
    let shift = 8 * i
    let mask = if ((a >> shift) & 0xFF) == ((b >> shift) & 0xFF) {
      (0xFF : UInt64)
    } else {
      0
    }
    continue result | (mask << shift)
  } nobreak {
    result
  }
}

///|
// Per-lane equality mask over the four 16-bit lanes of a `UInt64`: each lane
// becomes `0xFFFF` when the operands' lanes match, `0x0000` otherwise.
#cfg(any(target="native", target="wasm"))
fn u64_u16_eq_mask(a : UInt64, b : UInt64) -> UInt64 {
  for i in 0..<4; result = (0 : UInt64) {
    let shift = 16 * i
    let mask = if ((a >> shift) & 0xFFFF) == ((b >> shift) & 0xFFFF) {
      (0xFFFF : UInt64)
    } else {
      0
    }
    continue result | (mask << shift)
  } nobreak {
    result
  }
}

///|
// Gathers the high bit (bit 7) of each of the eight bytes of a `UInt64` into
// the low eight bits of an `Int`.
#cfg(any(target="native", target="wasm"))
fn u64_high_bits(value : UInt64) -> Int {
  for i in 0..<8; result = 0 {
    let bit = ((value >> (8 * i + 7)) & 1).to_int()
    continue result | (bit << i)
  } nobreak {
    result
  }
}

///|
// Gathers the high bit (bit 15) of each of the four 16-bit lanes of a `UInt64`
// into the low four bits of an `Int`.
#cfg(any(target="native", target="wasm"))
fn u64_u16_high_bits(value : UInt64) -> Int {
  for i in 0..<4; result = 0 {
    let bit = ((value >> (16 * i + 15)) & 1).to_int()
    continue result | (bit << i)
  } nobreak {
    result
  }
}
