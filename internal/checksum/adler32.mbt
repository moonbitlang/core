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
/// Largest modulus.
const ADLER_MODULUS : Int32 = 65521

///|
/// With reduced a,b <= 65520 and bytes <= 255, after n bytes:
/// b <= 65520 + n*65520 + 255*n*(n+1)/2.
/// At n=3800 this is 2090626020, below signed Int's 2147483647 limit.
const ADLER_BLOCK_SIZE : Int32 = 3800

///|
/// Incremental Adler-32 accumulator (RFC 1950 §9), the streaming counterpart to
/// `adler32`. Feed bytes with `update`, read with `finish`.
struct Adler32 {
  mut a : Int32
  mut b : Int32
}

///|
/// Create a fresh Adler-32 accumulator.
pub fn Adler32::Adler32() -> Adler32 {
  { a: 1, b: 0, }
}

///|
/// The plain sum (low 16 bits) and the weighted sum `8*d0 + 7*d1 + ... + d7`
/// (bits 16 and up) of the eight bytes at `i`; both fit their fields.
#cfg(not(any(target="native", target="wasm")))
#inline
fn adler_group8(data : BytesView, i : Int32) -> Int32 {
  // SAFETY: callers prove `data.length() - i >= 8`.
  let d0 = data.unsafe_get(i).to_int()
  let d1 = data.unsafe_get(i + 1).to_int()
  let d2 = data.unsafe_get(i + 2).to_int()
  let d3 = data.unsafe_get(i + 3).to_int()
  let d4 = data.unsafe_get(i + 4).to_int()
  let d5 = data.unsafe_get(i + 5).to_int()
  let d6 = data.unsafe_get(i + 6).to_int()
  let d7 = data.unsafe_get(i + 7).to_int()
  adler_group_sums(d0, d1, d2, d3, d4, d5, d6, d7)
}

///|
/// Pack the plain sum and the 8..1 weighted sum of eight bytes.
#cfg(not(any(target="native", target="wasm")))
#inline
fn adler_group_sums(
  d0 : Int32,
  d1 : Int32,
  d2 : Int32,
  d3 : Int32,
  d4 : Int32,
  d5 : Int32,
  d6 : Int32,
  d7 : Int32,
) -> Int32 {
  let s01 = d0 + d1
  let s0123 = s01 + (d2 + d3)
  let s45 = d4 + d5
  let s4567 = s45 + (d6 + d7)
  let weighted = (s0123 << 2) +
    (s0123 + (s01 << 1) + d0 + d2) +
    (s4567 + (s45 << 1) + d4 + d6)
  (s0123 + s4567) | (weighted << 16)
}

///|
/// SWAR form of the scalar `adler_group8`: one 64-bit load, with the even
/// and odd bytes spread into 16-bit lanes and gathered by multiplication.
/// Lane sums stay below 2^16, so no carry crosses into the gathered lane.
#cfg(any(target="native", target="wasm"))
#inline
fn adler_group8(data : BytesView, i : Int32) -> Int32 {
  // SAFETY: callers prove `data.length() - i >= 8`.
  let x = data.unsafe_read_uint64_le(i)
  let even = x & 0x00FF00FF00FF00FFUL // d0, d2, d4, d6
  let odd = (x >> 8) & 0x00FF00FF00FF00FFUL // d1, d3, d5, d7
  let sum = ((even + odd) * 0x0001000100010001UL) >> 48
  // 0*d0 + 1*d1 + ... + 7*d7, gathered in the top lane.
  let indexed = ((even * 0x0000000200040006UL) >> 48) +
    ((odd * 0x0001000300050007UL) >> 48)
  (sum | (((sum << 3) - indexed) << 16)).to_int()
}

///|
/// The end of the whole eight-byte groups in `start..<end`. Computed from
/// the span so that no index past `end` is ever formed, even for views
/// ending near `Int` overflow.
fn adler_groups_end(start : Int32, end : Int32) -> Int32 {
  end - (end - start) % 8
}

///|
/// `Bytes` and `FixedArray[Byte]` share one backing layout on these backends;
/// the borrowed array only feeds the vector loads of `fold_chunks16`.
#cfg(any(target="native", target="wasm"))
fn adler_bytes_as_fixedarray(data : Bytes) -> FixedArray[Byte] = "%identity"

///|
#cfg(any(target="native", target="wasm"))
#inline
fn adler_lane_sum(lanes : V128) -> Int32 {
  (@v128.i32x4_extract_lane(lanes, 0) +
  @v128.i32x4_extract_lane(lanes, 1) +
  @v128.i32x4_extract_lane(lanes, 2) +
  @v128.i32x4_extract_lane(lanes, 3)).reinterpret_as_int()
}

///|
/// Fold the whole 16-byte chunks of `data[start:end)` into the unreduced sums
/// and return the position behind them, as zlib-rs's NEON kernel does: for a
/// chunk `d0..d15`, `a` gains the plain sum and `b` gains `16 * a` (with `a`
/// from before the chunk) plus the weighted sum `16*d0 + 15*d1 + ... + d15`.
/// The lanes collect, over all chunks, the plain sums (`sums`), the plain
/// sums of the chunks before each chunk (`before`) and the weighted sums
/// (`weighted`). Every lane and every partial sum is at most the serial
/// loop's `b` after the same bytes, so the caller's block bound holds and the
/// reduced result is the same.
///
/// The caller passes `0 <= start <= end <= data.length()` with `a` and `b`
/// reduced and at most `ADLER_BLOCK_SIZE` bytes in between.
#cfg(any(target="native", target="wasm"))
fn Adler32::fold_chunks16(
  self : Adler32,
  data : BytesView,
  start : Int32,
  end : Int32,
) -> Int32 {
  let chunks = (end - start) / 16
  guard chunks > 0 else { return start }
  let bytes = adler_bytes_as_fixedarray(data.data())
  let offset = data.start_offset() + start
  let weights_low = @v128.i16x8_const(16, 15, 14, 13, 12, 11, 10, 9)
  let weights_high = @v128.i16x8_const(8, 7, 6, 5, 4, 3, 2, 1)
  let mut sums = @v128.i32x4_splat(0)
  let mut before = @v128.i32x4_splat(0)
  let mut weighted = @v128.i32x4_splat(0)
  for chunk in 0..<chunks {
    // SAFETY: `chunk < chunks` gives `start + 16 * chunk + 16 <= end`, and
    // `end <= data.length()`: the sixteen bytes lie inside the view, hence
    // inside its backing bytes.
    let block = @v128.v128_load(bytes, offset + chunk * 16)
    before = @v128.i32x4_add(before, sums)
    sums = @v128.i32x4_add(
      sums,
      @v128.i32x4_extadd_pairwise_i16x8_u(
        @v128.i16x8_extadd_pairwise_i8x16_u(block),
      ),
    )
    // Zero-extended bytes times weights of at most 16: the signed 16-bit
    // products of the dot product are exact.
    weighted = @v128.i32x4_add(
      weighted,
      @v128.i32x4_dot_i16x8_s(
        @v128.i16x8_extend_low_i8x16_u(block),
        weights_low,
      ),
    )
    weighted = @v128.i32x4_add(
      weighted,
      @v128.i32x4_dot_i16x8_s(
        @v128.i16x8_extend_high_i8x16_u(block),
        weights_high,
      ),
    )
  }
  let length = chunks * 16
  self.b = self.b +
    length * self.a +
    (adler_lane_sum(before) << 4) +
    adler_lane_sum(weighted)
  self.a = self.a + adler_lane_sum(sums)
  start + length
}

///|
/// Without vector lanes the eight-byte groups fold the whole block.
#cfg(not(any(target="native", target="wasm")))
#inline
fn Adler32::fold_chunks16(
  _self : Adler32,
  _data : BytesView,
  start : Int32,
  _end : Int32,
) -> Int32 {
  start
}

///|
/// Fold `data` into the running checksum.
pub fn Adler32::update(self : Adler32, data : BytesView) -> Unit {
  let mut a = self.a
  let mut b = self.b
  let mut start = 0
  while start < data.length() {
    let end = start + (data.length() - start).min(ADLER_BLOCK_SIZE)
    // Eight serial steps folded into one: `b` gains `8a` (with `a` from
    // before the group) plus the byte weights 8..1, and `a` gains the plain
    // sum. The `b` terms are collected in two separate sums so no long add
    // chain runs through `b`. Every partial sum is at most the serial loop's
    // `b` after the same bytes, so the block bound still holds, and the
    // reduced result is the same.
    let mut a_sum = 0
    let mut weighted_sum = 0
    // Whole 16-byte chunks go through vector lanes where those are real;
    // the groups below then fold what is left of the block.
    self.a = a
    self.b = b
    let mut i = self.fold_chunks16(data, start, end)
    a = self.a
    b = self.b
    let groups_end = adler_groups_end(i, end)
    while i < groups_end {
      let packed = adler_group8(data, i)
      let weighted = packed >> 16
      a_sum = a_sum + a
      weighted_sum = weighted_sum + weighted
      a = a + (packed & 0xFFFF)
      i = i + 8
    }
    b = b + (a_sum << 3) + weighted_sum
    while i < end {
      a = a + data.unsafe_get(i).to_int()
      b = b + a
      i = i + 1
    }
    a = a % ADLER_MODULUS
    b = b % ADLER_MODULUS
    start = end
  }
  self.a = a
  self.b = b
}

///|
/// Fold a single byte into the running checksum. Lets a caller checksum bytes
/// it can only reach one at a time (e.g. read back from a `MutArrayView`
/// output) without materializing a `Bytes`.
pub fn Adler32::update_byte(self : Adler32, byte : Byte) -> Unit {
  self.a = (self.a + byte.to_int()) % ADLER_MODULUS
  self.b = (self.b + self.a) % ADLER_MODULUS
}

///|
/// The Adler-32 of everything fed so far. Non-destructive.
pub fn Adler32::finish(self : Adler32) -> UInt32 {
  (self.b.reinterpret_as_uint() << 16) | self.a.reinterpret_as_uint()
}

///|
/// Compute the Adler-32 checksum of `data` in one shot. Shared primitive:
/// `@checksum.adler32`.
pub fn adler32(data : BytesView) -> UInt32 {
  let d = Adler32()
  d.update(data[:])
  d.finish()
}
