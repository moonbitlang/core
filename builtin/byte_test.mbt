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

test "byte.to_string" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  inspect!(b1, content="b'\\x00'")
  inspect!(b2, content="b'\\x0F'")
  inspect!(b3, content="b'\\xFF'")
}

test "byte_compare" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  assert_true!(b1.compare(b1) == 0)
  assert_true!(b1.compare(b2) < 0)
  assert_true!(b2.compare(b1) > 0)
  assert_true!(b2.compare(b3) < 0)
  assert_true!(b3.compare(b2) > 0)
  assert_true!(b3.compare(b3) == 0)
}

test "byte_op_equal" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  assert_true!(b1.op_equal(b1))
  assert_true!(b1.op_equal(b2) |> not)
  assert_true!(b2.op_equal(b1) |> not)
  assert_true!(b2.op_equal(b2))
  assert_true!(b2.op_equal(b3) |> not)
  assert_true!(b3.op_equal(b2) |> not)
  assert_true!(b3.op_equal(b3))
}

test "byte_lsl" {
  assert_eq!(b'\xFF'.lsl(8), b'\x00')
  assert_eq!(b'\xFF'.lsl(8).to_int(), 0)
}

test "byte_lsr" {
  assert_eq!(b'\xFF'.lsr(8), b'\x00')
  assert_eq!((0xFFF).to_byte().lsr(8), b'\x00')
}

test "byte_lxor" {
  assert_eq!(b'\xFF' ^ b'\xFF', b'\x00')
  assert_eq!(b'\xFF' ^ b'\x0F', b'\xF0')
  assert_eq!(b'\x0F' ^ b'\xFF', b'\xF0')
}

test "byte_lor" {
  assert_eq!(b'\xFF' | b'\xFF', b'\xFF')
  assert_eq!(b'\xFF' | b'\x0F', b'\xFF')
  assert_eq!(b'\x0F' | b'\xFF', b'\xFF')
}

test "byte_land" {
  assert_eq!(b'\xFF' & b'\xFF', b'\xFF')
  assert_eq!(b'\xFF' & b'\x0F', b'\x0F')
  assert_eq!(b'\x0F' & b'\xFF', b'\x0F')
}
