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

test "overflow" {
  // signed integer expected to be negative
  inspect!(0xC2B2AE3D, content="-1028477379")
  inspect!(0x85EBCA77, content="-2048144777")
  inspect!(0x80000000, content="-2147483648")
  // here it works as expected due to overflow
  inspect!(-0x80000000, content="-2147483648")
  inspect!(0x7fff_ffff, content="2147483647")
  inspect!(-0x7fff_ffff, content="-2147483647")
}

test "hash" {
  inspect!((0).hash(), content="0")
  inspect!((1).hash(), content="69681622")
  inspect!((2).hash(), content="-236984087")
  inspect!((3).hash(), content="-1057966777")
  inspect!((4).hash(), content="-744398955")
  inspect!((5).hash(), content="-482482911")
  inspect!((6).hash(), content="-1506254959")
  inspect!((7).hash(), content="1327878809")
  inspect!((8).hash(), content="1120898975")
  inspect!((9).hash(), content="1567958539")
  inspect!((0x7fffffff).hash(), content="943411498")
  inspect!(Hash::hash(0x7fffffff + 1), content="963800214")
}

test "abs function coverage" {
  // Test cases for abs function
  assert_eq!(Int::abs(5), 5)
  assert_eq!(Int::abs(-5), 5)
  assert_eq!(Int::abs(0), 0)
  assert_eq!(Int::abs(@int.min_value), @int.min_value.abs())
  assert_eq!(Int::abs(@int.max_value), @int.max_value)
}

test "to_le_bytes" {
  let bytes = @int.to_le_bytes(0x12345678)
  inspect!(
    bytes,
    content=
      #|b"\x78\x56\x34\x12"
    ,
  )
}

test "to_be_bytes" {
  let bytes = @int.to_be_bytes(0x12345678)
  inspect!(
    bytes,
    content=
      #|b"\x12\x34\x56\x78"
    ,
  )
}
