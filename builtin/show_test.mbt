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
test "Show for Unit" {
  inspect(().to_string(), content="()")
}

///|
test "Show for Bool" {
  inspect(true.to_string(), content="true")
  inspect(false.to_string(), content="false")
}

///|
test "Show for Int" {
  // Zero
  inspect((0).to_string(), content="0")

  // Single digit (1-9)
  inspect((1).to_string(), content="1")
  inspect((5).to_string(), content="5")
  inspect((9).to_string(), content="9")
  inspect((-1).to_string(), content="-1")
  inspect((-9).to_string(), content="-9")

  // Two digits (10-99)
  inspect((10).to_string(), content="10")
  inspect((42).to_string(), content="42")
  inspect((99).to_string(), content="99")
  inspect((-10).to_string(), content="-10")
  inspect((-99).to_string(), content="-99")

  // Three digits (100-999)
  inspect((100).to_string(), content="100")
  inspect((256).to_string(), content="256")
  inspect((999).to_string(), content="999")
  inspect((-100).to_string(), content="-100")
  inspect((-999).to_string(), content="-999")

  // Four digits (1000-9999) - exercises different path in decimal_count32
  inspect((1000).to_string(), content="1000")
  inspect((5555).to_string(), content="5555")
  inspect((9999).to_string(), content="9999")
  inspect((-1000).to_string(), content="-1000")
  inspect((-9999).to_string(), content="-9999")

  // Five digits (10000-99999) - boundary for decimal_count32
  inspect((10000).to_string(), content="10000")
  inspect((12345).to_string(), content="12345")
  inspect((99999).to_string(), content="99999")
  inspect((-10000).to_string(), content="-10000")
  inspect((-99999).to_string(), content="-99999")

  // Six digits (100000-999999) - next branch in decimal_count32
  inspect((100000).to_string(), content="100000")
  inspect((654321).to_string(), content="654321")
  inspect((999999).to_string(), content="999999")
  inspect((-100000).to_string(), content="-100000")
  inspect((-999999).to_string(), content="-999999")

  // Seven digits (1000000-9999999)
  inspect((1000000).to_string(), content="1000000")
  inspect((1234567).to_string(), content="1234567")
  inspect((9999999).to_string(), content="9999999")
  inspect((-1000000).to_string(), content="-1000000")
  inspect((-9999999).to_string(), content="-9999999")

  // Eight digits (10000000-99999999) - boundary for decimal_count32
  inspect((10000000).to_string(), content="10000000")
  inspect((87654321).to_string(), content="87654321")
  inspect((99999999).to_string(), content="99999999")
  inspect((-10000000).to_string(), content="-10000000")
  inspect((-99999999).to_string(), content="-99999999")

  // Nine digits (100000000-999999999)
  inspect((100000000).to_string(), content="100000000")
  inspect((123456789).to_string(), content="123456789")
  inspect((999999999).to_string(), content="999999999")
  inspect((-100000000).to_string(), content="-100000000")
  inspect((-999999999).to_string(), content="-999999999")

  // Ten digits (1000000000-2147483647) - boundary for decimal_count32
  inspect((1000000000).to_string(), content="1000000000")
  inspect((1234567890).to_string(), content="1234567890")
  inspect((2000000000).to_string(), content="2000000000")
  inspect((-1000000000).to_string(), content="-1000000000")
  inspect((-2000000000).to_string(), content="-2000000000")

  // Edge cases: max and min values
  inspect(@int.max_value.to_string(), content="2147483647")
  inspect(@int.min_value.to_string(), content="-2147483648")

  // Powers of 10 (boundary testing for decimal_count32)
  inspect((10).to_string(), content="10")
  inspect((100).to_string(), content="100")
  inspect((1000).to_string(), content="1000")
  inspect((10000).to_string(), content="10000")
  inspect((100000).to_string(), content="100000")
  inspect((1000000).to_string(), content="1000000")
  inspect((10000000).to_string(), content="10000000")
  inspect((100000000).to_string(), content="100000000")
  inspect((1000000000).to_string(), content="1000000000")
}

///|
test "Show for Int - hexadecimal (radix=16)" {
  // Zero
  inspect((0).to_string(radix=16), content="0")

  // Single hex digit (0x1-0xf)
  inspect((1).to_string(radix=16), content="1")
  inspect((10).to_string(radix=16), content="a")
  inspect((15).to_string(radix=16), content="f")
  inspect((-1).to_string(radix=16), content="-1")
  inspect((-15).to_string(radix=16), content="-f")

  // Two hex digits (0x10-0xff) - tests hex pair writing
  inspect((16).to_string(radix=16), content="10")
  inspect((255).to_string(radix=16), content="ff")
  inspect((171).to_string(radix=16), content="ab")
  inspect((-16).to_string(radix=16), content="-10")
  inspect((-255).to_string(radix=16), content="-ff")

  // Three hex digits (0x100-0xfff) - odd number, tests single digit handling
  inspect((256).to_string(radix=16), content="100")
  inspect((2748).to_string(radix=16), content="abc")
  inspect((4095).to_string(radix=16), content="fff")
  inspect((-256).to_string(radix=16), content="-100")
  inspect((-4095).to_string(radix=16), content="-fff")

  // Four hex digits (0x1000-0xffff) - tests byte-pair processing
  inspect((4096).to_string(radix=16), content="1000")
  inspect((43981).to_string(radix=16), content="abcd")
  inspect((65535).to_string(radix=16), content="ffff")
  inspect((-4096).to_string(radix=16), content="-1000")
  inspect((-65535).to_string(radix=16), content="-ffff")

  // Five hex digits (0x10000-0xfffff)
  inspect((65536).to_string(radix=16), content="10000")
  inspect((703710).to_string(radix=16), content="abcde")
  inspect((1048575).to_string(radix=16), content="fffff")
  inspect((-65536).to_string(radix=16), content="-10000")
  inspect((-1048575).to_string(radix=16), content="-fffff")

  // Six hex digits (0x100000-0xffffff)
  inspect((1048576).to_string(radix=16), content="100000")
  inspect((11259375).to_string(radix=16), content="abcdef")
  inspect((16777215).to_string(radix=16), content="ffffff")
  inspect((-1048576).to_string(radix=16), content="-100000")
  inspect((-16777215).to_string(radix=16), content="-ffffff")

  // Seven hex digits (0x1000000-0xfffffff)
  inspect((16777216).to_string(radix=16), content="1000000")
  inspect((268435455).to_string(radix=16), content="fffffff")
  inspect((-16777216).to_string(radix=16), content="-1000000")
  inspect((-268435455).to_string(radix=16), content="-fffffff")

  // Eight hex digits (0x10000000-0x7fffffff) - max for positive Int
  inspect((268435456).to_string(radix=16), content="10000000")
  inspect((2147483647).to_string(radix=16), content="7fffffff")
  inspect((-268435456).to_string(radix=16), content="-10000000")
  inspect((-2147483648).to_string(radix=16), content="-80000000")

  // Edge cases: max and min
  inspect(@int.max_value.to_string(radix=16), content="7fffffff")
  inspect(@int.min_value.to_string(radix=16), content="-80000000")

  // Powers of 16 (boundary testing for hex_count32)
  inspect((1).to_string(radix=16), content="1")
  inspect((16).to_string(radix=16), content="10")
  inspect((256).to_string(radix=16), content="100")
  inspect((4096).to_string(radix=16), content="1000")
  inspect((65536).to_string(radix=16), content="10000")
  inspect((1048576).to_string(radix=16), content="100000")
  inspect((16777216).to_string(radix=16), content="1000000")
  inspect((268435456).to_string(radix=16), content="10000000")
}

///|
test "Show for Int - binary (radix=2)" {
  // Power-of-two optimization path
  inspect((0).to_string(radix=2), content="0")
  inspect((1).to_string(radix=2), content="1")
  inspect((2).to_string(radix=2), content="10")
  inspect((7).to_string(radix=2), content="111")
  inspect((15).to_string(radix=2), content="1111")
  inspect((255).to_string(radix=2), content="11111111")
  inspect((256).to_string(radix=2), content="100000000")
  inspect((-1).to_string(radix=2), content="-1")
  inspect((-255).to_string(radix=2), content="-11111111")
  inspect(
    @int.max_value.to_string(radix=2),
    content="1111111111111111111111111111111",
  )
  inspect(
    @int.min_value.to_string(radix=2),
    content="-10000000000000000000000000000000",
  )
}

///|
test "Show for Int - octal (radix=8)" {
  // Power-of-two optimization path
  inspect((0).to_string(radix=8), content="0")
  inspect((7).to_string(radix=8), content="7")
  inspect((8).to_string(radix=8), content="10")
  inspect((64).to_string(radix=8), content="100")
  inspect((511).to_string(radix=8), content="777")
  inspect((512).to_string(radix=8), content="1000")
  inspect((-8).to_string(radix=8), content="-10")
  inspect((-64).to_string(radix=8), content="-100")
  inspect(@int.max_value.to_string(radix=8), content="17777777777")
  inspect(@int.min_value.to_string(radix=8), content="-20000000000")
}

///|
test "Show for Int - base 4 (radix=4)" {
  // Power-of-two optimization path
  inspect((0).to_string(radix=4), content="0")
  inspect((3).to_string(radix=4), content="3")
  inspect((4).to_string(radix=4), content="10")
  inspect((15).to_string(radix=4), content="33")
  inspect((16).to_string(radix=4), content="100")
  inspect((255).to_string(radix=4), content="3333")
  inspect((-4).to_string(radix=4), content="-10")
  inspect((-255).to_string(radix=4), content="-3333")
}

///|
test "Show for Int - base 32 (radix=32)" {
  // Power-of-two optimization path
  inspect((0).to_string(radix=32), content="0")
  inspect((31).to_string(radix=32), content="v")
  inspect((32).to_string(radix=32), content="10")
  inspect((1023).to_string(radix=32), content="vv")
  inspect((1024).to_string(radix=32), content="100")
  inspect((-32).to_string(radix=32), content="-10")
  inspect(@int.max_value.to_string(radix=32), content="1vvvvvv")
  inspect(@int.min_value.to_string(radix=32), content="-2000000")
}

///|
test "Show for Int - base 3 (radix=3)" {
  // Non-power-of-two, uses division path
  inspect((0).to_string(radix=3), content="0")
  inspect((2).to_string(radix=3), content="2")
  inspect((3).to_string(radix=3), content="10")
  inspect((8).to_string(radix=3), content="22")
  inspect((9).to_string(radix=3), content="100")
  inspect((26).to_string(radix=3), content="222")
  inspect((27).to_string(radix=3), content="1000")
  inspect((-3).to_string(radix=3), content="-10")
  inspect((-27).to_string(radix=3), content="-1000")
}

///|
test "Show for Int - base 5 (radix=5)" {
  // Non-power-of-two, uses division path
  inspect((0).to_string(radix=5), content="0")
  inspect((4).to_string(radix=5), content="4")
  inspect((5).to_string(radix=5), content="10")
  inspect((24).to_string(radix=5), content="44")
  inspect((25).to_string(radix=5), content="100")
  inspect((124).to_string(radix=5), content="444")
  inspect((125).to_string(radix=5), content="1000")
  inspect((-5).to_string(radix=5), content="-10")
  inspect((-125).to_string(radix=5), content="-1000")
}

///|
test "Show for Int - base 36 (radix=36)" {
  // Maximum radix, non-power-of-two
  inspect((0).to_string(radix=36), content="0")
  inspect((35).to_string(radix=36), content="z")
  inspect((36).to_string(radix=36), content="10")
  inspect((1295).to_string(radix=36), content="zz")
  inspect((1296).to_string(radix=36), content="100")
  inspect((-36).to_string(radix=36), content="-10")
  inspect(@int.max_value.to_string(radix=36), content="zik0zj")
  inspect(@int.min_value.to_string(radix=36), content="-zik0zk")
}

///|
test "Show for Int64" {
  inspect((0 : Int64).to_string(), content="0")
  inspect(@int64.max_value.to_string(), content="9223372036854775807")
  inspect(@int64.min_value.to_string(), content="-9223372036854775808")
}

///|
test "Show for Int64 - hexadecimal (radix=16)" {
  // Zero
  inspect((0 : Int64).to_string(radix=16), content="0")

  // Various hex values
  inspect((1 : Int64).to_string(radix=16), content="1")
  inspect((15 : Int64).to_string(radix=16), content="f")
  inspect((16 : Int64).to_string(radix=16), content="10")
  inspect((255 : Int64).to_string(radix=16), content="ff")
  inspect((256 : Int64).to_string(radix=16), content="100")
  inspect((65535 : Int64).to_string(radix=16), content="ffff")
  inspect((4294967295 : Int64).to_string(radix=16), content="ffffffff")
  inspect((-1 : Int64).to_string(radix=16), content="-1")
  inspect((-255 : Int64).to_string(radix=16), content="-ff")
  inspect((-65535 : Int64).to_string(radix=16), content="-ffff")

  // Large 64-bit values
  inspect(
    (72057594037927935 : Int64).to_string(radix=16),
    content="ffffffffffffff",
  )
  inspect(@int64.max_value.to_string(radix=16), content="7fffffffffffffff")
  inspect(@int64.min_value.to_string(radix=16), content="-8000000000000000")

  // Powers of 16
  inspect((1 : Int64).to_string(radix=16), content="1")
  inspect((16 : Int64).to_string(radix=16), content="10")
  inspect((256 : Int64).to_string(radix=16), content="100")
  inspect((4096 : Int64).to_string(radix=16), content="1000")
  inspect((65536 : Int64).to_string(radix=16), content="10000")
  inspect((1048576 : Int64).to_string(radix=16), content="100000")
  inspect((16777216 : Int64).to_string(radix=16), content="1000000")
  inspect((268435456 : Int64).to_string(radix=16), content="10000000")
  inspect((4294967296 : Int64).to_string(radix=16), content="100000000")
}

///|
test "Show for Int64 - binary (radix=2)" {
  inspect((0 : Int64).to_string(radix=2), content="0")
  inspect((1 : Int64).to_string(radix=2), content="1")
  inspect((2 : Int64).to_string(radix=2), content="10")
  inspect((7 : Int64).to_string(radix=2), content="111")
  inspect((255 : Int64).to_string(radix=2), content="11111111")
  inspect((-1 : Int64).to_string(radix=2), content="-1")
  inspect((-255 : Int64).to_string(radix=2), content="-11111111")
  inspect(
    @int64.max_value.to_string(radix=2),
    content="111111111111111111111111111111111111111111111111111111111111111",
  )
  inspect(
    @int64.min_value.to_string(radix=2),
    content="-1000000000000000000000000000000000000000000000000000000000000000",
  )
}

///|
test "Show for Int64 - octal (radix=8)" {
  inspect((0 : Int64).to_string(radix=8), content="0")
  inspect((7 : Int64).to_string(radix=8), content="7")
  inspect((8 : Int64).to_string(radix=8), content="10")
  inspect((64 : Int64).to_string(radix=8), content="100")
  inspect((511 : Int64).to_string(radix=8), content="777")
  inspect((-8 : Int64).to_string(radix=8), content="-10")
  inspect((-64 : Int64).to_string(radix=8), content="-100")
  inspect(@int64.max_value.to_string(radix=8), content="777777777777777777777")
  inspect(
    @int64.min_value.to_string(radix=8),
    content="-1000000000000000000000",
  )
}

///|
test "Show for Int64 - base 3 (radix=3)" {
  inspect((0 : Int64).to_string(radix=3), content="0")
  inspect((2 : Int64).to_string(radix=3), content="2")
  inspect((3 : Int64).to_string(radix=3), content="10")
  inspect((8 : Int64).to_string(radix=3), content="22")
  inspect((27 : Int64).to_string(radix=3), content="1000")
  inspect((-3 : Int64).to_string(radix=3), content="-10")
  inspect((-27 : Int64).to_string(radix=3), content="-1000")
}

///|
test "Show for Int64 - base 36 (radix=36)" {
  inspect((0 : Int64).to_string(radix=36), content="0")
  inspect((35 : Int64).to_string(radix=36), content="z")
  inspect((36 : Int64).to_string(radix=36), content="10")
  inspect((1295 : Int64).to_string(radix=36), content="zz")
  inspect((-36 : Int64).to_string(radix=36), content="-10")
  inspect(@int64.max_value.to_string(radix=36), content="1y2p0ij32e8e7")
  inspect(@int64.min_value.to_string(radix=36), content="-1y2p0ij32e8e8")
}

///|
test "Show for UInt" {
  inspect((0 : UInt).to_string(), content="0")
  inspect(@uint.max_value.to_string(), content="4294967295")
  inspect(@uint.min_value.to_string(), content="0")
}

///|
test "Show for UInt - hexadecimal (radix=16)" {
  // Zero
  inspect((0 : UInt).to_string(radix=16), content="0")

  // Single hex digit (0x1-0xf)
  inspect((1 : UInt).to_string(radix=16), content="1")
  inspect((10 : UInt).to_string(radix=16), content="a")
  inspect((15 : UInt).to_string(radix=16), content="f")

  // Two hex digits (0x10-0xff)
  inspect((16 : UInt).to_string(radix=16), content="10")
  inspect((255 : UInt).to_string(radix=16), content="ff")
  inspect((171 : UInt).to_string(radix=16), content="ab")

  // Four hex digits (0x1000-0xffff)
  inspect((4096 : UInt).to_string(radix=16), content="1000")
  inspect((43981 : UInt).to_string(radix=16), content="abcd")
  inspect((65535 : UInt).to_string(radix=16), content="ffff")

  // Eight hex digits (max for UInt)
  inspect((268435456 : UInt).to_string(radix=16), content="10000000")
  inspect((4294967295 : UInt).to_string(radix=16), content="ffffffff")

  // Edge cases
  inspect(@uint.max_value.to_string(radix=16), content="ffffffff")
  inspect(@uint.min_value.to_string(radix=16), content="0")

  // Powers of 16
  inspect((1 : UInt).to_string(radix=16), content="1")
  inspect((16 : UInt).to_string(radix=16), content="10")
  inspect((256 : UInt).to_string(radix=16), content="100")
  inspect((4096 : UInt).to_string(radix=16), content="1000")
  inspect((65536 : UInt).to_string(radix=16), content="10000")
  inspect((1048576 : UInt).to_string(radix=16), content="100000")
  inspect((16777216 : UInt).to_string(radix=16), content="1000000")
  inspect((268435456 : UInt).to_string(radix=16), content="10000000")
}

///|
test "Show for UInt - binary (radix=2)" {
  inspect((0 : UInt).to_string(radix=2), content="0")
  inspect((1 : UInt).to_string(radix=2), content="1")
  inspect((2 : UInt).to_string(radix=2), content="10")
  inspect((7 : UInt).to_string(radix=2), content="111")
  inspect((15 : UInt).to_string(radix=2), content="1111")
  inspect((255 : UInt).to_string(radix=2), content="11111111")
  inspect((256 : UInt).to_string(radix=2), content="100000000")
  inspect(
    @uint.max_value.to_string(radix=2),
    content="11111111111111111111111111111111",
  )
}

///|
test "Show for UInt - octal (radix=8)" {
  inspect((0 : UInt).to_string(radix=8), content="0")
  inspect((7 : UInt).to_string(radix=8), content="7")
  inspect((8 : UInt).to_string(radix=8), content="10")
  inspect((64 : UInt).to_string(radix=8), content="100")
  inspect((511 : UInt).to_string(radix=8), content="777")
  inspect((512 : UInt).to_string(radix=8), content="1000")
  inspect(@uint.max_value.to_string(radix=8), content="37777777777")
}

///|
test "Show for UInt - base 3 (radix=3)" {
  inspect((0 : UInt).to_string(radix=3), content="0")
  inspect((2 : UInt).to_string(radix=3), content="2")
  inspect((3 : UInt).to_string(radix=3), content="10")
  inspect((8 : UInt).to_string(radix=3), content="22")
  inspect((9 : UInt).to_string(radix=3), content="100")
  inspect((26 : UInt).to_string(radix=3), content="222")
  inspect((27 : UInt).to_string(radix=3), content="1000")
}

///|
test "Show for UInt - base 36 (radix=36)" {
  inspect((0 : UInt).to_string(radix=36), content="0")
  inspect((35 : UInt).to_string(radix=36), content="z")
  inspect((36 : UInt).to_string(radix=36), content="10")
  inspect((1295 : UInt).to_string(radix=36), content="zz")
  inspect((1296 : UInt).to_string(radix=36), content="100")
  inspect(@uint.max_value.to_string(radix=36), content="1z141z3")
}

///|
test "Show for UInt64" {
  inspect((0 : UInt64).to_string(), content="0")
  inspect(@uint64.max_value.to_string(), content="18446744073709551615")
  inspect(@uint64.min_value.to_string(), content="0")
}

///|
test "Show for UInt64 - hexadecimal (radix=16)" {
  // Zero
  inspect((0 : UInt64).to_string(radix=16), content="0")

  // Various hex values
  inspect((1 : UInt64).to_string(radix=16), content="1")
  inspect((15 : UInt64).to_string(radix=16), content="f")
  inspect((16 : UInt64).to_string(radix=16), content="10")
  inspect((255 : UInt64).to_string(radix=16), content="ff")
  inspect((256 : UInt64).to_string(radix=16), content="100")
  inspect((65535 : UInt64).to_string(radix=16), content="ffff")
  inspect((4294967295 : UInt64).to_string(radix=16), content="ffffffff")

  // Large 64-bit values
  inspect(
    (72057594037927935 : UInt64).to_string(radix=16),
    content="ffffffffffffff",
  )
  inspect(@uint64.max_value.to_string(radix=16), content="ffffffffffffffff")

  // Powers of 16
  inspect((1 : UInt64).to_string(radix=16), content="1")
  inspect((16 : UInt64).to_string(radix=16), content="10")
  inspect((256 : UInt64).to_string(radix=16), content="100")
  inspect((4096 : UInt64).to_string(radix=16), content="1000")
  inspect((65536 : UInt64).to_string(radix=16), content="10000")
  inspect((1048576 : UInt64).to_string(radix=16), content="100000")
  inspect((16777216 : UInt64).to_string(radix=16), content="1000000")
  inspect((268435456 : UInt64).to_string(radix=16), content="10000000")
  inspect((4294967296 : UInt64).to_string(radix=16), content="100000000")
  inspect((1099511627776 : UInt64).to_string(radix=16), content="10000000000")
}

///|
test "Show for UInt64 - binary (radix=2)" {
  inspect((0 : UInt64).to_string(radix=2), content="0")
  inspect((1 : UInt64).to_string(radix=2), content="1")
  inspect((2 : UInt64).to_string(radix=2), content="10")
  inspect((7 : UInt64).to_string(radix=2), content="111")
  inspect((255 : UInt64).to_string(radix=2), content="11111111")
  inspect(
    @uint64.max_value.to_string(radix=2),
    content="1111111111111111111111111111111111111111111111111111111111111111",
  )
}

///|
test "Show for UInt64 - octal (radix=8)" {
  inspect((0 : UInt64).to_string(radix=8), content="0")
  inspect((7 : UInt64).to_string(radix=8), content="7")
  inspect((8 : UInt64).to_string(radix=8), content="10")
  inspect((64 : UInt64).to_string(radix=8), content="100")
  inspect((511 : UInt64).to_string(radix=8), content="777")
  inspect(
    @uint64.max_value.to_string(radix=8),
    content="1777777777777777777777",
  )
}

///|
test "Show for UInt64 - base 3 (radix=3)" {
  inspect((0 : UInt64).to_string(radix=3), content="0")
  inspect((2 : UInt64).to_string(radix=3), content="2")
  inspect((3 : UInt64).to_string(radix=3), content="10")
  inspect((8 : UInt64).to_string(radix=3), content="22")
  inspect((27 : UInt64).to_string(radix=3), content="1000")
}

///|
test "Show for UInt64 - base 36 (radix=36)" {
  inspect((0 : UInt64).to_string(radix=36), content="0")
  inspect((35 : UInt64).to_string(radix=36), content="z")
  inspect((36 : UInt64).to_string(radix=36), content="10")
  inspect((1295 : UInt64).to_string(radix=36), content="zz")
  inspect(@uint64.max_value.to_string(radix=36), content="3w5e11264sgsf")
}

///|
test "Show for UInt16" {
  inspect((0 : UInt16).to_string(), content="0")
  inspect((65535 : UInt16).to_string(), content="65535")
  inspect((65535 : UInt16).to_string(radix=8), content="177777")
  inspect((65533 : UInt16), content="65533")
  // TODO:
  // inspect((65536 : UInt16), content="65536")
  // 65536 is overflow for uint16
}

///|
test "Show for UInt16 - hexadecimal (radix=16)" {
  inspect((0 : UInt16).to_string(radix=16), content="0")
  inspect((15 : UInt16).to_string(radix=16), content="f")
  inspect((16 : UInt16).to_string(radix=16), content="10")
  inspect((255 : UInt16).to_string(radix=16), content="ff")
  inspect((256 : UInt16).to_string(radix=16), content="100")
  inspect((4095 : UInt16).to_string(radix=16), content="fff")
  inspect((65535 : UInt16).to_string(radix=16), content="ffff")
}

///|
test "Show for UInt16 - binary (radix=2)" {
  inspect((0 : UInt16).to_string(radix=2), content="0")
  inspect((1 : UInt16).to_string(radix=2), content="1")
  inspect((7 : UInt16).to_string(radix=2), content="111")
  inspect((255 : UInt16).to_string(radix=2), content="11111111")
  inspect((65535 : UInt16).to_string(radix=2), content="1111111111111111")
}

///|
test "Show for UInt16 - octal (radix=8)" {
  inspect((0 : UInt16).to_string(radix=8), content="0")
  inspect((7 : UInt16).to_string(radix=8), content="7")
  inspect((8 : UInt16).to_string(radix=8), content="10")
  inspect((511 : UInt16).to_string(radix=8), content="777")
  inspect((65535 : UInt16).to_string(radix=8), content="177777")
}

///|
test "Show for UInt16 - base 36 (radix=36)" {
  inspect((0 : UInt16).to_string(radix=36), content="0")
  inspect((35 : UInt16).to_string(radix=36), content="z")
  inspect((36 : UInt16).to_string(radix=36), content="10")
  inspect((1295 : UInt16).to_string(radix=36), content="zz")
  inspect((65535 : UInt16).to_string(radix=36), content="1ekf")
}

///|
test "Show for Bytes" {
  inspect(
    Show::to_string(b"abcdefg"),
    content=(
      #|b"abcdefg"
    ),
  )
  inspect(
    Show::to_string(b"\x00\xff\x63"),
    content=(
      #|b"\x00\xffc"
    ),
  )
}

///|
test "Show for BytesView" {
  inspect(
    b"abcdefg"[1:5].to_string(),
    content=(
      #|b"bcde"
    ),
  )
  inspect(
    b"\x00\xff\x63"[:].to_string(),
    content=(
      #|b"\x00\xffc"
    ),
  )
}

///|
test "Show for String" {
  fn to_string_using_output(str) {
    let buf = StringBuilder::new()
    Show::output(str, buf)
    buf.to_string()
  }

  inspect(
    to_string_using_output("abcdefg中文字符"),
    content=(
      #|"abcdefg中文字符"
    ),
  )
  inspect(Show::to_string("abcdefg中文字符"), content="abcdefg中文字符")
  inspect(
    to_string_using_output("---\"---'---\\---\n---\t---\u{67}---"),
    content=(
      #|"---\"---'---\\---\n---\t---g---"
    ),
  )
  // should be identity
  inspect(
    Show::to_string("---\"---'---\\---\n---\t---\u{67}---"),
    content=(
      #|---"---'---\---
      #|---	---g---
    ),
  )
}

///|
test "Show for Result" {
  // use explicit type annotation to specify the type of Ok/Err
  fn result_to_string(x : Result[String, String]) {
    x.to_string()
  }

  inspect(
    result_to_string(Ok("abc")),
    content=(
      #|Ok("abc")
    ),
  )
  inspect(
    result_to_string(Err("def")),
    content=(
      #|Err("def")
    ),
  )
}

///|
test "Show for Ref" {
  inspect(
    Ref::{ val: "abc" }.to_string(),
    content=(
      #|{val: "abc"}
    ),
  )
}

///|
test "Show for FixedArray" {
  inspect(
    (["a", "b", "c"] : FixedArray[_]).to_string(),
    content=(
      #|["a", "b", "c"]
    ),
  )
  inspect(([] : FixedArray[String]).to_string(), content="[]")
}

///|
test "Show for Array" {
  inspect(
    ["a", "b", "c"].to_string(),
    content=(
      #|["a", "b", "c"]
    ),
  )
  inspect(([] : Array[String]).to_string(), content="[]")
}

///|
test "Show for ArrayView" {
  let arr = ["a", "b", "c", "d"]
  inspect(
    arr[1:3].to_string(),
    content=(
      #|["b", "c"]
    ),
  )
  inspect(arr[2:2].to_string(), content="[]")
}

///|
test "Show for Char" {
  inspect(Show::to_string('a'), content="a")
  inspect(Show::to_string('字'), content="字")
  inspect(
    Show::to_string('\n'),
    content=(
      #|
      #|
    ),
  )
  inspect(Show::to_string('\t'), content="\t")
  inspect(
    Show::to_string('"'),
    content=(
      #|"
    ),
  )
  inspect(Show::to_string('\''), content="'")
  inspect(Show::to_string('\\'), content="\\")
  inspect('a'.to_string(), content="a")
  inspect('字'.to_string(), content="字")
  inspect(
    '\n'.to_string(),
    content=(
      #|
      #|
    ),
  )
  inspect('\t'.to_string(), content="\t")
  inspect(
    '"'.to_string(),
    content=(
      #|"
    ),
  )
  inspect('\''.to_string(), content="'")
  inspect('\\'.to_string(), content="\\")
}

///|
test "char show hex digits" {
  // inspect('\x01', content="\x01")
  // FIXME: inspect('\x0b') will not work with update test
  // inspect('\x0b', content="\x0b")
  inspect('\u{01}' |> repr, content="'\\u{01}'")
  inspect('\u{0b}' |> repr, content="'\\u{0b}'")
}

///|
test "char show hex digits extended" {
  inspect('\u{0605}' |> repr, content="'\\u{0605}'")
  inspect('\u{FDD0}' |> repr, content="'\\u{fdd0}'")
  inspect('\u{1FFFE}' |> repr, content="'\\u{01fffe}'")
  inspect('\u{10FFFE}' |> repr, content="'\\u{10fffe}'")
}

///|
test "char_special" {
  inspect('\r', content="\r")
  inspect('\b', content="\u{8}")
}

///|
test "Show for Failure" {
  let f = Failure::Failure("test error message")
  inspect(
    f.to_string(),
    content=(
      #|Failure("test error message")
    ),
  )
}

///|
test "Show for Char special cases" {
  // Test escape sequences
  inspect('\''.to_string(), content="'")

  // Test various special character outputs
  let quote_buf = StringBuilder::new()
  '\''.output(quote_buf)
  inspect(quote_buf.to_string(), content="'\\''")
  let backslash_buf = StringBuilder::new()
  '\\'.output(backslash_buf)
  inspect(backslash_buf.to_string(), content="'\\\\'")
  let cr_buf = StringBuilder::new()
  '\r'.output(cr_buf)
  inspect(cr_buf.to_string(), content="'\\r'")
  let backspace_buf = StringBuilder::new()
  '\b'.output(backspace_buf)
  inspect(backspace_buf.to_string(), content="'\\b'")
  let tab_buf = StringBuilder::new()
  '\t'.output(tab_buf)
  inspect(tab_buf.to_string(), content="'\\t'")

  // Test hex output for control characters
  let ctrl1_buf = StringBuilder::new()
  '\u{01}'.output(ctrl1_buf)
  inspect(ctrl1_buf.to_string(), content="'\\u{01}'")
  let ctrl_f_buf = StringBuilder::new()
  '\u{0F}'.output(ctrl_f_buf)
  inspect(ctrl_f_buf.to_string(), content="'\\u{0f}'")
  let ctrl_1f_buf = StringBuilder::new()
  '\u{1F}'.output(ctrl_1f_buf)
  inspect(ctrl_1f_buf.to_string(), content="'\\u{1f}'")
}
