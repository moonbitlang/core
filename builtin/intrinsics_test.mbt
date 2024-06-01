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

// fn debug_string[T : Debug](t : T) -> String {
//   let buf = Buffer::make(50)
//   t.debug_write(buf)
//   buf.to_string()
// }
// fn assert_eq[T : Debug + Eq](
//   a : T,
//   b : T,
//   ~loc : SourceLoc = _
// ) -> Result[Unit, String] {
//   if a == b {
//     Ok(())
//   } else {
//     let a = debug_string(a)
//     let b = debug_string(b)
//     Err("FAILED:\(loc) `\(a) == \(b)`")
//   }
// }

/// test Int::land
test "Int::land should perform bitwise AND operation" {
  let a = 0b101
  let b = 0b011
  inspect(a.land(b), content="1")?
  inspect((0xffff_ffff).land(0xa000_0000) == 0xa000_0000, content="true")?
  inspect((0xffff_ffff).land(0x0) == 0, content="true")?
  inspect((0xffff_ffff).land(0xffff_ffff) == 0xffff_ffff, content="true")?
}

/// test Int::lor
test "Int::lor should perform bitwise OR operation" {
  inspect((0b101).lor(0b011) == 0b111, content="true")?
  inspect((0xffff_ffff).lor(0xa000_0000) == 0xffff_ffff, content="true")?
  inspect((0xffff_ffff).lor(0x0) == 0xffff_ffff, content="true")?
  inspect((0xffff_ffff).lor(0xffff_ffff) == 0xffff_ffff, content="true")?
}

/// test Int::lxor
test "Int::lxor should perform bitwise XOR operation" {
  inspect((0b101).lxor(0b011) == 0b110, content="true")?
  inspect((0xffff_ffff).lxor(0xa000_0000) == 0x5fff_ffff, content="true")?
  inspect((0xffff_ffff).lxor(0x0) == 0xffff_ffff, content="true")?
  inspect((0xffff_ffff).lxor(0xffff_ffff) == 0, content="true")?
}

/// test Int::lsl
test "Int::lsl should perform left shift operation" {
  inspect((7).lsl(1), content="14")?
  inspect((0b101).lsl(1) == 0b1010, content="true")?
  inspect((0xffff_ffff).lsl(1) == 0xffff_fffe, content="true")?
  inspect((0xffff_ffff).lsl(0) == 0xffff_ffff, content="true")?
  inspect((0xffff_ffff).lsl(3), content="-8")?
  let arr = Array::make(33, 0).mapi(fn { i, _ => i })
  inspect(
    arr,
    content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]",
  )?
  let r = arr.map(fn { i => (0xffff_ffff).lsl(i) })
  // note when shifting 32 bits or more, it returns the original value
  inspect(
    r,
    content="[-1, -2, -4, -8, -16, -32, -64, -128, -256, -512, -1024, -2048, -4096, -8192, -16384, -32768, -65536, -131072, -262144, -524288, -1048576, -2097152, -4194304, -8388608, -16777216, -33554432, -67108864, -134217728, -268435456, -536870912, -1073741824, -2147483648, -1]",
  )?
  inspect((7).lsl(32), content="7")?
}
