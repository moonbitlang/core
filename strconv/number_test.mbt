// Copyright 2024 International Digital Economy Academy
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

test "parse_double" {
  let tests : Array[(String, String)] = [
    (
      "1x", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 1))",
    ),
    (
      "1.1.", "Some(({exponent: -1, mantissa: 11, negative: false, many_digits: false}, 3))",
    ),
    (
      "1e", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 1))",
    ),
    (
      "1e-", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 1))",
    ),
    (".e-1", "None"),
    (
      "1", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 1))",
    ),
    (
      "+1", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 2))",
    ),
    (
      "1e23", "Some(({exponent: 23, mantissa: 1, negative: false, many_digits: false}, 4))",
    ),
    (
      "1E23", "Some(({exponent: 23, mantissa: 1, negative: false, many_digits: false}, 4))",
    ),
    (
      "100000000000000000000000", "Some(({exponent: 5, mantissa: 1000000000000000000, negative: false, many_digits: true}, 24))",
    ),
    (
      "1e-100", "Some(({exponent: -100, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "123456700", "Some(({exponent: 0, mantissa: 123456700, negative: false, many_digits: false}, 9))",
    ),
    (
      "99999999999999974834176", "Some(({exponent: 4, mantissa: -8446744073709554133, negative: false, many_digits: true}, 23))",
    ),
    (
      "100000000000000000000001", "Some(({exponent: 5, mantissa: 1000000000000000000, negative: false, many_digits: true}, 24))",
    ),
    (
      "100000000000000008388608", "Some(({exponent: 5, mantissa: 1000000000000000083, negative: false, many_digits: true}, 24))",
    ),
    (
      "100000000000000016777215", "Some(({exponent: 5, mantissa: 1000000000000000167, negative: false, many_digits: true}, 24))",
    ),
    (
      "100000000000000016777216", "Some(({exponent: 5, mantissa: 1000000000000000167, negative: false, many_digits: true}, 24))",
    ),
    (
      "-1", "Some(({exponent: 0, mantissa: 1, negative: true, many_digits: false}, 2))",
    ),
    (
      "-0.1", "Some(({exponent: -1, mantissa: 1, negative: true, many_digits: false}, 4))",
    ),
    (
      "-0", "Some(({exponent: 0, mantissa: 0, negative: true, many_digits: false}, 2))",
    ),
    (
      "1e-20", "Some(({exponent: -20, mantissa: 1, negative: false, many_digits: false}, 5))",
    ),
    (
      "625e-3", "Some(({exponent: -3, mantissa: 625, negative: false, many_digits: false}, 6))",
    ),
    (
      "6.62607015e-34", "Some(({exponent: -42, mantissa: 662607015, negative: false, many_digits: false}, 14))",
    ),
    (
      "2.2250738585072012e-308", "Some(({exponent: -324, mantissa: 22250738585072012, negative: false, many_digits: false}, 23))",
    ),
    (
      "2.2250738585072011e-308", "Some(({exponent: -324, mantissa: 22250738585072011, negative: false, many_digits: false}, 23))",
    ),
    (
      "0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 1))",
    ),
    (
      "0e0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 3))",
    ),
    (
      "-0e0", "Some(({exponent: 0, mantissa: 0, negative: true, many_digits: false}, 4))",
    ),
    (
      "+0e0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 4))",
    ),
    (
      "0e-0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 4))",
    ),
    (
      "-0e-0", "Some(({exponent: 0, mantissa: 0, negative: true, many_digits: false}, 5))",
    ),
    (
      "+0e-0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 5))",
    ),
    (
      "0e+0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 4))",
    ),
    (
      "-0e+0", "Some(({exponent: 0, mantissa: 0, negative: true, many_digits: false}, 5))",
    ),
    (
      "+0e+0", "Some(({exponent: 0, mantissa: 0, negative: false, many_digits: false}, 5))",
    ),
    (
      "0e+01234567890123456789", "Some(({exponent: 123456, mantissa: 0, negative: false, many_digits: false}, 23))",
    ),
    (
      "0.00e-01234567890123456789", "Some(({exponent: -123458, mantissa: 0, negative: false, many_digits: false}, 26))",
    ),
    (
      "-0e+01234567890123456789", "Some(({exponent: 123456, mantissa: 0, negative: true, many_digits: false}, 24))",
    ),
    (
      "-0.00e-01234567890123456789", "Some(({exponent: -123458, mantissa: 0, negative: true, many_digits: false}, 27))",
    ),
    (
      "0e292", "Some(({exponent: 292, mantissa: 0, negative: false, many_digits: false}, 5))",
    ),
    (
      "0e347", "Some(({exponent: 347, mantissa: 0, negative: false, many_digits: false}, 5))",
    ),
    (
      "0e348", "Some(({exponent: 348, mantissa: 0, negative: false, many_digits: false}, 5))",
    ),
    (
      "-0e291", "Some(({exponent: 291, mantissa: 0, negative: true, many_digits: false}, 6))",
    ),
    (
      "-0e292", "Some(({exponent: 292, mantissa: 0, negative: true, many_digits: false}, 6))",
    ),
    (
      "-0e347", "Some(({exponent: 347, mantissa: 0, negative: true, many_digits: false}, 6))",
    ),
    (
      "-0e348", "Some(({exponent: 348, mantissa: 0, negative: true, many_digits: false}, 6))",
    ),
    (
      "1.7976931348623157e308", "Some(({exponent: 292, mantissa: 17976931348623157, negative: false, many_digits: false}, 22))",
    ),
    (
      "-1.7976931348623157e308", "Some(({exponent: 292, mantissa: 17976931348623157, negative: true, many_digits: false}, 23))",
    ),
    (
      "1.7976931348623158e308", "Some(({exponent: 292, mantissa: 17976931348623158, negative: false, many_digits: false}, 22))",
    ),
    (
      "-1.7976931348623158e308", "Some(({exponent: 292, mantissa: 17976931348623158, negative: true, many_digits: false}, 23))",
    ),
    (
      "1e308", "Some(({exponent: 308, mantissa: 1, negative: false, many_digits: false}, 5))",
    ),
    (
      "1.7976931348623159e308", "Some(({exponent: 292, mantissa: 17976931348623159, negative: false, many_digits: false}, 22))",
    ),
    (
      "-1.7976931348623159e308", "Some(({exponent: 292, mantissa: 17976931348623159, negative: true, many_digits: false}, 23))",
    ),
    (
      "2e308", "Some(({exponent: 308, mantissa: 2, negative: false, many_digits: false}, 5))",
    ),
    (
      "1e309", "Some(({exponent: 309, mantissa: 1, negative: false, many_digits: false}, 5))",
    ),
    (
      "1e310", "Some(({exponent: 310, mantissa: 1, negative: false, many_digits: false}, 5))",
    ),
    (
      "1e400", "Some(({exponent: 400, mantissa: 1, negative: false, many_digits: false}, 5))",
    ),
    (
      "1e40000", "Some(({exponent: 40000, mantissa: 1, negative: false, many_digits: false}, 7))",
    ),
    (
      "1e-305", "Some(({exponent: -305, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-306", "Some(({exponent: -306, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-307", "Some(({exponent: -307, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-308", "Some(({exponent: -308, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-309", "Some(({exponent: -309, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-310", "Some(({exponent: -310, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-322", "Some(({exponent: -322, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "5e-324", "Some(({exponent: -324, mantissa: 5, negative: false, many_digits: false}, 6))",
    ),
    (
      "4e-324", "Some(({exponent: -324, mantissa: 4, negative: false, many_digits: false}, 6))",
    ),
    (
      "3e-324", "Some(({exponent: -324, mantissa: 3, negative: false, many_digits: false}, 6))",
    ),
    (
      "2e-324", "Some(({exponent: -324, mantissa: 2, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-350", "Some(({exponent: -350, mantissa: 1, negative: false, many_digits: false}, 6))",
    ),
    (
      "1e-400000", "Some(({exponent: -400000, mantissa: 1, negative: false, many_digits: false}, 9))",
    ),
    (
      "1_23.50_0_0e+1_2", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 1))",
    ),
    ("-_123.5e+12", "None"),
    ("+_123.5e+12", "None"),
    ("_123.5e+12", "None"),
    (
      "1__23.5e+12", "Some(({exponent: 0, mantissa: 1, negative: false, many_digits: false}, 1))",
    ),
    (
      "123_.5e+12", "Some(({exponent: 0, mantissa: 123, negative: false, many_digits: false}, 3))",
    ),
    (
      "123._5e+12", "Some(({exponent: 0, mantissa: 123, negative: false, many_digits: false}, 4))",
    ),
    (
      "123.5_e+12", "Some(({exponent: -1, mantissa: 1235, negative: false, many_digits: false}, 5))",
    ),
    (
      "123.5__0e+12", "Some(({exponent: -1, mantissa: 1235, negative: false, many_digits: false}, 5))",
    ),
    (
      "123.5e_+12", "Some(({exponent: -1, mantissa: 1235, negative: false, many_digits: false}, 5))",
    ),
    (
      "123.5e+_12", "Some(({exponent: -1, mantissa: 1235, negative: false, many_digits: false}, 5))",
    ),
    (
      "123.5e_-12", "Some(({exponent: -1, mantissa: 1235, negative: false, many_digits: false}, 5))",
    ),
    (
      "123.5e-_12", "Some(({exponent: -1, mantissa: 1235, negative: false, many_digits: false}, 5))",
    ),
    (
      "123.5e+1__2", "Some(({exponent: 0, mantissa: 1235, negative: false, many_digits: false}, 8))",
    ),
    (
      "123.5e+12_", "Some(({exponent: 11, mantissa: 1235, negative: false, many_digits: false}, 9))",
    ),
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    let s = parse_number(t.0)
    @assertion.assert_true(s.to_string() == t.1)?
  }
}