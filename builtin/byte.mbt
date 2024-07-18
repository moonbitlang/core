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

pub fn debug_write(self : Byte, buf : Buffer) -> Unit {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  buf.write_string("b'\\x")
  buf.write_string(hi)
  buf.write_string(lo)
  buf.write_string("'")
}

pub fn hash(self : Byte) -> Int {
  self.to_int()
}

pub fn hash_combine(self : Byte, hasher : Hasher) -> Unit {
  hasher.combine_byte(self)
}

test "panic alphabet function coverage" {
  // Test cases to cover all branches in the alphabet function
  eq(alphabet(0), "0")!
  eq(alphabet(1), "1")!
  eq(alphabet(2), "2")!
  eq(alphabet(3), "3")!
  eq(alphabet(4), "4")!
  eq(alphabet(5), "5")!
  eq(alphabet(6), "6")!
  eq(alphabet(7), "7")!
  eq(alphabet(8), "8")!
  eq(alphabet(9), "9")!
  eq(alphabet(10), "A")!
  eq(alphabet(11), "B")!
  eq(alphabet(12), "C")!
  eq(alphabet(13), "D")!
  eq(alphabet(14), "E")!
  eq(alphabet(15), "F")!
  // Test for the panic case
  alphabet(16) |> ignore
}

fn debug_string[T : Debug](t : T) -> String {
  let buf = Buffer::new(size_hint=50)
  t.debug_write(buf)
  buf.to_string()
}

fn eq[T : Debug + Eq](a : T, b : T, ~loc : SourceLoc = _) -> Unit!String {
  if a != b {
    let a = debug_string(a)
    let b = debug_string(b)
    raise "FAILED: \(loc) `\(a) == \(b)`"
  }
}
