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

test "UInt to byte" {
  let a = 10U.to_byte()
  inspect!(a, content="b'\\x0A'")
  let b = 255U.to_byte()
  inspect!(b, content="b'\\xFF'")
  let c = 10UL.to_byte()
  inspect!(c, content="b'\\x0A'")
  let d = 255UL.to_byte()
  inspect!(d, content="b'\\xFF'")
  let f = 24U >> 16
  let e = f.to_byte()
  inspect!(e, content="b'\\x00'")
  let f = 24U >> 64
  let e = f.to_byte()
  inspect!(e, content="b'\\x18'")
  // to_byte
  let u = 0xDEADBEEFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xEF'")
  let u = 0x87654321U
  let b = u.to_byte()
  inspect!(b, content="b'\\x21'")
  let u = 0xFFFFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xFF'")
  let u = 0xFFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xFF'")
  let u = 0x12345678U
  let b = u.to_byte()
  inspect!(b, content="b'\\x78'")
  let u = 0U
  let b = u.to_byte()
  inspect!(b, content="b'\\x00'")
}

test "shift" {
  inspect!(1U << 2, content="4")
  inspect!(4U >> 2, content="1")
  inspect!(2U >> 2, content="0")
}

test "default" {
  inspect!(@uint.default(), content="0")
}

test "to_le_bytes" {
  let x : UInt = 0x12345678U
  let bytes = @uint.to_le_bytes(x)
  inspect!(bytes[0].to_int(), content="120") // 0x78
  inspect!(bytes[1].to_int(), content="86") // 0x56
  inspect!(bytes[2].to_int(), content="52") // 0x34
  inspect!(bytes[3].to_int(), content="18") // 0x12
}

test "test UInt::default" {
  inspect!(UInt::default(), content="0")
}

test "to_be_bytes" {
  let n = 4294967295U // maximum UInt value
  inspect!(@uint.to_be_bytes(n), content="b\"\\xff\\xff\\xff\\xff\"")
}
