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
pub let max_value : Int16 = 32767

///|
pub let min_value : Int16 = -32768

///|
pub impl Add for Int16 with add(self : Int16, that : Int16) -> Int16 {
  (self.to_int() + that.to_int()).to_int16()
}

///|
pub impl Sub for Int16 with sub(self : Int16, that : Int16) -> Int16 {
  (self.to_int() - that.to_int()).to_int16()
}

///|
pub impl Mul for Int16 with mul(self : Int16, that : Int16) -> Int16 {
  (self.to_int() * that.to_int()).to_int16()
}

///|
pub impl Div for Int16 with div(self : Int16, that : Int16) -> Int16 {
  (self.to_int() / that.to_int()).to_int16()
}

///|
pub impl Mod for Int16 with mod(self : Int16, that : Int16) -> Int16 {
  (self.to_int() % that.to_int()).to_int16()
}

///|
pub impl Eq for Int16 with equal(self, that) {
  self.to_int() == that.to_int()
}

///|
pub impl Compare for Int16 with compare(self, that) {
  self.to_int().compare(that.to_int())
}

///|
pub impl Hash for Int16 with hash(self) {
  self.to_int()
}

///|
pub impl Hash for Int16 with hash_combine(self, hasher) {
  hasher.combine_int(self.to_int())
}

///|
pub impl Shl for Int16 with shl(self : Int16, that : Int) -> Int16 {
  (self.to_int() << that).to_int16()
}

///|
pub impl Shr for Int16 with shr(self : Int16, that : Int) -> Int16 {
  (self.to_int() >> that).to_int16()
}

///|
pub impl BitOr for Int16 with lor(self : Int16, that : Int16) -> Int16 {
  (self.to_int() | that.to_int()).to_int16()
}

///|
pub impl BitAnd for Int16 with land(self : Int16, that : Int16) -> Int16 {
  (self.to_int() & that.to_int()).to_int16()
}

///|
pub impl BitXOr for Int16 with lxor(self : Int16, that : Int16) -> Int16 {
  (self.to_int() ^ that.to_int()).to_int16()
}

///|
pub impl Neg for Int16 with neg(self : Int16) -> Int16 {
  (-self.to_int()).to_int16()
}

///|
pub fn Int16::abs(self : Int16) -> Int16 {
  if self < 0 {
    -self
  } else {
    self
  }
}

///|
pub impl Default for Int16 with default() {
  0
}

///|
pub impl ToJson for Int16 with to_json(self : Int16) -> Json {
  Json::number(self.to_int().to_double())
}

///|
/// reinterpret as an unsigned integer with binary complement
pub fn Int16::reinterpret_as_uint16(self : Int16) -> UInt16 {
  self.to_int().to_uint16()
}
