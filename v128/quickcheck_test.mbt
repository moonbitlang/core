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

// QuickCheck lane-semantics properties for the `v128` package.
//
// Every property builds vectors from per-lane values derived from the
// generated seed array, applies a SIMD operation, extracts all lanes, and
// compares them against the same operation applied lane-by-lane by a scalar
// reference. Lane values are strongly biased toward the sign boundaries
// (0x7f/0x80, 0x7fff/0x8000, ...) where sign-extension, saturation, and
// signed-vs-unsigned bugs surface, and float lanes include NaN, +/-0,
// infinities, and denormals.

///|
/// Avalanche the small integers QuickCheck generates across the full 32-bit
/// range so lane values cover both halves of every lane width.
fn mix(x : UInt, salt : UInt) -> UInt {
  let mut h = x ^ (salt * 0x9E3779B1)
  h = (h ^ (h >> 16)) * 0x85EBCA6B
  h = (h ^ (h >> 13)) * 0xC2B2AE35
  h ^ (h >> 16)
}

///|
fn seed_at(seeds : Array[UInt], index : Int, salt : UInt) -> UInt {
  let base = if seeds.is_empty() { 0U } else { seeds[index % seeds.length()] }
  mix(base + index.reinterpret_as_uint(), salt)
}

///|
/// A byte biased toward the i8 sign boundary.
fn pick_u8(r : UInt) -> Byte {
  match (r >> 28).reinterpret_as_int() {
    0 => 0x00
    1 => 0x01
    2 => 0x7e
    3 => 0x7f
    4 => 0x80
    5 => 0x81
    6 => 0xfe
    7 => 0xff
    _ => (r & 0xff).to_byte()
  }
}

///|
/// A 16-bit lane value (in the low bits of a `UInt`) biased toward the i16
/// sign boundary.
fn pick_u16(r : UInt) -> UInt {
  match (r >> 28).reinterpret_as_int() {
    0 => 0x0000
    1 => 0x0001
    2 => 0x7fff
    3 => 0x8000
    4 => 0x8001
    5 => 0xfffe
    6 => 0xffff
    7 => 0x00ff
    _ => r & 0xffff
  }
}

///|
fn pick_u32(r : UInt) -> UInt {
  match (r >> 28).reinterpret_as_int() {
    0 => 0x00000000
    1 => 0x00000001
    2 => 0x7fffffff
    3 => 0x80000000
    4 => 0x80000001
    5 => 0xffffffff
    6 => 0x0000ffff
    7 => 0xffff0000
    _ => r
  }
}

///|
fn pick_u64(r1 : UInt, r2 : UInt) -> UInt64 {
  match (r1 >> 28).reinterpret_as_int() {
    0 => 0UL
    1 => 1UL
    2 => 0x7fffffffffffffffUL
    3 => 0x8000000000000000UL
    4 => 0x8000000000000001UL
    5 => 0xffffffffffffffffUL
    6 => 0x00000000ffffffffUL
    7 => 0xffffffff00000000UL
    _ => (r1.to_uint64() << 32) | r2.to_uint64()
  }
}

///|
fn lanes8_of(seeds : Array[UInt], salt : UInt) -> Array[Byte] {
  Array::makei(16, i => pick_u8(seed_at(seeds, i, salt)))
}

///|
fn lanes16_of(seeds : Array[UInt], salt : UInt) -> Array[UInt] {
  Array::makei(8, i => pick_u16(seed_at(seeds, i, salt)))
}

///|
fn lanes32_of(seeds : Array[UInt], salt : UInt) -> Array[UInt] {
  Array::makei(4, i => pick_u32(seed_at(seeds, i, salt)))
}

///|
fn lanes64_of(seeds : Array[UInt], salt : UInt) -> Array[UInt64] {
  Array::makei(2, i => {
    pick_u64(seed_at(seeds, i * 2, salt), seed_at(seeds, i * 2 + 1, salt))
  })
}

///|
fn v8(l : Array[Byte]) -> V128 {
  @v128.i8x16_const(
    l[0],
    l[1],
    l[2],
    l[3],
    l[4],
    l[5],
    l[6],
    l[7],
    l[8],
    l[9],
    l[10],
    l[11],
    l[12],
    l[13],
    l[14],
    l[15],
  )
}

///|
fn v16(l : Array[UInt]) -> V128 {
  @v128.i16x8_const(
    l[0].to_uint16(),
    l[1].to_uint16(),
    l[2].to_uint16(),
    l[3].to_uint16(),
    l[4].to_uint16(),
    l[5].to_uint16(),
    l[6].to_uint16(),
    l[7].to_uint16(),
  )
}

///|
fn v32(l : Array[UInt]) -> V128 {
  @v128.i32x4_const(l[0], l[1], l[2], l[3])
}

///|
fn v64(l : Array[UInt64]) -> V128 {
  @v128.i64x2_const(l[0], l[1])
}

///|
fn out8(v : V128) -> Array[Byte] {
  Array::makei(16, i => @v128.i8x16_extract_lane_u(v, i).to_byte())
}

///|
fn out16(v : V128) -> Array[UInt] {
  Array::makei(8, i => @v128.i16x8_extract_lane_u(v, i))
}

///|
fn out32(v : V128) -> Array[UInt] {
  Array::makei(4, i => @v128.i32x4_extract_lane(v, i))
}

///|
fn out64(v : V128) -> Array[UInt64] {
  Array::makei(2, i => @v128.i64x2_extract_lane(v, i))
}

///|
/// The signed value of a byte lane.
fn s8(b : Byte) -> Int {
  let v = b.to_int()
  if v >= 128 {
    v - 256
  } else {
    v
  }
}

///|
/// The signed value of a 16-bit lane held in a `UInt`.
fn s16(x : UInt) -> Int {
  let v = (x & 0xffff).reinterpret_as_int()
  if v >= 32768 {
    v - 65536
  } else {
    v
  }
}

///|
/// Wrap an `Int` to a byte lane (two's complement).
fn w8(v : Int) -> Byte {
  (v & 0xff).to_byte()
}

///|
/// Wrap an `Int` to a 16-bit lane (two's complement).
fn w16(v : Int) -> UInt {
  (v & 0xffff).reinterpret_as_uint()
}

///|
fn clamp(v : Int, lower : Int, upper : Int) -> Int {
  if v < lower {
    lower
  } else if v > upper {
    upper
  } else {
    v
  }
}

///|
fn m8(cond : Bool) -> Byte {
  if cond {
    0xff
  } else {
    0x00
  }
}

///|
fn m16(cond : Bool) -> UInt {
  if cond {
    0xffff
  } else {
    0
  }
}

///|
fn m32(cond : Bool) -> UInt {
  if cond {
    0xffffffff
  } else {
    0
  }
}

///|
fn m64(cond : Bool) -> UInt64 {
  if cond {
    0xffffffffffffffffUL
  } else {
    0
  }
}

///|
test "quickcheck: construct, splat, extract, replace roundtrip" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a8 = lanes8_of(seeds, 0x11)
    let va8 = v8(a8)
    // Lane order is little-endian within the two 64-bit words.
    let mut lo_word = 0UL
    let mut hi_word = 0UL
    for i in 0..<8 {
      lo_word = lo_word | (a8[i].to_uint64() << (i * 8))
      hi_word = hi_word | (a8[i + 8].to_uint64() << (i * 8))
    }
    guard @v128.i64x2_extract_lane(va8, 0) == lo_word &&
      @v128.i64x2_extract_lane(va8, 1) == hi_word else {
      return false
    }
    for i in 0..<16 {
      guard @v128.i8x16_extract_lane_u(va8, i) == a8[i].to_uint() else {
        return false
      }
      guard @v128.i8x16_extract_lane_s(va8, i) ==
        s8(a8[i]).reinterpret_as_uint() else {
        return false
      }
    }
    // Byte lanes viewed as wider lanes agree with little-endian packing.
    for i in 0..<8 {
      let expect = a8[2 * i].to_uint() | (a8[2 * i + 1].to_uint() << 8)
      guard @v128.i16x8_extract_lane_u(va8, i) == expect else { return false }
    }
    let a16 = lanes16_of(seeds, 0x22)
    let va16 = v16(a16)
    guard out16(va16) == a16 else { return false }
    for i in 0..<8 {
      guard @v128.i16x8_extract_lane_s(va16, i) ==
        s16(a16[i]).reinterpret_as_uint() else {
        return false
      }
    }
    let a32 = lanes32_of(seeds, 0x33)
    guard out32(v32(a32)) == a32 else { return false }
    let a64 = lanes64_of(seeds, 0x44)
    guard out64(v64(a64)) == a64 else { return false }
    // Splats fill every lane.
    guard out8(@v128.i8x16_splat(a8[0])) == Array::make(16, a8[0]) else {
      return false
    }
    guard out16(@v128.i16x8_splat(a16[0].to_uint16())) == Array::make(8, a16[0]) else {
      return false
    }
    guard out32(@v128.i32x4_splat(a32[0])) == Array::make(4, a32[0]) else {
      return false
    }
    guard out64(@v128.i64x2_splat(a64[0])) == Array::make(2, a64[0]) else {
      return false
    }
    // Replacing one lane keeps every other lane intact, for every index.
    for i in 0..<16 {
      let r = pick_u8(seed_at(seeds, i, 0x55))
      let expect = a8.copy()
      expect[i] = r
      guard out8(@v128.i8x16_replace_lane(va8, r.to_uint(), i)) == expect else {
        return false
      }
    }
    for i in 0..<8 {
      let r = pick_u16(seed_at(seeds, i, 0x66))
      let expect = a16.copy()
      expect[i] = r
      guard out16(@v128.i16x8_replace_lane(va16, r, i)) == expect else {
        return false
      }
    }
    for i in 0..<4 {
      let r = pick_u32(seed_at(seeds, i, 0x77))
      let expect = a32.copy()
      expect[i] = r
      guard out32(@v128.i32x4_replace_lane(v32(a32), r, i)) == expect else {
        return false
      }
    }
    for i in 0..<2 {
      let r = pick_u64(seed_at(seeds, i, 0x88), seed_at(seeds, i, 0x99))
      let expect = a64.copy()
      expect[i] = r
      guard out64(@v128.i64x2_replace_lane(v64(a64), r, i)) == expect else {
        return false
      }
    }
    true
  })
}

///|
test "quickcheck: i8x16 arithmetic matches scalar reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a = lanes8_of(seeds, 0x1)
    let b = lanes8_of(seeds, 0x2)
    let va = v8(a)
    let vb = v8(b)
    fn binop(got : V128, f : (Byte, Byte) -> Byte) -> Bool {
      out8(got) == Array::makei(16, i => f(a[i], b[i]))
    }

    fn unop(got : V128, f : (Byte) -> Byte) -> Bool {
      out8(got) == Array::makei(16, i => f(a[i]))
    }

    guard binop(@v128.i8x16_add(va, vb), (x, y) => w8(s8(x) + s8(y))) else {
      return false
    }
    guard binop(@v128.i8x16_sub(va, vb), (x, y) => w8(s8(x) - s8(y))) else {
      return false
    }
    guard binop(@v128.i8x16_add_sat_s(va, vb), (x, y) => {
      w8(clamp(s8(x) + s8(y), -128, 127))
    }) else {
      return false
    }
    guard binop(@v128.i8x16_add_sat_u(va, vb), (x, y) => {
      w8(clamp(x.to_int() + y.to_int(), 0, 255))
    }) else {
      return false
    }
    guard binop(@v128.i8x16_sub_sat_s(va, vb), (x, y) => {
      w8(clamp(s8(x) - s8(y), -128, 127))
    }) else {
      return false
    }
    guard binop(@v128.i8x16_sub_sat_u(va, vb), (x, y) => {
      w8(clamp(x.to_int() - y.to_int(), 0, 255))
    }) else {
      return false
    }
    guard binop(@v128.i8x16_min_s(va, vb), (x, y) => {
      if s8(x) < s8(y) {
        x
      } else {
        y
      }
    }) else {
      return false
    }
    guard binop(@v128.i8x16_max_s(va, vb), (x, y) => {
      if s8(x) > s8(y) {
        x
      } else {
        y
      }
    }) else {
      return false
    }
    guard binop(@v128.i8x16_min_u(va, vb), (x, y) => if x < y { x } else { y }) else {
      return false
    }
    guard binop(@v128.i8x16_max_u(va, vb), (x, y) => if x > y { x } else { y }) else {
      return false
    }
    guard binop(@v128.i8x16_avgr_u(va, vb), (x, y) => {
      w8((x.to_int() + y.to_int() + 1) / 2)
    }) else {
      return false
    }
    guard unop(@v128.i8x16_neg(va), x => w8(-s8(x))) else { return false }
    guard unop(@v128.i8x16_abs(va), x => {
      w8(if s8(x) < 0 { -s8(x) } else { s8(x) })
    }) else {
      return false
    }
    guard unop(@v128.i8x16_popcnt(va), x => x.popcnt().to_byte()) else {
      return false
    }
    true
  })
}

///|
test "quickcheck: i16x8 arithmetic matches scalar reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a = lanes16_of(seeds, 0x3)
    let b = lanes16_of(seeds, 0x4)
    let va = v16(a)
    let vb = v16(b)
    fn binop(got : V128, f : (UInt, UInt) -> UInt) -> Bool {
      out16(got) == Array::makei(8, i => f(a[i], b[i]))
    }

    fn unop(got : V128, f : (UInt) -> UInt) -> Bool {
      out16(got) == Array::makei(8, i => f(a[i]))
    }

    guard binop(@v128.i16x8_add(va, vb), (x, y) => w16(s16(x) + s16(y))) else {
      return false
    }
    guard binop(@v128.i16x8_sub(va, vb), (x, y) => w16(s16(x) - s16(y))) else {
      return false
    }
    guard binop(@v128.i16x8_mul(va, vb), (x, y) => w16(s16(x) * s16(y))) else {
      return false
    }
    guard binop(@v128.i16x8_add_sat_s(va, vb), (x, y) => {
      w16(clamp(s16(x) + s16(y), -32768, 32767))
    }) else {
      return false
    }
    guard binop(@v128.i16x8_add_sat_u(va, vb), (x, y) => {
      w16(clamp(x.reinterpret_as_int() + y.reinterpret_as_int(), 0, 65535))
    }) else {
      return false
    }
    guard binop(@v128.i16x8_sub_sat_s(va, vb), (x, y) => {
      w16(clamp(s16(x) - s16(y), -32768, 32767))
    }) else {
      return false
    }
    guard binop(@v128.i16x8_sub_sat_u(va, vb), (x, y) => {
      w16(clamp(x.reinterpret_as_int() - y.reinterpret_as_int(), 0, 65535))
    }) else {
      return false
    }
    guard binop(@v128.i16x8_min_s(va, vb), (x, y) => {
      if s16(x) < s16(y) {
        x
      } else {
        y
      }
    }) else {
      return false
    }
    guard binop(@v128.i16x8_max_s(va, vb), (x, y) => {
      if s16(x) > s16(y) {
        x
      } else {
        y
      }
    }) else {
      return false
    }
    guard binop(@v128.i16x8_min_u(va, vb), (x, y) => if x < y { x } else { y }) else {
      return false
    }
    guard binop(@v128.i16x8_max_u(va, vb), (x, y) => if x > y { x } else { y }) else {
      return false
    }
    guard binop(@v128.i16x8_avgr_u(va, vb), (x, y) => {
      w16((x.reinterpret_as_int() + y.reinterpret_as_int() + 1) / 2)
    }) else {
      return false
    }
    guard binop(@v128.i16x8_q15mulr_sat_s(va, vb), (x, y) => {
      w16(clamp((s16(x) * s16(y) + 0x4000) >> 15, -32768, 32767))
    }) else {
      return false
    }
    guard unop(@v128.i16x8_neg(va), x => w16(-s16(x))) else { return false }
    guard unop(@v128.i16x8_abs(va), x => {
      w16(if s16(x) < 0 { -s16(x) } else { s16(x) })
    }) else {
      return false
    }
    true
  })
}

///|
test "quickcheck: i32x4 arithmetic matches scalar reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a = lanes32_of(seeds, 0x5)
    let b = lanes32_of(seeds, 0x6)
    let va = v32(a)
    let vb = v32(b)
    fn binop(got : V128, f : (UInt, UInt) -> UInt) -> Bool {
      out32(got) == Array::makei(4, i => f(a[i], b[i]))
    }

    fn unop(got : V128, f : (UInt) -> UInt) -> Bool {
      out32(got) == Array::makei(4, i => f(a[i]))
    }

    guard binop(@v128.i32x4_add(va, vb), (x, y) => {
      (x.reinterpret_as_int() + y.reinterpret_as_int()).reinterpret_as_uint()
    }) else {
      return false
    }
    guard binop(@v128.i32x4_sub(va, vb), (x, y) => {
      (x.reinterpret_as_int() - y.reinterpret_as_int()).reinterpret_as_uint()
    }) else {
      return false
    }
    guard binop(@v128.i32x4_mul(va, vb), (x, y) => {
      (x.reinterpret_as_int() * y.reinterpret_as_int()).reinterpret_as_uint()
    }) else {
      return false
    }
    guard binop(@v128.i32x4_min_s(va, vb), (x, y) => {
      if x.reinterpret_as_int() < y.reinterpret_as_int() {
        x
      } else {
        y
      }
    }) else {
      return false
    }
    guard binop(@v128.i32x4_max_s(va, vb), (x, y) => {
      if x.reinterpret_as_int() > y.reinterpret_as_int() {
        x
      } else {
        y
      }
    }) else {
      return false
    }
    guard binop(@v128.i32x4_min_u(va, vb), (x, y) => if x < y { x } else { y }) else {
      return false
    }
    guard binop(@v128.i32x4_max_u(va, vb), (x, y) => if x > y { x } else { y }) else {
      return false
    }
    guard unop(@v128.i32x4_neg(va), x => {
      (0 - x.reinterpret_as_int()).reinterpret_as_uint()
    }) else {
      return false
    }
    guard unop(@v128.i32x4_abs(va), x => {
      let v = x.reinterpret_as_int()
      (if v < 0 { 0 - v } else { v }).reinterpret_as_uint()
    }) else {
      return false
    }
    true
  })
}

///|
test "quickcheck: i64x2 arithmetic matches scalar reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a = lanes64_of(seeds, 0x7)
    let b = lanes64_of(seeds, 0x8)
    let va = v64(a)
    let vb = v64(b)
    fn binop(got : V128, f : (UInt64, UInt64) -> UInt64) -> Bool {
      out64(got) == Array::makei(2, i => f(a[i], b[i]))
    }

    fn unop(got : V128, f : (UInt64) -> UInt64) -> Bool {
      out64(got) == Array::makei(2, i => f(a[i]))
    }

    guard binop(@v128.i64x2_add(va, vb), (x, y) => {
      (x.reinterpret_as_int64() + y.reinterpret_as_int64()).reinterpret_as_uint64()
    }) else {
      return false
    }
    guard binop(@v128.i64x2_sub(va, vb), (x, y) => {
      (x.reinterpret_as_int64() - y.reinterpret_as_int64()).reinterpret_as_uint64()
    }) else {
      return false
    }
    guard binop(@v128.i64x2_mul(va, vb), (x, y) => {
      (x.reinterpret_as_int64() * y.reinterpret_as_int64()).reinterpret_as_uint64()
    }) else {
      return false
    }
    guard unop(@v128.i64x2_neg(va), x => {
      (0L - x.reinterpret_as_int64()).reinterpret_as_uint64()
    }) else {
      return false
    }
    guard unop(@v128.i64x2_abs(va), x => {
      let v = x.reinterpret_as_int64()
      (if v < 0L { 0L - v } else { v }).reinterpret_as_uint64()
    }) else {
      return false
    }
    true
  })
}

///|
test "quickcheck: integer comparisons produce all-ones or all-zeros masks" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a8 = lanes8_of(seeds, 0xa1)
    let b8 = lanes8_of(seeds, 0xa2)
    // Force some equal lanes so eq/le/ge boundaries are exercised.
    for i in 0..<16 {
      if seed_at(seeds, i, 0xa3) % 4 == 0 {
        b8[i] = a8[i]
      }
    }
    let va8 = v8(a8)
    let vb8 = v8(b8)
    fn mask8(got : V128, f : (Byte, Byte) -> Bool) -> Bool {
      out8(got) == Array::makei(16, i => m8(f(a8[i], b8[i])))
    }

    guard mask8(@v128.i8x16_eq(va8, vb8), (x, y) => x == y) else {
      return false
    }
    guard mask8(@v128.i8x16_ne(va8, vb8), (x, y) => x != y) else {
      return false
    }
    guard mask8(@v128.i8x16_lt_s(va8, vb8), (x, y) => s8(x) < s8(y)) else {
      return false
    }
    guard mask8(@v128.i8x16_lt_u(va8, vb8), (x, y) => x < y) else {
      return false
    }
    guard mask8(@v128.i8x16_le_s(va8, vb8), (x, y) => s8(x) <= s8(y)) else {
      return false
    }
    guard mask8(@v128.i8x16_le_u(va8, vb8), (x, y) => x <= y) else {
      return false
    }
    guard mask8(@v128.i8x16_gt_s(va8, vb8), (x, y) => s8(x) > s8(y)) else {
      return false
    }
    guard mask8(@v128.i8x16_gt_u(va8, vb8), (x, y) => x > y) else {
      return false
    }
    guard mask8(@v128.i8x16_ge_s(va8, vb8), (x, y) => s8(x) >= s8(y)) else {
      return false
    }
    guard mask8(@v128.i8x16_ge_u(va8, vb8), (x, y) => x >= y) else {
      return false
    }
    let a16 = lanes16_of(seeds, 0xa4)
    let b16 = lanes16_of(seeds, 0xa5)
    for i in 0..<8 {
      if seed_at(seeds, i, 0xa6) % 4 == 0 {
        b16[i] = a16[i]
      }
    }
    let va16 = v16(a16)
    let vb16 = v16(b16)
    fn mask16(got : V128, f : (UInt, UInt) -> Bool) -> Bool {
      out16(got) == Array::makei(8, i => m16(f(a16[i], b16[i])))
    }

    guard mask16(@v128.i16x8_eq(va16, vb16), (x, y) => x == y) else {
      return false
    }
    guard mask16(@v128.i16x8_ne(va16, vb16), (x, y) => x != y) else {
      return false
    }
    guard mask16(@v128.i16x8_lt_s(va16, vb16), (x, y) => s16(x) < s16(y)) else {
      return false
    }
    guard mask16(@v128.i16x8_lt_u(va16, vb16), (x, y) => x < y) else {
      return false
    }
    guard mask16(@v128.i16x8_le_s(va16, vb16), (x, y) => s16(x) <= s16(y)) else {
      return false
    }
    guard mask16(@v128.i16x8_le_u(va16, vb16), (x, y) => x <= y) else {
      return false
    }
    guard mask16(@v128.i16x8_gt_s(va16, vb16), (x, y) => s16(x) > s16(y)) else {
      return false
    }
    guard mask16(@v128.i16x8_gt_u(va16, vb16), (x, y) => x > y) else {
      return false
    }
    guard mask16(@v128.i16x8_ge_s(va16, vb16), (x, y) => s16(x) >= s16(y)) else {
      return false
    }
    guard mask16(@v128.i16x8_ge_u(va16, vb16), (x, y) => x >= y) else {
      return false
    }
    let a32 = lanes32_of(seeds, 0xa7)
    let b32 = lanes32_of(seeds, 0xa8)
    for i in 0..<4 {
      if seed_at(seeds, i, 0xa9) % 4 == 0 {
        b32[i] = a32[i]
      }
    }
    let va32 = v32(a32)
    let vb32 = v32(b32)
    fn mask32(got : V128, f : (UInt, UInt) -> Bool) -> Bool {
      out32(got) == Array::makei(4, i => m32(f(a32[i], b32[i])))
    }

    guard mask32(@v128.i32x4_eq(va32, vb32), (x, y) => x == y) else {
      return false
    }
    guard mask32(@v128.i32x4_ne(va32, vb32), (x, y) => x != y) else {
      return false
    }
    guard mask32(@v128.i32x4_lt_s(va32, vb32), (x, y) => {
      x.reinterpret_as_int() < y.reinterpret_as_int()
    }) else {
      return false
    }
    guard mask32(@v128.i32x4_lt_u(va32, vb32), (x, y) => x < y) else {
      return false
    }
    guard mask32(@v128.i32x4_le_s(va32, vb32), (x, y) => {
      x.reinterpret_as_int() <= y.reinterpret_as_int()
    }) else {
      return false
    }
    guard mask32(@v128.i32x4_le_u(va32, vb32), (x, y) => x <= y) else {
      return false
    }
    guard mask32(@v128.i32x4_gt_s(va32, vb32), (x, y) => {
      x.reinterpret_as_int() > y.reinterpret_as_int()
    }) else {
      return false
    }
    guard mask32(@v128.i32x4_gt_u(va32, vb32), (x, y) => x > y) else {
      return false
    }
    guard mask32(@v128.i32x4_ge_s(va32, vb32), (x, y) => {
      x.reinterpret_as_int() >= y.reinterpret_as_int()
    }) else {
      return false
    }
    guard mask32(@v128.i32x4_ge_u(va32, vb32), (x, y) => x >= y) else {
      return false
    }
    let a64 = lanes64_of(seeds, 0xaa)
    let b64 = lanes64_of(seeds, 0xab)
    for i in 0..<2 {
      if seed_at(seeds, i, 0xac) % 4 == 0 {
        b64[i] = a64[i]
      }
    }
    let va64 = v64(a64)
    let vb64 = v64(b64)
    fn mask64(got : V128, f : (UInt64, UInt64) -> Bool) -> Bool {
      out64(got) == Array::makei(2, i => m64(f(a64[i], b64[i])))
    }

    guard mask64(@v128.i64x2_eq(va64, vb64), (x, y) => x == y) else {
      return false
    }
    guard mask64(@v128.i64x2_ne(va64, vb64), (x, y) => x != y) else {
      return false
    }
    guard mask64(@v128.i64x2_lt_s(va64, vb64), (x, y) => {
      x.reinterpret_as_int64() < y.reinterpret_as_int64()
    }) else {
      return false
    }
    guard mask64(@v128.i64x2_le_s(va64, vb64), (x, y) => {
      x.reinterpret_as_int64() <= y.reinterpret_as_int64()
    }) else {
      return false
    }
    guard mask64(@v128.i64x2_gt_s(va64, vb64), (x, y) => {
      x.reinterpret_as_int64() > y.reinterpret_as_int64()
    }) else {
      return false
    }
    guard mask64(@v128.i64x2_ge_s(va64, vb64), (x, y) => {
      x.reinterpret_as_int64() >= y.reinterpret_as_int64()
    }) else {
      return false
    }
    true
  })
}

///|
test "quickcheck: any_true, all_true and bitmask agree with scalar folds" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a8 = lanes8_of(seeds, 0xb1)
    let va8 = v8(a8)
    let mut any = false
    let mut all8 = true
    let mut bm8 = 0
    for i in 0..<16 {
      if a8[i] != 0 {
        any = true
      } else {
        all8 = false
      }
      if s8(a8[i]) < 0 {
        bm8 = bm8 | (1 << i)
      }
    }
    guard @v128.v128_any_true(va8) == any else { return false }
    guard @v128.i8x16_all_true(va8) == all8 else { return false }
    guard @v128.i8x16_bitmask(va8) == bm8 else { return false }
    let a16 = lanes16_of(seeds, 0xb2)
    let va16 = v16(a16)
    let mut all16 = true
    let mut bm16 = 0
    for i in 0..<8 {
      if a16[i] == 0 {
        all16 = false
      }
      if s16(a16[i]) < 0 {
        bm16 = bm16 | (1 << i)
      }
    }
    guard @v128.i16x8_all_true(va16) == all16 else { return false }
    guard @v128.i16x8_bitmask(va16) == bm16 else { return false }
    let a32 = lanes32_of(seeds, 0xb3)
    let va32 = v32(a32)
    let mut all32 = true
    let mut bm32 = 0
    for i in 0..<4 {
      if a32[i] == 0 {
        all32 = false
      }
      if a32[i].reinterpret_as_int() < 0 {
        bm32 = bm32 | (1 << i)
      }
    }
    guard @v128.i32x4_all_true(va32) == all32 else { return false }
    guard @v128.i32x4_bitmask(va32) == bm32 else { return false }
    let a64 = lanes64_of(seeds, 0xb4)
    let va64 = v64(a64)
    let mut all64 = true
    let mut bm64 = 0
    for i in 0..<2 {
      if a64[i] == 0 {
        all64 = false
      }
      if a64[i].reinterpret_as_int64() < 0L {
        bm64 = bm64 | (1 << i)
      }
    }
    guard @v128.i64x2_all_true(va64) == all64 else { return false }
    guard @v128.i64x2_bitmask(va64) == bm64 else { return false }
    true
  })
}

///|
test "quickcheck: bitwise ops match the 64-bit word reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a = lanes64_of(seeds, 0xc1)
    let b = lanes64_of(seeds, 0xc2)
    let c = lanes64_of(seeds, 0xc3)
    let va = v64(a)
    let vb = v64(b)
    let vc = v64(c)
    guard out64(@v128.v128_not(va)) == [a[0].lnot(), a[1].lnot()] else {
      return false
    }
    guard out64(@v128.v128_and_(va, vb)) == [a[0] & b[0], a[1] & b[1]] else {
      return false
    }
    guard out64(@v128.v128_or_(va, vb)) == [a[0] | b[0], a[1] | b[1]] else {
      return false
    }
    guard out64(@v128.v128_xor(va, vb)) == [a[0] ^ b[0], a[1] ^ b[1]] else {
      return false
    }
    guard out64(@v128.v128_andnot(va, vb)) ==
      [a[0] & b[0].lnot(), a[1] & b[1].lnot()] else {
      return false
    }
    guard out64(@v128.v128_bitselect(va, vb, vc)) ==
      [
        (a[0] & c[0]) | (b[0] & c[0].lnot()),
        (a[1] & c[1]) | (b[1] & c[1].lnot()),
      ] else {
      return false
    }
    true
  })
}

///|
test "quickcheck: shifts mask the shift count by the lane width" {
  @quickcheck.check(count=200, (seeds : Array[UInt]) => {
    let a8 = lanes8_of(seeds, 0xd1)
    let va8 = v8(a8)
    let a16 = lanes16_of(seeds, 0xd2)
    let va16 = v16(a16)
    let a32 = lanes32_of(seeds, 0xd3)
    let va32 = v32(a32)
    let a64 = lanes64_of(seeds, 0xd4)
    let va64 = v64(a64)
    let shifts = [0, 1, 3, 7, 8, 9, 15, 16, 17, 31, 32, 33, 63, 64, 65, 100]
    for sh in shifts {
      let s3 = sh & 7
      guard out8(@v128.i8x16_shl(va8, sh)) ==
        Array::makei(16, i => w8(a8[i].to_int() << s3)) else {
        return false
      }
      guard out8(@v128.i8x16_shr_u(va8, sh)) ==
        Array::makei(16, i => w8(a8[i].to_int() >> s3)) else {
        return false
      }
      guard out8(@v128.i8x16_shr_s(va8, sh)) ==
        Array::makei(16, i => w8(s8(a8[i]) >> s3)) else {
        return false
      }
      let s4 = sh & 15
      guard out16(@v128.i16x8_shl(va16, sh)) ==
        Array::makei(8, i => w16(a16[i].reinterpret_as_int() << s4)) else {
        return false
      }
      guard out16(@v128.i16x8_shr_u(va16, sh)) ==
        Array::makei(8, i => w16(a16[i].reinterpret_as_int() >> s4)) else {
        return false
      }
      guard out16(@v128.i16x8_shr_s(va16, sh)) ==
        Array::makei(8, i => w16(s16(a16[i]) >> s4)) else {
        return false
      }
      let s5 = sh & 31
      guard out32(@v128.i32x4_shl(va32, sh)) ==
        Array::makei(4, i => a32[i] << s5) else {
        return false
      }
      guard out32(@v128.i32x4_shr_u(va32, sh)) ==
        Array::makei(4, i => a32[i] >> s5) else {
        return false
      }
      guard out32(@v128.i32x4_shr_s(va32, sh)) ==
        Array::makei(4, i => {
          (a32[i].reinterpret_as_int() >> s5).reinterpret_as_uint()
        }) else {
        return false
      }
      let s6 = sh & 63
      guard out64(@v128.i64x2_shl(va64, sh)) ==
        Array::makei(2, i => a64[i] << s6) else {
        return false
      }
      guard out64(@v128.i64x2_shr_u(va64, sh)) ==
        Array::makei(2, i => a64[i] >> s6) else {
        return false
      }
      guard out64(@v128.i64x2_shr_s(va64, sh)) ==
        Array::makei(2, i => {
          (a64[i].reinterpret_as_int64() >> s6).reinterpret_as_uint64()
        }) else {
        return false
      }
    }
    true
  })
}

///|
test "quickcheck: widening, narrowing and pairwise ops match scalar reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a8 = lanes8_of(seeds, 0xe1)
    let b8 = lanes8_of(seeds, 0xe2)
    let va8 = v8(a8)
    let vb8 = v8(b8)
    let a16 = lanes16_of(seeds, 0xe3)
    let b16 = lanes16_of(seeds, 0xe4)
    let va16 = v16(a16)
    let vb16 = v16(b16)
    let a32 = lanes32_of(seeds, 0xe5)
    let b32 = lanes32_of(seeds, 0xe6)
    let va32 = v32(a32)
    let vb32 = v32(b32)
    // 8 -> 16 extensions
    guard out16(@v128.i16x8_extend_low_i8x16_s(va8)) ==
      Array::makei(8, i => w16(s8(a8[i]))) else {
      return false
    }
    guard out16(@v128.i16x8_extend_high_i8x16_s(va8)) ==
      Array::makei(8, i => w16(s8(a8[i + 8]))) else {
      return false
    }
    guard out16(@v128.i16x8_extend_low_i8x16_u(va8)) ==
      Array::makei(8, i => a8[i].to_uint()) else {
      return false
    }
    guard out16(@v128.i16x8_extend_high_i8x16_u(va8)) ==
      Array::makei(8, i => a8[i + 8].to_uint()) else {
      return false
    }
    // 16 -> 32 extensions
    guard out32(@v128.i32x4_extend_low_i16x8_s(va16)) ==
      Array::makei(4, i => s16(a16[i]).reinterpret_as_uint()) else {
      return false
    }
    guard out32(@v128.i32x4_extend_high_i16x8_s(va16)) ==
      Array::makei(4, i => s16(a16[i + 4]).reinterpret_as_uint()) else {
      return false
    }
    guard out32(@v128.i32x4_extend_low_i16x8_u(va16)) ==
      Array::makei(4, i => a16[i]) else {
      return false
    }
    guard out32(@v128.i32x4_extend_high_i16x8_u(va16)) ==
      Array::makei(4, i => a16[i + 4]) else {
      return false
    }
    // 32 -> 64 extensions
    guard out64(@v128.i64x2_extend_low_i32x4_s(va32)) ==
      Array::makei(2, i => {
        a32[i].reinterpret_as_int().to_int64().reinterpret_as_uint64()
      }) else {
      return false
    }
    guard out64(@v128.i64x2_extend_high_i32x4_s(va32)) ==
      Array::makei(2, i => {
        a32[i + 2].reinterpret_as_int().to_int64().reinterpret_as_uint64()
      }) else {
      return false
    }
    guard out64(@v128.i64x2_extend_low_i32x4_u(va32)) ==
      Array::makei(2, i => a32[i].to_uint64()) else {
      return false
    }
    guard out64(@v128.i64x2_extend_high_i32x4_u(va32)) ==
      Array::makei(2, i => a32[i + 2].to_uint64()) else {
      return false
    }
    // Narrowing with saturation, low operand first.
    guard out8(@v128.i8x16_narrow_i16x8_s(va16, vb16)) ==
      Array::makei(16, i => {
        if i < 8 {
          w8(clamp(s16(a16[i]), -128, 127))
        } else {
          w8(clamp(s16(b16[i - 8]), -128, 127))
        }
      }) else {
      return false
    }
    guard out8(@v128.i8x16_narrow_i16x8_u(va16, vb16)) ==
      Array::makei(16, i => {
        if i < 8 {
          w8(clamp(s16(a16[i]), 0, 255))
        } else {
          w8(clamp(s16(b16[i - 8]), 0, 255))
        }
      }) else {
      return false
    }
    guard out16(@v128.i16x8_narrow_i32x4_s(va32, vb32)) ==
      Array::makei(8, i => {
        if i < 4 {
          w16(clamp(a32[i].reinterpret_as_int(), -32768, 32767))
        } else {
          w16(clamp(b32[i - 4].reinterpret_as_int(), -32768, 32767))
        }
      }) else {
      return false
    }
    guard out16(@v128.i16x8_narrow_i32x4_u(va32, vb32)) ==
      Array::makei(8, i => {
        if i < 4 {
          w16(clamp(a32[i].reinterpret_as_int(), 0, 65535))
        } else {
          w16(clamp(b32[i - 4].reinterpret_as_int(), 0, 65535))
        }
      }) else {
      return false
    }
    // Widening multiplies
    guard out16(@v128.i16x8_extmul_low_i8x16_s(va8, vb8)) ==
      Array::makei(8, i => w16(s8(a8[i]) * s8(b8[i]))) else {
      return false
    }
    guard out16(@v128.i16x8_extmul_high_i8x16_s(va8, vb8)) ==
      Array::makei(8, i => w16(s8(a8[i + 8]) * s8(b8[i + 8]))) else {
      return false
    }
    guard out16(@v128.i16x8_extmul_low_i8x16_u(va8, vb8)) ==
      Array::makei(8, i => w16(a8[i].to_int() * b8[i].to_int())) else {
      return false
    }
    guard out16(@v128.i16x8_extmul_high_i8x16_u(va8, vb8)) ==
      Array::makei(8, i => w16(a8[i + 8].to_int() * b8[i + 8].to_int())) else {
      return false
    }
    guard out32(@v128.i32x4_extmul_low_i16x8_s(va16, vb16)) ==
      Array::makei(4, i => (s16(a16[i]) * s16(b16[i])).reinterpret_as_uint()) else {
      return false
    }
    guard out32(@v128.i32x4_extmul_high_i16x8_s(va16, vb16)) ==
      Array::makei(4, i => {
        (s16(a16[i + 4]) * s16(b16[i + 4])).reinterpret_as_uint()
      }) else {
      return false
    }
    guard out32(@v128.i32x4_extmul_low_i16x8_u(va16, vb16)) ==
      Array::makei(4, i => a16[i] * b16[i]) else {
      return false
    }
    guard out32(@v128.i32x4_extmul_high_i16x8_u(va16, vb16)) ==
      Array::makei(4, i => a16[i + 4] * b16[i + 4]) else {
      return false
    }
    guard out64(@v128.i64x2_extmul_low_i32x4_s(va32, vb32)) ==
      Array::makei(2, i => {
        (a32[i].reinterpret_as_int().to_int64() *
        b32[i].reinterpret_as_int().to_int64()).reinterpret_as_uint64()
      }) else {
      return false
    }
    guard out64(@v128.i64x2_extmul_high_i32x4_s(va32, vb32)) ==
      Array::makei(2, i => {
        (a32[i + 2].reinterpret_as_int().to_int64() *
        b32[i + 2].reinterpret_as_int().to_int64()).reinterpret_as_uint64()
      }) else {
      return false
    }
    guard out64(@v128.i64x2_extmul_low_i32x4_u(va32, vb32)) ==
      Array::makei(2, i => a32[i].to_uint64() * b32[i].to_uint64()) else {
      return false
    }
    guard out64(@v128.i64x2_extmul_high_i32x4_u(va32, vb32)) ==
      Array::makei(2, i => a32[i + 2].to_uint64() * b32[i + 2].to_uint64()) else {
      return false
    }
    // Pairwise widening adds
    guard out16(@v128.i16x8_extadd_pairwise_i8x16_s(va8)) ==
      Array::makei(8, i => w16(s8(a8[2 * i]) + s8(a8[2 * i + 1]))) else {
      return false
    }
    guard out16(@v128.i16x8_extadd_pairwise_i8x16_u(va8)) ==
      Array::makei(8, i => w16(a8[2 * i].to_int() + a8[2 * i + 1].to_int())) else {
      return false
    }
    guard out32(@v128.i32x4_extadd_pairwise_i16x8_s(va16)) ==
      Array::makei(4, i => {
        (s16(a16[2 * i]) + s16(a16[2 * i + 1])).reinterpret_as_uint()
      }) else {
      return false
    }
    guard out32(@v128.i32x4_extadd_pairwise_i16x8_u(va16)) ==
      Array::makei(4, i => a16[2 * i] + a16[2 * i + 1]) else {
      return false
    }
    // Dot products
    guard out32(@v128.i32x4_dot_i16x8_s(va16, vb16)) ==
      Array::makei(4, i => {
        (s16(a16[2 * i]) * s16(b16[2 * i]) +
        s16(a16[2 * i + 1]) * s16(b16[2 * i + 1])).reinterpret_as_uint()
      }) else {
      return false
    }
    // Relaxed dot products are only fully specified when the second operand
    // has i7 (non-negative) lanes.
    let b7 = Array::makei(16, i => b8[i] & 0x7f)
    guard out16(@v128.i16x8_relaxed_dot_i8x16_i7x16_s(va8, v8(b7))) ==
      Array::makei(8, i => {
        w16(
          s8(a8[2 * i]) * b7[2 * i].to_int() +
          s8(a8[2 * i + 1]) * b7[2 * i + 1].to_int(),
        )
      }) else {
      return false
    }
    guard out32(@v128.i32x4_relaxed_dot_i8x16_i7x16_add_s(va8, v8(b7), va32)) ==
      Array::makei(4, j => {
        let dot = s8(a8[4 * j]) * b7[4 * j].to_int() +
          s8(a8[4 * j + 1]) * b7[4 * j + 1].to_int() +
          s8(a8[4 * j + 2]) * b7[4 * j + 2].to_int() +
          s8(a8[4 * j + 3]) * b7[4 * j + 3].to_int()
        (dot + a32[j].reinterpret_as_int()).reinterpret_as_uint()
      }) else {
      return false
    }
    true
  })
}

///|
test "quickcheck: swizzle, shuffle and lane selects" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a = lanes8_of(seeds, 0xf1)
    let b = lanes8_of(seeds, 0xf2)
    let va = v8(a)
    let vb = v8(b)
    // Swizzle: out-of-range indices (>= 16) select zero.
    let idx = Array::makei(16, i => (seed_at(seeds, i, 0xf3) % 40).to_byte())
    let swizzled = out8(@v128.i8x16_swizzle(va, v8(idx)))
    for i in 0..<16 {
      let j = idx[i].to_int()
      let expect : Byte = if j < 16 { a[j] } else { 0 }
      guard swizzled[i] == expect else { return false }
    }
    // Relaxed swizzle is only fully specified for in-range indices.
    let idx2 = Array::makei(16, i => idx[i] & 0x0f)
    guard out8(@v128.i8x16_relaxed_swizzle(va, v8(idx2))) ==
      Array::makei(16, i => a[idx2[i].to_int()]) else {
      return false
    }
    // Constant-index shuffle: interleave the low halves.
    guard out8(
        @v128.i8x16_shuffle(
          va, vb, 0, 16, 1, 17, 2, 18, 3, 19, 4, 20, 5, 21, 6, 22, 7, 23,
        ),
      ) ==
      Array::makei(16, i => if i % 2 == 0 { a[i / 2] } else { b[i / 2] }) else {
      return false
    }
    // Runtime-index shuffle over the concatenation of both vectors.
    let ridx = Array::makei(16, i => {
      (seed_at(seeds, i, 0xf4) % 32).reinterpret_as_int()
    })
    let shuffled = out8(
      @v128.i8x16_shuffle(
        va,
        vb,
        ridx[0],
        ridx[1],
        ridx[2],
        ridx[3],
        ridx[4],
        ridx[5],
        ridx[6],
        ridx[7],
        ridx[8],
        ridx[9],
        ridx[10],
        ridx[11],
        ridx[12],
        ridx[13],
        ridx[14],
        ridx[15],
      ),
    )
    for i in 0..<16 {
      let r = ridx[i]
      let expect = if r < 16 { a[r] } else { b[r - 16] }
      guard shuffled[i] == expect else { return false }
    }
    // Lane selects driven by canonical (all-ones / all-zeros) masks.
    let c8 = lanes8_of(seeds, 0xf5)
    let mask8v = @v128.i8x16_lt_s(vb, v8(c8))
    let selected8 = Array::makei(16, i => {
      if s8(b[i]) < s8(c8[i]) {
        a[i]
      } else {
        b[i]
      }
    })
    guard out8(@v128.i8x16_relaxed_laneselect(va, vb, mask8v)) == selected8 else {
      return false
    }
    // With a canonical mask, bitselect agrees with laneselect.
    guard out8(@v128.v128_bitselect(va, vb, mask8v)) == selected8 else {
      return false
    }
    let a16 = lanes16_of(seeds, 0xf6)
    let b16 = lanes16_of(seeds, 0xf7)
    let c16 = lanes16_of(seeds, 0xf8)
    let mask16v = @v128.i16x8_lt_s(v16(b16), v16(c16))
    guard out16(@v128.i16x8_relaxed_laneselect(v16(a16), v16(b16), mask16v)) ==
      Array::makei(8, i => {
        if s16(b16[i]) < s16(c16[i]) {
          a16[i]
        } else {
          b16[i]
        }
      }) else {
      return false
    }
    let a32 = lanes32_of(seeds, 0xf9)
    let b32 = lanes32_of(seeds, 0xfa)
    let c32 = lanes32_of(seeds, 0xfb)
    let mask32v = @v128.i32x4_lt_s(v32(b32), v32(c32))
    guard out32(@v128.i32x4_relaxed_laneselect(v32(a32), v32(b32), mask32v)) ==
      Array::makei(4, i => {
        if b32[i].reinterpret_as_int() < c32[i].reinterpret_as_int() {
          a32[i]
        } else {
          b32[i]
        }
      }) else {
      return false
    }
    let a64 = lanes64_of(seeds, 0xfc)
    let b64 = lanes64_of(seeds, 0xfd)
    let c64 = lanes64_of(seeds, 0xfe)
    let mask64v = @v128.i64x2_lt_s(v64(b64), v64(c64))
    guard out64(@v128.i64x2_relaxed_laneselect(v64(a64), v64(b64), mask64v)) ==
      Array::makei(2, i => {
        if b64[i].reinterpret_as_int64() < c64[i].reinterpret_as_int64() {
          a64[i]
        } else {
          b64[i]
        }
      }) else {
      return false
    }
    true
  })
}

///|
/// A 32-bit float bit pattern biased toward special values.
fn pick_f32_bits(r : UInt) -> UInt {
  match (r >> 28).reinterpret_as_int() {
    0 => 0x00000000 // +0.0
    1 => 0x80000000 // -0.0
    2 => 0x3f800000 // 1.0
    3 => 0xbf800000 // -1.0
    4 => 0x7f800000 // +inf
    5 => 0xff800000 // -inf
    6 => 0x7fc00000 // NaN
    7 => 0x00000001 // denormal
    8 => 0x7f7fffff // max finite
    9 => 0x3f000000 // 0.5
    10 => 0xbf000000 // -0.5
    11 => 0x40200000 // 2.5
    _ => r
  }
}

///|
/// A 64-bit float bit pattern biased toward special values.
fn pick_f64_bits(r1 : UInt, r2 : UInt) -> UInt64 {
  match (r1 >> 28).reinterpret_as_int() {
    0 => 0x0000000000000000UL // +0.0
    1 => 0x8000000000000000UL // -0.0
    2 => 0x3ff0000000000000UL // 1.0
    3 => 0xbff0000000000000UL // -1.0
    4 => 0x7ff0000000000000UL // +inf
    5 => 0xfff0000000000000UL // -inf
    6 => 0x7ff8000000000000UL // NaN
    7 => 0x0000000000000001UL // denormal
    8 => 0x3fe0000000000000UL // 0.5
    9 => 0xbfe0000000000000UL // -0.5
    10 => 0x4004000000000000UL // 2.5
    11 => 0xc004000000000000UL // -2.5
    _ => (r1.to_uint64() << 32) | r2.to_uint64()
  }
}

///|
/// Bitwise equality, except that any NaN matches any NaN: NaN payloads are
/// not guaranteed to be preserved across every backend.
fn f32_bits_ok(got_bits : UInt, expect : Float) -> Bool {
  if expect.is_nan() {
    Float::reinterpret_from_uint(got_bits).is_nan()
  } else {
    got_bits == expect.reinterpret_as_uint()
  }
}

///|
fn f64_bits_ok(got_bits : UInt64, expect : Double) -> Bool {
  if expect.is_nan() {
    got_bits.reinterpret_as_double().is_nan()
  } else {
    got_bits == expect.reinterpret_as_uint64()
  }
}

///|
/// Round to nearest, ties to even, preserving the sign of zero results.
fn ref_nearest(v : Double) -> Double {
  if v.is_nan() || v.is_inf() || v == 0.0 {
    return v
  }
  let f = v.floor()
  let diff = v - f
  let r = if diff < 0.5 {
    f
  } else if diff > 0.5 {
    f + 1.0
  } else if (f * 0.5).floor() * 2.0 == f {
    f
  } else {
    f + 1.0
  }
  if r == 0.0 && v < 0.0 {
    -0.0
  } else {
    r
  }
}

///|
fn ref_nearest_f32(v : Float) -> Float {
  Float::from_double(ref_nearest(v.to_double()))
}

///|
/// Wasm `min`: NaN propagates and `min(-0.0, +0.0)` is `-0.0`.
fn ref_f32_min(x : Float, y : Float) -> Float {
  if x.is_nan() {
    x
  } else if y.is_nan() {
    y
  } else if x < y {
    x
  } else if y < x {
    y
  } else {
    Float::reinterpret_from_uint(
      x.reinterpret_as_uint() | y.reinterpret_as_uint(),
    )
  }
}

///|
/// Wasm `max`: NaN propagates and `max(-0.0, +0.0)` is `+0.0`.
fn ref_f32_max(x : Float, y : Float) -> Float {
  if x.is_nan() {
    x
  } else if y.is_nan() {
    y
  } else if x > y {
    x
  } else if y > x {
    y
  } else {
    Float::reinterpret_from_uint(
      x.reinterpret_as_uint() & y.reinterpret_as_uint(),
    )
  }
}

///|
fn ref_f64_min(x : Double, y : Double) -> Double {
  if x.is_nan() {
    x
  } else if y.is_nan() {
    y
  } else if x < y {
    x
  } else if y < x {
    y
  } else {
    (x.reinterpret_as_uint64() | y.reinterpret_as_uint64()).reinterpret_as_double()
  }
}

///|
fn ref_f64_max(x : Double, y : Double) -> Double {
  if x.is_nan() {
    x
  } else if y.is_nan() {
    y
  } else if x > y {
    x
  } else if y > x {
    y
  } else {
    (x.reinterpret_as_uint64() & y.reinterpret_as_uint64()).reinterpret_as_double()
  }
}

///|
test "quickcheck: f32x4 ops match scalar Float reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let abits = Array::makei(4, i => pick_f32_bits(seed_at(seeds, i, 0x301)))
    let bbits = Array::makei(4, i => pick_f32_bits(seed_at(seeds, i, 0x302)))
    let va = v32(abits)
    let vb = v32(bbits)
    let af = Array::makei(4, i => Float::reinterpret_from_uint(abits[i]))
    let bf = Array::makei(4, i => Float::reinterpret_from_uint(bbits[i]))
    fn binop(got : V128, f : (Float, Float) -> Float) -> Bool {
      let bits = out32(got)
      for i in 0..<4 {
        if !f32_bits_ok(bits[i], f(af[i], bf[i])) {
          return false
        }
      }
      true
    }

    fn unop(got : V128, f : (Float) -> Float) -> Bool {
      let bits = out32(got)
      for i in 0..<4 {
        if !f32_bits_ok(bits[i], f(af[i])) {
          return false
        }
      }
      true
    }

    fn cmpop(got : V128, f : (Float, Float) -> Bool) -> Bool {
      out32(got) == Array::makei(4, i => m32(f(af[i], bf[i])))
    }

    // Lane extraction and splat/replace roundtrip.
    for i in 0..<4 {
      guard f32_bits_ok(
        @v128.f32x4_extract_lane(va, i).reinterpret_as_uint(),
        af[i],
      ) else {
        return false
      }
    }
    let splat_bits = out32(@v128.f32x4_splat(af[0]))
    for i in 0..<4 {
      guard f32_bits_ok(splat_bits[i], af[0]) else { return false }
    }
    for i in 0..<4 {
      let replaced = out32(@v128.f32x4_replace_lane(va, bf[0], i))
      for j in 0..<4 {
        let expect = if j == i { bf[0] } else { af[j] }
        guard f32_bits_ok(replaced[j], expect) else { return false }
      }
    }
    // Arithmetic
    guard binop(@v128.f32x4_add(va, vb), (x, y) => x + y) else { return false }
    guard binop(@v128.f32x4_sub(va, vb), (x, y) => x - y) else { return false }
    guard binop(@v128.f32x4_mul(va, vb), (x, y) => x * y) else { return false }
    guard binop(@v128.f32x4_div(va, vb), (x, y) => x / y) else { return false }
    guard binop(@v128.f32x4_min(va, vb), ref_f32_min) else { return false }
    guard binop(@v128.f32x4_max(va, vb), ref_f32_max) else { return false }
    guard binop(@v128.f32x4_pmin(va, vb), (x, y) => if y < x { y } else { x }) else {
      return false
    }
    guard binop(@v128.f32x4_pmax(va, vb), (x, y) => if x < y { y } else { x }) else {
      return false
    }
    guard unop(@v128.f32x4_abs(va), x => x.abs()) else { return false }
    guard unop(@v128.f32x4_neg(va), x => -x) else { return false }
    guard unop(@v128.f32x4_sqrt(va), x => x.sqrt()) else { return false }
    guard unop(@v128.f32x4_ceil(va), x => x.ceil()) else { return false }
    guard unop(@v128.f32x4_floor(va), x => x.floor()) else { return false }
    guard unop(@v128.f32x4_trunc(va), x => x.trunc()) else { return false }
    guard unop(@v128.f32x4_nearest(va), ref_nearest_f32) else { return false }
    // Comparisons (NaN compares false except through ne).
    guard cmpop(@v128.f32x4_eq(va, vb), (x, y) => x == y) else { return false }
    guard cmpop(@v128.f32x4_ne(va, vb), (x, y) => x != y) else { return false }
    guard cmpop(@v128.f32x4_lt(va, vb), (x, y) => x < y) else { return false }
    guard cmpop(@v128.f32x4_le(va, vb), (x, y) => x <= y) else { return false }
    guard cmpop(@v128.f32x4_gt(va, vb), (x, y) => x > y) else { return false }
    guard cmpop(@v128.f32x4_ge(va, vb), (x, y) => x >= y) else { return false }
    // Relaxed fused multiply-add: use small integers so that fused and
    // unfused lowerings give bit-identical results.
    let sa = Array::makei(4, i => {
      Float::from_int((seed_at(seeds, i, 0x303) % 33).reinterpret_as_int() - 16)
    })
    let sb = Array::makei(4, i => {
      Float::from_int((seed_at(seeds, i, 0x304) % 33).reinterpret_as_int() - 16)
    })
    let sc = Array::makei(4, i => {
      Float::from_int((seed_at(seeds, i, 0x305) % 33).reinterpret_as_int() - 16)
    })
    let vsa = @v128.f32x4_const(sa[0], sa[1], sa[2], sa[3])
    let vsb = @v128.f32x4_const(sb[0], sb[1], sb[2], sb[3])
    let vsc = @v128.f32x4_const(sc[0], sc[1], sc[2], sc[3])
    let madd = out32(@v128.f32x4_relaxed_madd(vsa, vsb, vsc))
    let nmadd = out32(@v128.f32x4_relaxed_nmadd(vsa, vsb, vsc))
    for i in 0..<4 {
      guard f32_bits_ok(madd[i], sa[i] * sb[i] + sc[i]) else { return false }
      guard f32_bits_ok(nmadd[i], sc[i] - sa[i] * sb[i]) else { return false }
    }
    true
  })
}

///|
test "quickcheck: f64x2 ops match scalar Double reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let abits = Array::makei(2, i => {
      pick_f64_bits(
        seed_at(seeds, 2 * i, 0x311),
        seed_at(seeds, 2 * i + 1, 0x311),
      )
    })
    let bbits = Array::makei(2, i => {
      pick_f64_bits(
        seed_at(seeds, 2 * i, 0x312),
        seed_at(seeds, 2 * i + 1, 0x312),
      )
    })
    let va = v64(abits)
    let vb = v64(bbits)
    let af = Array::makei(2, i => abits[i].reinterpret_as_double())
    let bf = Array::makei(2, i => bbits[i].reinterpret_as_double())
    fn binop(got : V128, f : (Double, Double) -> Double) -> Bool {
      let bits = out64(got)
      for i in 0..<2 {
        if !f64_bits_ok(bits[i], f(af[i], bf[i])) {
          return false
        }
      }
      true
    }

    fn unop(got : V128, f : (Double) -> Double) -> Bool {
      let bits = out64(got)
      for i in 0..<2 {
        if !f64_bits_ok(bits[i], f(af[i])) {
          return false
        }
      }
      true
    }

    fn cmpop(got : V128, f : (Double, Double) -> Bool) -> Bool {
      out64(got) == Array::makei(2, i => m64(f(af[i], bf[i])))
    }

    // Lane extraction and splat/replace roundtrip.
    for i in 0..<2 {
      guard f64_bits_ok(
        @v128.f64x2_extract_lane(va, i).reinterpret_as_uint64(),
        af[i],
      ) else {
        return false
      }
    }
    let splat_bits = out64(@v128.f64x2_splat(af[0]))
    for i in 0..<2 {
      guard f64_bits_ok(splat_bits[i], af[0]) else { return false }
    }
    for i in 0..<2 {
      let replaced = out64(@v128.f64x2_replace_lane(va, bf[0], i))
      for j in 0..<2 {
        let expect = if j == i { bf[0] } else { af[j] }
        guard f64_bits_ok(replaced[j], expect) else { return false }
      }
    }
    // Arithmetic
    guard binop(@v128.f64x2_add(va, vb), (x, y) => x + y) else { return false }
    guard binop(@v128.f64x2_sub(va, vb), (x, y) => x - y) else { return false }
    guard binop(@v128.f64x2_mul(va, vb), (x, y) => x * y) else { return false }
    guard binop(@v128.f64x2_div(va, vb), (x, y) => x / y) else { return false }
    guard binop(@v128.f64x2_min(va, vb), ref_f64_min) else { return false }
    guard binop(@v128.f64x2_max(va, vb), ref_f64_max) else { return false }
    guard binop(@v128.f64x2_pmin(va, vb), (x, y) => if y < x { y } else { x }) else {
      return false
    }
    guard binop(@v128.f64x2_pmax(va, vb), (x, y) => if x < y { y } else { x }) else {
      return false
    }
    guard unop(@v128.f64x2_abs(va), x => x.abs()) else { return false }
    guard unop(@v128.f64x2_neg(va), x => -x) else { return false }
    guard unop(@v128.f64x2_sqrt(va), x => x.sqrt()) else { return false }
    guard unop(@v128.f64x2_ceil(va), x => x.ceil()) else { return false }
    guard unop(@v128.f64x2_floor(va), x => x.floor()) else { return false }
    guard unop(@v128.f64x2_trunc(va), x => x.trunc()) else { return false }
    guard unop(@v128.f64x2_nearest(va), ref_nearest) else { return false }
    // Comparisons
    guard cmpop(@v128.f64x2_eq(va, vb), (x, y) => x == y) else { return false }
    guard cmpop(@v128.f64x2_ne(va, vb), (x, y) => x != y) else { return false }
    guard cmpop(@v128.f64x2_lt(va, vb), (x, y) => x < y) else { return false }
    guard cmpop(@v128.f64x2_le(va, vb), (x, y) => x <= y) else { return false }
    guard cmpop(@v128.f64x2_gt(va, vb), (x, y) => x > y) else { return false }
    guard cmpop(@v128.f64x2_ge(va, vb), (x, y) => x >= y) else { return false }
    // Relaxed fused multiply-add with exactly representable small integers.
    let sa = Array::makei(2, i => {
      ((seed_at(seeds, i, 0x313) % 33).reinterpret_as_int() - 16).to_double()
    })
    let sb = Array::makei(2, i => {
      ((seed_at(seeds, i, 0x314) % 33).reinterpret_as_int() - 16).to_double()
    })
    let sc = Array::makei(2, i => {
      ((seed_at(seeds, i, 0x315) % 33).reinterpret_as_int() - 16).to_double()
    })
    let vsa = @v128.f64x2_const(sa[0], sa[1])
    let vsb = @v128.f64x2_const(sb[0], sb[1])
    let vsc = @v128.f64x2_const(sc[0], sc[1])
    let madd = out64(@v128.f64x2_relaxed_madd(vsa, vsb, vsc))
    let nmadd = out64(@v128.f64x2_relaxed_nmadd(vsa, vsb, vsc))
    for i in 0..<2 {
      guard f64_bits_ok(madd[i], sa[i] * sb[i] + sc[i]) else { return false }
      guard f64_bits_ok(nmadd[i], sc[i] - sa[i] * sb[i]) else { return false }
    }
    true
  })
}

///|
test "quickcheck: lane-type conversions match scalar reference" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let a32 = lanes32_of(seeds, 0x321)
    let va32 = v32(a32)
    // i32 -> f32 (both signednesses; conversion may round).
    let cs = out32(@v128.f32x4_convert_i32x4_s(va32))
    let cu = out32(@v128.f32x4_convert_i32x4_u(va32))
    for i in 0..<4 {
      guard cs[i] ==
        Float::from_double(a32[i].reinterpret_as_int().to_double()).reinterpret_as_uint() else {
        return false
      }
      guard cu[i] ==
        Float::from_double(a32[i].to_double()).reinterpret_as_uint() else {
        return false
      }
    }
    // low i32 -> f64 (exact)
    let ds = out64(@v128.f64x2_convert_low_i32x4_s(va32))
    let du = out64(@v128.f64x2_convert_low_i32x4_u(va32))
    for i in 0..<2 {
      guard ds[i] ==
        a32[i].reinterpret_as_int().to_double().reinterpret_as_uint64() else {
        return false
      }
      guard du[i] == a32[i].to_double().reinterpret_as_uint64() else {
        return false
      }
    }
    // f32 <-> f64
    let fbits = Array::makei(4, i => pick_f32_bits(seed_at(seeds, i, 0x322)))
    let vf = v32(fbits)
    let promoted = out64(@v128.f64x2_promote_low_f32x4(vf))
    for i in 0..<2 {
      guard f64_bits_ok(
        promoted[i],
        Float::reinterpret_from_uint(fbits[i]).to_double(),
      ) else {
        return false
      }
    }
    let dbits = Array::makei(2, i => {
      pick_f64_bits(
        seed_at(seeds, 2 * i, 0x323),
        seed_at(seeds, 2 * i + 1, 0x323),
      )
    })
    let vd = v64(dbits)
    let demoted = out32(@v128.f32x4_demote_f64x2_zero(vd))
    for i in 0..<2 {
      guard f32_bits_ok(
        demoted[i],
        Float::from_double(dbits[i].reinterpret_as_double()),
      ) else {
        return false
      }
    }
    guard demoted[2] == 0 && demoted[3] == 0 else { return false }
    // Saturating truncation to integers; the scalar conversions saturate
    // and send NaN to zero, matching the wasm trunc_sat semantics.
    let ts = out32(@v128.i32x4_trunc_sat_f32x4_s(vf))
    let tu = out32(@v128.i32x4_trunc_sat_f32x4_u(vf))
    for i in 0..<4 {
      let f = Float::reinterpret_from_uint(fbits[i])
      guard ts[i] == f.to_int().reinterpret_as_uint() else { return false }
      guard tu[i] == f.to_double().to_uint() else { return false }
    }
    let tds = out32(@v128.i32x4_trunc_sat_f64x2_s_zero(vd))
    let tdu = out32(@v128.i32x4_trunc_sat_f64x2_u_zero(vd))
    for i in 0..<2 {
      let d = dbits[i].reinterpret_as_double()
      guard tds[i] == d.to_int().reinterpret_as_uint() else { return false }
      guard tdu[i] == d.to_uint() else { return false }
    }
    guard tds[2] == 0 && tds[3] == 0 && tdu[2] == 0 && tdu[3] == 0 else {
      return false
    }
    // Relaxed truncations are only fully specified for values that fit, so
    // feed them small in-range values and expect exact truncation.
    let small = Array::makei(4, i => {
      Float::from_int(
        (seed_at(seeds, i, 0x324) % 2001).reinterpret_as_int() - 1000,
      ) *
      0.5F
    })
    let vsmall = @v128.f32x4_const(small[0], small[1], small[2], small[3])
    let rs = out32(@v128.i32x4_relaxed_trunc_f32x4_s(vsmall))
    for i in 0..<4 {
      guard rs[i] == small[i].to_int().reinterpret_as_uint() else {
        return false
      }
    }
    let small_pos = Array::makei(4, i => {
      Float::from_int((seed_at(seeds, i, 0x325) % 2001).reinterpret_as_int()) *
      0.5F
    })
    let vsmall_pos = @v128.f32x4_const(
      small_pos[0],
      small_pos[1],
      small_pos[2],
      small_pos[3],
    )
    let ru = out32(@v128.i32x4_relaxed_trunc_f32x4_u(vsmall_pos))
    for i in 0..<4 {
      guard ru[i] == small_pos[i].to_double().to_uint() else { return false }
    }
    let dsmall = Array::makei(2, i => {
      ((seed_at(seeds, i, 0x326) % 2001).reinterpret_as_int() - 1000).to_double() *
      0.5
    })
    let vdsmall = @v128.f64x2_const(dsmall[0], dsmall[1])
    let rds = out32(@v128.i32x4_relaxed_trunc_f64x2_s_zero(vdsmall))
    for i in 0..<2 {
      guard rds[i] == dsmall[i].to_int().reinterpret_as_uint() else {
        return false
      }
    }
    guard rds[2] == 0 && rds[3] == 0 else { return false }
    let dsmall_pos = Array::makei(2, i => {
      (seed_at(seeds, i, 0x327) % 2001).reinterpret_as_int().to_double() * 0.5
    })
    let vdsmall_pos = @v128.f64x2_const(dsmall_pos[0], dsmall_pos[1])
    let rdu = out32(@v128.i32x4_relaxed_trunc_f64x2_u_zero(vdsmall_pos))
    for i in 0..<2 {
      guard rdu[i] == dsmall_pos[i].to_uint() else { return false }
    }
    guard rdu[2] == 0 && rdu[3] == 0 else { return false }
    true
  })
}

///|
fn le16_at(buf : FixedArray[Byte], off : Int) -> UInt {
  buf[off].to_uint() | (buf[off + 1].to_uint() << 8)
}

///|
fn le32_at(buf : FixedArray[Byte], off : Int) -> UInt {
  le16_at(buf, off) | (le16_at(buf, off + 2) << 16)
}

///|
fn le64_at(buf : FixedArray[Byte], off : Int) -> UInt64 {
  le32_at(buf, off).to_uint64() | (le32_at(buf, off + 4).to_uint64() << 32)
}

///|
test "quickcheck: memory loads and stores are little-endian roundtrips" {
  @quickcheck.check(count=250, (seeds : Array[UInt]) => {
    let buf : FixedArray[Byte] = FixedArray::makei(48, i => {
      pick_u8(seed_at(seeds, i, 0x401))
    })
    let off = (seed_at(seeds, 99, 0x402) % 24).reinterpret_as_int()
    let v = @v128.v128_load(buf, off)
    guard out8(v) == Array::makei(16, i => buf[off + i]) else { return false }
    // Store writes exactly 16 bytes at the offset.
    let dst : FixedArray[Byte] = FixedArray::make(48, 0xaa)
    @v128.v128_store(dst, off, v)
    for i in 0..<48 {
      let expect : Byte = if i >= off && i < off + 16 { buf[i] } else { 0xaa }
      guard dst[i] == expect else { return false }
    }
    // Widening loads
    let w8s = out16(@v128.v128_load8x8_s(buf, off))
    let w8u = out16(@v128.v128_load8x8_u(buf, off))
    for i in 0..<8 {
      guard w8s[i] == w16(s8(buf[off + i])) else { return false }
      guard w8u[i] == buf[off + i].to_uint() else { return false }
    }
    let w16s = out32(@v128.v128_load16x4_s(buf, off))
    let w16u = out32(@v128.v128_load16x4_u(buf, off))
    for i in 0..<4 {
      guard w16s[i] == s16(le16_at(buf, off + 2 * i)).reinterpret_as_uint() else {
        return false
      }
      guard w16u[i] == le16_at(buf, off + 2 * i) else { return false }
    }
    let w32s = out64(@v128.v128_load32x2_s(buf, off))
    let w32u = out64(@v128.v128_load32x2_u(buf, off))
    for i in 0..<2 {
      guard w32s[i] ==
        le32_at(buf, off + 4 * i)
        .reinterpret_as_int()
        .to_int64()
        .reinterpret_as_uint64() else {
        return false
      }
      guard w32u[i] == le32_at(buf, off + 4 * i).to_uint64() else {
        return false
      }
    }
    // Splat loads
    guard out8(@v128.v128_load8_splat(buf, off)) == Array::make(16, buf[off]) else {
      return false
    }
    guard out16(@v128.v128_load16_splat(buf, off)) ==
      Array::make(8, le16_at(buf, off)) else {
      return false
    }
    guard out32(@v128.v128_load32_splat(buf, off)) ==
      Array::make(4, le32_at(buf, off)) else {
      return false
    }
    guard out64(@v128.v128_load64_splat(buf, off)) ==
      Array::make(2, le64_at(buf, off)) else {
      return false
    }
    // Zero-extending single-element loads
    guard out32(@v128.v128_load32_zero(buf, off)) ==
      [le32_at(buf, off), 0, 0, 0] else {
      return false
    }
    guard out64(@v128.v128_load64_zero(buf, off)) == [le64_at(buf, off), 0] else {
      return false
    }
    // Lane loads keep the other lanes, for every lane index.
    let base8 = lanes8_of(seeds, 0x403)
    let vbase8 = v8(base8)
    for lane in 0..<16 {
      let expect = base8.copy()
      expect[lane] = buf[off]
      guard out8(@v128.v128_load8_lane(buf, off, vbase8, lane)) == expect else {
        return false
      }
    }
    let base16 = lanes16_of(seeds, 0x404)
    let vbase16 = v16(base16)
    for lane in 0..<8 {
      let expect = base16.copy()
      expect[lane] = le16_at(buf, off)
      guard out16(@v128.v128_load16_lane(buf, off, vbase16, lane)) == expect else {
        return false
      }
    }
    let base32 = lanes32_of(seeds, 0x405)
    let vbase32 = v32(base32)
    for lane in 0..<4 {
      let expect = base32.copy()
      expect[lane] = le32_at(buf, off)
      guard out32(@v128.v128_load32_lane(buf, off, vbase32, lane)) == expect else {
        return false
      }
    }
    let base64 = lanes64_of(seeds, 0x406)
    let vbase64 = v64(base64)
    for lane in 0..<2 {
      let expect = base64.copy()
      expect[lane] = le64_at(buf, off)
      guard out64(@v128.v128_load64_lane(buf, off, vbase64, lane)) == expect else {
        return false
      }
    }
    // Lane stores write exactly the selected lane, for every lane index.
    for lane in 0..<16 {
      let dst2 : FixedArray[Byte] = FixedArray::make(48, 0xaa)
      @v128.v128_store8_lane(dst2, off, vbase8, lane)
      for i in 0..<48 {
        let expect : Byte = if i == off { base8[lane] } else { 0xaa }
        guard dst2[i] == expect else { return false }
      }
    }
    for lane in 0..<8 {
      let dst2 : FixedArray[Byte] = FixedArray::make(48, 0xaa)
      @v128.v128_store16_lane(dst2, off, vbase16, lane)
      for i in 0..<48 {
        let expect : Byte = if i == off {
          (base16[lane] & 0xff).to_byte()
        } else if i == off + 1 {
          (base16[lane] >> 8).to_byte()
        } else {
          0xaa
        }
        guard dst2[i] == expect else { return false }
      }
    }
    for lane in 0..<4 {
      let dst2 : FixedArray[Byte] = FixedArray::make(48, 0xaa)
      @v128.v128_store32_lane(dst2, off, vbase32, lane)
      for i in 0..<48 {
        let expect : Byte = if i >= off && i < off + 4 {
          ((base32[lane] >> (8 * (i - off))) & 0xff).to_byte()
        } else {
          0xaa
        }
        guard dst2[i] == expect else { return false }
      }
    }
    for lane in 0..<2 {
      let dst2 : FixedArray[Byte] = FixedArray::make(48, 0xaa)
      @v128.v128_store64_lane(dst2, off, vbase64, lane)
      for i in 0..<48 {
        let expect : Byte = if i >= off && i < off + 8 {
          ((base64[lane] >> (8 * (i - off))) & 0xff).to_byte()
        } else {
          0xaa
        }
        guard dst2[i] == expect else { return false }
      }
    }
    true
  })
}
