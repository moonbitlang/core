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
test "parse_inf_nan basic cases" {
  inspect(parse_inf_nan("nan"), content="NaN")
  inspect(parse_inf_nan("inf"), content="Infinity")
}

///|
test "parse_inf_nan with signs" {
  inspect(parse_inf_nan("+nan"), content="NaN")
  inspect(parse_inf_nan("-inf"), content="-Infinity")
}

///|
test "parse_inf_nan case insensitive" {
  inspect(parse_inf_nan("NAN"), content="NaN")
  inspect(parse_inf_nan("InF"), content="Infinity")
}

///|
test "parse_inf_nan with infinity suffix" {
  inspect(parse_inf_nan("infinity"), content="Infinity")
  inspect(parse_inf_nan("-INFINITY"), content="-Infinity")
}

///|
test "parse_inf_nan with trailing strings" {
  inspect(try? parse_inf_nan("infabc"), content="Err(invalid syntax)")
  inspect(try? parse_inf_nan("nanxyz"), content="Err(invalid syntax)")
  inspect(try? parse_inf_nan("+infinity123"), content="Err(invalid syntax)")
}

///|
test "parse_inf_nan failures" {
  // Test invalid input
  inspect(try? parse_inf_nan("hello"), content="Err(invalid syntax)")
  inspect(try? parse_inf_nan(""), content="Err(invalid syntax)")
  inspect(try? parse_inf_nan("in"), content="Err(invalid syntax)")
  inspect(try? parse_inf_nan("na"), content="Err(invalid syntax)")
}

///|
test "checked_mul basic cases" {
  // Test zero multiplication
  inspect(checked_mul(0UL, 5UL), content="Some(0)")
  inspect(checked_mul(5UL, 0UL), content="Some(0)")

  // Test multiplication by one
  inspect(checked_mul(1UL, 42UL), content="Some(42)")
  inspect(checked_mul(42UL, 1UL), content="Some(42)")

  // Test normal multiplication
  inspect(checked_mul(3UL, 4UL), content="Some(12)")
  inspect(checked_mul(10UL, 10UL), content="Some(100)")
}

///|
test "checked_mul edge cases" {
  // Test potential overflow
  let large_val = 0xFFFFFFFFFFFFFFFFUL // max uint64
  inspect(checked_mul(large_val, 2UL), content="None")
  inspect(checked_mul(2UL, large_val), content="None")

  // Test small multiplication that should work
  inspect(checked_mul(2UL, 3UL), content="Some(6)")

  // Test corner case
  inspect(
    checked_mul(5UL, 3689348814741910323UL),
    content="Some(18446744073709551615)",
  )
  inspect(
    checked_mul(3689348814741910323UL, 5UL),
    content="Some(18446744073709551615)",
  )
  inspect(
    checked_mul(4UL, 4611686018427387903UL),
    content="Some(18446744073709551612)",
  )
  inspect(
    checked_mul(4611686018427387903UL, 4UL),
    content="Some(18446744073709551612)",
  )
  inspect(checked_mul(4611686018427387904UL, 4UL), content="None")
  inspect(checked_mul(4UL, 4611686018427387904UL), content="None")
}
