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
pub fn Bool::to_string(self : Bool) -> String {
  if self {
    "true"
  } else {
    "false"
  }
}

///|
pub fn Int64::to_string(self : Int64) -> String {
  fn abs(n : Int64) -> Int64 {
    if n < 0L {
      0L - n
    } else {
      n
    }
  }

  // The min and max value of i64 are -9223372036854775808 and 9223372036854775807,
  // so max=20 is enough.

  let buf = StringBuilder::new(size_hint=20)
  if self < 0L {
    buf.write_char('-')
  }
  fn write_digits(num) {
    let num2 = num / 10L
    if num2 != 0L {
      write_digits(num2)
    }
    buf.write_char(Char::from_int(abs(num % 10L).to_int() + 48))
  }

  write_digits(self)
  buf.to_string()
}

///|
pub fn Int::to_string(self : Int) -> String {
  fn abs(n : Int) -> Int {
    if n < 0 {
      0 - n
    } else {
      n
    }
  }

  // The min and max value of i32 are -2147483648 and 2147483647,
  // so max=11 is enough.

  let buf = StringBuilder::new()
  if self < 0 {
    buf.write_char('-')
  }
  fn write_digits(num) {
    let num2 = num / 10
    if num2 != 0 {
      write_digits(num2)
    }
    buf.write_char(Char::from_int(abs(num % 10) + 48))
  }

  write_digits(self)
  buf.to_string()
}

///|
pub fn UInt::to_string(self : UInt) -> String {
  let buf = StringBuilder::new()
  fn write_digits(num) {
    let num2 = num / 10U
    if num2 != 0U {
      write_digits(num2)
    }
    buf.write_char(Char::from_int((num % 10U).reinterpret_as_int() + 48))
  }

  write_digits(self)
  buf.to_string()
}

///|
test "UInt::to_string" {
  inspect!(0U, content="0")
  inspect!(17U, content="17")
  inspect!(4294967295U, content="4294967295")
}

///|
pub fn UInt64::to_string(self : UInt64) -> String {
  let buf = StringBuilder::new()
  fn write_digits(num : UInt64) {
    let num2 = num / 10UL
    if num2 != 0UL {
      write_digits(num2)
    }
    buf.write_char(
      Char::from_int((num % 10UL).reinterpret_as_int64().to_int() + 48),
    )
  }

  write_digits(self)
  buf.to_string()
}

///|
pub fn Int16::to_string(self : Int16) -> String {
  self.to_int().to_string()
}

///|
pub fn UInt16::to_string(self : UInt16) -> String {
  self.to_int().to_string()
}

///|
const ALPHABET : String = "0123456789abcdefghijklmnopqrstuvwxyz"

///|
pub fn Int64::to_string_by_radix(self : Int64, radix~ : Int = 10) -> String {
  guard radix <= 36 && radix >= 2 else {
    abort("radix must be between 2 and 36")
  }
  fn abs(n : Int64) -> Int64 {
    if n < 0L {
      0L - n
    } else {
      n
    }
  }

  // max length should be over 64 + 1, 80 is enough
  let buf = StringBuilder::new(size_hint=80)
  if self < 0L {
    buf.write_char('-')
  }
  let radix : Int64 = radix.to_int64()
  fn write_digits(num : Int64) {
    let num2 = num / radix
    if num2 != 0L {
      write_digits(num2)
    }
    buf.write_char(ALPHABET[abs(num % radix).to_int()])
  }

  write_digits(abs(self))
  buf.to_string()
}

///|
pub fn Int::to_string_by_radix(self : Int, radix~ : Int = 10) -> String {
  guard radix <= 36 && radix >= 2 else {
    abort("radix must be between 2 and 36")
  }
  fn abs(n : Int) -> Int {
    if n < 0 {
      0 - n
    } else {
      n
    }
  }

  // max length should be over 32 + 1, 40 is enough
  let buf = StringBuilder::new(size_hint=40)
  if self < 0 {
    buf.write_char('-')
  }
  fn write_digits(num : Int) {
    let num2 = num / radix
    if num2 != 0 {
      write_digits(num2)
    }
    buf.write_char(ALPHABET[abs(num % radix)])
  }

  write_digits(abs(self))
  buf.to_string()
}

///|
pub fn UInt::to_string_by_radix(self : UInt, radix~ : Int = 10) -> String {
  guard radix <= 36 && radix >= 2 else {
    abort("radix must be between 2 and 36")
  }

  // max length should be over 32, 40 is enough
  let buf = StringBuilder::new(size_hint=40)
  let radix : UInt = radix.reinterpret_as_uint()
  fn write_digits(num : UInt) {
    let num2 = num / radix
    if num2 != 0U {
      write_digits(num2)
    }
    buf.write_char(ALPHABET[(num % radix).reinterpret_as_int()])
  }

  write_digits(self)
  buf.to_string()
}

///|
pub fn UInt64::to_string_by_radix(self : UInt64, radix~ : Int = 10) -> String {
  guard radix <= 36 && radix >= 2 else {
    abort("radix must be between 2 and 36")
  }

  // max length should be over 64, 80 is enough
  let buf = StringBuilder::new(size_hint=80)
  let radix : UInt64 = radix.to_uint64()
  fn write_digits(num : UInt64) {
    let num2 = num / radix
    if num2 != 0UL {
      write_digits(num2)
    }
    buf.write_char(ALPHABET[(num % radix).to_int()])
  }

  write_digits(self)
  buf.to_string()
}

test "to_string_by_radix" {
  // Binary
  inspect!((0).to_string_by_radix(radix=2), content="0")
  inspect!((1).to_string_by_radix(radix=2), content="1")
  inspect!((2).to_string_by_radix(radix=2), content="10")
  inspect!((255).to_string_by_radix(radix=2), content="11111111")
  inspect!((-255).to_string_by_radix(radix=2), content="-11111111")

  // Octal
  inspect!((0).to_string_by_radix(radix=8), content="0")
  inspect!((8).to_string_by_radix(radix=8), content="10")
  inspect!((64).to_string_by_radix(radix=8), content="100")
  inspect!((-64).to_string_by_radix(radix=8), content="-100")

  // Decimal
  inspect!((0).to_string_by_radix(radix=10), content="0")
  inspect!((123).to_string_by_radix(radix=10), content="123")
  inspect!((-123).to_string_by_radix(radix=10), content="-123")
  inspect!(
    0x7fff_ffff_ffff_ffffL.to_string_by_radix(radix=10),
    content="9223372036854775807",
  )
  inspect!(
    0x8000_0000_0000_0000L.to_string_by_radix(radix=10),
    content="-9223372036854775808",
  )

  // Hexadecimal
  inspect!((0).to_string_by_radix(radix=16), content="0")
  inspect!((0x11).to_string_by_radix(radix=16), content="11")
  inspect!((0x15ef).to_string_by_radix(radix=16), content="15ef")
  inspect!((-0xabcd).to_string_by_radix(radix=16), content="-abcd")
  inspect!(
    (1.0 : Float).reinterpret_as_int().to_string_by_radix(radix=16),
    content="3f800000",
  )

  // UInt
  inspect!(0U.to_string_by_radix(radix=16), content="0")
  inspect!(0x1AU.to_string_by_radix(radix=16), content="1a")
  inspect!(0xabcdU.to_string_by_radix(radix=16), content="abcd")
  inspect!(
    (-2.0 : Float).reinterpret_as_uint().to_string_by_radix(radix=16),
    content="c0000000",
  )
  inspect!(
    (-1).reinterpret_as_uint().to_string_by_radix(radix=16),
    content="ffffffff",
  )

  // Int64
  inspect!(0L.to_string_by_radix(radix=16), content="0")
  inspect!(0x2fL.to_string_by_radix(radix=16), content="2f")
  inspect!(0xf0aeL.to_string_by_radix(radix=16), content="f0ae")
  inspect!((-0x1234eacbL).to_string_by_radix(radix=16), content="-1234eacb")
  inspect!(
    1.0.reinterpret_as_uint64().to_string_by_radix(radix=16),
    content="3ff0000000000000",
  )

  // UInt64
  inspect!(0UL.to_string_by_radix(radix=16), content="0")
  inspect!(0x11UL.to_string_by_radix(radix=16), content="11")
  inspect!(0x12bdUL.to_string_by_radix(radix=16), content="12bd")
  inspect!(
    (-1L).reinterpret_as_uint64().to_string_by_radix(radix=16),
    content="ffffffffffffffff",
  )
  inspect!(
    2.0.reinterpret_as_uint64().to_string_by_radix(radix=16),
    content="4000000000000000",
  )
}

test "panic to_string_by_radix/illegal_radix" {
  ignore((1).to_string_by_radix(radix=1))
  ignore((1).to_string_by_radix(radix=37))
  ignore(1L.to_string_by_radix(radix=0))
  ignore(1L.to_string_by_radix(radix=42))
  ignore(1U.to_string_by_radix(radix=-1))
  ignore(1U.to_string_by_radix(radix=73))
  ignore(1UL.to_string_by_radix(radix=-100))
  ignore(1UL.to_string_by_radix(radix=100))
}
