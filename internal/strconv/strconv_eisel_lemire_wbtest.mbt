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
test "Eisel-Lemire agrees with exact Decimal conversion" {
  let cases : FixedArray[(String, UInt64, Int64, Bool)] = [
    ("-65.613616999999977", 65613616999999977UL, -15L, true),
    ("43.420273000000009", 43420273000000009UL, -15L, false),
    ("-65.619720000000029", 65619720000000029UL, -15L, true),
    ("43.418052999999986", 43418052999999986UL, -15L, false),
    ("9.999999999999999999", 9999999999999999999UL, -18L, false),
    ("1.234567890123456789e100", 1234567890123456789UL, 82L, false),
    ("1e-307", 1UL, -307L, false),
    ("1e308", 1UL, 308L, false),
  ]
  for case in cases {
    let (input, mantissa, exponent, negative) = case
    let fast = try_eisel_lemire64(mantissa, exponent, negative)
    if fast.is_nan() {
      fail("Eisel-Lemire unexpectedly rejected \{input}")
    }
    let exact = parse_decimal_priv(input).to_double_priv()
    @test.assert_eq(fast.reinterpret_as_uint64(), exact.reinterpret_as_uint64())
  }
}

///|
test "Eisel-Lemire preserves negative zero" {
  inspect(
    try_eisel_lemire64(0UL, 0L, true).reinterpret_as_uint64(),
    content="9223372036854775808",
  )
}

///|
test "Eisel-Lemire rejects values reserved for the exact fallback" {
  inspect(try_eisel_lemire64(1UL, -348L, false).is_nan(), content="true")
  inspect(try_eisel_lemire64(1UL, 348L, false).is_nan(), content="true")
}

///|
test "Eisel-Lemire differential exponent coverage" {
  let mantissas : FixedArray[UInt64] = [
    1UL, 10UL, 9007199254740993UL, 65613616999999977UL, 1234567890123456789UL, 9223372036854775807UL,
    9999999999999999999UL,
  ]
  for mantissa in mantissas {
    for exponent in -340..<=340 {
      let fast = try_eisel_lemire64(mantissa, exponent.to_int64(), false)
      if !fast.is_nan() {
        let input = "\{mantissa}e\{exponent}"
        let exact = parse_decimal_priv(input).to_double_priv()
        @test.assert_eq(
          fast.reinterpret_as_uint64(),
          exact.reinterpret_as_uint64(),
        )
      }
    }
  }
}
