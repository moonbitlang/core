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
struct Num {
  value : Int32
}

///|
fn num(value : Int32) -> Num {
  { value, }
}

///|
impl Add for Num with fn add(self, other) {
  num(self.value + other.value)
}

///|
impl Sub for Num with fn sub(self, other) {
  num(self.value - other.value)
}

///|
impl Mul for Num with fn mul(self, other) {
  num(self.value * other.value)
}

///|
impl Div for Num with fn div(self, other) {
  num(self.value / other.value)
}

///|
impl Mod for Num with fn mod(self, other) {
  num(self.value % other.value)
}

///|
impl Neg for Num with fn neg(self) {
  num(-self.value)
}

///|
impl Shl for Num with fn shl(self, i) {
  num(self.value << i)
}

///|
impl Shr for Num with fn shr(self, i) {
  num(self.value >> i)
}

///|
test "operator trait methods on builtin types" {
  inspect(Add::add(1, 2), content="3")
  inspect(Sub::sub(5, 3), content="2")
  inspect(Mul::mul(2, 3), content="6")
  inspect(Div::div(8, 2), content="4")
  inspect(Mod::mod(7, 4), content="3")
  inspect(Neg::neg(5), content="-5")
  inspect(Shl::shl(1, 3), content="8")
  inspect(Shr::shr(8, 2), content="2")
}

///|
test "integer shift methods" {
  inspect((1 : Int32).shl(3), content="8")
  inspect((-8 : Int32).shr(2), content="-2")
  inspect((1 : Int64).shl(40), content="1099511627776")
  inspect((-8 : Int64).shr(2), content="-2")
  inspect((1 : UInt32).shl(31), content="2147483648")
  inspect((0x80000000 : UInt32).shr(31), content="1")
  inspect((1 : UInt64).shl(63), content="9223372036854775808")
  inspect((0x8000000000000000 : UInt64).shr(63), content="1")
}

///|
test "integer shift methods as function values" {
  let shl32 = Int32::shl
  let shr32 = Int32::shr
  let shl64 = Int64::shl
  let shr64 = Int64::shr
  let ushl32 = UInt32::shl
  let ushr32 = UInt32::shr
  let ushl64 = UInt64::shl
  let ushr64 = UInt64::shr
  inspect(shl32(1, 3), content="8")
  inspect(shr32(-8, 2), content="-2")
  inspect(shl64(1, 40), content="1099511627776")
  inspect(shr64(-8, 2), content="-2")
  inspect(ushl32(1, 31), content="2147483648")
  inspect(ushr32(0x80000000, 31), content="1")
  inspect(ushl64(1, 63), content="9223372036854775808")
  inspect(ushr64(0x8000000000000000, 63), content="1")
}

///|
test "operator trait methods on custom types" {
  inspect(Add::add(num(8), num(3)).value, content="11")
  inspect(Sub::sub(num(8), num(3)).value, content="5")
  inspect(Mul::mul(num(4), num(3)).value, content="12")
  inspect(Div::div(num(9), num(3)).value, content="3")
  inspect(Mod::mod(num(10), num(3)).value, content="1")
  inspect(Neg::neg(num(4)).value, content="-4")
  inspect(Shl::shl(num(1), 4).value, content="16")
  inspect(Shr::shr(num(16), 2).value, content="4")
}
