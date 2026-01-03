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
test "to_string with radix" {
  // Binary
  inspect((0).to_string(radix=2), content="0")
  inspect((1).to_string(radix=2), content="1")
  inspect((2).to_string(radix=2), content="10")
  inspect((255).to_string(radix=2), content="11111111")
  inspect((-255).to_string(radix=2), content="-11111111")

  // Octal
  inspect((0).to_string(radix=8), content="0")
  inspect((8).to_string(radix=8), content="10")
  inspect((64).to_string(radix=8), content="100")
  inspect((-64).to_string(radix=8), content="-100")

  // Decimal
  inspect((0).to_string(radix=10), content="0")
  inspect((123).to_string(radix=10), content="123")
  inspect((-123).to_string(radix=10), content="-123")
  inspect(
    0x7fff_ffff_ffff_ffffL.to_string(radix=10),
    content="9223372036854775807",
  )
  inspect(
    0x8000_0000_0000_0000L.to_string(radix=10),
    content="-9223372036854775808",
  )

  // Hexadecimal
  inspect((0).to_string(radix=16), content="0")
  inspect((0x11).to_string(radix=16), content="11")
  inspect((0x15ef).to_string(radix=16), content="15ef")
  inspect((-0xabcd).to_string(radix=16), content="-abcd")
  inspect(
    (1.0 : Float).reinterpret_as_int().to_string(radix=16),
    content="3f800000",
  )

  // UInt
  inspect(0U.to_string(radix=16), content="0")
  inspect(0x1AU.to_string(radix=16), content="1a")
  inspect(0xabcdU.to_string(radix=16), content="abcd")
  inspect(
    (-2.0 : Float).reinterpret_as_uint().to_string(radix=16),
    content="c0000000",
  )
  inspect((-1).reinterpret_as_uint().to_string(radix=16), content="ffffffff")

  // Int64
  inspect(0L.to_string(radix=16), content="0")
  inspect(0x2fL.to_string(radix=16), content="2f")
  inspect(0xf0aeL.to_string(radix=16), content="f0ae")
  inspect((-0x1234eacbL).to_string(radix=16), content="-1234eacb")
  inspect(
    1.0.reinterpret_as_uint64().to_string(radix=16),
    content="3ff0000000000000",
  )
  inspect(0b101L.to_string(radix=2), content="101")
  inspect(0o17L.to_string(radix=8), content="17")

  // UInt64
  inspect(0UL.to_string(radix=16), content="0")
  inspect(0x11UL.to_string(radix=16), content="11")
  inspect(0x12bdUL.to_string(radix=16), content="12bd")
  inspect(
    (-1L).reinterpret_as_uint64().to_string(radix=16),
    content="ffffffffffffffff",
  )
  inspect(
    2.0.reinterpret_as_uint64().to_string(radix=16),
    content="4000000000000000",
  )
}

///|
test "UInt64 decimal digit counts" {
  inspect(100000UL.to_string(), content="100000")
  inspect(1000000UL.to_string(), content="1000000")
  inspect(10000000000UL.to_string(), content="10000000000")
  inspect(100000000000UL.to_string(), content="100000000000")
  inspect(1000000000000UL.to_string(), content="1000000000000")
  inspect(10000000000000UL.to_string(), content="10000000000000")
  inspect(100000000000000UL.to_string(), content="100000000000000")
  inspect(1000000000000000UL.to_string(), content="1000000000000000")
}

///|
test "panic Int::to_string invalid radix" {
  ignore((1).to_string(radix=1))
}

///|
test "panic UInt::to_string invalid radix" {
  ignore(1U.to_string(radix=37))
}

///|
test "to_string runtime zero paths" {
  let arr = Array::new()
  arr.push(1)
  ignore(arr.pop())
  let zero = arr.length()
  inspect(zero.to_string(radix=16), content="0")
  inspect(zero.to_string(radix=2), content="0")
  inspect(zero.to_int64().to_string(radix=16), content="0")
  inspect(zero.to_int64().to_string(radix=2), content="0")
}

///|
test "panic UInt64::to_string invalid radix" {
  let arr = Array::new()
  arr.push(1)
  ignore(arr.pop())
  let zero = arr.length().to_uint64()
  ignore(UInt64::to_string(zero, radix=1))
}
