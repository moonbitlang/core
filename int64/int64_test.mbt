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
test "Int64 overflow" {
  inspect(0x8000000000000000L, content="-9223372036854775808")
  inspect(-0x8000000000000000L, content="-9223372036854775808")
  inspect(0x7fffffffffffffffL, content="9223372036854775807")
  inspect(-0x7fffffffffffffffL, content="-9223372036854775807")
}

///|
test "Int64::from_int" {
  inspect(Int64::from_int(1256), content="1256")
}

///|
test "from_int" {
  inspect(Int64::from_int(1256), content="1256")
}

///|
test "Int64::min_value" {
  let min_value = @int64.min_value
  assert_eq(min_value, -9223372036854775808L)
}

///|
test "Int64::shift" {
  inspect(1L << 2, content="4")
  inspect(4L >> 2, content="1")
  inspect(-2L >> 2, content="-1")
  inspect(2L >> 2, content="0")
}

///|
test "Int64::ctz boundary cases" {
  inspect(Int64::ctz(0L), content="64")
  inspect(Int64::ctz(1L), content="0")
  inspect(Int64::ctz(-1L), content="0")
  inspect(Int64::ctz(@int64.min_value), content="63")
  inspect(Int64::ctz(@int64.max_value), content="0")
}

///|
test "Int64::ctz mixed cases" {
  // Cover positive and negative values with various trailing zero counts.
  let cases = [
    (2L, 1),
    (-2L, 1),
    (4L, 2),
    (-4L, 2),
    (0x0000000000000080L, 7),
    (0x0000000000008000L, 15),
    (0x0000000001000000L, 24),
    (0x0000001000000000L, 36),
    (0x0000100000000000L, 44),
    (0x0001000000000000L, 48),
    (0x0040000000000000L, 54),
    (0x4000000000000000L, 62),
  ]
  for case in cases {
    let (value, expected) = case
    assert_eq(Int64::ctz(value), expected)
  }
}

///|
test "Int64::clz boundary cases" {
  inspect(Int64::clz(0L), content="64")
  inspect(Int64::clz(1L), content="63")
  inspect(Int64::clz(@int64.max_value), content="1")
  inspect(Int64::clz(@int64.min_value), content="0")
  inspect(Int64::clz(-1L), content="0")
}

///|
test "Int64::clz mixed cases" {
  let cases = [
    (0x123456789ABCDEF0L, 3),
    (0x00000000FFFFFFFFL, 32),
    (0x0000000000000001L, 63),
    (0x000000000000000FL, 60),
    (0x00000000000000FFL, 56),
    (-0x543210FEDCBA9877L, 0),
  ]
  for case in cases {
    let (value, expected) = case
    assert_eq(Int64::clz(value), expected)
  }
}

///|
test "Int64::popcnt boundary cases" {
  inspect(Int64::popcnt(0L), content="0")
  inspect(Int64::popcnt(1L), content="1")
  inspect(Int64::popcnt(-1L), content="64")
  inspect(Int64::popcnt(@int64.min_value), content="1")
  inspect(Int64::popcnt(@int64.max_value), content="63")
}

///|
test "Int64::popcnt mixed cases" {
  let cases = [
    (0x123456789ABCDEF0L, 32),
    (0x0F0F0F0F0F0F0F0FL, 32),
    (0x5555555555555555L, 32),
    (-2L, 63),
    (-4L, 62),
    (-0x4000000000000000L, 2),
  ]
  for case in cases {
    let (value, expected) = case
    assert_eq(Int64::popcnt(value), expected)
  }
}

///|
fn Int64::to_be_bytes_local(self : Int64) -> Bytes {
  // self.reinterpret_as_uint64().to_be_bytes()
  let buf = @buffer.new(size_hint=8)
  buf.write_int64_be(self)
  buf.to_bytes()
}

///|
test "to_be_bytes" {
  let num = 0x1234567890ABCDEFL
  inspect(
    num.to_be_bytes_local(),
    content=(
      #|b"\x124Vx\x90\xab\xcd\xef"
    ),
  )
}

///|
fn Int64::to_le_bytes_local(self : Int64) -> Bytes {
  // self.reinterpret_as_uint64().to_le_bytes()
  let buf = @buffer.new(size_hint=8)
  buf.write_int64_le(self)
  buf.to_bytes()
}

///|
test "to_le_bytes of negative Int64" {
  let num = -0x1234567890ABCDEFL
  inspect(
    num.to_le_bytes_local(),
    content=(
      #|b"\x112To\x87\xa9\xcb\xed"
    ),
  )
}
