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
  assert_eq(
    @v128.i16x8_relaxed_dot_s_i8x16(bytes, @v128.i8x16_splat(2)),
    @v128.i16x8_const(0xfefe, 6, 14, 22, 254, 0xfff6, 34, 42),
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
  assert_eq(
    @v128.i32x4_relaxed_dot_add_s_i16x8(
      words,
      @v128.i16x8_splat(2),
      @v128.i32x4_splat(1),
    ),
    @v128.i32x4_const(0xfffeffff, 7, 0xffff, 0x2465),
  )

  assert_eq(
    @v128.i8x16_relaxed_laneselect(
      @v128.i8x16_splat(0xaa),
      @v128.i8x16_splat(0x55),
      @v128.i8x16_const(0x80, 0, 0xff, 0x7f, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
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
      @v128.i32x4_const(0x80000000, 0, 0xffffffff, 0x7fffffff),
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
    let replaced = @v128.i8x16_replace_lane(bytes, lane, 0xee)
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
    let replaced = @v128.i16x8_replace_lane(words, lane, 0xbeef)
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
    let replaced = @v128.i32x4_replace_lane(dwords, lane, 0xdeadbeef)
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
    let replaced = @v128.i64x2_replace_lane(qwords, lane, 0xa5a5a5a5a5a5a5a5UL)
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
    let replaced = @v128.f32x4_replace_lane(floats, lane, 9.0)
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
    let replaced = @v128.f64x2_replace_lane(doubles, lane, -9.0)
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
    @v128.f32x4_const(2.0, nan32, 0.0, -4.0),
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
