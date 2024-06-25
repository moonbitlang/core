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

test "from_double overflow" {
  let result = Rational::from_double(10.0e200)
  @assertion.assert_eq(result, Err("Rational::from_double: overflow"))?
}

test "from_double NaN" {
  let result = Rational::from_double(Double::nan())
  @assertion.assert_eq(result, Err("Rational::from_double: cannot convert NaN"))?
}

test "from_double normal case" {
  let result = Rational::from_double(0.5)
  @assertion.assert_eq(result, Ok(Rational::new_unchecked(1L, 2L)))?
}

test "from_double edge case" {
  let result = Rational::from_double(9_223_372_036_800_000_000.0)
  @assertion.assert_eq(
    result,
    Ok(Rational::new_unchecked(9_223_372_036_800_000_000L, 1L)),
  )?
}

test "from_double overflow edge case" {
  let result = Rational::from_double(9_223_372_036_854_775_807.1)
  @assertion.assert_eq(result, Err("Rational::from_double: overflow"))?
}

test "from_double overflow edge case" {
  let result = Rational::from_double(9_223_372_036_854_775_807.1)
  @assertion.assert_eq(result, Err("Rational::from_double: overflow"))?
}

test "from_double overflow check in continued fraction algorithm" {
  let result = Rational::from_double(10.0e200)
  @assertion.assert_eq(result, Err("Rational::from_double: overflow"))?
}

test "from_double NaN check" {
  let result = Rational::from_double(Double::nan())
  @assertion.assert_eq(result, Err("Rational::from_double: cannot convert NaN"))?
}

test "from_double normal case" {
  let result = Rational::from_double(0.5)
  @assertion.assert_eq(result, Ok(Rational::new_unchecked(1L, 2L)))?
}

test "from_double edge case" {
  let result = Rational::from_double(9_223_372_036_800_000_000.0)
  @assertion.assert_eq(
    result,
    Ok(Rational::new_unchecked(9_223_372_036_800_000_000L, 1L)),
  )?
}
