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
test "parse_inf_nan basic cases" {
  // Test basic NaN parsing
  let result_nan = parse_inf_nan("nan")
  match result_nan {
    Some((value, length)) => {
      inspect(value.is_nan(), content="true")
      inspect(length, content="3")
    }
    None => fail("Expected to parse 'nan'")
  }

  // Test basic infinity parsing
  let result_inf = parse_inf_nan("inf")
  match result_inf {
    Some((value, length)) => {
      inspect(value.is_inf() && value > 0.0, content="true")
      inspect(length, content="3")
    }
    None => fail("Expected to parse 'inf'")
  }
}

///|
test "parse_inf_nan with signs" {
  // Test positive signed NaN
  let result_pos_nan = parse_inf_nan("+nan")
  match result_pos_nan {
    Some((value, length)) => {
      inspect(value.is_nan(), content="true")
      inspect(length, content="4")
    }
    None => fail("Expected to parse '+nan'")
  }

  // Test negative signed infinity
  let result_neg_inf = parse_inf_nan("-inf")
  match result_neg_inf {
    Some((value, length)) => {
      inspect(value.is_inf() && value < 0.0, content="true")
      inspect(length, content="4")
    }
    None => fail("Expected to parse '-inf'")
  }
}

///|
test "parse_inf_nan case insensitive" {
  // Test uppercase
  let result_uppercase = parse_inf_nan("NAN")
  match result_uppercase {
    Some((value, length)) => {
      inspect(value.is_nan(), content="true")
      inspect(length, content="3")
    }
    None => fail("Expected to parse 'NAN'")
  }

  // Test mixed case
  let result_mixed = parse_inf_nan("InF")
  match result_mixed {
    Some((value, length)) => {
      inspect(value.is_inf() && value > 0.0, content="true")
      inspect(length, content="3")
    }
    None => fail("Expected to parse 'InF'")
  }
}

///|
test "parse_inf_nan with infinity suffix" {
  // Test full infinity word
  let result_infinity = parse_inf_nan("infinity")
  match result_infinity {
    Some((value, length)) => {
      inspect(value.is_inf() && value > 0.0, content="true")
      inspect(length, content="8")
    }
    None => fail("Expected to parse 'infinity'")
  }

  // Test signed full infinity
  let result_neg_infinity = parse_inf_nan("-INFINITY")
  match result_neg_infinity {
    Some((value, length)) => {
      inspect(value.is_inf() && value < 0.0, content="true")
      inspect(length, content="9")
    }
    None => fail("Expected to parse '-INFINITY'")
  }
}

///|
test "parse_inf_nan with trailing strings" {
  // Test trailing characters after 'inf'
  let result_trailing = parse_inf_nan("infabc")
  match result_trailing {
    Some((value, length)) => {
      inspect(value.is_inf() && value > 0.0, content="true")
      inspect(length, content="3") // should only parse 'inf'
    }
    None => fail("Expected to parse 'inf' but got None")
  }

  // Test trailing characters after 'nan'
  let result_nan_trailing = parse_inf_nan("nanxyz")
  match result_nan_trailing {
    Some((value, length)) => {
      inspect(value.is_nan(), content="true")
      inspect(length, content="3") // should only parse 'nan'
    }
    None => fail("Expected to parse 'nan' but got None")
  }

  // Test trailing characters after signed infinity
  let result_signed_trailing = parse_inf_nan("+infinity123")
  match result_signed_trailing {
    Some((value, length)) => {
      inspect(value.is_inf() && value > 0.0, content="true")
      inspect(length, content="9") // should only parse '+infinity'
    }
    None => fail("Expected to parse '+infinity' but got None")
  }
}

///|
test "parse_inf_nan failures" {
  // Test invalid input
  inspect(parse_inf_nan("hello"), content="None")
  inspect(parse_inf_nan(""), content="None")
  inspect(parse_inf_nan("in"), content="None")
  inspect(parse_inf_nan("na"), content="None")
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
