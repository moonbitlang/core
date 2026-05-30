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
fn assert_bits(value : V128, lo : UInt64, hi : UInt64) -> Unit raise {
  assert_eq(@v128.lo(value), lo)
  assert_eq(@v128.hi(value), hi)
}

///|
fn make_by_index(index : Int) -> V128 {
  match index {
    0 => @v128.make(0x0000000000000000UL, 0x0000000000000001UL)
    1 => @v128.make(0x1111111111111111UL, 0x1111111111111112UL)
    2 => @v128.make(0x2222222222222222UL, 0x2222222222222223UL)
    3 => @v128.make(0x3333333333333333UL, 0x3333333333333334UL)
    4 => @v128.make(0x4444444444444444UL, 0x4444444444444445UL)
    _ => @v128.make(0xffffffffffffffffUL, 0xeeeeeeeeeeeeeeeeUL)
  }
}

///|
fn pass_through(value : V128) -> V128 {
  @v128.make(@v128.lo(value), @v128.hi(value))
}

///|
test "make and extract lanes" {
  let a = @v128.make(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  let b = @v128.make(0x1111111122222222UL, 0x3333333344444444UL)
  let c = @v128.make(0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(@v128.make(0UL, 0UL), 0UL, 0UL)
  assert_bits(@v128.make(1UL, 2UL), 1UL, 2UL)
  assert_bits(a, 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(c, 0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(pass_through(a), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(
    if true {
      a
    } else {
      b
    },
    0x0123456789abcdefUL,
    0xfedcba9876543210UL,
  )
  assert_bits(
    if false {
      a
    } else {
      b
    },
    0x1111111122222222UL,
    0x3333333344444444UL,
  )
}

///|
test "array storage" {
  let a = @v128.make(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  let b = @v128.make(0x1111111122222222UL, 0x3333333344444444UL)
  let c = @v128.make(0xffffffffffffffffUL, 0x8000000000000000UL)
  let xs : Array[V128] = Array::make(5, a)
  inspect(xs.length(), content="5")
  assert_bits(xs.unsafe_get(0), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(2), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(4), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  xs.unsafe_set(1, b)
  xs.unsafe_set(3, c)
  assert_bits(xs.unsafe_get(0), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(1), 0x1111111122222222UL, 0x3333333344444444UL)
  assert_bits(xs.unsafe_get(2), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(xs.unsafe_get(3), 0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(xs.unsafe_get(4), 0x0123456789abcdefUL, 0xfedcba9876543210UL)
}

///|
test "array and fixedarray makei" {
  let ys : Array[V128] = Array::makei(6, make_by_index)
  inspect(ys.length(), content="6")
  assert_bits(ys.unsafe_get(0), 0x0000000000000000UL, 0x0000000000000001UL)
  assert_bits(ys.unsafe_get(3), 0x3333333333333333UL, 0x3333333333333334UL)
  assert_bits(ys.unsafe_get(5), 0xffffffffffffffffUL, 0xeeeeeeeeeeeeeeeeUL)

  let zs : FixedArray[V128] = FixedArray::makei(4, make_by_index)
  inspect(zs.length(), content="4")
  assert_bits(zs.unsafe_get(0), 0x0000000000000000UL, 0x0000000000000001UL)
  assert_bits(zs.unsafe_get(2), 0x2222222222222222UL, 0x2222222222222223UL)
  assert_bits(zs.unsafe_get(3), 0x3333333333333333UL, 0x3333333333333334UL)
}

///|
test "integer lane constants and extraction" {
  let bytes = @v128.i8x16_const(
    0, 1, 2, 3, 4, 5, 6, 7, 0x80, 0xff, 10, 11, 12, 13, 14, 15,
  )
  assert_bits(bytes, 0x0706050403020100UL, 0x0f0e0d0c0b0aff80UL)
  inspect(@v128.i8x16_extract_lane_u(bytes, 9), content="255")
  inspect(@v128.i8x16_extract_lane_s(bytes, 8), content="4294967168")
  inspect(@v128.i8x16_extract_lane_s(bytes, 9), content="4294967295")

  let words = @v128.i16x8_const(0, 1, 0x8000, 0xffff, 4, 5, 6, 7)
  assert_bits(words, 0xffff800000010000UL, 0x0007000600050004UL)
  inspect(@v128.i16x8_extract_lane_u(words, 3), content="65535")
  inspect(@v128.i16x8_extract_lane_s(words, 2), content="4294934528")
  inspect(@v128.i16x8_extract_lane_s(words, 3), content="4294967295")

  let dwords = @v128.i32x4_const(0x01234567, 0x89abcdef, 2, 3)
  assert_bits(dwords, 0x89abcdef01234567UL, 0x0000000300000002UL)
  inspect(@v128.i32x4_extract_lane(dwords, 1), content="2309737967")

  let qwords = @v128.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_bits(qwords, 0x0123456789abcdefUL, 0xfedcba9876543210UL)
  inspect(@v128.i64x2_extract_lane(qwords, 1), content="18364758544493064720")
}

///|
test "splats and lane replacement" {
  assert_eq(
    @v128.i8x16_splat(0xab),
    @v128.i8x16_const(
      0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab, 0xab,
      0xab, 0xab, 0xab,
    ),
  )
  let replaced = @v128.i16x8_replace_lane(@v128.i16x8_splat(1), 4, 0xbeef)
  assert_eq(replaced, @v128.i16x8_const(1, 1, 1, 1, 0xbeef, 1, 1, 1))
  assert_eq(
    @v128.i32x4_replace_lane(@v128.i32x4_splat(7), 2, 0xfeedface),
    @v128.i32x4_const(7, 7, 0xfeedface, 7),
  )
  assert_eq(
    @v128.i64x2_replace_lane(@v128.i64x2_splat(3UL), 1, 0x0123456789abcdefUL),
    @v128.i64x2_const(3UL, 0x0123456789abcdefUL),
  )
}

///|
test "vector bit operations" {
  let a = @v128.i32x4_const(0xffffffff, 0x00000000, 0xff00ff00, 0x00ff00ff)
  let b = @v128.i32x4_const(0x0f0f0f0f, 0x0f0f0f0f, 0xffffffff, 0xffffffff)
  assert_eq(
    @v128.v128_not(a),
    @v128.i32x4_const(0x00000000, 0xffffffff, 0x00ff00ff, 0xff00ff00),
  )
  assert_eq(
    @v128.v128_and_(a, b),
    @v128.i32x4_const(0x0f0f0f0f, 0x00000000, 0xff00ff00, 0x00ff00ff),
  )
  assert_eq(
    @v128.v128_or_(a, b),
    @v128.i32x4_const(0xffffffff, 0x0f0f0f0f, 0xffffffff, 0xffffffff),
  )
  assert_eq(
    @v128.v128_xor(a, b),
    @v128.i32x4_const(0xf0f0f0f0, 0x0f0f0f0f, 0x00ff00ff, 0xff00ff00),
  )
  assert_eq(
    @v128.v128_bitselect(a, b, @v128.i32x4_const(0xffffffff, 0, 0xffffffff, 0)),
    @v128.i32x4_const(0xffffffff, 0x0f0f0f0f, 0xff00ff00, 0xffffffff),
  )
  assert_false(@v128.v128_any_true(@v128.i64x2_const(0UL, 0UL)))
  assert_true(@v128.v128_any_true(@v128.i64x2_const(0UL, 1UL)))
}

///|
test "integer arithmetic and shifts" {
  assert_eq(
    @v128.i8x16_add(@v128.i8x16_splat(255), @v128.i8x16_splat(2)),
    @v128.i8x16_splat(1),
  )
  assert_eq(
    @v128.i16x8_mul(@v128.i16x8_splat(0x1000), @v128.i16x8_splat(0x10)),
    @v128.i16x8_splat(0),
  )
  assert_eq(
    @v128.i32x4_sub(@v128.i32x4_splat(0), @v128.i32x4_splat(1)),
    @v128.i32x4_splat(0xffffffff),
  )
  assert_eq(
    @v128.i64x2_add(
      @v128.i64x2_const(0xffffffffffffffffUL, 40UL),
      @v128.i64x2_const(1UL, 2UL),
    ),
    @v128.i64x2_const(0UL, 42UL),
  )
  assert_eq(
    @v128.i8x16_shr_s(
      @v128.i8x16_const(0x80, 0xff, 0x7f, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
      1,
    ),
    @v128.i8x16_const(0xc0, 0xff, 0x3f, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
  )
  assert_eq(
    @v128.i32x4_shl(@v128.i32x4_const(1, 2, 3, 4), 4),
    @v128.i32x4_const(16, 32, 48, 64),
  )
}

///|
test "integer masks and truth tests" {
  let bytes = @v128.i8x16_const(
    0x80, 0, 0xff, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 0x80,
  )
  inspect(@v128.i8x16_bitmask(bytes), content="32773")
  assert_false(@v128.i8x16_all_true(bytes))
  assert_true(@v128.i8x16_all_true(@v128.i8x16_splat(1)))

  let words = @v128.i16x8_const(0x8000, 0, 1, 2, 3, 4, 0xffff, 0x7fff)
  inspect(@v128.i16x8_bitmask(words), content="65")
  assert_false(@v128.i16x8_all_true(words))
  assert_true(@v128.i16x8_all_true(@v128.i16x8_splat(1)))

  inspect(
    @v128.i32x4_bitmask(@v128.i32x4_const(0x80000000, 0, 0xffffffff, 1)),
    content="5",
  )
  inspect(
    @v128.i64x2_bitmask(@v128.i64x2_const(0x8000000000000000UL, 1UL)),
    content="1",
  )
}

///|
test "integer saturating and aggregate lane ops" {
  assert_eq(
    @v128.i8x16_add_sat_s(
      @v128.i8x16_const(
        0x7f, 0x80, 100, 0xff, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
      ),
      @v128.i8x16_const(
        1, 0xff, 100, 0xff, 255, 254, 253, 252, 251, 250, 249, 248, 247, 246, 245,
        244,
      ),
    ),
    @v128.i8x16_const(
      0x7f, 0x80, 0x7f, 0xfe, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ),
  )
  assert_eq(
    @v128.i8x16_add_sat_u(@v128.i8x16_splat(250), @v128.i8x16_splat(10)),
    @v128.i8x16_splat(255),
  )
  assert_eq(
    @v128.i8x16_sub_sat_u(@v128.i8x16_splat(3), @v128.i8x16_splat(10)),
    @v128.i8x16_splat(0),
  )
  assert_eq(
    @v128.i8x16_avgr_u(@v128.i8x16_splat(1), @v128.i8x16_splat(2)),
    @v128.i8x16_splat(2),
  )
  assert_eq(
    @v128.i8x16_popcnt(
      @v128.i8x16_const(
        0, 1, 3, 7, 15, 31, 63, 127, 255, 128, 129, 170, 85, 240, 15, 254,
      ),
    ),
    @v128.i8x16_const(0, 1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 4, 4, 4, 4, 7),
  )

  assert_eq(
    @v128.i16x8_add_sat_s(
      @v128.i16x8_const(0x7fff, 0x8000, 100, 0xffff, 1, 2, 3, 4),
      @v128.i16x8_const(
        1, 0xffff, 0x7fff, 0xffff, 0xffff, 0xfffe, 0xfffd, 0xfffc,
      ),
    ),
    @v128.i16x8_const(0x7fff, 0x8000, 0x7fff, 0xfffe, 0, 0, 0, 0),
  )
  assert_eq(
    @v128.i16x8_add_sat_u(@v128.i16x8_splat(65530), @v128.i16x8_splat(10)),
    @v128.i16x8_splat(65535),
  )
  assert_eq(
    @v128.i16x8_sub_sat_u(@v128.i16x8_splat(3), @v128.i16x8_splat(10)),
    @v128.i16x8_splat(0),
  )
  assert_eq(
    @v128.i16x8_avgr_u(@v128.i16x8_splat(1), @v128.i16x8_splat(2)),
    @v128.i16x8_splat(2),
  )
}

///|
test "integer comparisons and min max" {
  let a8 = @v128.i8x16_const(
    0x80, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
  )
  let b8 = @v128.i8x16_const(
    0x7f, 0, 2, 1, 3, 0xff, 5, 0, 8, 7, 9, 0, 11, 0, 14, 0,
  )
  assert_eq(
    @v128.i8x16_lt_s(a8, b8),
    @v128.i8x16_const(
      0xff, 0, 0xff, 0, 0, 0, 0, 0, 0xff, 0, 0, 0, 0, 0, 0xff, 0,
    ),
  )
  assert_eq(
    @v128.i8x16_lt_u(a8, b8),
    @v128.i8x16_const(
      0, 0, 0xff, 0, 0, 0xff, 0, 0, 0xff, 0, 0, 0, 0, 0, 0xff, 0,
    ),
  )
  assert_eq(
    @v128.i8x16_min_s(a8, b8),
    @v128.i8x16_const(0x80, 0, 1, 1, 3, 0xff, 5, 0, 7, 7, 9, 0, 11, 0, 13, 0),
  )
  assert_eq(
    @v128.i8x16_max_u(a8, b8),
    @v128.i8x16_const(0x80, 0, 2, 2, 3, 0xff, 5, 6, 8, 8, 9, 10, 11, 12, 14, 14),
  )

  let a16 = @v128.i16x8_const(0x8000, 0, 1, 2, 3, 4, 5, 6)
  let b16 = @v128.i16x8_const(0x7fff, 0, 2, 1, 3, 0xffff, 5, 0)
  assert_eq(
    @v128.i16x8_lt_s(a16, b16),
    @v128.i16x8_const(0xffff, 0, 0xffff, 0, 0, 0, 0, 0),
  )
  assert_eq(
    @v128.i16x8_lt_u(a16, b16),
    @v128.i16x8_const(0, 0, 0xffff, 0, 0, 0xffff, 0, 0),
  )
  assert_eq(
    @v128.i16x8_min_s(a16, b16),
    @v128.i16x8_const(0x8000, 0, 1, 1, 3, 0xffff, 5, 0),
  )
  assert_eq(
    @v128.i16x8_max_u(a16, b16),
    @v128.i16x8_const(0x8000, 0, 2, 2, 3, 0xffff, 5, 6),
  )

  let a32 = @v128.i32x4_const(0x80000000, 0, 1, 4)
  let b32 = @v128.i32x4_const(0x7fffffff, 0, 2, 3)
  assert_eq(
    @v128.i32x4_lt_s(a32, b32),
    @v128.i32x4_const(0xffffffff, 0, 0xffffffff, 0),
  )
  assert_eq(@v128.i32x4_lt_u(a32, b32), @v128.i32x4_const(0, 0, 0xffffffff, 0))
  assert_eq(@v128.i32x4_min_s(a32, b32), @v128.i32x4_const(0x80000000, 0, 1, 3))
  assert_eq(@v128.i32x4_max_u(a32, b32), @v128.i32x4_const(0x80000000, 0, 2, 4))

  let a64 = @v128.i64x2_const(0x8000000000000000UL, 4UL)
  let b64 = @v128.i64x2_const(0x7fffffffffffffffUL, 3UL)
  assert_eq(
    @v128.i64x2_lt_s(a64, b64),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.i64x2_ge_s(a64, b64),
    @v128.i64x2_const(0UL, 0xffffffffffffffffUL),
  )
}
