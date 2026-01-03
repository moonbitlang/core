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
  value : Int
}

///|
fn num(value : Int) -> Num {
  Num::{ value, }
}

///|
impl Add for Num with add(self, other) {
  num(self.value + other.value)
}

///|
impl Sub for Num with sub(self, other) {
  num(self.value - other.value)
}

///|
impl Mul for Num with mul(self, other) {
  num(self.value * other.value)
}

///|
impl Div for Num with div(self, other) {
  num(self.value / other.value)
}

///|
impl Mod for Num with mod(self, other) {
  num(self.value % other.value)
}

///|
impl Neg for Num with neg(self) {
  num(-self.value)
}

///|
impl Shl for Num with shl(self, i) {
  num(self.value << i)
}

///|
impl Shr for Num with shr(self, i) {
  num(self.value >> i)
}

///|
test "deprecated operator helpers" {
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
#warnings("-deprecated")
test "deprecated operator defaults" {
  inspect(Add::op_add(num(8), num(3)).value, content="11")
  inspect(Sub::op_sub(num(8), num(3)).value, content="5")
  inspect(Mul::op_mul(num(4), num(3)).value, content="12")
  inspect(Div::op_div(num(9), num(3)).value, content="3")
  inspect(Mod::op_mod(num(10), num(3)).value, content="1")
  inspect(Neg::op_neg(num(4)).value, content="-4")
  inspect(Shl::op_shl(num(1), 4).value, content="16")
  inspect(Shr::op_shr(num(16), 2).value, content="4")
}
