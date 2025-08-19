// Copyright 2025 International Digital Economy Academy
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
test "from_int creates correct decimal" {
  let d = from_int(42)
  assert_eq(d.to_string(), "42")
}

///|
test "to_string with scale 0" {
  let d = from_parts(@bigint.BigInt::from_int(12345), 0)
  assert_eq(d.to_string(), "12345")
}

///|
test "to_string with scale less than length" {
  let d = from_parts(@bigint.BigInt::from_int(12345), 2)
  assert_eq(d.to_string(), "123.45")
}

///|
test "to_string with scale greater than length" {
  let d = from_parts(@bigint.BigInt::from_int(5), 3)
  assert_eq(d.to_string(), "0.005")
}

///|
test "negative decimal string" {
  let d = from_parts(@bigint.BigInt::from_int(-123), 1)
  assert_eq(d.to_string(), "-12.3")
}

///|
test "add with same scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(123), 1)
  let d2 = from_parts(@bigint.BigInt::from_int(456), 1)
  let result = add(d1, d2)
  assert_eq(result.to_string(), "57.9")
}

///|
test "sub with same scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(123), 1)
  let d2 = from_parts(@bigint.BigInt::from_int(456), 1)
  let result = sub(d1, d2)
  assert_eq(result.to_string(), "-33.3")
}

///|
test "add with different scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(1234), 2)
  let d2 = from_parts(@bigint.BigInt::from_int(56), 1)
  let result = add(d1, d2)
  assert_eq(result.to_string(), "17.94")
}

///|
test "sub with different scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(1234), 2)
  let d2 = from_parts(@bigint.BigInt::from_int(56), 1)
  let result = sub(d1, d2)
  assert_eq(result.to_string(), "6.74")
}

///|
test "mul with same scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(123), 1)
  let d2 = from_parts(@bigint.BigInt::from_int(456), 1)
  let result = mul(d1, d2)
  assert_eq(result.to_string(), "560.88")
}

///|
test "mul with different scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(1234), 2)
  let d2 = from_parts(@bigint.BigInt::from_int(56), 1)
  let result = mul(d1, d2)
  assert_eq(result.to_string(), "69.104")
}

///|
test "div with same scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(123), 1) // 12.3
  let d2 = from_parts(@bigint.BigInt::from_int(41), 1) // 4.1
  let result = div(d1, d2) // 12.3 / 4.1 ≈ 3.0
  assert_eq(result.to_string(), "3.0000000000000000000000000000")
}

///|
test "div with different scale" {
  let d1 = from_parts(@bigint.BigInt::from_int(1234), 2) // 12.34
  let d2 = from_parts(@bigint.BigInt::from_int(56), 1) // 5.6
  let result = div(d1, d2) // 12.34 / 5.6 ≈ 2.203571428571429...
  assert_eq(result.to_string().substring(end=7), "2.20357")
}

///|
test "div resulting in less than 1" {
  let d1 = from_parts(@bigint.BigInt::from_int(5), 1) // 0.5
  let d2 = from_parts(@bigint.BigInt::from_int(20), 1) // 2.0
  let result = div(d1, d2) // 0.5 / 2.0 = 0.25
  assert_eq(result.to_string(), "0.2500000000000000000000000000")
}

///|
test "div with integer result" {
  let d1 = from_parts(@bigint.BigInt::from_int(1000), 2) // 10.00
  let d2 = from_parts(@bigint.BigInt::from_int(2), 0) // 2
  let result = div(d1, d2) // 10 / 2 = 5
  assert_eq(result.to_string(), "5.000000000000000000000000000000")
}

///|
test "panic_test" {
  let d1 = from_parts(@bigint.BigInt::from_int(5), 3)
  let d2 = from_int(0)
  let _ = div(d1, d2)
}
