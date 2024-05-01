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

test "neg" {
  let a = from_int64(123456789012345678L)
  let b = -a
  inspect(b.to_decimal_string(), content="-123456789012345678")?
  check_len(b)?
  let a = from_decimal_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = -a
  inspect(
    b.to_decimal_string(),
    content="-123456789012345678123456789012345678123456789012345678123456789012345678",
  )?
  check_len(b)?
  let a = from_decimal_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = -a
  inspect(
    b.to_decimal_string(),
    content="123456789012345678123456789012345678123456789012345678123456789012345678",
  )?
  check_len(b)?
}

test "add" {
  let a = from_int64(123456789012345678L)
  let b = from_int64(987654321098765432L)
  let c = a + b
  inspect(c.to_decimal_string(), content="1111111110111111110")?
  check_len(c)?
  let a = from_decimal_string("123456789012345678123456789012345678")
  let b = from_decimal_string("9876543210987654329876543210987654321241243")
  let c = a + b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="9876543334444443342222221334444443333586921",
  )?
  let a = from_decimal_string(
    "-345678987654356798765467898765456789098764567890987655678",
  )
  let b = from_decimal_string("76678908909876567890987656789098789")
  let c = a + b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="-345678987654356798765391219856546912530873580234198556889",
  )?
  let a = from_decimal_string(
    "-123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_decimal_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a + b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="-123456794480236665780245887778024588000245887779444446014444446903333367",
  )?
  let a = from_decimal_string(
    "123456789012345678123456789012345678123456789012345678123456789012345678",
  )
  let b = from_decimal_string(
    "-5467890987656789098765678909876789098767098767890987657890987689",
  )
  let c = a + b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="123456783544454690466667690246666768246667690245246910232469131121357989",
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
  let a = from_decimal_string("-123456789012345678123456789012345678")
  let b = from_decimal_string("-987654321098765432987654321098765432")
  let c = a - b
  check_len(c)?
  inspect(c.to_decimal_string(), content="864197532086419754864197532086419754")?
  let c = b - a
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="-864197532086419754864197532086419754",
  )?
  let a = from_decimal_string("123456789012345678123456789012345678233")
  let b = from_decimal_string("-987654321098765432987654321098765432")
  let c = a - b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="124444443333444443556444443333444443665",
  )?
  let a = from_decimal_string("-123456789012345678123456789012345678233")
  let b = from_decimal_string("987654321098765432987654321098765432")
  let c = a - b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="-124444443333444443556444443333444443665",
  )?
  let a = from_decimal_string("123456789012345678123456789012345678233")
  let b = from_decimal_string("987")
  let c = a - b
  check_len(c)?
  inspect(
    c.to_decimal_string(),
    content="123456789012345678123456789012345677246",
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
  check_len(c)?
  inspect(c.to_decimal_string(), content="8")?
  let c = a % b
  check_len(c)?
  inspect(c.to_decimal_string(), content="9000000008000000009000000008")?
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

test "from_int" {
  let a = from_int(1234567899)
  inspect(a.to_decimal_string(), content="1234567899")?
  let b = from_int(-1234567890)
  inspect(b.to_decimal_string(), content="-1234567890")?
}
