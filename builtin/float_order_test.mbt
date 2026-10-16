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
priv struct FloatKey[T] {
  value : T
} derive(Eq, Compare, Hash)

///|
fn[T : Compare + Hash] check_float_order(
  values : Array[T],
  direct : (T, T) -> (Bool, Bool, Bool, Bool, Bool, Bool),
) -> Unit raise {
  for a in values {
    assert_true(a == a)
    for b in values {
      let cmp = Compare::compare(a, b)
      assert_eq(cmp, -Compare::compare(b, a))
      assert_eq(a == b, cmp == 0)
      assert_eq(a != b, cmp != 0)
      assert_eq(a < b, cmp < 0)
      assert_eq(a <= b, cmp <= 0)
      assert_eq(a > b, cmp > 0)
      assert_eq(a >= b, cmp >= 0)
      assert_eq(
        direct(a, b),
        (cmp == 0, cmp != 0, cmp < 0, cmp <= 0, cmp > 0, cmp >= 0),
      )
      let ka = FloatKey::{ value: a, }
      let kb = FloatKey::{ value: b, }
      assert_eq(ka == kb, cmp == 0)
      assert_eq(Compare::compare(ka, kb), cmp)
      if a == b {
        assert_eq(Hash::hash(a), Hash::hash(b))
        assert_eq(Hash::hash(ka), Hash::hash(kb))
      }
      for c in values {
        if a <= b && b <= c {
          assert_true(a <= c)
        }
        if a == b && b == c {
          assert_true(a == c)
        }
      }
    }
  }
}

///|
test "Double Eq Compare Hash laws and concrete operators" {
  let values : Array[Double] = [
    0UL, 0x8000000000000000UL, 0x3ff0000000000000UL, 0xbff0000000000000UL, 0x7ff0000000000000UL,
    0xfff0000000000000UL, 0x7ff8000000000001UL, 0x7ff8000000000002UL, 0xfff8000000000001UL,
    0x7ff0000000000001UL, 0xfff0000000000001UL, 1UL, 0x8000000000000001UL, 0x7fefffffffffffffUL,
    0x0010000000000000UL,
  ].map(x => x.reinterpret_as_double())
  let mut bits = 0x123456789abcdefUL
  for _ in 0..<24 {
    bits = bits ^ (bits << 13)
    bits = bits ^ (bits >> 7)
    bits = bits ^ (bits << 17)
    values.push(bits.reinterpret_as_double())
  }
  check_float_order(values, (a, b) => {
    (a == b, a != b, a < b, a <= b, a > b, a >= b)
  })
  inspect(@double.infinity < @double.not_a_number, content="true")
  inspect(
    Double::equal(@double.not_a_number, -@double.not_a_number),
    content="true",
  )
}

///|
test "Float Eq Compare Hash laws and concrete operators" {
  let values : Array[Float] = [
    0U, 0x80000000U, 0x3f800000U, 0xbf800000U, 0x7f800000U, 0xff800000U, 0x7fc00001U,
    0x7fc00002U, 0xffc00001U, 0x7f800001U, 0xff800001U, 1U, 0x80000001U, 0x7f7fffffU,
    0x00800000U,
  ].map(Float::reinterpret_from_uint)
  let mut bits = 0x12345678U
  for _ in 0..<24 {
    bits = bits ^ (bits << 13)
    bits = bits ^ (bits >> 17)
    bits = bits ^ (bits << 5)
    values.push(Float::reinterpret_from_uint(bits))
  }
  check_float_order(values, (a, b) => {
    (a == b, a != b, a < b, a <= b, a > b, a >= b)
  })
  inspect(@float.infinity < @float.not_a_number, content="true")
  inspect(
    Float::equal(@float.not_a_number, -@float.not_a_number),
    content="true",
  )
}

///|
test "floating keys collapse NaN payloads and signed zero" {
  let nan = 0x7ff8000000000001UL.reinterpret_as_double()
  let other = 0xfff8000000000002UL.reinterpret_as_double()
  let map : Map[Double, Int32] = Map([
    (nan, 1),
    (other, 2),
    (-0.0, 3),
    (0.0, 4),
    (1.0, 5),
  ])
  inspect(map.length(), content="3")
  debug_inspect(map.get(nan), content="Some(2)")
  debug_inspect(map.get(-0.0), content="Some(4)")
  map.remove(other)
  debug_inspect(map.get(nan), content="None")
  let f = Float::reinterpret_from_uint(0x7fc00001U)
  let g = Float::reinterpret_from_uint(0xffc00002U)
  let fm : Map[Float, Int32] = Map([(f, 1), (g, 2), (-0.0F, 3), (0.0F, 4)])
  inspect(fm.length(), content="2")
  debug_inspect(fm.get(f), content="Some(2)")
  debug_inspect(fm.get(-0.0F), content="Some(4)")
  let sorted = [nan, 1.0, -0.0, @double.neg_infinity, other, @double.infinity]
  sorted.sort()
  inspect(
    sorted.map(x => x.to_string()).join(","),
    content="-Infinity,0,1,Infinity,NaN,NaN",
  )
  assert_eq(
    sorted.binary_search(nan),
    sorted.binary_search_by(x => x.compare(nan)),
  )
  assert_true((1.0, nan) < (2.0, -1.0))
  assert_true((nan, 1.0) < (other, 2.0))
}

///|
test "raw IEEE predicates stay unordered and arithmetic preserves signed zero" {
  for
    nan in [@double.not_a_number, 0x7ff0000000000001UL.reinterpret_as_double()] {
    for x in [nan, -1.0, 0.0, @double.infinity] {
      assert_false(nan.ieee_equal(x))
      assert_true(nan.ieee_not_equal(x))
      assert_false(nan.ieee_lt(x))
      assert_false(nan.ieee_le(x))
      assert_false(nan.ieee_gt(x))
      assert_false(nan.ieee_ge(x))
      assert_false(x.ieee_lt(nan))
      assert_false(x.ieee_ge(nan))
    }
    assert_false(nan.is_inf())
    assert_false(nan.is_pos_inf())
    assert_false(nan.is_neg_inf())
    assert_false(nan.is_close(nan))
    assert_true(nan.clamp(min=0.0, max=1.0).is_nan())
    assert_true(nan.signum().is_nan())
  }
  let nan = @float.not_a_number
  for x in [nan, -1.0F, 0.0F, @float.infinity] {
    assert_false(nan.ieee_equal(x))
    assert_true(nan.ieee_not_equal(x))
    assert_false(nan.ieee_lt(x))
    assert_false(nan.ieee_le(x))
    assert_false(nan.ieee_gt(x))
    assert_false(nan.ieee_ge(x))
    assert_false(x.ieee_lt(nan))
    assert_false(x.ieee_ge(nan))
  }
  assert_false(nan.is_inf())
  assert_false(nan.is_close(nan))
  assert_true(nan.clamp(min=0.0F, max=1.0F).is_nan())
  let negative_zero = float_order_runtime_double(0x8000000000000000UL)
  let positive_zero = float_order_runtime_double(0UL)
  inspect((1.0 / negative_zero).is_neg_inf(), content="true")
  inspect((1.0 / positive_zero).is_pos_inf(), content="true")
  inspect(
    (negative_zero * 2.0).reinterpret_as_uint64(),
    content="9223372036854775808",
  )
  let negative_zero_f = float_order_runtime_float(0x80000000U)
  inspect((1.0F / negative_zero_f).is_neg_inf(), content="true")
  inspect((negative_zero_f * 2.0F).reinterpret_as_uint(), content="2147483648")
}

///|
#inline(never)
fn float_order_runtime_double(bits : UInt64) -> Double {
  bits.reinterpret_as_double()
}

///|
#inline(never)
fn float_order_runtime_float(bits : UInt32) -> Float {
  Float::reinterpret_from_uint(bits)
}

///|
const Float_order_inf : Double = 1.0e308 * 1.0e308

///|
const Float_order_nan : Double = Float_order_inf - Float_order_inf

///|
const Float_order_equal : Bool = Float_order_nan == Float_order_nan

///|
const Float_order_not_equal : Bool = Float_order_nan != Float_order_nan

///|
const Float_order_last : Bool = Float_order_nan > Float_order_inf

///|
const Float_order_float_round : Bool = 16777216.0F == 16777217.0F

///|
test "NaN constant patterns agree with equality" {
  let nan = float_order_runtime_double(0xfff8000000000002UL)
  inspect(nan is Float_order_nan, content="true")
  inspect(1.0 is Float_order_nan, content="false")
  inspect(Float_order_nan is Float_order_nan, content="true")
  let mut calls = 0
  fn next() -> Double {
    calls += 1
    nan
  }
  inspect(next() is Float_order_nan, content="true")
  inspect(calls, content="1")
}

///|
test "constant folded NaN comparisons agree with runtime" {
  inspect(Float_order_equal, content="true")
  inspect(Float_order_not_equal, content="false")
  inspect(Float_order_last, content="true")
  inspect(Float_order_float_round, content="true")
  let inf = 1.0e308 * 1.0e308
  let nan = inf - inf
  inspect(nan == nan, content="true")
  inspect(nan != nan, content="false")
  inspect(nan > inf, content="true")
  inspect(nan < 1.0, content="false")
  inspect(nan.is_nan(), content="true")
  inspect(nan.ieee_equal(nan), content="false")
  inspect(nan.ieee_not_equal(nan), content="true")
  inspect(nan.ieee_lt(1.0), content="false")
  inspect(nan.ieee_le(nan), content="false")
  inspect(nan.ieee_gt(1.0), content="false")
  inspect(nan.ieee_ge(nan), content="false")
}

///|
#inline(never)
fn[T] apply_float_equal(f : (T, T) -> Bool, a : T, b : T) -> Bool {
  f(a, b)
}

///|
#inline(never)
fn[T] apply_float_compare(f : (T, T) -> Int32, a : T, b : T) -> Int32 {
  f(a, b)
}

///|
test "unsaturated floating comparison methods" {
  let a = float_order_runtime_double(0x7ff8000000000001UL)
  let b = float_order_runtime_double(0xfff8000000000002UL)
  inspect(apply_float_equal(Double::equal, a, b), content="true")
  inspect(apply_float_compare(Double::compare, a, b), content="0")
  inspect(
    apply_float_compare(Double::compare, a, @double.infinity),
    content="1",
  )
  let x = float_order_runtime_float(0x7fc00001U)
  let y = float_order_runtime_float(0xffc00002U)
  inspect(apply_float_equal(Float::equal, x, y), content="true")
  inspect(apply_float_compare(Float::compare, x, y), content="0")
  inspect(apply_float_compare(Float::compare, x, @float.infinity), content="1")
}
