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
  assert_eq(@v128.i64x2_extract_lane(value, 0), lo)
  assert_eq(@v128.i64x2_extract_lane(value, 1), hi)
}

///|
fn make_by_index(index : Int) -> V128 {
  match index {
    0 => @v128.i64x2_const(0x0000000000000000UL, 0x0000000000000001UL)
    1 => @v128.i64x2_const(0x1111111111111111UL, 0x1111111111111112UL)
    2 => @v128.i64x2_const(0x2222222222222222UL, 0x2222222222222223UL)
    3 => @v128.i64x2_const(0x3333333333333333UL, 0x3333333333333334UL)
    4 => @v128.i64x2_const(0x4444444444444444UL, 0x4444444444444445UL)
    _ => @v128.i64x2_const(0xffffffffffffffffUL, 0xeeeeeeeeeeeeeeeeUL)
  }
}

///|
fn pass_through(value : V128) -> V128 {
  @v128.i64x2_const(
    @v128.i64x2_extract_lane(value, 0),
    @v128.i64x2_extract_lane(value, 1),
  )
}

///|
test "make and extract lanes" {
  let a = @v128.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  let b = @v128.i64x2_const(0x1111111122222222UL, 0x3333333344444444UL)
  let c = @v128.i64x2_const(0xffffffffffffffffUL, 0x8000000000000000UL)
  assert_bits(@v128.i64x2_const(0UL, 0UL), 0UL, 0UL)
  assert_bits(@v128.i64x2_const(1UL, 2UL), 1UL, 2UL)
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
  let a = @v128.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  let b = @v128.i64x2_const(0x1111111122222222UL, 0x3333333344444444UL)
  let c = @v128.i64x2_const(0xffffffffffffffffUL, 0x8000000000000000UL)
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
  let replaced = @v128.i16x8_replace_lane(@v128.i16x8_splat(1), 0xbeef, 4)
  assert_eq(replaced, @v128.i16x8_const(1, 1, 1, 1, 0xbeef, 1, 1, 1))
  assert_eq(
    @v128.i32x4_replace_lane(@v128.i32x4_splat(7), 0xfeedface, 2),
    @v128.i32x4_const(7, 7, 0xfeedface, 7),
  )
  assert_eq(
    @v128.i64x2_replace_lane(@v128.i64x2_splat(3UL), 0x0123456789abcdefUL, 1),
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

///|
test "shuffle and swizzle" {
  let a = @v128.i8x16_const(
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
  )
  let b = @v128.i8x16_const(
    16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  )
  assert_eq(
    @v128.i8x16_shuffle(
      a, b, 31, 30, 17, 16, 15, 14, 1, 0, 8, 9, 10, 11, 20, 21, 22, 23,
    ),
    @v128.i8x16_const(
      31, 30, 17, 16, 15, 14, 1, 0, 8, 9, 10, 11, 20, 21, 22, 23,
    ),
  )
  assert_eq(
    @v128.i8x16_swizzle(
      a,
      @v128.i8x16_const(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 16),
    ),
    @v128.i8x16_const(15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0),
  )
}

///|
test "loads and stores" {
  let bytes : FixedArray[Byte] = [
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x80, 0xff, 0xaa, 0xbb, 0xcc,
    0xdd, 0xee, 0xff, 0x10, 0x20, 0x30, 0x40,
  ]
  assert_eq(
    @v128.v128_load(bytes, 0),
    @v128.i8x16_const(
      0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x80, 0xff, 0xaa, 0xbb, 0xcc,
      0xdd, 0xee, 0xff,
    ),
  )
  assert_eq(
    @v128.v128_load8x8_s(bytes, 8),
    @v128.i16x8_const(
      0xff80, 0xffff, 0xffaa, 0xffbb, 0xffcc, 0xffdd, 0xffee, 0xffff,
    ),
  )
  assert_eq(
    @v128.v128_load8x8_u(bytes, 8),
    @v128.i16x8_const(0x80, 0xff, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff),
  )
  assert_eq(
    @v128.v128_load16x4_s(bytes, 8),
    @v128.i32x4_const(0xffffff80, 0xffffbbaa, 0xffffddcc, 0xffffffee),
  )
  assert_eq(
    @v128.v128_load32x2_u(bytes, 8),
    @v128.i64x2_const(0xbbaaff80UL, 0xffeeddccUL),
  )
  assert_eq(
    @v128.v128_load32_zero(bytes, 0),
    @v128.i32x4_const(0x03020100, 0, 0, 0),
  )
  assert_eq(
    @v128.v128_load64_splat(bytes, 0),
    @v128.i64x2_const(0x0706050403020100UL, 0x0706050403020100UL),
  )

  let out : FixedArray[Byte] = FixedArray::make(20, 0)
  @v128.v128_store(out, 2, @v128.v128_load(bytes, 0))
  inspect(out.unsafe_get(2), content="b'\\x00'")
  inspect(out.unsafe_get(9), content="b'\\x07'")
  inspect(out.unsafe_get(10), content="b'\\x80'")
  inspect(out.unsafe_get(17), content="b'\\xFF'")

  @v128.v128_store16_lane(
    out,
    0,
    @v128.i16x8_const(0x1234, 0xabcd, 0, 0, 0, 0, 0, 0),
    1,
  )
  inspect(out.unsafe_get(0), content="b'\\xCD'")
  inspect(out.unsafe_get(1), content="b'\\xAB'")

  let with_lane = @v128.v128_load32_lane(bytes, 16, @v128.i32x4_splat(0), 2)
  assert_eq(with_lane, @v128.i32x4_const(0, 0, 0x40302010, 0))
}

///|
test "integer widening narrowing and dot products" {
  let bytes = @v128.i8x16_const(
    0x80, 0xff, 1, 2, 3, 4, 5, 6, 0x7f, 0, 0xfe, 0xfd, 8, 9, 10, 11,
  )
  assert_eq(
    @v128.i16x8_extend_low_i8x16_s(bytes),
    @v128.i16x8_const(0xff80, 0xffff, 1, 2, 3, 4, 5, 6),
  )
  assert_eq(
    @v128.i16x8_extend_high_i8x16_u(bytes),
    @v128.i16x8_const(0x7f, 0, 0xfe, 0xfd, 8, 9, 10, 11),
  )
  assert_eq(
    @v128.i16x8_extadd_pairwise_i8x16_s(bytes),
    @v128.i16x8_const(0xff7f, 3, 7, 11, 0x7f, 0xfffb, 17, 21),
  )
  assert_eq(
    @v128.i16x8_extadd_pairwise_i8x16_u(bytes),
    @v128.i16x8_const(383, 3, 7, 11, 127, 507, 17, 21),
  )

  assert_eq(
    @v128.i16x8_extmul_low_i8x16_s(bytes, @v128.i8x16_splat(2)),
    @v128.i16x8_const(0xff00, 0xfffe, 2, 4, 6, 8, 10, 12),
  )
  assert_eq(
    @v128.i16x8_extmul_high_i8x16_u(bytes, @v128.i8x16_splat(2)),
    @v128.i16x8_const(254, 0, 508, 506, 16, 18, 20, 22),
  )
  // relaxed dot is implementation-defined for negative/overflowing
  // operands; use small non-negative inputs where all engines agree
  let dot_in = @v128.i8x16_const(
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  )
  assert_eq(
    @v128.i16x8_relaxed_dot_i8x16_i7x16_s(dot_in, @v128.i8x16_splat(2)),
    @v128.i16x8_const(6, 14, 22, 30, 38, 46, 54, 62),
  )

  let words0 = @v128.i16x8_const(
    0x8000, 0xff80, 0xffff, 0, 1, 0x007f, 0x0080, 0x7fff,
  )
  let words1 = @v128.i16x8_const(
    0xffff, 0, 0x00ff, 0x0100, 0x7fff, 0x8000, 42, 0xff00,
  )
  assert_eq(
    @v128.i8x16_narrow_i16x8_s(words0, words1),
    @v128.i8x16_const(
      0x80, 0x80, 0xff, 0, 1, 0x7f, 0x7f, 0x7f, 0xff, 0, 0x7f, 0x7f, 0x7f, 0x80,
      42, 0x80,
    ),
  )
  assert_eq(
    @v128.i8x16_narrow_i16x8_u(words0, words1),
    @v128.i8x16_const(
      0, 0, 0, 0, 1, 127, 128, 255, 0, 0, 255, 255, 255, 0, 42, 0,
    ),
  )

  let words = @v128.i16x8_const(0x8000, 0xffff, 1, 2, 0x7fff, 0, 0xfffe, 0x1234)
  assert_eq(
    @v128.i32x4_extend_low_i16x8_s(words),
    @v128.i32x4_const(0xffff8000, 0xffffffff, 1, 2),
  )
  assert_eq(
    @v128.i32x4_extend_high_i16x8_u(words),
    @v128.i32x4_const(0x7fff, 0, 0xfffe, 0x1234),
  )
  assert_eq(
    @v128.i32x4_extadd_pairwise_i16x8_s(words),
    @v128.i32x4_const(0xffff7fff, 3, 32767, 4658),
  )
  assert_eq(
    @v128.i32x4_extmul_low_i16x8_u(words, @v128.i16x8_splat(2)),
    @v128.i32x4_const(0x10000, 0x1fffe, 2, 4),
  )
  assert_eq(
    @v128.i16x8_q15mulr_sat_s(
      @v128.i16x8_const(0x4000, 0x7fff, 0x8000, 0xc000, 0, 1, 2, 3),
      @v128.i16x8_const(0x4000, 0x7fff, 0x8000, 0x4000, 0x7fff, 0x8000, 2, 3),
    ),
    @v128.i16x8_const(0x2000, 0x7ffe, 0x7fff, 0xe000, 0, 0xffff, 0, 0),
  )
  assert_eq(
    @v128.i32x4_dot_i16x8_s(words, @v128.i16x8_splat(2)),
    @v128.i32x4_const(0xfffefffe, 6, 0xfffe, 0x2464),
  )
  // Runs via the portable fallback (the intrinsic is omitted pending a
  // compiler naming/lowering fix), so the exact result is deterministic
  // across all backends.
  assert_eq(
    @v128.i32x4_relaxed_dot_i8x16_i7x16_add_s(
      dot_in,
      @v128.i8x16_splat(2),
      @v128.i32x4_splat(1),
    ),
    @v128.i32x4_const(21, 53, 85, 117),
  )

  assert_eq(
    @v128.i8x16_relaxed_laneselect(
      @v128.i8x16_splat(0xaa),
      @v128.i8x16_splat(0x55),
      // relaxed_laneselect is only deterministic when every mask lane is
      // all ones or all zeros
      @v128.i8x16_const(0xff, 0, 0xff, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
    ),
    @v128.i8x16_const(
      0xaa, 0x55, 0xaa, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55, 0x55,
      0x55, 0x55, 0x55,
    ),
  )
  assert_eq(
    @v128.i32x4_relaxed_laneselect(
      @v128.i32x4_splat(0xaaaaaaaa),
      @v128.i32x4_splat(0x55555555),
      @v128.i32x4_const(0xffffffff, 0, 0xffffffff, 0),
    ),
    @v128.i32x4_const(0xaaaaaaaa, 0x55555555, 0xaaaaaaaa, 0x55555555),
  )

  let dwords0 = @v128.i32x4_const(0x80000000, 0xffffffff, 0, 65536)
  let dwords1 = @v128.i32x4_const(0x7fffffff, 0x00010000, 0xffffffff, 42)
  assert_eq(
    @v128.i16x8_narrow_i32x4_s(dwords0, dwords1),
    @v128.i16x8_const(0x8000, 0xffff, 0, 0x7fff, 0x7fff, 0x7fff, 0xffff, 42),
  )
  assert_eq(
    @v128.i16x8_narrow_i32x4_u(dwords0, dwords1),
    @v128.i16x8_const(0, 0, 0, 0xffff, 0xffff, 0xffff, 0, 42),
  )

  let dwords = @v128.i32x4_const(0x80000000, 0xffffffff, 2, 3)
  assert_eq(
    @v128.i64x2_extend_low_i32x4_s(dwords),
    @v128.i64x2_const(0xffffffff80000000UL, 0xffffffffffffffffUL),
  )
  assert_eq(
    @v128.i64x2_extend_high_i32x4_u(dwords),
    @v128.i64x2_const(2UL, 3UL),
  )
  assert_eq(
    @v128.i64x2_extmul_low_i32x4_s(
      @v128.i32x4_const(0xffffffff, 2, 0, 0),
      @v128.i32x4_const(2, 3, 0, 0),
    ),
    @v128.i64x2_const(0xfffffffffffffffeUL, 6UL),
  )
  assert_eq(
    @v128.i64x2_extmul_high_i32x4_u(
      @v128.i32x4_const(0, 0, 0xffffffff, 3),
      @v128.i32x4_const(0, 0, 2, 4),
    ),
    @v128.i64x2_const(0x00000001fffffffeUL, 12UL),
  )
}

///|
test "floating point arithmetic comparisons and conversion" {
  let f = @v128.f32x4_const(-1.5, 2.5, 4.0, -0.5)
  assert_eq(@v128.f32x4_abs(f), @v128.f32x4_const(1.5, 2.5, 4.0, 0.5))
  assert_eq(@v128.f32x4_neg(f), @v128.f32x4_const(1.5, -2.5, -4.0, 0.5))
  assert_eq(
    @v128.f32x4_add(f, @v128.f32x4_splat(1.0)),
    @v128.f32x4_const(-0.5, 3.5, 5.0, 0.5),
  )
  assert_eq(
    @v128.f32x4_mul(f, @v128.f32x4_splat(2.0)),
    @v128.f32x4_const(-3.0, 5.0, 8.0, -1.0),
  )
  assert_eq(
    @v128.f32x4_sqrt(@v128.f32x4_const(4.0, 9.0, 16.0, 25.0)),
    @v128.f32x4_const(2.0, 3.0, 4.0, 5.0),
  )
  assert_eq(
    @v128.f32x4_nearest(@v128.f32x4_const(1.5, 2.5, -1.5, -2.5)),
    @v128.f32x4_const(2.0, 2.0, -2.0, -2.0),
  )
  assert_eq(
    @v128.f32x4_lt(f, @v128.f32x4_const(0.0, 2.0, 5.0, -1.0)),
    @v128.i32x4_const(0xffffffff, 0, 0xffffffff, 0),
  )
  assert_eq(
    @v128.f32x4_convert_i32x4_s(@v128.i32x4_const(0xffffffff, 2, 0xfffffffd, 4)),
    @v128.f32x4_const(-1.0, 2.0, -3.0, 4.0),
  )
  assert_eq(
    @v128.f32x4_convert_i32x4_u(@v128.i32x4_const(1, 2, 3, 4)),
    @v128.f32x4_const(1.0, 2.0, 3.0, 4.0),
  )
  assert_eq(
    @v128.f32x4_relaxed_madd(
      @v128.f32x4_const(1.0, 2.0, 3.0, 4.0),
      @v128.f32x4_splat(2.0),
      @v128.f32x4_splat(1.0),
    ),
    @v128.f32x4_const(3.0, 5.0, 7.0, 9.0),
  )
  assert_eq(
    @v128.f32x4_relaxed_nmadd(
      @v128.f32x4_const(1.0, 2.0, 3.0, 4.0),
      @v128.f32x4_splat(2.0),
      @v128.f32x4_splat(10.0),
    ),
    @v128.f32x4_const(8.0, 6.0, 4.0, 2.0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f32x4_s(@v128.f32x4_const(-1.9, 2.9, 1.0e20, -1.0e20)),
    @v128.i32x4_const(0xffffffff, 2, 0x7fffffff, 0x80000000),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f32x4_u(@v128.f32x4_const(-1.9, 2.9, 1.0e20, 0.0)),
    @v128.i32x4_const(0, 2, 0xffffffff, 0),
  )

  let d = @v128.f64x2_const(-1.5, 2.5)
  assert_eq(@v128.f64x2_abs(d), @v128.f64x2_const(1.5, 2.5))
  assert_eq(@v128.f64x2_nearest(d), @v128.f64x2_const(-2.0, 2.0))
  assert_eq(
    @v128.f64x2_div(@v128.f64x2_const(6.0, 10.0), @v128.f64x2_const(2.0, 4.0)),
    @v128.f64x2_const(3.0, 2.5),
  )
  assert_eq(
    @v128.f64x2_ge(d, @v128.f64x2_const(-2.0, 3.0)),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.f64x2_convert_low_i32x4_s(@v128.i32x4_const(0xffffffff, 2, 3, 4)),
    @v128.f64x2_const(-1.0, 2.0),
  )
  assert_eq(
    @v128.f64x2_relaxed_madd(
      @v128.f64x2_const(2.0, 3.0),
      @v128.f64x2_splat(4.0),
      @v128.f64x2_splat(1.0),
    ),
    @v128.f64x2_const(9.0, 13.0),
  )
  assert_eq(
    @v128.f64x2_relaxed_nmadd(
      @v128.f64x2_const(2.0, 3.0),
      @v128.f64x2_splat(4.0),
      @v128.f64x2_splat(20.0),
    ),
    @v128.f64x2_const(12.0, 8.0),
  )
  assert_eq(
    @v128.f64x2_promote_low_f32x4(@v128.f32x4_const(1.5, -2.5, 3.0, 4.0)),
    @v128.f64x2_const(1.5, -2.5),
  )
  assert_eq(
    @v128.f32x4_demote_f64x2_zero(@v128.f64x2_const(1.5, -2.5)),
    @v128.f32x4_const(1.5, -2.5, 0.0, 0.0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f64x2_s_zero(@v128.f64x2_const(-1.9, 1.0e40)),
    @v128.i32x4_const(0xffffffff, 0x7fffffff, 0, 0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f64x2_u_zero(@v128.f64x2_const(-1.9, 1.0e40)),
    @v128.i32x4_const(0, 0xffffffff, 0, 0),
  )
}

///|
test "systematic lane extraction and replacement" {
  let bytes = @v128.i8x16_const(
    0, 1, 2, 3, 4, 5, 6, 7, 128, 129, 130, 131, 252, 253, 254, 255,
  )
  for lane in 0..<16 {
    assert_eq(
      @v128.i8x16_extract_lane_u(bytes, lane),
      if lane < 8 {
        lane.reinterpret_as_uint()
      } else if lane < 12 {
        (lane + 120).reinterpret_as_uint()
      } else {
        (lane + 240).reinterpret_as_uint()
      },
    )
    let replaced = @v128.i8x16_replace_lane(bytes, 0xee, lane)
    for i in 0..<16 {
      assert_eq(
        @v128.i8x16_extract_lane_u(replaced, i),
        if i == lane {
          0xee
        } else {
          @v128.i8x16_extract_lane_u(bytes, i)
        },
      )
    }
  }

  let words = @v128.i16x8_const(0, 1, 2, 0x7fff, 0x8000, 0xfffd, 0xfffe, 0xffff)
  for lane in 0..<8 {
    let replaced = @v128.i16x8_replace_lane(words, 0xbeef, lane)
    for i in 0..<8 {
      assert_eq(
        @v128.i16x8_extract_lane_u(replaced, i),
        if i == lane {
          0xbeef
        } else {
          @v128.i16x8_extract_lane_u(words, i)
        },
      )
    }
  }

  let dwords = @v128.i32x4_const(0, 1, 0x80000000, 0xffffffff)
  for lane in 0..<4 {
    let replaced = @v128.i32x4_replace_lane(dwords, 0xdeadbeef, lane)
    for i in 0..<4 {
      assert_eq(
        @v128.i32x4_extract_lane(replaced, i),
        if i == lane {
          0xdeadbeef
        } else {
          @v128.i32x4_extract_lane(dwords, i)
        },
      )
    }
  }

  let qwords = @v128.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  for lane in 0..<2 {
    let replaced = @v128.i64x2_replace_lane(qwords, 0xa5a5a5a5a5a5a5a5UL, lane)
    for i in 0..<2 {
      assert_eq(
        @v128.i64x2_extract_lane(replaced, i),
        if i == lane {
          0xa5a5a5a5a5a5a5a5UL
        } else {
          @v128.i64x2_extract_lane(qwords, i)
        },
      )
    }
  }

  let floats = @v128.f32x4_const(-0.0, 1.5, -2.5, 4.0)
  for lane in 0..<4 {
    let replaced = @v128.f32x4_replace_lane(floats, 9.0, lane)
    for i in 0..<4 {
      assert_eq(
        @v128.f32x4_extract_lane(replaced, i).reinterpret_as_uint(),
        if i == lane {
          9.0F.reinterpret_as_uint()
        } else {
          @v128.f32x4_extract_lane(floats, i).reinterpret_as_uint()
        },
      )
    }
  }

  let doubles = @v128.f64x2_const(-0.0, 1.5)
  for lane in 0..<2 {
    let replaced = @v128.f64x2_replace_lane(doubles, -9.0, lane)
    for i in 0..<2 {
      assert_eq(
        @v128.f64x2_extract_lane(replaced, i).reinterpret_as_uint64(),
        if i == lane {
          (-9.0).reinterpret_as_uint64()
        } else {
          @v128.f64x2_extract_lane(doubles, i).reinterpret_as_uint64()
        },
      )
    }
  }
}

///|
test "systematic memory lane offsets" {
  let bytes : FixedArray[Byte] = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
  ]

  for lane in 0..<16 {
    let loaded = @v128.v128_load8_lane(
      bytes,
      lane,
      @v128.i8x16_splat(0xaa),
      lane,
    )
    for i in 0..<16 {
      assert_eq(
        @v128.i8x16_extract_lane_u(loaded, i),
        if i == lane {
          lane.reinterpret_as_uint()
        } else {
          0xaa
        },
      )
    }
    let out : FixedArray[Byte] = FixedArray::make(32, 0)
    @v128.v128_store8_lane(out, lane, @v128.v128_load(bytes, 0), lane)
    assert_eq(out.unsafe_get(lane), lane.to_byte())
  }

  for lane in 0..<8 {
    let offset = lane * 2
    let expected = ((offset + 1).reinterpret_as_uint() << 8) |
      offset.reinterpret_as_uint()
    let loaded = @v128.v128_load16_lane(
      bytes,
      offset,
      @v128.i16x8_splat(0xaaaa),
      lane,
    )
    for i in 0..<8 {
      assert_eq(
        @v128.i16x8_extract_lane_u(loaded, i),
        if i == lane {
          expected
        } else {
          0xaaaa
        },
      )
    }
    let out : FixedArray[Byte] = FixedArray::make(32, 0)
    @v128.v128_store16_lane(out, offset, loaded, lane)
    assert_eq(out.unsafe_get(offset), offset.to_byte())
    assert_eq(out.unsafe_get(offset + 1), (offset + 1).to_byte())
  }

  for lane in 0..<4 {
    let offset = lane * 4
    let expected = ((offset + 3).reinterpret_as_uint() << 24) |
      ((offset + 2).reinterpret_as_uint() << 16) |
      ((offset + 1).reinterpret_as_uint() << 8) |
      offset.reinterpret_as_uint()
    let loaded = @v128.v128_load32_lane(
      bytes,
      offset,
      @v128.i32x4_splat(0xaaaaaaaa),
      lane,
    )
    for i in 0..<4 {
      assert_eq(
        @v128.i32x4_extract_lane(loaded, i),
        if i == lane {
          expected
        } else {
          0xaaaaaaaa
        },
      )
    }
    let out : FixedArray[Byte] = FixedArray::make(32, 0)
    @v128.v128_store32_lane(out, offset, loaded, lane)
    for i in 0..<4 {
      assert_eq(out.unsafe_get(offset + i), (offset + i).to_byte())
    }
  }

  for lane in 0..<2 {
    let offset = lane * 8
    let loaded = @v128.v128_load64_lane(
      bytes,
      offset,
      @v128.i64x2_splat(0xaaaaaaaaaaaaaaaaUL),
      lane,
    )
    let out : FixedArray[Byte] = FixedArray::make(32, 0)
    @v128.v128_store64_lane(out, offset, loaded, lane)
    for i in 0..<8 {
      assert_eq(out.unsafe_get(offset + i), (offset + i).to_byte())
    }
  }
}

///|
test "systematic shifts and saturation boundaries" {
  let bytes = @v128.i8x16_const(
    0x01, 0x02, 0x7f, 0x80, 0xff, 0x40, 0xc0, 0x55, 0xaa, 0x10, 0xf0, 0x08, 0x81,
    0x3f, 0xfe, 0x00,
  )
  assert_eq(@v128.i8x16_shl(bytes, 8), bytes)
  assert_eq(@v128.i8x16_shl(bytes, 9), @v128.i8x16_shl(bytes, 1))
  assert_eq(@v128.i8x16_shr_u(bytes, 8), bytes)
  assert_eq(@v128.i8x16_shr_s(bytes, 9), @v128.i8x16_shr_s(bytes, 1))

  let words = @v128.i16x8_const(
    0x0001, 0x0002, 0x7fff, 0x8000, 0xffff, 0x4000, 0xc000, 0,
  )
  assert_eq(@v128.i16x8_shl(words, 16), words)
  assert_eq(@v128.i16x8_shl(words, 17), @v128.i16x8_shl(words, 1))
  assert_eq(@v128.i16x8_shr_u(words, 16), words)
  assert_eq(@v128.i16x8_shr_s(words, 17), @v128.i16x8_shr_s(words, 1))

  let dwords = @v128.i32x4_const(1, 0x7fffffff, 0x80000000, 0xffffffff)
  assert_eq(@v128.i32x4_shl(dwords, 32), dwords)
  assert_eq(@v128.i32x4_shl(dwords, 33), @v128.i32x4_shl(dwords, 1))
  assert_eq(@v128.i32x4_shr_u(dwords, 32), dwords)
  assert_eq(@v128.i32x4_shr_s(dwords, 33), @v128.i32x4_shr_s(dwords, 1))

  let qwords = @v128.i64x2_const(1UL, 0x8000000000000000UL)
  assert_eq(@v128.i64x2_shl(qwords, 64), qwords)
  assert_eq(@v128.i64x2_shl(qwords, 65), @v128.i64x2_shl(qwords, 1))
  assert_eq(@v128.i64x2_shr_u(qwords, 64), qwords)
  assert_eq(@v128.i64x2_shr_s(qwords, 65), @v128.i64x2_shr_s(qwords, 1))

  // negative counts wrap like wasm's unsigned modulo: -7 mod 8 == 1
  assert_eq(@v128.i8x16_shl(bytes, -7), @v128.i8x16_shl(bytes, 1))
  assert_eq(@v128.i16x8_shr_u(words, -15), @v128.i16x8_shr_u(words, 1))
  assert_eq(@v128.i32x4_shr_s(dwords, -31), @v128.i32x4_shr_s(dwords, 1))
  assert_eq(@v128.i64x2_shl(qwords, -63), @v128.i64x2_shl(qwords, 1))

  assert_eq(
    @v128.i8x16_add_sat_s(
      @v128.i8x16_const(
        0x7e, 0x7f, 0x80, 0x81, 0xff, 0, 1, 2, 126, 127, 128, 129, 254, 255, 0, 1,
      ),
      @v128.i8x16_const(
        1, 1, 0xff, 0xff, 0xff, 0xff, 0x7f, 0x80, 2, 2, 0xfe, 0xfe, 2, 2, 0x80, 0x7f,
      ),
    ),
    @v128.i8x16_const(
      0x7f, 0x7f, 0x80, 0x80, 0xfe, 0xff, 0x7f, 0x82, 0x7f, 0x7f, 0x80, 0x80, 0,
      1, 0x80, 0x7f,
    ),
  )
  assert_eq(
    @v128.i16x8_sub_sat_s(
      @v128.i16x8_const(0x8000, 0x8001, 0x7fff, 0x7ffe, 0, 1, 0xffff, 0x4000),
      @v128.i16x8_const(1, 2, 0xffff, 0xfffe, 1, 0x8000, 0x7fff, 0xc000),
    ),
    @v128.i16x8_const(
      0x8000, 0x8000, 0x7fff, 0x7fff, 0xffff, 0x7fff, 0x8000, 0x7fff,
    ),
  )
}

///|
test "floating point edge cases" {
  let nan32 = Float::reinterpret_from_uint(0x7fc00000)
  let float_edges = @v128.f32x4_const(nan32, -0.0, 0.0, 1.0)
  assert_eq(
    @v128.f32x4_eq(float_edges, float_edges),
    @v128.i32x4_const(0, 0xffffffff, 0xffffffff, 0xffffffff),
  )
  assert_eq(
    @v128.f32x4_ne(float_edges, float_edges),
    @v128.i32x4_const(0xffffffff, 0, 0, 0),
  )
  assert_eq(
    @v128.f32x4_abs(@v128.f32x4_const(-0.0, -1.0, -2.5, -4.0)),
    @v128.f32x4_const(0.0, 1.0, 2.5, 4.0),
  )
  assert_eq(
    @v128.f32x4_nearest(@v128.f32x4_const(0.5, -0.5, 3.5, -3.5)),
    @v128.f32x4_const(0.0, -0.0, 4.0, -4.0),
  )
  assert_eq(
    @v128.f32x4_pmin(
      @v128.f32x4_const(nan32, 1.0, -0.0, 3.0),
      @v128.f32x4_const(2.0, nan32, 0.0, -4.0),
    ),
    @v128.f32x4_const(nan32, 1.0, -0.0, -4.0),
  )

  let nan64 = 0x7ff8000000000000UL.reinterpret_as_double()
  let double_edges = @v128.f64x2_const(nan64, -0.0)
  assert_eq(
    @v128.f64x2_eq(double_edges, double_edges),
    @v128.i64x2_const(0UL, 0xffffffffffffffffUL),
  )
  assert_eq(
    @v128.f64x2_ne(double_edges, double_edges),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.f64x2_nearest(@v128.f64x2_const(0.5, -0.5)),
    @v128.f64x2_const(0.0, -0.0),
  )
}

///|
test "min/max NaN propagation and signed zeros" {
  let nan32 = Float::reinterpret_from_uint(0x7fc00000)
  let a32 = @v128.f32x4_const(nan32, 1.0, -0.0, 0.0)
  let b32 = @v128.f32x4_const(2.0, nan32, 0.0, -0.0)
  // min/max synthesize a NaN when either input is NaN, but the NaN
  // sign/payload is implementation-defined; only the non-NaN lanes are
  // deterministic (min picks -0.0, max picks +0.0).
  let rmin = @v128.f32x4_min(a32, b32)
  assert_true(@v128.f32x4_extract_lane(rmin, 0).is_nan())
  assert_true(@v128.f32x4_extract_lane(rmin, 1).is_nan())
  assert_eq(@v128.f32x4_extract_lane(rmin, 2).reinterpret_as_uint(), 0x80000000)
  assert_eq(@v128.f32x4_extract_lane(rmin, 3).reinterpret_as_uint(), 0x80000000)
  let rmax = @v128.f32x4_max(a32, b32)
  assert_true(@v128.f32x4_extract_lane(rmax, 0).is_nan())
  assert_true(@v128.f32x4_extract_lane(rmax, 1).is_nan())
  assert_eq(@v128.f32x4_extract_lane(rmax, 2).reinterpret_as_uint(), 0)
  assert_eq(@v128.f32x4_extract_lane(rmax, 3).reinterpret_as_uint(), 0)
  // pmin/pmax return the first operand on ties and NaN
  assert_eq(@v128.f32x4_pmin(a32, b32), a32)
  assert_eq(@v128.f32x4_pmax(a32, b32), a32)

  let nan64 = 0x7ff8000000000000UL.reinterpret_as_double()
  let a64 = @v128.f64x2_const(nan64, -0.0)
  let b64 = @v128.f64x2_const(5.0, 0.0)
  let m1 = @v128.f64x2_min(a64, b64)
  assert_true(@v128.f64x2_extract_lane(m1, 0).is_nan())
  assert_eq(
    @v128.f64x2_extract_lane(m1, 1).reinterpret_as_uint64(),
    0x8000000000000000UL,
  )
  let m2 = @v128.f64x2_min(b64, a64)
  assert_true(@v128.f64x2_extract_lane(m2, 0).is_nan())
  assert_eq(
    @v128.f64x2_extract_lane(m2, 1).reinterpret_as_uint64(),
    0x8000000000000000UL,
  )
  let m3 = @v128.f64x2_max(a64, b64)
  assert_true(@v128.f64x2_extract_lane(m3, 0).is_nan())
  assert_eq(@v128.f64x2_extract_lane(m3, 1).reinterpret_as_uint64(), 0UL)
  let m4 = @v128.f64x2_max(b64, a64)
  assert_true(@v128.f64x2_extract_lane(m4, 0).is_nan())
  assert_eq(@v128.f64x2_extract_lane(m4, 1).reinterpret_as_uint64(), 0UL)
  assert_eq(@v128.f64x2_pmin(a64, b64), a64)
  assert_eq(@v128.f64x2_pmin(b64, a64), b64)
  assert_eq(@v128.f64x2_pmax(a64, b64), a64)
  assert_eq(@v128.f64x2_pmax(b64, a64), b64)

  // ordering still works on plain values
  assert_eq(
    @v128.f32x4_min(
      @v128.f32x4_const(1.5, -2.0, 7.0, -8.0),
      @v128.f32x4_const(2.5, -1.0, 6.0, -9.0),
    ),
    @v128.f32x4_const(1.5, -2.0, 6.0, -9.0),
  )
  assert_eq(
    @v128.f64x2_max(@v128.f64x2_const(1.5, -2.0), @v128.f64x2_const(2.5, -3.0)),
    @v128.f64x2_const(2.5, -2.0),
  )
}

///|
test "explicit coverage for basic and memory ops" {
  let value = @v128.i64x2_const(0x0123456789abcdefUL, 0xfedcba9876543210UL)
  assert_true(value == value)
  assert_true(value != @v128.i64x2_splat(0UL))
  assert_eq(
    @v128.v128_andnot(
      @v128.i32x4_const(0xffff0000, 0x00ff00ff, 0xffffffff, 0),
      @v128.i32x4_const(0x00ff00ff, 0xffff0000, 0, 0xffffffff),
    ),
    @v128.i32x4_const(0xff000000, 0x000000ff, 0xffffffff, 0),
  )
  inspect(
    @v128.i64x2_const(1UL, 0xfedcba9876543210UL).to_string(),
    content="V128(0x0000000000000001, 0xfedcba9876543210)",
  )

  let bytes : FixedArray[Byte] = [
    0xff, 0xff, 0xff, 0xff, 0, 0, 0, 0x80, 1, 2, 3, 4, 5, 6, 7, 8,
  ]
  assert_eq(@v128.v128_load8_splat(bytes, 8), @v128.i8x16_splat(1))
  assert_eq(@v128.v128_load16_splat(bytes, 8), @v128.i16x8_splat(0x0201))
  assert_eq(@v128.v128_load32_splat(bytes, 8), @v128.i32x4_splat(0x04030201))
  assert_eq(
    @v128.v128_load16x4_u(bytes, 8),
    @v128.i32x4_const(0x0201, 0x0403, 0x0605, 0x0807),
  )
  assert_eq(
    @v128.v128_load32x2_s(bytes, 0),
    @v128.i64x2_const(0xffffffffffffffffUL, 0xffffffff80000000UL),
  )
  assert_eq(
    @v128.v128_load64_zero(bytes, 8),
    @v128.i64x2_const(0x0807060504030201UL, 0UL),
  )
}

///|
test "explicit coverage for i8 ops" {
  let a = @v128.i8x16_const(
    0xff, 0x80, 0x7f, 5, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
  )
  let b = @v128.i8x16_const(
    1, 0xff, 0x80, 2, 0, 1, 3, 2, 5, 4, 6, 0, 9, 8, 10, 12,
  )
  assert_eq(
    @v128.i8x16_abs(a),
    @v128.i8x16_const(1, 0x80, 0x7f, 5, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11),
  )
  assert_eq(
    @v128.i8x16_neg(
      @v128.i8x16_const(
        1, 0xff, 0x80, 0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,
      ),
    ),
    @v128.i8x16_const(
      0xff, 1, 0x80, 0, 0xfe, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf8, 0xf7, 0xf6, 0xf5,
      0xf4, 0xf3,
    ),
  )
  assert_eq(
    @v128.i8x16_sub(@v128.i8x16_splat(3), @v128.i8x16_splat(5)),
    @v128.i8x16_splat(0xfe),
  )
  assert_eq(
    @v128.i8x16_sub_sat_s(
      @v128.i8x16_const(
        0x80, 0x7f, 10, 0xf0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
      ),
      @v128.i8x16_const(
        1, 0xff, 20, 0x10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
      ),
    ),
    @v128.i8x16_const(
      0x80, 0x7f, 0xf6, 0xe0, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
      0xff, 0xff, 0xff,
    ),
  )
  assert_eq(
    @v128.i8x16_eq(a, b),
    @v128.i8x16_const(
      0, 0, 0, 0, 0xff, 0xff, 0, 0, 0, 0, 0xff, 0, 0, 0, 0xff, 0,
    ),
  )
  assert_eq(
    @v128.i8x16_ne(a, b),
    @v128.i8x16_const(
      0xff, 0xff, 0xff, 0xff, 0, 0, 0xff, 0xff, 0xff, 0xff, 0, 0xff, 0xff, 0xff,
      0, 0xff,
    ),
  )
  assert_eq(
    @v128.i8x16_le_s(a, b),
    @v128.i8x16_const(
      0xff, 0xff, 0, 0, 0xff, 0xff, 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0xff,
    ),
  )
  assert_eq(
    @v128.i8x16_le_u(a, b),
    @v128.i8x16_const(
      0, 0xff, 0xff, 0, 0xff, 0xff, 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0xff,
    ),
  )
  assert_eq(
    @v128.i8x16_gt_s(a, b),
    @v128.i8x16_const(
      0, 0, 0xff, 0xff, 0, 0, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0,
    ),
  )
  assert_eq(
    @v128.i8x16_gt_u(a, b),
    @v128.i8x16_const(
      0xff, 0, 0, 0xff, 0, 0, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0xff, 0, 0,
    ),
  )
  assert_eq(@v128.i8x16_ge_s(a, b), @v128.v128_not(@v128.i8x16_lt_s(a, b)))
  assert_eq(@v128.i8x16_ge_u(a, b), @v128.v128_not(@v128.i8x16_lt_u(a, b)))
  assert_eq(
    @v128.i8x16_max_s(a, b),
    @v128.i8x16_const(1, 0xff, 0x7f, 5, 0, 1, 3, 3, 5, 5, 6, 7, 9, 9, 10, 12),
  )
  assert_eq(
    @v128.i8x16_min_u(a, b),
    @v128.i8x16_const(1, 0x80, 0x7f, 2, 0, 1, 2, 2, 4, 4, 6, 0, 8, 8, 10, 11),
  )
  // relaxed swizzle is implementation-defined for out-of-range indices;
  // for in-range indices it must match the strict swizzle
  let idx = @v128.i8x16_const(
    0, 2, 4, 6, 8, 10, 12, 14, 1, 3, 5, 7, 9, 11, 13, 15,
  )
  assert_eq(@v128.i8x16_relaxed_swizzle(a, idx), @v128.i8x16_swizzle(a, idx))
}

///|
test "explicit coverage for i16 ops" {
  let a = @v128.i16x8_const(0xffff, 0xfffe, 0x7fff, 5, 0, 1, 2, 3)
  let b = @v128.i16x8_const(1, 0xffff, 0x8000, 2, 0, 1, 3, 2)
  assert_eq(@v128.i16x8_abs(a), @v128.i16x8_const(1, 2, 0x7fff, 5, 0, 1, 2, 3))
  assert_eq(
    @v128.i16x8_neg(@v128.i16x8_const(1, 0xffff, 0x8000, 0, 2, 3, 4, 5)),
    @v128.i16x8_const(0xffff, 1, 0x8000, 0, 0xfffe, 0xfffd, 0xfffc, 0xfffb),
  )
  assert_eq(
    @v128.i16x8_add(@v128.i16x8_splat(0xffff), @v128.i16x8_splat(2)),
    @v128.i16x8_splat(1),
  )
  assert_eq(
    @v128.i16x8_sub(@v128.i16x8_splat(3), @v128.i16x8_splat(5)),
    @v128.i16x8_splat(0xfffe),
  )
  assert_eq(
    @v128.i16x8_eq(a, b),
    @v128.i16x8_const(0, 0, 0, 0, 0xffff, 0xffff, 0, 0),
  )
  assert_eq(
    @v128.i16x8_ne(a, b),
    @v128.i16x8_const(0xffff, 0xffff, 0xffff, 0xffff, 0, 0, 0xffff, 0xffff),
  )
  assert_eq(@v128.i16x8_le_s(a, b), @v128.v128_not(@v128.i16x8_gt_s(a, b)))
  assert_eq(@v128.i16x8_le_u(a, b), @v128.v128_not(@v128.i16x8_gt_u(a, b)))
  assert_eq(@v128.i16x8_ge_s(a, b), @v128.v128_not(@v128.i16x8_lt_s(a, b)))
  assert_eq(@v128.i16x8_ge_u(a, b), @v128.v128_not(@v128.i16x8_lt_u(a, b)))
  assert_eq(
    @v128.i16x8_gt_s(a, b),
    @v128.i16x8_const(0, 0, 0xffff, 0xffff, 0, 0, 0, 0xffff),
  )
  assert_eq(
    @v128.i16x8_gt_u(a, b),
    @v128.i16x8_const(0xffff, 0, 0, 0xffff, 0, 0, 0, 0xffff),
  )
  assert_eq(
    @v128.i16x8_max_s(a, b),
    @v128.i16x8_const(1, 0xffff, 0x7fff, 5, 0, 1, 3, 3),
  )
  assert_eq(
    @v128.i16x8_min_u(a, b),
    @v128.i16x8_const(1, 0xfffe, 0x7fff, 2, 0, 1, 2, 2),
  )

  let bytes = @v128.i8x16_const(
    0x80, 1, 2, 3, 4, 5, 6, 7, 0xff, 0xfe, 8, 9, 10, 11, 12, 13,
  )
  assert_eq(
    @v128.i16x8_extend_high_i8x16_s(bytes),
    @v128.i16x8_const(0xffff, 0xfffe, 8, 9, 10, 11, 12, 13),
  )
  assert_eq(
    @v128.i16x8_extend_low_i8x16_u(bytes),
    @v128.i16x8_const(0x80, 1, 2, 3, 4, 5, 6, 7),
  )
  assert_eq(
    @v128.i16x8_extmul_high_i8x16_s(bytes, @v128.i8x16_splat(2)),
    @v128.i16x8_const(0xfffe, 0xfffc, 16, 18, 20, 22, 24, 26),
  )
  assert_eq(
    @v128.i16x8_extmul_low_i8x16_u(bytes, @v128.i8x16_splat(2)),
    @v128.i16x8_const(0x100, 2, 4, 6, 8, 10, 12, 14),
  )
  assert_eq(
    @v128.i16x8_relaxed_laneselect(
      @v128.i16x8_splat(0xaaaa),
      @v128.i16x8_splat(0x5555),
      // relaxed_laneselect is only deterministic when every mask lane is
      // all ones or all zeros
      @v128.i16x8_const(0xffff, 0, 0xffff, 0, 0, 0, 0, 0),
    ),
    @v128.i16x8_const(
      0xaaaa, 0x5555, 0xaaaa, 0x5555, 0x5555, 0x5555, 0x5555, 0x5555,
    ),
  )
  assert_eq(
    @v128.i16x8_relaxed_q15mulr_s(
      @v128.i16x8_splat(0x4000),
      @v128.i16x8_splat(0x4000),
    ),
    @v128.i16x8_splat(0x2000),
  )
}

///|
test "explicit coverage for i32 ops" {
  let a = @v128.i32x4_const(0xffffffff, 0xfffffffe, 0x7fffffff, 5)
  let b = @v128.i32x4_const(1, 0xffffffff, 0x80000000, 2)
  assert_eq(@v128.i32x4_abs(a), @v128.i32x4_const(1, 2, 0x7fffffff, 5))
  assert_eq(
    @v128.i32x4_neg(@v128.i32x4_const(1, 0xffffffff, 0x80000000, 0)),
    @v128.i32x4_const(0xffffffff, 1, 0x80000000, 0),
  )
  assert_eq(
    @v128.i32x4_add(@v128.i32x4_splat(0xffffffff), @v128.i32x4_splat(2)),
    @v128.i32x4_splat(1),
  )
  assert_eq(
    @v128.i32x4_mul(
      @v128.i32x4_const(2, 3, 4, 5),
      @v128.i32x4_const(6, 7, 8, 9),
    ),
    @v128.i32x4_const(12, 21, 32, 45),
  )
  assert_true(@v128.i32x4_all_true(@v128.i32x4_const(1, 2, 3, 4)))
  assert_false(@v128.i32x4_all_true(@v128.i32x4_const(1, 2, 0, 4)))
  assert_eq(@v128.i32x4_eq(a, b), @v128.i32x4_const(0, 0, 0, 0))
  assert_eq(
    @v128.i32x4_ne(a, b),
    @v128.i32x4_const(0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff),
  )
  assert_eq(@v128.i32x4_le_s(a, b), @v128.v128_not(@v128.i32x4_gt_s(a, b)))
  assert_eq(@v128.i32x4_le_u(a, b), @v128.v128_not(@v128.i32x4_gt_u(a, b)))
  assert_eq(@v128.i32x4_ge_s(a, b), @v128.v128_not(@v128.i32x4_lt_s(a, b)))
  assert_eq(@v128.i32x4_ge_u(a, b), @v128.v128_not(@v128.i32x4_lt_u(a, b)))
  assert_eq(
    @v128.i32x4_gt_s(a, b),
    @v128.i32x4_const(0, 0, 0xffffffff, 0xffffffff),
  )
  assert_eq(
    @v128.i32x4_gt_u(a, b),
    @v128.i32x4_const(0xffffffff, 0, 0, 0xffffffff),
  )
  assert_eq(
    @v128.i32x4_max_s(a, b),
    @v128.i32x4_const(1, 0xffffffff, 0x7fffffff, 5),
  )
  assert_eq(
    @v128.i32x4_min_u(a, b),
    @v128.i32x4_const(1, 0xfffffffe, 0x7fffffff, 2),
  )

  let words = @v128.i16x8_const(0x8000, 1, 2, 3, 0xffff, 0xfffe, 8, 9)
  assert_eq(
    @v128.i32x4_extadd_pairwise_i16x8_u(words),
    @v128.i32x4_const(0x8001, 5, 0x1fffd, 17),
  )
  assert_eq(
    @v128.i32x4_extend_high_i16x8_s(words),
    @v128.i32x4_const(0xffffffff, 0xfffffffe, 8, 9),
  )
  assert_eq(
    @v128.i32x4_extend_low_i16x8_u(words),
    @v128.i32x4_const(0x8000, 1, 2, 3),
  )
  assert_eq(
    @v128.i32x4_extmul_high_i16x8_s(words, @v128.i16x8_splat(2)),
    @v128.i32x4_const(0xfffffffe, 0xfffffffc, 16, 18),
  )
  assert_eq(
    @v128.i32x4_extmul_high_i16x8_u(words, @v128.i16x8_splat(2)),
    @v128.i32x4_const(0x1fffe, 0x1fffc, 16, 18),
  )
  assert_eq(
    @v128.i32x4_extmul_low_i16x8_s(words, @v128.i16x8_splat(2)),
    @v128.i32x4_const(0xffff0000, 2, 4, 6),
  )
  // relaxed trunc is implementation-defined outside the integer range;
  // use in-range inputs (strict trunc_sat covers out-of-range saturation)
  assert_eq(
    @v128.i32x4_relaxed_trunc_f32x4_s(@v128.f32x4_const(-1.9, 2.9, 0.0, 5.0)),
    @v128.i32x4_const(0xffffffff, 2, 0, 5),
  )
  assert_eq(
    @v128.i32x4_relaxed_trunc_f32x4_u(@v128.f32x4_const(1.9, 2.9, 0.0, 5.0)),
    @v128.i32x4_const(1, 2, 0, 5),
  )
  assert_eq(
    @v128.i32x4_relaxed_trunc_f64x2_s_zero(@v128.f64x2_const(-1.9, 5.0)),
    @v128.i32x4_const(0xffffffff, 5, 0, 0),
  )
  assert_eq(
    @v128.i32x4_relaxed_trunc_f64x2_u_zero(@v128.f64x2_const(1.9, 5.0)),
    @v128.i32x4_const(1, 5, 0, 0),
  )
}

///|
test "explicit coverage for i64 ops" {
  let a = @v128.i64x2_const(0xffffffffffffffffUL, 5UL)
  let b = @v128.i64x2_const(1UL, 2UL)
  assert_eq(@v128.i64x2_abs(a), @v128.i64x2_const(1UL, 5UL))
  assert_eq(
    @v128.i64x2_neg(@v128.i64x2_const(1UL, 0xffffffffffffffffUL)),
    @v128.i64x2_const(0xffffffffffffffffUL, 1UL),
  )
  assert_eq(
    @v128.i64x2_sub(@v128.i64x2_const(3UL, 4UL), @v128.i64x2_const(5UL, 1UL)),
    @v128.i64x2_const(0xfffffffffffffffeUL, 3UL),
  )
  assert_eq(
    @v128.i64x2_mul(@v128.i64x2_const(2UL, 3UL), @v128.i64x2_const(4UL, 5UL)),
    @v128.i64x2_const(8UL, 15UL),
  )
  assert_true(@v128.i64x2_all_true(@v128.i64x2_const(1UL, 2UL)))
  assert_false(@v128.i64x2_all_true(@v128.i64x2_const(1UL, 0UL)))
  assert_eq(@v128.i64x2_eq(a, b), @v128.i64x2_const(0UL, 0UL))
  assert_eq(
    @v128.i64x2_ne(a, b),
    @v128.i64x2_const(0xffffffffffffffffUL, 0xffffffffffffffffUL),
  )
  assert_eq(
    @v128.i64x2_le_s(a, b),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.i64x2_gt_s(a, b),
    @v128.i64x2_const(0UL, 0xffffffffffffffffUL),
  )
  assert_eq(
    @v128.i64x2_relaxed_laneselect(
      @v128.i64x2_splat(0xaaaaaaaaaaaaaaaaUL),
      @v128.i64x2_splat(0x5555555555555555UL),
      // relaxed_laneselect is only deterministic when every mask lane is
      // all ones or all zeros
      @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
    ),
    @v128.i64x2_const(0xaaaaaaaaaaaaaaaaUL, 0x5555555555555555UL),
  )

  let dwords = @v128.i32x4_const(0x80000000, 1, 0xffffffff, 2)
  assert_eq(
    @v128.i64x2_extend_high_i32x4_s(dwords),
    @v128.i64x2_const(0xffffffffffffffffUL, 2UL),
  )
  assert_eq(
    @v128.i64x2_extend_low_i32x4_u(dwords),
    @v128.i64x2_const(0x80000000UL, 1UL),
  )
  assert_eq(
    @v128.i64x2_extmul_high_i32x4_s(dwords, @v128.i32x4_splat(2)),
    @v128.i64x2_const(0xfffffffffffffffeUL, 4UL),
  )
  assert_eq(
    @v128.i64x2_extmul_low_i32x4_u(dwords, @v128.i32x4_splat(2)),
    @v128.i64x2_const(0x100000000UL, 2UL),
  )
}

///|
test "explicit coverage for floating point ops" {
  let f = @v128.f32x4_const(-1.25, 2.75, 4.0, -8.0)
  assert_eq(
    @v128.f32x4_sub(f, @v128.f32x4_splat(1.0)),
    @v128.f32x4_const(-2.25, 1.75, 3.0, -9.0),
  )
  assert_eq(
    @v128.f32x4_div(
      @v128.f32x4_const(6.0, 8.0, -9.0, 10.0),
      @v128.f32x4_const(2.0, 4.0, 3.0, 5.0),
    ),
    @v128.f32x4_const(3.0, 2.0, -3.0, 2.0),
  )
  assert_eq(@v128.f32x4_ceil(f), @v128.f32x4_const(-1.0, 3.0, 4.0, -8.0))
  assert_eq(@v128.f32x4_floor(f), @v128.f32x4_const(-2.0, 2.0, 4.0, -8.0))
  assert_eq(@v128.f32x4_trunc(f), @v128.f32x4_const(-1.0, 2.0, 4.0, -8.0))
  assert_eq(
    @v128.f32x4_min(
      @v128.f32x4_const(1.0, -2.0, 3.0, 4.0),
      @v128.f32x4_const(2.0, -3.0, 2.0, 5.0),
    ),
    @v128.f32x4_const(1.0, -3.0, 2.0, 4.0),
  )
  assert_eq(
    @v128.f32x4_max(
      @v128.f32x4_const(1.0, -2.0, 3.0, 4.0),
      @v128.f32x4_const(2.0, -3.0, 2.0, 5.0),
    ),
    @v128.f32x4_const(2.0, -2.0, 3.0, 5.0),
  )
  assert_eq(
    @v128.f32x4_pmax(
      @v128.f32x4_const(1.0, -2.0, 3.0, 4.0),
      @v128.f32x4_const(2.0, -3.0, 2.0, 5.0),
    ),
    @v128.f32x4_const(2.0, -2.0, 3.0, 5.0),
  )
  assert_eq(
    @v128.f32x4_relaxed_min(
      @v128.f32x4_const(1.0, -2.0, 3.0, 4.0),
      @v128.f32x4_const(2.0, -3.0, 2.0, 5.0),
    ),
    @v128.f32x4_const(1.0, -3.0, 2.0, 4.0),
  )
  assert_eq(
    @v128.f32x4_relaxed_max(
      @v128.f32x4_const(1.0, -2.0, 3.0, 4.0),
      @v128.f32x4_const(2.0, -3.0, 2.0, 5.0),
    ),
    @v128.f32x4_const(2.0, -2.0, 3.0, 5.0),
  )
  assert_eq(
    @v128.f32x4_le(f, @v128.f32x4_const(-1.25, 3.0, 3.0, -9.0)),
    @v128.i32x4_const(0xffffffff, 0xffffffff, 0, 0),
  )
  assert_eq(
    @v128.f32x4_gt(f, @v128.f32x4_const(-2.0, 3.0, 3.0, -9.0)),
    @v128.i32x4_const(0xffffffff, 0, 0xffffffff, 0xffffffff),
  )
  assert_eq(
    @v128.f32x4_ge(f, @v128.f32x4_const(-1.25, 3.0, 3.0, -9.0)),
    @v128.i32x4_const(0xffffffff, 0, 0xffffffff, 0xffffffff),
  )

  let d = @v128.f64x2_const(-1.25, 2.75)
  assert_eq(
    @v128.f64x2_add(d, @v128.f64x2_splat(1.0)),
    @v128.f64x2_const(-0.25, 3.75),
  )
  assert_eq(
    @v128.f64x2_sub(d, @v128.f64x2_splat(1.0)),
    @v128.f64x2_const(-2.25, 1.75),
  )
  assert_eq(
    @v128.f64x2_mul(d, @v128.f64x2_const(2.0, 4.0)),
    @v128.f64x2_const(-2.5, 11.0),
  )
  assert_eq(@v128.f64x2_neg(d), @v128.f64x2_const(1.25, -2.75))
  assert_eq(
    @v128.f64x2_sqrt(@v128.f64x2_const(4.0, 9.0)),
    @v128.f64x2_const(2.0, 3.0),
  )
  assert_eq(@v128.f64x2_ceil(d), @v128.f64x2_const(-1.0, 3.0))
  assert_eq(@v128.f64x2_floor(d), @v128.f64x2_const(-2.0, 2.0))
  assert_eq(@v128.f64x2_trunc(d), @v128.f64x2_const(-1.0, 2.0))
  assert_eq(
    @v128.f64x2_min(@v128.f64x2_const(1.0, -2.0), @v128.f64x2_const(2.0, -3.0)),
    @v128.f64x2_const(1.0, -3.0),
  )
  assert_eq(
    @v128.f64x2_max(@v128.f64x2_const(1.0, -2.0), @v128.f64x2_const(2.0, -3.0)),
    @v128.f64x2_const(2.0, -2.0),
  )
  assert_eq(
    @v128.f64x2_pmin(@v128.f64x2_const(1.0, -2.0), @v128.f64x2_const(2.0, -3.0)),
    @v128.f64x2_const(1.0, -3.0),
  )
  assert_eq(
    @v128.f64x2_pmax(@v128.f64x2_const(1.0, -2.0), @v128.f64x2_const(2.0, -3.0)),
    @v128.f64x2_const(2.0, -2.0),
  )
  assert_eq(
    @v128.f64x2_relaxed_min(
      @v128.f64x2_const(1.0, -2.0),
      @v128.f64x2_const(2.0, -3.0),
    ),
    @v128.f64x2_const(1.0, -3.0),
  )
  assert_eq(
    @v128.f64x2_relaxed_max(
      @v128.f64x2_const(1.0, -2.0),
      @v128.f64x2_const(2.0, -3.0),
    ),
    @v128.f64x2_const(2.0, -2.0),
  )
  assert_eq(
    @v128.f64x2_lt(d, @v128.f64x2_const(0.0, 2.0)),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.f64x2_le(d, @v128.f64x2_const(-1.25, 2.0)),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.f64x2_gt(d, @v128.f64x2_const(-2.0, 3.0)),
    @v128.i64x2_const(0xffffffffffffffffUL, 0UL),
  )
  assert_eq(
    @v128.f64x2_convert_low_i32x4_u(@v128.i32x4_const(1, 2, 0xffffffff, 4)),
    @v128.f64x2_const(1.0, 2.0),
  )
}

///|
test "debug repr" {
  @debug.debug_inspect(
    @v128.i64x2_const(1UL, 0xfedcba9876543210UL),
    content="<V128: (0x0000000000000001, 0xfedcba9876543210)>",
  )
  @debug.debug_inspect(
    @v128.i8x16_splat(0xab),
    content="<V128: (0xabababababababab, 0xabababababababab)>",
  )
}

///|
/// Literal lane indices so the wasm backends specialize every
/// load/store_lane instruction (loop-variable lanes use the fallback).
test "memory lane intrinsics with immediate lanes" {
  let bytes : FixedArray[Byte] = [
    0x10, 0x32, 0x54, 0x76, 0x98, 0xba, 0xdc, 0xfe, 1, 2, 3, 4, 5, 6, 7, 8,
  ]
  let base = @v128.i64x2_splat(0xaaaaaaaaaaaaaaaaUL)
  assert_eq(
    @v128.v128_load8_lane(bytes, 0, base, 1),
    @v128.i64x2_const(0xaaaaaaaaaaaa10aaUL, 0xaaaaaaaaaaaaaaaaUL),
  )
  assert_eq(
    @v128.v128_load16_lane(bytes, 0, base, 2),
    @v128.i64x2_const(0xaaaa3210aaaaaaaaUL, 0xaaaaaaaaaaaaaaaaUL),
  )
  assert_eq(
    @v128.v128_load32_lane(bytes, 0, base, 3),
    @v128.i64x2_const(0xaaaaaaaaaaaaaaaaUL, 0x76543210aaaaaaaaUL),
  )
  assert_eq(
    @v128.v128_load64_lane(bytes, 0, base, 0),
    @v128.i64x2_const(0xfedcba9876543210UL, 0xaaaaaaaaaaaaaaaaUL),
  )
  let v = @v128.i64x2_const(0xfedcba9876543210UL, 0x0807060504030201UL)
  let out : FixedArray[Byte] = FixedArray::make(16, 0)
  @v128.v128_store8_lane(out, 0, v, 5)
  @v128.v128_store16_lane(out, 2, v, 3)
  @v128.v128_store32_lane(out, 4, v, 2)
  @v128.v128_store64_lane(out, 8, v, 1)
  let expected : FixedArray[Byte] = [
    0xba, 0, 0xdc, 0xfe, 1, 2, 3, 4, 1, 2, 3, 4, 5, 6, 7, 8,
  ]
  for i in 0..<16 {
    assert_eq(out.unsafe_get(i), expected.unsafe_get(i))
  }
}

///|
/// High-bit operands so the 32x32 cross terms of the 64-bit multiply
/// lowerings are actually exercised.
test "multiplication wraparound and cross terms" {
  assert_eq(
    @v128.i32x4_mul(
      @v128.i32x4_const(0xffffffff, 0x80000000, 0x7fffffff, 0x12345678),
      @v128.i32x4_const(0xffffffff, 2, 0x7fffffff, 0x9abcdef0),
    ),
    @v128.i32x4_const(1, 0, 1, 0x242d2080),
  )
  assert_eq(
    @v128.i64x2_mul(
      @v128.i64x2_const(0xffffffffffffffffUL, 0x123456789abcdef0UL),
      @v128.i64x2_const(0xffffffffffffffffUL, 0xfedcba9876543210UL),
    ),
    @v128.i64x2_const(1UL, 0x236d88fe5618cf00UL),
  )
  assert_eq(
    @v128.i64x2_mul(
      @v128.i64x2_const(0x100000000UL, 0x1ffffffffUL),
      @v128.i64x2_const(0x100000000UL, 0x200000003UL),
    ),
    @v128.i64x2_const(0UL, 0x3fffffffdUL),
  )
  assert_eq(
    @v128.i64x2_extmul_low_i32x4_u(
      @v128.i32x4_const(0xffffffff, 0x80000000, 0, 0),
      @v128.i32x4_const(0xffffffff, 0x80000000, 0, 0),
    ),
    @v128.i64x2_const(0xfffffffe00000001UL, 0x4000000000000000UL),
  )
  assert_eq(
    @v128.i64x2_extmul_high_i32x4_u(
      @v128.i32x4_const(0, 0, 0xffffffff, 2),
      @v128.i32x4_const(0, 0, 0x80000000, 0xffffffff),
    ),
    @v128.i64x2_const(0x7fffffff80000000UL, 0x1fffffffeUL),
  )
}

///|
test "trunc_sat and conversions with special values" {
  let nan32 = Float::reinterpret_from_uint(0x7fc00000)
  let inf32 = Float::reinterpret_from_uint(0x7f800000)
  let neg_inf32 = Float::reinterpret_from_uint(0xff800000)
  assert_eq(
    @v128.i32x4_trunc_sat_f32x4_s(
      @v128.f32x4_const(nan32, inf32, neg_inf32, 2147483648.0),
    ),
    @v128.i32x4_const(0, 0x7fffffff, 0x80000000, 0x7fffffff),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f32x4_s(
      @v128.f32x4_const(2147483520.0, -2147483648.0, -0.9, 0.0),
    ),
    @v128.i32x4_const(0x7fffff80, 0x80000000, 0, 0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f32x4_u(
      @v128.f32x4_const(nan32, inf32, neg_inf32, 4294967040.0),
    ),
    @v128.i32x4_const(0, 0xffffffff, 0, 0xffffff00),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f32x4_u(
      @v128.f32x4_const(-0.9, 0.5, 2147483648.0, 4294967296.0),
    ),
    @v128.i32x4_const(0, 0, 0x80000000, 0xffffffff),
  )
  let nan64 = 0x7ff8000000000000UL.reinterpret_as_double()
  let inf64 = 0x7ff0000000000000UL.reinterpret_as_double()
  let neg_inf64 = 0xfff0000000000000UL.reinterpret_as_double()
  assert_eq(
    @v128.i32x4_trunc_sat_f64x2_s_zero(@v128.f64x2_const(nan64, inf64)),
    @v128.i32x4_const(0, 0x7fffffff, 0, 0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f64x2_s_zero(
      @v128.f64x2_const(neg_inf64, 2147483647.0),
    ),
    @v128.i32x4_const(0x80000000, 0x7fffffff, 0, 0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f64x2_u_zero(@v128.f64x2_const(nan64, 4294967295.0)),
    @v128.i32x4_const(0, 0xffffffff, 0, 0),
  )
  assert_eq(
    @v128.i32x4_trunc_sat_f64x2_u_zero(@v128.f64x2_const(inf64, -1.0)),
    @v128.i32x4_const(0xffffffff, 0, 0, 0),
  )
  assert_eq(
    @v128.f32x4_convert_i32x4_u(
      @v128.i32x4_const(0xffffffff, 0x80000000, 0xfffffff0, 1),
    ),
    @v128.f32x4_const(4294967296.0, 2147483648.0, 4294967296.0, 1.0),
  )
  assert_eq(
    @v128.f64x2_convert_low_i32x4_u(
      @v128.i32x4_const(0xffffffff, 0x80000000, 9, 9),
    ),
    @v128.f64x2_const(4294967295.0, 2147483648.0),
  )
  assert_eq(
    @v128.f32x4_demote_f64x2_zero(@v128.f64x2_const(1.0e308, -1.0e308)),
    @v128.f32x4_const(inf32, neg_inf32, 0.0, 0.0),
  )
  assert_eq(
    @v128.f64x2_promote_low_f32x4(@v128.f32x4_const(inf32, -0.0, 9.0, 9.0)),
    @v128.f64x2_const(inf64, -0.0),
  )
}

///|
test "rounding preserves the sign of zero" {
  assert_eq(
    @v128.f32x4_ceil(@v128.f32x4_const(-0.5, -0.0, 0.5, 2.5)),
    @v128.f32x4_const(-0.0, -0.0, 1.0, 3.0),
  )
  assert_eq(
    @v128.f32x4_floor(@v128.f32x4_const(0.5, -0.5, -0.0, 0.0)),
    @v128.f32x4_const(0.0, -1.0, -0.0, 0.0),
  )
  assert_eq(
    @v128.f32x4_trunc(@v128.f32x4_const(-0.5, 0.5, -2.5, 2.5)),
    @v128.f32x4_const(-0.0, 0.0, -2.0, 2.0),
  )
  assert_eq(
    @v128.f64x2_ceil(@v128.f64x2_const(-0.5, -0.0)),
    @v128.f64x2_const(-0.0, -0.0),
  )
  assert_eq(
    @v128.f64x2_floor(@v128.f64x2_const(-0.5, 0.5)),
    @v128.f64x2_const(-1.0, 0.0),
  )
  assert_eq(
    @v128.f64x2_trunc(@v128.f64x2_const(-0.5, -0.0)),
    @v128.f64x2_const(-0.0, -0.0),
  )
}

///|
test "unaligned memory offsets" {
  let bytes : FixedArray[Byte] = [
    0x10, 0x21, 0x32, 0x43, 0x54, 0x65, 0x76, 0x87, 0x98, 0xa9, 0xba, 0xcb, 0xdc,
    0xed, 0xfe, 0x0f, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
  ]
  assert_eq(
    @v128.v128_load(bytes, 1),
    @v128.i8x16_const(
      0x21, 0x32, 0x43, 0x54, 0x65, 0x76, 0x87, 0x98, 0xa9, 0xba, 0xcb, 0xdc, 0xed,
      0xfe, 0x0f, 0x11,
    ),
  )
  assert_eq(
    @v128.v128_load(bytes, 3),
    @v128.i8x16_const(
      0x43, 0x54, 0x65, 0x76, 0x87, 0x98, 0xa9, 0xba, 0xcb, 0xdc, 0xed, 0xfe, 0x0f,
      0x11, 0x22, 0x33,
    ),
  )
  assert_eq(
    @v128.v128_load8x8_s(bytes, 5),
    @v128.i16x8_const(
      0x65, 0x76, 0xff87, 0xff98, 0xffa9, 0xffba, 0xffcb, 0xffdc,
    ),
  )
  assert_eq(
    @v128.v128_load16x4_u(bytes, 1),
    @v128.i32x4_const(0x3221, 0x5443, 0x7665, 0x9887),
  )
  assert_eq(
    @v128.v128_load16x4_s(bytes, 3),
    @v128.i32x4_const(0x5443, 0x7665, 0xffff9887, 0xffffbaa9),
  )
  assert_eq(
    @v128.v128_load32x2_s(bytes, 1),
    @v128.i64x2_const(0x54433221UL, 0xffffffff98877665UL),
  )
  assert_eq(
    @v128.v128_load32x2_u(bytes, 3),
    @v128.i64x2_const(0x76655443UL, 0xbaa99887UL),
  )
  assert_eq(@v128.v128_load16_splat(bytes, 1), @v128.i16x8_splat(0x3221))
  assert_eq(@v128.v128_load32_splat(bytes, 3), @v128.i32x4_splat(0x76655443))
  assert_eq(
    @v128.v128_load64_splat(bytes, 1),
    @v128.i64x2_splat(0x9887766554433221UL),
  )
  assert_eq(
    @v128.v128_load32_zero(bytes, 1),
    @v128.i32x4_const(0x54433221, 0, 0, 0),
  )
  assert_eq(
    @v128.v128_load64_zero(bytes, 3),
    @v128.i64x2_const(0xbaa9988776655443UL, 0UL),
  )
  let base = @v128.i64x2_splat(0xaaaaaaaaaaaaaaaaUL)
  assert_eq(
    @v128.v128_load16_lane(bytes, 1, base, 3),
    @v128.i64x2_const(0x3221aaaaaaaaaaaaUL, 0xaaaaaaaaaaaaaaaaUL),
  )
  assert_eq(
    @v128.v128_load32_lane(bytes, 3, base, 2),
    @v128.i64x2_const(0xaaaaaaaaaaaaaaaaUL, 0xaaaaaaaa76655443UL),
  )
  assert_eq(
    @v128.v128_load64_lane(bytes, 5, base, 1),
    @v128.i64x2_const(0xaaaaaaaaaaaaaaaaUL, 0xdccbbaa998877665UL),
  )
  let out : FixedArray[Byte] = FixedArray::make(20, 0)
  @v128.v128_store(out, 3, @v128.v128_load(bytes, 0))
  for i in 0..<16 {
    assert_eq(out.unsafe_get(i + 3), bytes.unsafe_get(i))
  }
  assert_eq(out.unsafe_get(2), 0)
  assert_eq(out.unsafe_get(19), 0)
  @v128.v128_store16_lane(out, 1, base, 0)
  assert_eq(out.unsafe_get(1), 0xaa)
  assert_eq(out.unsafe_get(2), 0xaa)
  @v128.v128_store32_lane(out, 15, @v128.v128_load(bytes, 0), 1)
  assert_eq(out.unsafe_get(15), 0x54)
  assert_eq(out.unsafe_get(16), 0x65)
  assert_eq(out.unsafe_get(17), 0x76)
  assert_eq(out.unsafe_get(18), 0x87)
  @v128.v128_store64_lane(out, 7, base, 1)
  for i in 0..<8 {
    assert_eq(out.unsafe_get(7 + i), 0xaa)
  }
  @v128.v128_store8_lane(out, 0, @v128.v128_load(bytes, 1), 2)
  assert_eq(out.unsafe_get(0), 0x43)
}

///|
test "bitmask lane patterns" {
  inspect(@v128.i8x16_bitmask(@v128.i8x16_splat(0xff)), content="65535")
  inspect(@v128.i8x16_bitmask(@v128.i8x16_splat(0x7f)), content="0")
  inspect(
    @v128.i8x16_bitmask(
      @v128.i8x16_const(
        0x80, 0, 0x80, 0, 0x80, 0, 0x80, 0, 0x80, 0, 0x80, 0, 0x80, 0, 0x80, 0,
      ),
    ),
    content="21845",
  )
  inspect(
    @v128.i8x16_bitmask(
      @v128.i8x16_const(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0x80),
    ),
    content="32768",
  )
  inspect(@v128.i16x8_bitmask(@v128.i16x8_splat(0x8000)), content="255")
  inspect(
    @v128.i16x8_bitmask(
      @v128.i16x8_const(
        0x8000, 0x7fff, 0x8000, 0x7fff, 0x8000, 0x7fff, 0x8000, 0x7fff,
      ),
    ),
    content="85",
  )
  inspect(@v128.i32x4_bitmask(@v128.i32x4_splat(0xffffffff)), content="15")
  inspect(
    @v128.i32x4_bitmask(@v128.i32x4_const(0, 0, 0, 0x80000000)),
    content="8",
  )
  inspect(
    @v128.i64x2_bitmask(@v128.i64x2_splat(0xffffffffffffffffUL)),
    content="3",
  )
  inspect(
    @v128.i64x2_bitmask(@v128.i64x2_const(0UL, 0x8000000000000000UL)),
    content="2",
  )
}

///|
test "replace_lane out-of-range index leaves value unchanged" {
  let v = @v128.i8x16_const(
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
  )
  // runtime lane (loop variable) forces the fallback path on every backend;
  // negative and too-large indices must be a no-op, not corrupt a lane.
  for lane in [-1, -8, -100, 16, 17, 100] {
    assert_eq(@v128.i8x16_replace_lane(v, 0xaa, lane), v)
    assert_eq(@v128.i16x8_replace_lane(v, 0xbeef, lane), v)
    assert_eq(@v128.i32x4_replace_lane(v, 0xdeadbeef, lane), v)
    assert_eq(@v128.i64x2_replace_lane(v, 0x0123456789abcdefUL, lane), v)
  }
}
