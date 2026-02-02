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
  let h0 = Hasher::new(seed=0)
  h0.combine(0)
  inspect(h0.finalize(), content="148298089")
  let h1 = Hasher::new(seed=0)
  h1.combine(1)
  inspect(h1.finalize(), content="-205818221")
  let h2 = Hasher::new(seed=0)
  h2.combine(2)
  inspect(h2.finalize(), content="527729046")
  let h3 = Hasher::new(seed=0)
  h3.combine(3)
  inspect(h3.finalize(), content="-2136036233")
  let h4 = Hasher::new(seed=0)
  h4.combine(4)
  inspect(h4.finalize(), content="-43556126")
  let h5 = Hasher::new(seed=0)
  h5.combine(5)
  inspect(h5.finalize(), content="-2146748363")
  let h6 = Hasher::new(seed=0)
  h6.combine(6)
  inspect(h6.finalize(), content="-1455877728")
  let h7 = Hasher::new(seed=0)
  h7.combine(7)
  inspect(h7.finalize(), content="-427046664")
  let h8 = Hasher::new(seed=0)
  h8.combine(8)
  inspect(h8.finalize(), content="-1629857596")
  let h9 = Hasher::new(seed=0)
  h9.combine(9)
  inspect(h9.finalize(), content="970764038")
  let h10 = Hasher::new(seed=0)
  h10.combine(0x7fffffff)
  inspect(h10.finalize(), content="1225377669")
  let h11 = Hasher::new(seed=0)
  h11.combine(0x7fffffff + 1)
  inspect(h11.finalize(), content="1509677505")
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
