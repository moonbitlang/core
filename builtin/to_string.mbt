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
const ALPHABET : String = "0123456789abcdefghijklmnopqrstuvwxyz"

///|
pub fn Int64::to_string(self : Int64, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=Int64::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for Int64 with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn Int::to_string(self : Int, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=Int::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for Int with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn UInt::to_string(self : UInt, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=UInt::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for UInt with to_string(self) {
  self.to_string(radix=10)
}

///|
test "UInt::to_string" {
  inspect(0U, content="0")
  inspect(17U, content="17")
  inspect(4294967295U, content="4294967295")
}

///|
pub fn UInt64::to_string(self : UInt64, radix? : Int = 10) -> String {
  let buf = StringBuilder::new(size_hint=UInt64::output_size_hint(radix~))
  self.output(buf, radix~)
  buf.to_string()
}

///|
pub impl Show for UInt64 with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn Int16::to_string(self : Int16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}

///|
pub impl Show for Int16 with to_string(self) {
  self.to_string(radix=10)
}

///|
pub fn UInt16::to_string(self : UInt16, radix? : Int = 10) -> String {
  self.to_int().to_string(radix~)
}

///|
pub impl Show for UInt16 with to_string(self) {
  self.to_string(radix=10)
}

///|
test "to_string" {
  assert_eq((0x100).to_string(), "256")
  assert_eq("\{0x100}", "256")
  assert_eq(0x200U.to_string(), "512")
  assert_eq("\{0x200U}", "512")
  assert_eq(0x300L.to_string(), "768")
  assert_eq("\{0x300L}", "768")
  assert_eq(0x400UL.to_string(), "1024")
  assert_eq("\{0x400UL}", "1024")
}

///|
test "to_string with radix" {
  // Binary
  inspect((0).to_string(radix=2), content="0")
  inspect((1).to_string(radix=2), content="1")
  inspect((2).to_string(radix=2), content="10")
  inspect((255).to_string(radix=2), content="11111111")
  inspect((-255).to_string(radix=2), content="-11111111")

  // Octal
  inspect((0).to_string(radix=8), content="0")
  inspect((8).to_string(radix=8), content="10")
  inspect((64).to_string(radix=8), content="100")
  inspect((-64).to_string(radix=8), content="-100")

  // Decimal
  inspect((0).to_string(radix=10), content="0")
  inspect((123).to_string(radix=10), content="123")
  inspect((-123).to_string(radix=10), content="-123")
  inspect(
    0x7fff_ffff_ffff_ffffL.to_string(radix=10),
    content="9223372036854775807",
  )
  inspect(
    0x8000_0000_0000_0000L.to_string(radix=10),
    content="-9223372036854775808",
  )

  // Hexadecimal
  inspect((0).to_string(radix=16), content="0")
  inspect((0x11).to_string(radix=16), content="11")
  inspect((0x15ef).to_string(radix=16), content="15ef")
  inspect((-0xabcd).to_string(radix=16), content="-abcd")
  inspect(
    (1.0 : Float).reinterpret_as_int().to_string(radix=16),
    content="3f800000",
  )

  // UInt
  inspect(0U.to_string(radix=16), content="0")
  inspect(0x1AU.to_string(radix=16), content="1a")
  inspect(0xabcdU.to_string(radix=16), content="abcd")
  inspect(
    (-2.0 : Float).reinterpret_as_uint().to_string(radix=16),
    content="c0000000",
  )
  inspect((-1).reinterpret_as_uint().to_string(radix=16), content="ffffffff")

  // Int64
  inspect(0L.to_string(radix=16), content="0")
  inspect(0x2fL.to_string(radix=16), content="2f")
  inspect(0xf0aeL.to_string(radix=16), content="f0ae")
  inspect((-0x1234eacbL).to_string(radix=16), content="-1234eacb")
  inspect(
    1.0.reinterpret_as_uint64().to_string(radix=16),
    content="3ff0000000000000",
  )
  inspect(0b101L.to_string(radix=2), content="101")
  inspect(0o17L.to_string(radix=8), content="17")

  // UInt64
  inspect(0UL.to_string(radix=16), content="0")
  inspect(0x11UL.to_string(radix=16), content="11")
  inspect(0x12bdUL.to_string(radix=16), content="12bd")
  inspect(
    (-1L).reinterpret_as_uint64().to_string(radix=16),
    content="ffffffffffffffff",
  )
  inspect(
    2.0.reinterpret_as_uint64().to_string(radix=16),
    content="4000000000000000",
  )
}

///|
test "panic to_string_by_radix/illegal_radix" {
  ignore((1).to_string(radix=1))
  ignore((1).to_string(radix=37))
  ignore(1L.to_string(radix=0))
  ignore(1L.to_string(radix=42))
  ignore(1U.to_string(radix=-1))
  ignore(1U.to_string(radix=73))
  ignore(1UL.to_string(radix=-100))
  ignore(1UL.to_string(radix=100))
}
