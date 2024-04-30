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

fn check_len(a : BigInt) -> Result[Unit, String] {
  @assertion.assert_ne(a.limbs[a.len - 1], 0)?
  for i = a.len; i < a.limbs.length(); i = i + 1 {
    @assertion.assert_eq(a.limbs[i], 0)?
  } else {
    Ok(())
  }
}

test "add" {
  let a = from_int64(123456789012345678L)
  let b = from_int64(987654321098765432L)
  let c = a + b
  inspect(c.to_decimal_string(), content="1111111110111111110")?
  check_len(c)?
  let a = from_decimal_string("123456789012345678123456789012345678")
  let b = from_decimal_string("987654321098765432987654321098765432")
  let c = a + b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="1111111110111111111111111110111111110",
  )?
}

test "sub" {
  let a = from_int64(987654321098765432L)
  let b = from_int64(123456789012345678L)
  let c = a - b
  check_len(c)?
  inspect(c.to_decimal_string(), content="864197532086419754")?
  let c = b - a
  check_len(c)?
  inspect(c.to_decimal_string(), content="-864197532086419754")?
  let a = from_decimal_string("987654321098765432987654321098765432")
  let b = from_decimal_string("123456789012345678123456789012345678")
  let c = a - b
  check_len(c)?
  inspect(c.to_decimal_string(), content="864197532086419754864197532086419754")?
  let c = b - a
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="-864197532086419754864197532086419754",
  )?
}

test "mul" {
  let a = from_int64(987654321098765432L)
  let b = from_int64(123456789012345678L)
  let c = a * b
  check_len(c)?
  inspect(c.to_decimal_string(), content="121932631137021794322511812221002896")?
  let a = from_decimal_string("987654321098765432987654321098765432")
  let b = from_decimal_string("123456789012345678123456789012345678")
  let c = a * b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="121932631137021794566377074495046484766956255579027586322511812221002896",
  )?
}

test "div" {
  let a = from_int64(987654321098765432L)
  let b = from_int64(123456789012345678L)
  let c = a / b
  check_len(c)?
  inspect(c.to_decimal_string(), content="8")?
  let c = a % b
  check_len(c)?
  inspect(c.to_decimal_string(), content="9000000008")?
  let a = from_decimal_string("987654321098765432987654321098765432")
  let b = from_decimal_string("123456789012345678123456789012345678")
  let c = a / b
  // check_len(c)?
  inspect(c.to_decimal_string(), content="8")?
  let c = a % b
  // check_len(c)?
  inspect(c.to_decimal_string(), content="9000000008000000009000000008")?
}

test "grade_school_div" {
  let a = from_int64(1234567890123456789L)
  let b = from_int64(123456789L)
  let (quotient, remainder) = grade_school_div(a, b)
  inspect(quotient.to_decimal_string(), content="10000000001")?
  inspect(remainder.to_decimal_string(), content="0")?
  let a = from_int64(9223372036854775807L)
  let b = from_int64(123456789L)
  let (quotient, remainder) = grade_school_div(a, b)
  inspect(quotient.to_decimal_string(), content="74709314178")?
  inspect(remainder.to_decimal_string(), content="46721365")?
  let a = from_int64(9223372036854775807L)
  let b = from_int64(2333333333L)
  let (quotient, remainder) = grade_school_div(a, b)
  inspect(quotient.to_decimal_string(), content="3952873730")?
  inspect(remainder.to_decimal_string(), content="1505733717")?

  // single digit divisor

  let a = from_int64(1234567890123456789L)
  let b = from_int64(123L)
  let (quotient, remainder) = grade_school_div(a, b)
  inspect(quotient.to_decimal_string(), content="10037137318076884")?
  inspect(remainder.to_decimal_string(), content="57")?
}

test "lsl" {
  let a = from_int64(1234567890123456789L)
  let b = a.lsl(1)
  inspect(b.to_decimal_string(), content="2469135780246913578")?
  let c = a.lsl(64)
  inspect(
    c.to_decimal_string(),
    content="22773757910726981402256170801141121024",
  )?
}

test "lsr" {
  let a = from_int64(1234567890123456789L)
  let b = a.lsr(1)
  inspect(b.to_decimal_string(), content="617283945061728394")?
  let c = a.lsr(64)
  inspect(c.to_decimal_string(), content="0")?
}

test "from_decimal_string" {
  let a = from_decimal_string("123")
  inspect(a.to_decimal_string(), content="123")?
  @assertion.assert_eq(a, from_int64(123L))?
  let a = from_decimal_string("1234567890123456789")
  inspect(a.to_decimal_string(), content="1234567890123456789")?
  let b = from_decimal_string("-1234567890")
  inspect(b.to_decimal_string(), content="-1234567890")?
  @assertion.assert_eq(a, from_int64(1234567890123456789L))?
}

test "to_decimal_string" {
  let a = from_int64(1234567890123456789L)
  inspect(a.to_decimal_string(), content="1234567890123456789")?
  let b = from_int64(-1234567890L)
  inspect(b.to_decimal_string(), content="-1234567890")?
}
