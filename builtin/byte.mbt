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

pub fn op_equal(self : Byte, that : Byte) -> Bool {
  return self.to_int() == that.to_int()
}

pub fn compare(self : Byte, that : Byte) -> Int {
  return self.to_int().compare(that.to_int())
}

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

pub fn to_string(self : Byte) -> String {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  "b'\\x\(hi)\(lo)'"
}

pub fn hash(self : Byte) -> Int {
  self.to_int()
}

pub fn hash_combine(self : Byte, hasher : Hasher) -> Unit {
  hasher.combine_byte(self)
}

test "panic alphabet function coverage" {
  // Test cases to cover all branches in the alphabet function
  inspect!(alphabet(0), content="0")
  inspect!(alphabet(1), content="1")
  inspect!(alphabet(2), content="2")
  inspect!(alphabet(3), content="3")
  inspect!(alphabet(4), content="4")
  inspect!(alphabet(5), content="5")
  inspect!(alphabet(6), content="6")
  inspect!(alphabet(7), content="7")
  inspect!(alphabet(8), content="8")
  inspect!(alphabet(9), content="9")
  inspect!(alphabet(10), content="A")
  inspect!(alphabet(11), content="B")
  inspect!(alphabet(12), content="C")
  inspect!(alphabet(13), content="D")
  inspect!(alphabet(14), content="E")
  inspect!(alphabet(15), content="F")
  // Test for the panic case
  alphabet(16) |> ignore
}

pub fn Byte::default() -> Byte {
  b'\x00'
}

pub fn Byte::lnot(self : Byte) -> Byte {
  self.to_int().lnot().to_byte()
}

pub fn Byte::land(self : Byte, that : Byte) -> Byte {
  self.to_int().land(that.to_int()).to_byte()
}

pub fn Byte::lor(self : Byte, that : Byte) -> Byte {
  self.to_int().lor(that.to_int()).to_byte()
}

pub fn Byte::lxor(self : Byte, that : Byte) -> Byte {
  self.to_int().lxor(that.to_int()).to_byte()
}

pub fn Byte::lsl(self : Byte, count : Int) -> Byte {
  self.to_int().lsl(count).to_byte()
}

pub fn Byte::lsr(self : Byte, count : Int) -> Byte {
  self.to_int().lsr(count).to_byte()
}
