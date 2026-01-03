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
test "overflow" {
  // signed integer expected to be negative
  inspect(0xC2B2AE3D, content="-1028477379")
  inspect(0x85EBCA77, content="-2048144777")
  inspect(0x80000000, content="-2147483648")
  // here it works as expected due to overflow
  inspect(-0x80000000, content="-2147483648")
  inspect(0x7fff_ffff, content="2147483647")
  inspect(-0x7fff_ffff, content="-2147483647")
}

///|
test "hash" {
  inspect(Hasher::new(seed=0)..combine(0).finalize(), content="148298089")
  inspect(Hasher::new(seed=0)..combine(1).finalize(), content="-205818221")
  inspect(Hasher::new(seed=0)..combine(2).finalize(), content="527729046")
  inspect(Hasher::new(seed=0)..combine(3).finalize(), content="-2136036233")
  inspect(Hasher::new(seed=0)..combine(4).finalize(), content="-43556126")
  inspect(Hasher::new(seed=0)..combine(5).finalize(), content="-2146748363")
  inspect(Hasher::new(seed=0)..combine(6).finalize(), content="-1455877728")
  inspect(Hasher::new(seed=0)..combine(7).finalize(), content="-427046664")
  inspect(Hasher::new(seed=0)..combine(8).finalize(), content="-1629857596")
  inspect(Hasher::new(seed=0)..combine(9).finalize(), content="970764038")
  inspect(
    Hasher::new(seed=0)..combine(0x7fffffff).finalize(),
    content="1225377669",
  )
  inspect(
    Hasher::new(seed=0)..combine(0x7fffffff + 1).finalize(),
    content="1509677505",
  )
}

///|
test "abs function coverage" {
  // Test cases for abs function
  inspect(Int::abs(5), content="5")
  inspect(Int::abs(-5), content="5")
  inspect(Int::abs(0), content="0")
  assert_eq(Int::abs(@int.min_value), @int.min_value.abs())
  assert_eq(Int::abs(@int.max_value), @int.max_value)
}

///|
test "to_le_bytes" {
  let buffer = @buffer.new()
  buffer.write_int_le(0x12345678)
  let bytes = buffer.contents()
  inspect(
    bytes,
    content=(
      #|b"xV4\x12"
    ),
  )
}

///|
test "to_be_bytes" {
  let buffer = @buffer.new()
  buffer.write_int_be(0x12345678)
  let bytes = buffer.contents()
  inspect(
    bytes,
    content=(
      #|b"\x124Vx"
    ),
  )
}
