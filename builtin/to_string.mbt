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
