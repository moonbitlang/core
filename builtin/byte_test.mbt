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
  @test.is_true!(b1.compare(b1) == 0)
  @test.is_true!(b1.compare(b2) < 0)
  @test.is_true!(b2.compare(b1) > 0)
  @test.is_true!(b2.compare(b3) < 0)
  @test.is_true!(b3.compare(b2) > 0)
  @test.is_true!(b3.compare(b3) == 0)
}

test "byte_op_equal" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  @test.is_true!(b1.op_equal(b1))
  @test.is_true!(b1.op_equal(b2) |> not)
  @test.is_true!(b2.op_equal(b1) |> not)
  @test.is_true!(b2.op_equal(b2))
  @test.is_true!(b2.op_equal(b3) |> not)
  @test.is_true!(b3.op_equal(b2) |> not)
  @test.is_true!(b3.op_equal(b3))
}

test "byte_lsl" {
  @test.eq!(b'\xFF'.lsl(8), b'\x00')
  @test.eq!(b'\xFF'.lsl(8).to_int(), 0)
}

test "byte_lsr" {
  @test.eq!(b'\xFF'.lsr(8), b'\x00')
  @test.eq!((0xFFF).to_byte().lsr(8), b'\x00')
}

test "byte_lxor" {
  @test.eq!(b'\xFF'.lxor(b'\xFF'), b'\x00')
  @test.eq!(b'\xFF'.lxor(b'\x0F'), b'\xF0')
  @test.eq!(b'\x0F'.lxor(b'\xFF'), b'\xF0')
}

test "byte_lor" {
  @test.eq!(b'\xFF'.lor(b'\xFF'), b'\xFF')
  @test.eq!(b'\xFF'.lor(b'\x0F'), b'\xFF')
  @test.eq!(b'\x0F'.lor(b'\xFF'), b'\xFF')
}

test "byte_land" {
  @test.eq!(b'\xFF'.land(b'\xFF'), b'\xFF')
  @test.eq!(b'\xFF'.land(b'\x0F'), b'\x0F')
  @test.eq!(b'\x0F'.land(b'\xFF'), b'\x0F')
}
