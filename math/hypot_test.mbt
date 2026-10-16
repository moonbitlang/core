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
test "hypot issue #4351 regressions" {
  inspect(@math.hypot(99.0, 20.0), content="101")
  inspect(@math.hypotf(99.0, 20.0), content="101")
  let x = 0xc127d00ce80451e2UL.reinterpret_as_double()
  let y = 0xc13dac6a5bf9e60eUL.reinterpret_as_double()
  // Exact integer comparisons against the squared rounding midpoints give
  // this nearest Double; the old ratio formula was two ulps away.
  for (a, b) in [(x, y), (y, x), (-x, y), (x, -y), (-x, -y)] {
    assert_eq(@math.hypot(a, b).reinterpret_as_uint64(), 0x413ff91b885e0990UL)
  }
  // A larger exact triple also needs compensation when adding the squares.
  for exponent in [0, 526, -526, -1074] {
    let a = @math.scalbn(4433317774767.0, exponent)
    let b = @math.scalbn(4403546189856.0, exponent)
    let expected = @math.scalbn(6248641895505.0, exponent)
    assert_eq(@math.hypot(a, b), expected)
  }
}

///|
test "hypot exact Pythagorean triples across exponents" {
  // Euclid's formula gives exact integer inputs and results. Scaling by a
  // power of two preserves them, including integer multiples of 2^-1074.
  for exponent in [0, 507, 508, 509, 900, -451, -452, -453, -1000, -1074] {
    for m in 2..<=40 {
      for n in 1..<m {
        let a = @math.scalbn((m * m - n * n).to_double(), exponent)
        let b = @math.scalbn((2 * m * n).to_double(), exponent)
        let expected = @math.scalbn((m * m + n * n).to_double(), exponent)
        assert_eq(@math.hypot(a, b), expected)
        assert_eq(@math.hypot(-b, a), expected)
      }
    }
  }
}

///|
test "hypotf exact Pythagorean triples across exponents" {
  // All the integer significands fit exactly in Float, even when scaled to
  // the smallest subnormal quantum. Squaring directly would overflow or
  // underflow at the extreme exponents.
  for exponent in [0, 100, -140, -149] {
    for m in 2..<=40 {
      for n in 1..<m {
        let a = @math.scalbnf(Float::from_int(m * m - n * n), exponent)
        let b = @math.scalbnf(Float::from_int(2 * m * n), exponent)
        let expected = @math.scalbnf(Float::from_int(m * m + n * n), exponent)
        assert_eq(@math.hypotf(a, b), expected)
        assert_eq(@math.hypotf(-b, a), expected)
      }
    }
  }
}

///|
test "hypot extreme finite values and positive zero" {
  let cases : ReadOnlyArray[(UInt64, UInt64, UInt64)] = [
    (0x0000000000000000, 0x0000000000000000, 0x0000000000000000),
    (0x8000000000000000, 0x0000000000000000, 0x0000000000000000),
    (0x8000000000000000, 0x8000000000000000, 0x0000000000000000),
    // The two smallest subnormals, and the smallest normal with a tiny leg.
    (0x0000000000000001, 0x0000000000000001, 0x0000000000000001),
    (0x0000000000000001, 0x0000000000000002, 0x0000000000000002),
    (0x0010000000000000, 0x0000000000000001, 0x0010000000000000),
    // A 3-4-5 triple close to overflow, then rounded finite/overflow cases.
    (0x7fd8000000000000, 0x7fe0000000000000, 0x7fe4000000000000),
    (0x7fefffffffffffff, 0x0000000000000001, 0x7fefffffffffffff),
    (0x7fefffffffffffff, 0x7fefffffffffffff, 0x7ff0000000000000),
  ]
  for (a, b, expected) in cases {
    let x = a.reinterpret_as_double()
    let y = b.reinterpret_as_double()
    assert_eq(@math.hypot(x, y).reinterpret_as_uint64(), expected)
    assert_eq(@math.hypot(y, x).reinterpret_as_uint64(), expected)
  }
}

///|
test "hypotf extreme finite values and positive zero" {
  let cases : ReadOnlyArray[(UInt32, UInt32, UInt32)] = [
    (0x00000000, 0x00000000, 0x00000000),
    (0x80000000, 0x00000000, 0x00000000),
    (0x80000000, 0x80000000, 0x00000000),
    (0x00000001, 0x00000001, 0x00000001),
    (0x00000001, 0x00000002, 0x00000002),
    (0x00800000, 0x00000001, 0x00800000),
    // 3*2^125, 4*2^125, 5*2^125.
    (0x7ec00000, 0x7f000000, 0x7f200000),
    (0x7f7fffff, 0x00000001, 0x7f7fffff),
    (0x7f7fffff, 0x7f7fffff, 0x7f800000),
  ]
  for (a, b, expected) in cases {
    let x = Float::reinterpret_from_uint(a)
    let y = Float::reinterpret_from_uint(b)
    assert_eq(@math.hypotf(x, y).reinterpret_as_uint(), expected)
    assert_eq(@math.hypotf(y, x).reinterpret_as_uint(), expected)
  }
}

///|
test "hypotf infinity takes precedence over NaN" {
  let others : ReadOnlyArray[Float] = [
    0.0, -1.0, @float.not_a_number, @float.neg_infinity,
  ]
  for infinity in [@float.infinity, @float.neg_infinity] {
    for other in others {
      assert_eq(@math.hypotf(infinity, other), @float.infinity)
      assert_eq(@math.hypotf(other, infinity), @float.infinity)
    }
  }
  inspect(@math.hypotf(@float.not_a_number, 0.0).is_nan(), content="true")
  inspect(@math.hypotf(0.0, @float.not_a_number).is_nan(), content="true")
  inspect(
    @math.hypotf(@float.not_a_number, @float.not_a_number).is_nan(),
    content="true",
  )
}
