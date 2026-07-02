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

// The 128-bit vector operations used by the SIMD byte scanners in
// `bytes_find.mbt`. `builtin` cannot import `moonbitlang/core/v128` (that would
// be a cycle), so the few ops the scanners need are hosted here directly.
//
// These are gated to the linear-memory backends that have the intrinsics, the
// same targets the scanners run on; the function bodies exist only so the
// `#intrinsic` declarations type-check and are never executed there.

///|
#cfg(any(target="native", target="wasm"))
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
#borrow(bytes)
#cfg(any(target="native", target="wasm"))
#intrinsic("%v128.v128_load")
fn v128_load(bytes : FixedArray[Byte], offset : Int) -> V128 {
  v128_make(
    fixedarray_read_uint64_le(bytes, offset),
    fixedarray_read_uint64_le(bytes, offset + 8),
  )
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
#intrinsic("%v128.i8x16_bitmask")
fn i8x16_bitmask(value : V128) -> Int {
  u64_high_bits(v128_lo(value)) | (u64_high_bits(v128_hi(value)) << 8)
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
