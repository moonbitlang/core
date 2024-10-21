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

///-----------------------------------------------------------------------------
pub fn op_equal(self : Byte, that : Byte) -> Bool {
  self.to_int() == that.to_int()
}

///-----------------------------------------------------------------------------
pub fn op_add(self : Byte, that : Byte) -> Byte {
  (self.to_int() + that.to_int()).to_byte()
}

///-----------------------------------------------------------------------------
pub fn op_sub(self : Byte, that : Byte) -> Byte {
  (self.to_int() - that.to_int()).to_byte()
}

///-----------------------------------------------------------------------------
pub fn compare(self : Byte, that : Byte) -> Int {
  self.to_int().compare(that.to_int())
}

///-----------------------------------------------------------------------------
fn alphabet(self : Int) -> String {
  match self {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "A"
    11 => "B"
    12 => "C"
    13 => "D"
    14 => "E"
    15 => "F"
    _ => abort("impossible")
  }
}

///-----------------------------------------------------------------------------
pub fn to_string(self : Byte) -> String {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  "b'\\x\{hi}\{lo}'"
}

///-----------------------------------------------------------------------------
pub impl Hash for Byte with hash(self) { self.to_int() }

///-----------------------------------------------------------------------------
pub impl Hash for Byte with hash_combine(self, hasher) {
  hasher.combine_byte(self)
}

///-----------------------------------------------------------------------------
pub fn Byte::default() -> Byte {
  b'\x00'
}

///-----------------------------------------------------------------------------
pub fn Byte::lnot(self : Byte) -> Byte {
  self.to_int().lnot().to_byte()
}

///-----------------------------------------------------------------------------
pub fn Byte::land(self : Byte, that : Byte) -> Byte {
  (self.to_int() & that.to_int()).to_byte()
}

///-----------------------------------------------------------------------------
pub fn Byte::lor(self : Byte, that : Byte) -> Byte {
  (self.to_int() | that.to_int()).to_byte()
}

///-----------------------------------------------------------------------------
pub fn Byte::lxor(self : Byte, that : Byte) -> Byte {
  (self.to_int() ^ that.to_int()).to_byte()
}

///-----------------------------------------------------------------------------
pub fn Byte::to_uint(self : Byte) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///-----------------------------------------------------------------------------
pub fn Byte::op_shl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///-----------------------------------------------------------------------------
pub fn Byte::op_shr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `<<` instead"
pub fn Byte::lsl(self : Byte, count : Int) -> Byte {
  (self.to_int() << count).to_byte()
}

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `>>` instead"
pub fn Byte::lsr(self : Byte, count : Int) -> Byte {
  (self.to_uint() >> count).reinterpret_as_int().to_byte()
}
