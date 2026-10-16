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
priv struct FloatingKey[T] {
  value : T
} derive(Eq, Compare, Hash)

///|
fn[T : Compare + Hash] check_float_relations(
  a : T,
  b : T,
  expected : (Bool, Bool, Bool, Bool, Bool, Bool),
  order : Int32?,
) -> Unit raise {
  let generic = (a == b, a != b, a < b, a <= b, a > b, a >= b)
  assert_eq(generic, expected)
  let eq : (T, T) -> Bool = Eq::equal
  let ne : (T, T) -> Bool = Eq::not_equal
  let lt : (T, T) -> Bool = Compare::op_lt
  let le : (T, T) -> Bool = Compare::op_le
  let gt : (T, T) -> Bool = Compare::op_gt
  let ge : (T, T) -> Bool = Compare::op_ge
  assert_eq(
    (eq(a, b), ne(a, b), lt(a, b), le(a, b), gt(a, b), ge(a, b)),
    expected,
  )
  let ka = FloatingKey::{ value: a, }
  let kb = FloatingKey::{ value: b, }
  assert_eq(ka == kb, expected.0)
  if expected.0 {
    assert_eq(Hash::hash(a), Hash::hash(b))
    assert_eq(Hash::hash(ka), Hash::hash(kb))
  }
  if order is Some(order) {
    let compare : (T, T) -> Int32 = Compare::compare
    assert_eq(Compare::compare(a, b).compare(0), order)
    assert_eq(compare(a, b).compare(0), order)
    assert_eq(Compare::compare(ka, kb).compare(0), order)
  }
}

///|
fn expected_float_relations(
  a : Int32,
  b : Int32,
) -> (Bool, Bool, Bool, Bool, Bool, Bool) {
  // Negative ranks denote NaNs; ordinary compare has no law on these inputs.
  let ordered = a >= 0 && b >= 0
  let eq = ordered && a == b
  (
    eq,
    !eq,
    ordered && a < b,
    ordered && a <= b,
    ordered && a > b,
    ordered && a >= b,
  )
}

///|
test "IEEE Double comparison paths and hashes" {
  let cases = [
    (0xfff0000000000000UL.reinterpret_as_double(), 0),
    (0xffefffffffffffffUL.reinterpret_as_double(), 1),
    (0xbff0000000000001UL.reinterpret_as_double(), 2),
    (0xbff0000000000000UL.reinterpret_as_double(), 3),
    (0x8010000000000000UL.reinterpret_as_double(), 4),
    (0x800fffffffffffffUL.reinterpret_as_double(), 5),
    (0x8000000000000001UL.reinterpret_as_double(), 6),
    (0x8000000000000000UL.reinterpret_as_double(), 7),
    (0x0000000000000000UL.reinterpret_as_double(), 7),
    (0x0000000000000001UL.reinterpret_as_double(), 8),
    (0x000fffffffffffffUL.reinterpret_as_double(), 9),
    (0x0010000000000000UL.reinterpret_as_double(), 10),
    (0x3ff0000000000000UL.reinterpret_as_double(), 11),
    (0x3ff0000000000001UL.reinterpret_as_double(), 12),
    (0x7fefffffffffffffUL.reinterpret_as_double(), 13),
    (0x7ff0000000000000UL.reinterpret_as_double(), 14),
    (0x7ff8000000000000UL.reinterpret_as_double(), -1),
    (0xfff8000000000000UL.reinterpret_as_double(), -1),
    (0x7fffffffffffffffUL.reinterpret_as_double(), -1),
    (0xffffffffffffffffUL.reinterpret_as_double(), -1),
    (0x7ff0000000000001UL.reinterpret_as_double(), -1),
    (0xfff0000000000001UL.reinterpret_as_double(), -1),
  ]
  for (a, arank) in cases {
    for (b, brank) in cases {
      let expected = expected_float_relations(arank, brank)
      assert_eq((a == b, a != b, a < b, a <= b, a > b, a >= b), expected)
      let order = if arank >= 0 && brank >= 0 {
        Some(arank.compare(brank))
      } else {
        None
      }
      check_float_relations(a, b, expected, order)
    }
  }
}

///|
test "IEEE Float comparison paths and hashes" {
  let cases = [
    (Float::reinterpret_from_uint(0xff800000U), 0),
    (Float::reinterpret_from_uint(0xff7fffffU), 1),
    (Float::reinterpret_from_uint(0xbf800001U), 2),
    (Float::reinterpret_from_uint(0xbf800000U), 3),
    (Float::reinterpret_from_uint(0x80800000U), 4),
    (Float::reinterpret_from_uint(0x807fffffU), 5),
    (Float::reinterpret_from_uint(0x80000001U), 6),
    (Float::reinterpret_from_uint(0x80000000U), 7),
    (Float::reinterpret_from_uint(0x00000000U), 7),
    (Float::reinterpret_from_uint(0x00000001U), 8),
    (Float::reinterpret_from_uint(0x007fffffU), 9),
    (Float::reinterpret_from_uint(0x00800000U), 10),
    (Float::reinterpret_from_uint(0x3f800000U), 11),
    (Float::reinterpret_from_uint(0x3f800001U), 12),
    (Float::reinterpret_from_uint(0x7f7fffffU), 13),
    (Float::reinterpret_from_uint(0x7f800000U), 14),
    (Float::reinterpret_from_uint(0x7fc00000U), -1),
    (Float::reinterpret_from_uint(0xffc00000U), -1),
    (Float::reinterpret_from_uint(0x7fffffffU), -1),
    (Float::reinterpret_from_uint(0xffffffffU), -1),
    (Float::reinterpret_from_uint(0x7f800001U), -1),
    (Float::reinterpret_from_uint(0xff800001U), -1),
  ]
  for (a, arank) in cases {
    for (b, brank) in cases {
      let expected = expected_float_relations(arank, brank)
      assert_eq((a == b, a != b, a < b, a <= b, a > b, a >= b), expected)
      let order = if arank >= 0 && brank >= 0 {
        Some(arank.compare(brank))
      } else {
        None
      }
      check_float_relations(a, b, expected, order)
    }
  }
}

///|
test "IEEE random encodings preserve ordinary non-NaN laws" {
  let mut state = 0x4d595df4d0f33173UL
  for _ in 0..<256 {
    state = state * 6364136223846793005UL + 1442695040888963407UL
    let a = state.reinterpret_as_double()
    let x = Float::reinterpret_from_uint(state.to_uint())
    state = state * 6364136223846793005UL + 1442695040888963407UL
    let b = state.reinterpret_as_double()
    let y = Float::reinterpret_from_uint(state.to_uint())
    if !a.is_nan() && !b.is_nan() {
      let order = Compare::compare(a, b)
      assert_eq(
        (a == b, a != b, a < b, a <= b, a > b, a >= b),
        (order == 0, order != 0, order < 0, order <= 0, order > 0, order >= 0),
      )
      check_float_relations(
        a,
        b,
        (a == b, a != b, a < b, a <= b, a > b, a >= b),
        Some(order.compare(0)),
      )
    }
    if !x.is_nan() && !y.is_nan() {
      let order = x.compare(y)
      assert_eq(
        (x == y, x != y, x < y, x <= y, x > y, x >= y),
        (order == 0, order != 0, order < 0, order <= 0, order > 0, order >= 0),
      )
      check_float_relations(
        x,
        y,
        (x == y, x != y, x < y, x <= y, x > y, x >= y),
        Some(order.compare(0)),
      )
    }
  }
}

///|
fn[T : Compare + Hash] check_float_collections(
  negative : T,
  positive : T,
  zero : T,
  neg_zero : T,
) -> Unit raise {
  let values = [positive, zero, negative, neg_zero]
  values.sort()
  assert_true(values.is_sorted())
  assert_eq(values.binary_search(zero), Ok(1))
  assert_eq(values.binary_search(neg_zero), Ok(1))
  let map : Map[T, Int32] = Map([])
  map[neg_zero] = 1
  assert_eq(map.get(zero), Some(1))
  map[zero] = 2
  assert_eq(map.length(), 1)
  assert_eq(map.get(neg_zero), Some(2))
  map.remove(neg_zero)
  assert_eq(map.length(), 0)
  let keys = [
    FloatingKey::{ value: positive, },
    { value: neg_zero, },
    { value: negative, },
    { value: zero, },
  ]
  keys.sort()
  assert_true(keys.is_sorted())
  assert_eq(keys.binary_search({ value: zero, }), Ok(1))
}

///|
#inline(never)
fn runtime_inverse_double(value : Double) -> Double {
  1.0 / value
}

///|
#inline(never)
fn runtime_inverse_float(value : Float) -> Float {
  (1.0 : Float) / value
}

///|
test "IEEE signed zeros work in ordinary sorting searching and maps" {
  check_float_collections(-1.0, 1.0, 0.0, -0.0)
  check_float_collections(
    (-1.0 : Float),
    (1.0 : Float),
    (0.0 : Float),
    (-0.0 : Float),
  )
  // Equality and hashing do not erase stored signs or affect arithmetic.
  let d = -0.0
  let f : Float = -0.0
  assert_eq(Hash::hash(d), Hash::hash(0.0))
  assert_eq(Hash::hash(f), Hash::hash((0.0 : Float)))
  assert_eq(d.reinterpret_as_int64(), -9223372036854775808L)
  assert_eq(f.reinterpret_as_uint(), 0x80000000U)
  assert_true(runtime_inverse_double(d) < 0.0)
  assert_true(runtime_inverse_float(f) < (0.0 : Float))
}
