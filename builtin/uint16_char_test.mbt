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
test "UInt16 surrogate checks" {
  let leading = (0xD800 : UInt16)
  let trailing = (0xDFFF : UInt16)
  let normal = (0x0041 : UInt16)
  inspect(leading.is_leading_surrogate(), content="true")
  inspect(trailing.is_trailing_surrogate(), content="true")
  inspect(leading.is_surrogate(), content="true")
  inspect(trailing.is_surrogate(), content="true")
  inspect(normal.is_surrogate(), content="false")
}

///|
test "UInt16 to_char and unsafe_to_char" {
  let a = (0x0041 : UInt16)
  assert_true(a.to_char() is Some('A'))
  inspect(a.unsafe_to_char(), content="A")
  assert_true((0xD800 : UInt16).to_char() is None)
}

///|
test "UInt16 arithmetic and bit ops" {
  let a = (0x0010 : UInt16)
  let b = (0x0003 : UInt16)
  inspect((a + b).to_int(), content="19")
  inspect((a - b).to_int(), content="13")
  inspect((a * b).to_int(), content="48")
  inspect((a / b).to_int(), content="5")
  inspect((a % b).to_int(), content="1")
  inspect((a << 1).to_int(), content="32")
  inspect((a >> 2).to_int(), content="4")
  inspect((a | b).to_int(), content="19")
  inspect((a & b).to_int(), content="0")
  inspect((a ^ b).to_int(), content="19")
  inspect(a == b, content="false")
  inspect(a != b, content="true")
}

///|
test "UInt16 compare and conversions" {
  let a = (0x0010 : UInt16)
  let b = (0x000F : UInt16)
  inspect(a.compare(b), content="1")
  inspect(b.compare(a), content="-1")
  inspect(a.to_uint(), content="16")
  inspect(a.to_uint64(), content="16")
  inspect(UInt16::default().to_int(), content="0")
  @json.inspect(ToJson::to_json(a), content=16)
}

///|
test "UInt16 hash combine" {
  let hasher = Hasher::new(seed=0)
  hasher.combine((0x00FF : UInt16))
  inspect(hasher.finalize() != 0, content="true")
}

///|
test "UInt16 not_equal" {
  inspect(Eq::not_equal((0x0001 : UInt16), (0x0002 : UInt16)), content="true")
}
