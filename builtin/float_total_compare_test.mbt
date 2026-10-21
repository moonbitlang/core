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
#inline(never)
fn[T] call_total_compare(compare : (T, T) -> Int32, a : T, b : T) -> Int32 {
  compare(a, b)
}

///|
fn[T : Compare] check_total_compare(
  cases : Array[(T, Int32)],
  compare : (T, T) -> Int32,
) -> Unit raise {
  // Rank -1 denotes the single NaN equivalence class. Repeated zero ranks
  // merge signed zeros; every other rank denotes one numerical value.
  for (a, arank) in cases {
    assert_eq(compare(a, a), 0)
    for (b, brank) in cases {
      let order = compare(a, b)
      assert_eq(order, arank.compare(brank))
      assert_eq(call_total_compare(compare, a, b), order)
      assert_eq(order, -compare(b, a))
      if arank >= 0 && brank >= 0 {
        assert_eq(order, a.compare(b).compare(0))
        assert_eq(order == 0, a == b)
        assert_eq(order < 0, a < b)
        assert_eq(order <= 0, a <= b)
        assert_eq(order > 0, a > b)
        assert_eq(order >= 0, a >= b)
      }
      for (c, _) in cases {
        if order <= 0 && compare(b, c) <= 0 {
          assert_true(compare(a, c) <= 0)
        }
      }
    }
  }
  let values = cases.map(pair => pair.0)
  values.rev_in_place()
  values.sort_by(compare)
  for i in 1..<values.length() {
    assert_true(compare(values[i - 1], values[i]) <= 0)
  }
  for (key, _) in cases {
    match values.binary_search_by(value => compare(value, key)) {
      Ok(index) => assert_eq(compare(values[index], key), 0)
      Err(_) => fail("total comparison search failed")
    }
  }
}

///|
test "Double::total_compare edge cases and laws" {
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
  check_total_compare(cases, Double::total_compare)
}

///|
test "Float::total_compare edge cases and laws" {
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
  check_total_compare(cases, Float::total_compare)
}

///|
test "total_compare random encodings and numerical agreement" {
  let mut state = 0x4d595df4d0f33173UL
  for _ in 0..<4096 {
    state = state * 6364136223846793005UL + 1442695040888963407UL
    let a = state.reinterpret_as_double()
    let x = Float::reinterpret_from_uint(state.to_uint())
    state = state * 6364136223846793005UL + 1442695040888963407UL
    let b = state.reinterpret_as_double()
    let y = Float::reinterpret_from_uint(state.to_uint())
    let expected_double = if a.is_nan() {
      if b.is_nan() {
        0
      } else {
        -1
      }
    } else if b.is_nan() {
      1
    } else {
      a.compare(b).compare(0)
    }
    let expected_float = if x.is_nan() {
      if y.is_nan() {
        0
      } else {
        -1
      }
    } else if y.is_nan() {
      1
    } else {
      x.compare(y).compare(0)
    }
    assert_eq(a.total_compare(b), expected_double)
    assert_eq(x.total_compare(y), expected_float)
    assert_eq(b.total_compare(a), -expected_double)
    assert_eq(y.total_compare(x), -expected_float)
    assert_eq(a.total_compare(a), 0)
    assert_eq(x.total_compare(x), 0)
  }
}

///|
test "total_compare constant operands" {
  inspect((-0.0).total_compare(0.0), content="0")
  inspect((0.0 / 0.0).total_compare(1.0), content="-1")
  inspect(1.0.total_compare(0.0 / 0.0), content="1")
  inspect((0.0 / 0.0).total_compare(0.0 / 0.0), content="0")
  inspect((-0.0 : Float).total_compare(0.0), content="0")
  inspect(((0.0 : Float) / 0.0).total_compare(1.0), content="-1")
  inspect((1.0 : Float).total_compare(0.0 / 0.0), content="1")
  inspect(((0.0 : Float) / 0.0).total_compare(0.0 / 0.0), content="0")
}
