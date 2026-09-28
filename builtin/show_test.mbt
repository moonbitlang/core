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
  inspect(@int.MAX_VALUE.to_string(), content="2147483647")
  inspect(@int.MIN_VALUE.to_string(), content="-2147483648")

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
  inspect(@int.MAX_VALUE.to_string(radix=16), content="7fffffff")
  inspect(@int.MIN_VALUE.to_string(radix=16), content="-80000000")

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
    @int.MAX_VALUE.to_string(radix=2),
    content="1111111111111111111111111111111",
  )
  inspect(
    @int.MIN_VALUE.to_string(radix=2),
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
  inspect(@int.MAX_VALUE.to_string(radix=8), content="17777777777")
  inspect(@int.MIN_VALUE.to_string(radix=8), content="-20000000000")
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
  inspect(@int.MAX_VALUE.to_string(radix=32), content="1vvvvvv")
  inspect(@int.MIN_VALUE.to_string(radix=32), content="-2000000")
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
  inspect(@int.MAX_VALUE.to_string(radix=36), content="zik0zj")
  inspect(@int.MIN_VALUE.to_string(radix=36), content="-zik0zk")
}

///|
test "Show for Int64" {
  inspect(Int64(0).to_string(), content="0")
  inspect(@int64.MAX_VALUE.to_string(), content="9223372036854775807")
  inspect(@int64.MIN_VALUE.to_string(), content="-9223372036854775808")
}

///|
test "Show for Int64 - hexadecimal (radix=16)" {
  // Zero
  inspect(Int64(0).to_string(radix=16), content="0")

  // Various hex values
  inspect(Int64(1).to_string(radix=16), content="1")
  inspect(Int64(15).to_string(radix=16), content="f")
  inspect(Int64(16).to_string(radix=16), content="10")
  inspect(Int64(255).to_string(radix=16), content="ff")
  inspect(Int64(256).to_string(radix=16), content="100")
  inspect(Int64(65535).to_string(radix=16), content="ffff")
  inspect(Int64(4294967295).to_string(radix=16), content="ffffffff")
  inspect(Int64(-1).to_string(radix=16), content="-1")
  inspect(Int64(-255).to_string(radix=16), content="-ff")
  inspect(Int64(-65535).to_string(radix=16), content="-ffff")

  // Large 64-bit values
  inspect(
    Int64(72057594037927935).to_string(radix=16),
    content="ffffffffffffff",
  )
  inspect(@int64.MAX_VALUE.to_string(radix=16), content="7fffffffffffffff")
  inspect(@int64.MIN_VALUE.to_string(radix=16), content="-8000000000000000")

  // Powers of 16
  inspect(Int64(1).to_string(radix=16), content="1")
  inspect(Int64(16).to_string(radix=16), content="10")
  inspect(Int64(256).to_string(radix=16), content="100")
  inspect(Int64(4096).to_string(radix=16), content="1000")
  inspect(Int64(65536).to_string(radix=16), content="10000")
  inspect(Int64(1048576).to_string(radix=16), content="100000")
  inspect(Int64(16777216).to_string(radix=16), content="1000000")
  inspect(Int64(268435456).to_string(radix=16), content="10000000")
  inspect(Int64(4294967296).to_string(radix=16), content="100000000")
}

///|
test "Show for Int64 - binary (radix=2)" {
  inspect(Int64(0).to_string(radix=2), content="0")
  inspect(Int64(1).to_string(radix=2), content="1")
  inspect(Int64(2).to_string(radix=2), content="10")
  inspect(Int64(7).to_string(radix=2), content="111")
  inspect(Int64(255).to_string(radix=2), content="11111111")
  inspect(Int64(-1).to_string(radix=2), content="-1")
  inspect(Int64(-255).to_string(radix=2), content="-11111111")
  inspect(
    @int64.MAX_VALUE.to_string(radix=2),
    content="111111111111111111111111111111111111111111111111111111111111111",
  )
  inspect(
    @int64.MIN_VALUE.to_string(radix=2),
    content="-1000000000000000000000000000000000000000000000000000000000000000",
  )
}

///|
test "Show for Int64 - octal (radix=8)" {
  inspect(Int64(0).to_string(radix=8), content="0")
  inspect(Int64(7).to_string(radix=8), content="7")
  inspect(Int64(8).to_string(radix=8), content="10")
  inspect(Int64(64).to_string(radix=8), content="100")
  inspect(Int64(511).to_string(radix=8), content="777")
  inspect(Int64(-8).to_string(radix=8), content="-10")
  inspect(Int64(-64).to_string(radix=8), content="-100")
  inspect(@int64.MAX_VALUE.to_string(radix=8), content="777777777777777777777")
  inspect(
    @int64.MIN_VALUE.to_string(radix=8),
    content="-1000000000000000000000",
  )
}

///|
test "Show for Int64 - base 3 (radix=3)" {
  inspect(Int64(0).to_string(radix=3), content="0")
  inspect(Int64(2).to_string(radix=3), content="2")
  inspect(Int64(3).to_string(radix=3), content="10")
  inspect(Int64(8).to_string(radix=3), content="22")
  inspect(Int64(27).to_string(radix=3), content="1000")
  inspect(Int64(-3).to_string(radix=3), content="-10")
  inspect(Int64(-27).to_string(radix=3), content="-1000")
}

///|
test "Show for Int64 - base 36 (radix=36)" {
  inspect(Int64(0).to_string(radix=36), content="0")
  inspect(Int64(35).to_string(radix=36), content="z")
  inspect(Int64(36).to_string(radix=36), content="10")
  inspect(Int64(1295).to_string(radix=36), content="zz")
  inspect(Int64(-36).to_string(radix=36), content="-10")
  inspect(@int64.MAX_VALUE.to_string(radix=36), content="1y2p0ij32e8e7")
  inspect(@int64.MIN_VALUE.to_string(radix=36), content="-1y2p0ij32e8e8")
}

///|
test "Show for UInt" {
  inspect(UInt(0).to_string(), content="0")
  inspect(@uint.MAX_VALUE.to_string(), content="4294967295")
  inspect(@uint.MIN_VALUE.to_string(), content="0")
}

///|
test "Show for UInt - hexadecimal (radix=16)" {
  // Zero
  inspect(UInt(0).to_string(radix=16), content="0")

  // Single hex digit (0x1-0xf)
  inspect(UInt(1).to_string(radix=16), content="1")
  inspect(UInt(10).to_string(radix=16), content="a")
  inspect(UInt(15).to_string(radix=16), content="f")

  // Two hex digits (0x10-0xff)
  inspect(UInt(16).to_string(radix=16), content="10")
  inspect(UInt(255).to_string(radix=16), content="ff")
  inspect(UInt(171).to_string(radix=16), content="ab")

  // Four hex digits (0x1000-0xffff)
  inspect(UInt(4096).to_string(radix=16), content="1000")
  inspect(UInt(43981).to_string(radix=16), content="abcd")
  inspect(UInt(65535).to_string(radix=16), content="ffff")

  // Eight hex digits (max for UInt)
  inspect(UInt(268435456).to_string(radix=16), content="10000000")
  inspect(UInt(4294967295).to_string(radix=16), content="ffffffff")

  // Edge cases
  inspect(@uint.MAX_VALUE.to_string(radix=16), content="ffffffff")
  inspect(@uint.MIN_VALUE.to_string(radix=16), content="0")

  // Powers of 16
  inspect(UInt(1).to_string(radix=16), content="1")
  inspect(UInt(16).to_string(radix=16), content="10")
  inspect(UInt(256).to_string(radix=16), content="100")
  inspect(UInt(4096).to_string(radix=16), content="1000")
  inspect(UInt(65536).to_string(radix=16), content="10000")
  inspect(UInt(1048576).to_string(radix=16), content="100000")
  inspect(UInt(16777216).to_string(radix=16), content="1000000")
  inspect(UInt(268435456).to_string(radix=16), content="10000000")
}

///|
test "Show for UInt - binary (radix=2)" {
  inspect(UInt(0).to_string(radix=2), content="0")
  inspect(UInt(1).to_string(radix=2), content="1")
  inspect(UInt(2).to_string(radix=2), content="10")
  inspect(UInt(7).to_string(radix=2), content="111")
  inspect(UInt(15).to_string(radix=2), content="1111")
  inspect(UInt(255).to_string(radix=2), content="11111111")
  inspect(UInt(256).to_string(radix=2), content="100000000")
  inspect(
    @uint.MAX_VALUE.to_string(radix=2),
    content="11111111111111111111111111111111",
  )
}

///|
test "Show for UInt - octal (radix=8)" {
  inspect(UInt(0).to_string(radix=8), content="0")
  inspect(UInt(7).to_string(radix=8), content="7")
  inspect(UInt(8).to_string(radix=8), content="10")
  inspect(UInt(64).to_string(radix=8), content="100")
  inspect(UInt(511).to_string(radix=8), content="777")
  inspect(UInt(512).to_string(radix=8), content="1000")
  inspect(@uint.MAX_VALUE.to_string(radix=8), content="37777777777")
}

///|
test "Show for UInt - base 3 (radix=3)" {
  inspect(UInt(0).to_string(radix=3), content="0")
  inspect(UInt(2).to_string(radix=3), content="2")
  inspect(UInt(3).to_string(radix=3), content="10")
  inspect(UInt(8).to_string(radix=3), content="22")
  inspect(UInt(9).to_string(radix=3), content="100")
  inspect(UInt(26).to_string(radix=3), content="222")
  inspect(UInt(27).to_string(radix=3), content="1000")
}

///|
test "Show for UInt - base 36 (radix=36)" {
  inspect(UInt(0).to_string(radix=36), content="0")
  inspect(UInt(35).to_string(radix=36), content="z")
  inspect(UInt(36).to_string(radix=36), content="10")
  inspect(UInt(1295).to_string(radix=36), content="zz")
  inspect(UInt(1296).to_string(radix=36), content="100")
  inspect(@uint.MAX_VALUE.to_string(radix=36), content="1z141z3")
}

///|
test "Show for UInt64" {
  inspect(UInt64(0).to_string(), content="0")
  inspect(@uint64.MAX_VALUE.to_string(), content="18446744073709551615")
  inspect(@uint64.MIN_VALUE.to_string(), content="0")
}

///|
test "Show for UInt64 - hexadecimal (radix=16)" {
  // Zero
  inspect(UInt64(0).to_string(radix=16), content="0")

  // Various hex values
  inspect(UInt64(1).to_string(radix=16), content="1")
  inspect(UInt64(15).to_string(radix=16), content="f")
  inspect(UInt64(16).to_string(radix=16), content="10")
  inspect(UInt64(255).to_string(radix=16), content="ff")
  inspect(UInt64(256).to_string(radix=16), content="100")
  inspect(UInt64(65535).to_string(radix=16), content="ffff")
  inspect(UInt64(4294967295).to_string(radix=16), content="ffffffff")

  // Large 64-bit values
  inspect(
    UInt64(72057594037927935).to_string(radix=16),
    content="ffffffffffffff",
  )
  inspect(@uint64.MAX_VALUE.to_string(radix=16), content="ffffffffffffffff")

  // Powers of 16
  inspect(UInt64(1).to_string(radix=16), content="1")
  inspect(UInt64(16).to_string(radix=16), content="10")
  inspect(UInt64(256).to_string(radix=16), content="100")
  inspect(UInt64(4096).to_string(radix=16), content="1000")
  inspect(UInt64(65536).to_string(radix=16), content="10000")
  inspect(UInt64(1048576).to_string(radix=16), content="100000")
  inspect(UInt64(16777216).to_string(radix=16), content="1000000")
  inspect(UInt64(268435456).to_string(radix=16), content="10000000")
  inspect(UInt64(4294967296).to_string(radix=16), content="100000000")
  inspect(UInt64(1099511627776).to_string(radix=16), content="10000000000")
}

///|
test "Show for UInt64 - binary (radix=2)" {
  inspect(UInt64(0).to_string(radix=2), content="0")
  inspect(UInt64(1).to_string(radix=2), content="1")
  inspect(UInt64(2).to_string(radix=2), content="10")
  inspect(UInt64(7).to_string(radix=2), content="111")
  inspect(UInt64(255).to_string(radix=2), content="11111111")
  inspect(
    @uint64.MAX_VALUE.to_string(radix=2),
    content="1111111111111111111111111111111111111111111111111111111111111111",
  )
}

///|
test "Show for UInt64 - octal (radix=8)" {
  inspect(UInt64(0).to_string(radix=8), content="0")
  inspect(UInt64(7).to_string(radix=8), content="7")
  inspect(UInt64(8).to_string(radix=8), content="10")
  inspect(UInt64(64).to_string(radix=8), content="100")
  inspect(UInt64(511).to_string(radix=8), content="777")
  inspect(
    @uint64.MAX_VALUE.to_string(radix=8),
    content="1777777777777777777777",
  )
}

///|
test "Show for UInt64 - base 3 (radix=3)" {
  inspect(UInt64(0).to_string(radix=3), content="0")
  inspect(UInt64(2).to_string(radix=3), content="2")
  inspect(UInt64(3).to_string(radix=3), content="10")
  inspect(UInt64(8).to_string(radix=3), content="22")
  inspect(UInt64(27).to_string(radix=3), content="1000")
}

///|
test "Show for UInt64 - base 36 (radix=36)" {
  inspect(UInt64(0).to_string(radix=36), content="0")
  inspect(UInt64(35).to_string(radix=36), content="z")
  inspect(UInt64(36).to_string(radix=36), content="10")
  inspect(UInt64(1295).to_string(radix=36), content="zz")
  inspect(@uint64.MAX_VALUE.to_string(radix=36), content="3w5e11264sgsf")
}

///|
test "Show for UInt16" {
  inspect(UInt16(0).to_string(), content="0")
  inspect(UInt16(65535).to_string(), content="65535")
  inspect(UInt16(65535).to_string(radix=8), content="177777")
  inspect(UInt16(65533), content="65533")
  // TODO:
  // inspect(UInt16(65536), content="65536")
  // 65536 is overflow for uint16
}

///|
test "Show for UInt16 - hexadecimal (radix=16)" {
  inspect(UInt16(0).to_string(radix=16), content="0")
  inspect(UInt16(15).to_string(radix=16), content="f")
  inspect(UInt16(16).to_string(radix=16), content="10")
  inspect(UInt16(255).to_string(radix=16), content="ff")
  inspect(UInt16(256).to_string(radix=16), content="100")
  inspect(UInt16(4095).to_string(radix=16), content="fff")
  inspect(UInt16(65535).to_string(radix=16), content="ffff")
}

///|
test "Show for UInt16 - binary (radix=2)" {
  inspect(UInt16(0).to_string(radix=2), content="0")
  inspect(UInt16(1).to_string(radix=2), content="1")
  inspect(UInt16(7).to_string(radix=2), content="111")
  inspect(UInt16(255).to_string(radix=2), content="11111111")
  inspect(UInt16(65535).to_string(radix=2), content="1111111111111111")
}

///|
test "Show for UInt16 - octal (radix=8)" {
  inspect(UInt16(0).to_string(radix=8), content="0")
  inspect(UInt16(7).to_string(radix=8), content="7")
  inspect(UInt16(8).to_string(radix=8), content="10")
  inspect(UInt16(511).to_string(radix=8), content="777")
  inspect(UInt16(65535).to_string(radix=8), content="177777")
}

///|
test "Show for UInt16 - base 36 (radix=36)" {
  inspect(UInt16(0).to_string(radix=36), content="0")
  inspect(UInt16(35).to_string(radix=36), content="z")
  inspect(UInt16(36).to_string(radix=36), content="10")
  inspect(UInt16(1295).to_string(radix=36), content="zz")
  inspect(UInt16(65535).to_string(radix=36), content="1ekf")
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
    let buf = StringBuilder()
    Show::output(str, buf)
    buf.to_string()
  }

  inspect(
    to_string_using_output("abcdefg中文字符"),
    content=(
      #|abcdefg中文字符
    ),
  )
  inspect(Show::to_string("abcdefg中文字符"), content="abcdefg中文字符")
  inspect(
    to_string_using_output("---\"---'---\\---\n---\t---\u{67}---"),
    content=(
      #|---"---'---\---
      #|---	---g---
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
#warnings("-deprecated")
test "Show for Result" {
  // use explicit type annotation to specify the type of Ok/Err
  fn result_to_string(x : Result[String, String]) {
    x.to_string()
  }

  inspect(
    result_to_string(Ok("abc")),
    content=(
      #|Ok(abc)
    ),
  )
  inspect(
    result_to_string(Err("def")),
    content=(
      #|Err(def)
    ),
  )
}

///|
#warnings("-deprecated")
test "Show for Ref" {
  debug_inspect(
    Ref("abc").to_string(),
    content=(
      #|"{val: abc}"
    ),
  )
}

///|
#warnings("-deprecated")
test "Show for FixedArray" {
  debug_inspect(
    (["a", "b", "c"] : FixedArray[_]).to_string(),
    content=(
      #|"[a, b, c]"
    ),
  )
  debug_inspect(
    ([] : FixedArray[String]).to_string(),
    content=(
      #|"[]"
    ),
  )
}

///|
#warnings("-deprecated")
test "Show for Array" {
  debug_inspect(
    ["a", "b", "c"].to_string(),
    content=(
      #|"[a, b, c]"
    ),
  )
  debug_inspect(
    ([] : Array[String]).to_string(),
    content=(
      #|"[]"
    ),
  )
}

///|
#warnings("-deprecated")
test "Show for ArrayView" {
  let arr = ["a", "b", "c", "d"]
  debug_inspect(
    arr[1:3].to_string(),
    content=(
      #|"[b, c]"
    ),
  )
  debug_inspect(
    arr[2:2].to_string(),
    content=(
      #|"[]"
    ),
  )
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
  inspect(Repr('\u{01}'), content="'\\u{01}'")
  inspect(Repr('\u{0b}'), content="'\\u{0b}'")
}

///|
test "char show hex digits extended" {
  inspect(Repr('\u{0605}'), content="'\\u{0605}'")
  inspect(Repr('\u{FDD0}'), content="'\\u{fdd0}'")
  inspect(Repr('\u{1FFFE}'), content="'\\u{01fffe}'")
  inspect(Repr('\u{10FFFE}'), content="'\\u{10fffe}'")
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
      #|Failure(test error message)
    ),
  )
}

///|
test "Show for Char special cases" {
  // Test escape sequences
  inspect('\''.to_string(), content="'")

  // Test various special character outputs
  let quote_buf = StringBuilder()
  Show::output('\'', quote_buf)
  @test.assert_eq(quote_buf.to_string(), "'")
  let backslash_buf = StringBuilder()
  Show::output('\\', backslash_buf)
  @test.assert_eq(backslash_buf.to_string(), "\\")
  let cr_buf = StringBuilder()
  Show::output('\r', cr_buf)
  @test.assert_eq(cr_buf.to_string(), "\r")
  let backspace_buf = StringBuilder()
  Show::output('\b', backspace_buf)
  @test.assert_eq(backspace_buf.to_string(), "\b")
  let tab_buf = StringBuilder()
  Show::output('\t', tab_buf)
  @test.assert_eq(tab_buf.to_string(), "\t")

  // Test hex output for control characters
  let ctrl1_buf = StringBuilder()
  Show::output('\u{01}', ctrl1_buf)
  @test.assert_eq(ctrl1_buf.to_string(), "\u{01}")
  let ctrl_f_buf = StringBuilder()
  Show::output('\u{0F}', ctrl_f_buf)
  @test.assert_eq(ctrl_f_buf.to_string(), "\u{0f}")
  let ctrl_1f_buf = StringBuilder()
  Show::output('\u{1F}', ctrl_1f_buf)
  @test.assert_eq(ctrl_1f_buf.to_string(), "\u{1f}")
}

///|
test "Char::escape" {
  // ASCII printable
  inspect('a'.escape(), content="'a'")
  inspect('a'.escape(quote=false), content="a")
  inspect('Z'.escape(), content="'Z'")
  inspect(' '.escape(), content="' '")
  inspect('~'.escape(), content="'~'")
  // Special escape sequences
  inspect('\''.escape(), content="'\\''")
  inspect('\\'.escape(), content="'\\\\'")
  inspect('\n'.escape(), content="'\\n'")
  inspect('\n'.escape(quote=false), content="\\n")
  inspect('\r'.escape(), content="'\\r'")
  inspect('\b'.escape(), content="'\\b'")
  inspect('\t'.escape(), content="'\\t'")
  // Non-printable control characters
  inspect('\u{0}'.escape(), content="'\\u{00}'")
  inspect('\u{01}'.escape(), content="'\\u{01}'")
  inspect('\u{1F}'.escape(), content="'\\u{1f}'")
  // Printable Unicode (displayed as-is)
  inspect('中'.escape(), content="'中'")
  inspect('中'.escape(quote=false), content="中")
}

///|
test "String::escape" {
  // Basic string
  inspect("hello".escape(), content="\"hello\"")
  inspect("hello".escape(quote=false), content="hello")
  // Special escape sequences
  inspect("a\nb".escape(), content="\"a\\nb\"")
  inspect("a\nb".escape(quote=false), content="a\\nb")
  inspect("a\rb".escape(), content="\"a\\rb\"")
  inspect("a\tb".escape(), content="\"a\\tb\"")
  inspect("a\bb".escape(), content="\"a\\bb\"")
  // Quote and backslash escaping
  inspect("a\"b".escape(), content="\"a\\\"b\"")
  inspect("a\\b".escape(), content="\"a\\\\b\"")
  // Control characters
  inspect("a\u{01}b".escape(), content="\"a\\u{01}b\"")
  // Empty string
  inspect("".escape(), content="\"\"")
  inspect("".escape(quote=false), content="")
  // Unicode (displayed as-is)
  inspect("你好".escape(), content="\"你好\"")
  inspect("你好".escape(quote=false), content="你好")
}

///|
test "StringView::escape" {
  inspect("xxhelloxx"[2:7].escape(), content="\"hello\"")
  inspect("xxhelloxx"[2:7].escape(quote=false), content="hello")
}
