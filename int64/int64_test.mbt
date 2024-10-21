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

///-----------------------------------------------------------------------------
test "overflow" {
  inspect!(0x8000000000000000L, content="-9223372036854775808")
  inspect!(-0x8000000000000000L, content="-9223372036854775808")
  inspect!(0x7fffffffffffffffL, content="9223372036854775807")
  inspect!(-0x7fffffffffffffffL, content="-9223372036854775807")
}

///-----------------------------------------------------------------------------
test "Int64::min_value" {
  let min_value = @int64.min_value
  assert_eq!(min_value, -9223372036854775808L)
}

///-----------------------------------------------------------------------------
test "shift" {
  inspect!(1L << 2, content="4")
  inspect!(4L >> 2, content="1")
  inspect!(-2L >> 2, content="-1")
  inspect!(2L >> 2, content="0")
}

///-----------------------------------------------------------------------------
test "grouped test for boundary cases" {
  // Test for the smallest UInt64 value
  inspect!(UInt64::ctz(0UL), content="64")

  // Test for the largest UInt64 value
  inspect!(UInt64::ctz(0xFFFFFFFFFFFFFFFFUL), content="0")

  // Test for a value with a single bit set
  inspect!(UInt64::ctz(1UL), content="0")

  // Test for a value with the most significant bit set
  inspect!(UInt64::ctz(0x8000000000000000UL), content="63")
}

///-----------------------------------------------------------------------------
test "grouped test for random cases" {
  // Random cases to test various bit patterns
  inspect!(UInt64::ctz(0x0000000000000001UL), content="0")
  inspect!(UInt64::ctz(0x0000000000000002UL), content="1")
  inspect!(UInt64::ctz(0x0000000000000004UL), content="2")
  inspect!(UInt64::ctz(0x0000000000000008UL), content="3")
  inspect!(UInt64::ctz(0x0000000000000010UL), content="4")
  inspect!(UInt64::ctz(0x0000000000000020UL), content="5")
  inspect!(UInt64::ctz(0x0000000000000040UL), content="6")
  inspect!(UInt64::ctz(0x0000000000000080UL), content="7")
  inspect!(UInt64::ctz(0x0000000000000100UL), content="8")
  inspect!(UInt64::ctz(0x0000000000000200UL), content="9")
  inspect!(UInt64::ctz(0x0000000000000400UL), content="10")
  inspect!(UInt64::ctz(0x0000000000000800UL), content="11")
  inspect!(UInt64::ctz(0x0000000000001000UL), content="12")
  inspect!(UInt64::ctz(0x0000000000002000UL), content="13")
  inspect!(UInt64::ctz(0x0000000000004000UL), content="14")
  inspect!(UInt64::ctz(0x0000000000008000UL), content="15")
  inspect!(UInt64::ctz(0x0000000000010000UL), content="16")
  inspect!(UInt64::ctz(0x0000000000020000UL), content="17")
  inspect!(UInt64::ctz(0x0000000000040000UL), content="18")
  inspect!(UInt64::ctz(0x0000000000080000UL), content="19")
  inspect!(UInt64::ctz(0x0000000000100000UL), content="20")
  inspect!(UInt64::ctz(0x0000000000200000UL), content="21")
  inspect!(UInt64::ctz(0x0000000000400000UL), content="22")
  inspect!(UInt64::ctz(0x0000000000800000UL), content="23")
  inspect!(UInt64::ctz(0x0000000001000000UL), content="24")
  inspect!(UInt64::ctz(0x0000000002000000UL), content="25")
  inspect!(UInt64::ctz(0x0000000004000000UL), content="26")
  inspect!(UInt64::ctz(0x0000000008000000UL), content="27")
  inspect!(UInt64::ctz(0x0000000010000000UL), content="28")
  inspect!(UInt64::ctz(0x0000000020000000UL), content="29")
  inspect!(UInt64::ctz(0x0000000040000000UL), content="30")
  inspect!(UInt64::ctz(0x0000000080000000UL), content="31")
  inspect!(UInt64::ctz(0x0000000100000000UL), content="32")
  inspect!(UInt64::ctz(0x0000000200000000UL), content="33")
  inspect!(UInt64::ctz(0x0000000400000000UL), content="34")
  inspect!(UInt64::ctz(0x0000000800000000UL), content="35")
  inspect!(UInt64::ctz(0x0000001000000000UL), content="36")
  inspect!(UInt64::ctz(0x0000002000000000UL), content="37")
  inspect!(UInt64::ctz(0x0000004000000000UL), content="38")
  inspect!(UInt64::ctz(0x0000008000000000UL), content="39")
  inspect!(UInt64::ctz(0x0000010000000000UL), content="40")
  inspect!(UInt64::ctz(0x0000020000000000UL), content="41")
  inspect!(UInt64::ctz(0x0000040000000000UL), content="42")
  inspect!(UInt64::ctz(0x0000080000000000UL), content="43")
  inspect!(UInt64::ctz(0x0000100000000000UL), content="44")
  inspect!(UInt64::ctz(0x0000200000000000UL), content="45")
  inspect!(UInt64::ctz(0x0000400000000000UL), content="46")
  inspect!(UInt64::ctz(0x0000800000000000UL), content="47")
  inspect!(UInt64::ctz(0x0001000000000000UL), content="48")
  inspect!(UInt64::ctz(0x0002000000000000UL), content="49")
  inspect!(UInt64::ctz(0x0004000000000000UL), content="50")
  inspect!(UInt64::ctz(0x0008000000000000UL), content="51")
  inspect!(UInt64::ctz(0x0010000000000000UL), content="52")
  inspect!(UInt64::ctz(0x0020000000000000UL), content="53")
  inspect!(UInt64::ctz(0x0040000000000000UL), content="54")
  inspect!(UInt64::ctz(0x0080000000000000UL), content="55")
  inspect!(UInt64::ctz(0x0100000000000000UL), content="56")
  inspect!(UInt64::ctz(0x0200000000000000UL), content="57")
  inspect!(UInt64::ctz(0x0400000000000000UL), content="58")
  inspect!(UInt64::ctz(0x0800000000000000UL), content="59")
  inspect!(UInt64::ctz(0x1000000000000000UL), content="60")
  inspect!(UInt64::ctz(0x2000000000000000UL), content="61")
  inspect!(UInt64::ctz(0x4000000000000000UL), content="62")
  inspect!(UInt64::ctz(0x8000000000000000UL), content="63")
}

///-----------------------------------------------------------------------------
test "grouped test for boundary cases" {
  inspect!(UInt64::clz(0UL), content="64")
  inspect!(UInt64::clz(1UL), content="63")
  inspect!(UInt64::clz(0x8000000000000000UL), content="0")
  inspect!(UInt64::clz(0x7FFFFFFFFFFFFFFFUL), content="1")
}

///-----------------------------------------------------------------------------
test "grouped test for random cases" {
  inspect!(UInt64::clz(0x123456789ABCDEF0UL), content="3")
  inspect!(UInt64::clz(0xABCDEF0123456789UL), content="0")
  inspect!(UInt64::clz(0x00000000FFFFFFFFUL), content="32")
  inspect!(UInt64::clz(0x0000000000000001UL), content="63")
  inspect!(UInt64::clz(0x000000000000000FUL), content="60")
  inspect!(UInt64::clz(0x00000000000000FFUL), content="56")
}

///-----------------------------------------------------------------------------
test "grouped test for edge cases with specific patterns" {
  inspect!(UInt64::clz(0x0000000000000000UL), content="64")
  inspect!(UInt64::clz(0xFFFFFFFFFFFFFFFFUL), content="0")
  inspect!(UInt64::clz(0x0000000000000001UL), content="63")
  inspect!(UInt64::clz(0x8000000000000000UL), content="0")
}

///-----------------------------------------------------------------------------
test "grouped test for basic functionality" {
  inspect!(UInt64::popcnt(0UL), content="0")
  inspect!(UInt64::popcnt(1UL), content="1")
  inspect!(UInt64::popcnt(2UL), content="1")
  inspect!(UInt64::popcnt(3UL), content="2")
}

///-----------------------------------------------------------------------------
test "grouped test for edge cases" {
  inspect!(UInt64::popcnt(0xFFFFFFFFFFFFFFFFUL), content="64")
  inspect!(UInt64::popcnt(0x8000000000000000UL), content="1")
  inspect!(UInt64::popcnt(0x7FFFFFFFFFFFFFFFUL), content="63")
}

///-----------------------------------------------------------------------------
test "grouped test for random cases" {
  inspect!(UInt64::popcnt(0x123456789ABCDEF0UL), content="32")
  inspect!(UInt64::popcnt(0xABCDEF0123456789UL), content="32")
  inspect!(UInt64::popcnt(0x5555555555555555UL), content="32")
  inspect!(UInt64::popcnt(0xAAAAAAAAAAAAAAAAUL), content="32")
  // 1101111010101101101111101110111111011110101011011011111011101111
  inspect!(UInt64::popcnt(0xDEADBEEFDEADBEEFUL), content="48")
  // 1011111011101111110111101010110110111110111011111101111010101101
  inspect!(UInt64::popcnt(0xBEEFDEADBEEFDEADUL), content="48")
}
