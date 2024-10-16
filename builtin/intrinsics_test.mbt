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

/// test Int::land
test "Int::land should perform bitwise AND operation" {
  let a = 0b101
  let b = 0b011
  inspect!(a & b, content="1")
  inspect!((0xffff_ffff & 0xa000_0000) == 0xa000_0000, content="true")
  inspect!((0xffff_ffff & 0x0) == 0, content="true")
  inspect!((0xffff_ffff & 0xffff_ffff) == 0xffff_ffff, content="true")
}

/// test Int::lor
test "Int::lor should perform bitwise OR operation" {
  inspect!((0b101 | 0b011) == 0b111, content="true")
  inspect!((0xffff_ffff | 0xa000_0000) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff | 0x0) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff | 0xffff_ffff) == 0xffff_ffff, content="true")
}

/// test Int::lxor
test "Int::lxor should perform bitwise XOR operation" {
  inspect!((0b101 ^ 0b011) == 0b110, content="true")
  inspect!((0xffff_ffff ^ 0xa000_0000) == 0x5fff_ffff, content="true")
  inspect!((0xffff_ffff ^ 0x0) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff ^ 0xffff_ffff) == 0, content="true")
}

/// test Int::op_shl
test "Int::op_shl should perform left shift operation" {
  inspect!(7 << 1, content="14")
  inspect!((0b101 << 1) == 0b1010, content="true")
  inspect!((0xffff_ffff << 1) == 0xffff_fffe, content="true")
  inspect!((0xffff_ffff << 0) == 0xffff_ffff, content="true")
  inspect!(0xffff_ffff << 3, content="-8")
  let arr = Array::make(33, 0).mapi(fn { i, _ => i })
  inspect!(
    arr,
    content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]",
  )
  let r = arr.map(fn { i => 0xffff_ffff << i })
  // note when shifting 32 bits or more, it returns the original value
  inspect!(
    r,
    content="[-1, -2, -4, -8, -16, -32, -64, -128, -256, -512, -1024, -2048, -4096, -8192, -16384, -32768, -65536, -131072, -262144, -524288, -1048576, -2097152, -4194304, -8388608, -16777216, -33554432, -67108864, -134217728, -268435456, -536870912, -1073741824, -2147483648, -1]",
  )
  inspect!(7 << 32, content="7")
}

test "reinterpret: UInt <-> Int" {
  inspect!(0U.reinterpret_as_int(), content="0")
  inspect!(1U.reinterpret_as_int(), content="1")
  inspect!(0x7fff_ffffU.reinterpret_as_int(), content="2147483647")
  inspect!(0x7fff_ffffU, content="2147483647")
  inspect!(0x8000_0000U.reinterpret_as_int(), content="-2147483648")
  inspect!(0x8000_0000U, content="2147483648")
  inspect!(0xffff_ffffU.reinterpret_as_int(), content="-1")
  inspect!(0xffff_ffffU, content="4294967295")
  inspect!((0).reinterpret_as_uint(), content="0")
  inspect!((1).reinterpret_as_uint(), content="1")
  inspect!((2147483647).reinterpret_as_uint(), content="2147483647")
  inspect!((-2147483648).reinterpret_as_uint(), content="2147483648")
  inspect!((-1).reinterpret_as_uint(), content="4294967295")
}

test "uint test" {
  inspect!(100U == 100U, content="true")
  inspect!(0U < 100U, content="true")
  inspect!(100U > 0U, content="true")
  inspect!(2147483648U.reinterpret_as_int(), content="-2147483648")
  inspect!((-2147483648).reinterpret_as_uint(), content="2147483648")
  inspect!((2147483648U + 1000000000U).to_uint64(), content="3147483648")
  inspect!(2147483647U + 1U, content="2147483648")
  inspect!(0U - 1U, content="4294967295")
  inspect!(2147483647U * 2U, content="4294967294")
  inspect!(0x80000000U / 2U, content="1073741824")
  inspect!(4294967295U % 17U, content="0")
  inspect!(0xFFFFFFFFU & 0xFFFFU, content="65535")
  inspect!(0xFF00U | 0xFFU, content="65535")
  inspect!(0xFFFF00U ^ 0xFF00FFU, content="65535")
  inspect!(0x1U << 31, content="2147483648")
  inspect!(2147483648U >> 31, content="1")
}

test "uint64 test" {
  inspect!(100UL == 100UL, content="true")
  inspect!(0UL < 100UL, content="true")
  inspect!(100UL > 0UL, content="true")
  inspect!(
    9223372036854775808UL.reinterpret_as_int64(),
    content="-9223372036854775808",
  )
  inspect!(
    (-9223372036854775808L).reinterpret_as_uint64(),
    content="9223372036854775808",
  )
  inspect!((9223372036854775808UL + 1UL).to_uint(), content="1")
  inspect!((9223372036854775808UL + 1UL).to_int(), content="1")
  inspect!(9223372036854775808UL + 1UL, content="9223372036854775809")
  inspect!(0UL - 1UL, content="18446744073709551615")
  inspect!(9223372036854775808UL * 2UL, content="0")
  inspect!(0x8000000000000000UL / 2UL, content="4611686018427387904")
  inspect!(18446744073709551615UL % 17UL, content="0")
  inspect!(0xFFFFFFFFUL & 0xFFFFUL, content="65535")
  inspect!(0xFF00UL | 0xFFUL, content="65535")
  inspect!(0xFFFF00UL ^ 0xFF00FFUL, content="65535")
  inspect!(0x1UL << 63, content="9223372036854775808")
  inspect!(9223372036854775808UL >> 63, content="1")
}

test "from double to" {
  inspect!(10.0.reinterpret_as_int64(), content="4621819117588971520")
  inspect!(10.0.reinterpret_as_uint64(), content="4621819117588971520")
  inspect!(20.0.reinterpret_as_int64(), content="4626322717216342016")
  inspect!(20.0.reinterpret_as_uint64(), content="4626322717216342016")
}

test "u64 to double" {
  inspect!(10UL.to_double(), content="10")
  inspect!(20UL.to_double(), content="20")
  inspect!(0UL.to_double(), content="0")
  inspect!(10L.to_double(), content="10")
  inspect!(20L.to_double(), content="20")
  inspect!(0L.to_double(), content="0")
  inspect!(18446744073709551615UL.to_double(), content="18446744073709552000")
  inspect!(8446744073709551615UL.to_double(), content="8446744073709552000")
  inspect!(8446744073709551615L.to_double(), content="8446744073709552000")
  inspect!(-8446744073709551615L.to_double(), content="-8446744073709552000")
  inspect!(844674400955615UL.to_double(), content="844674400955615")
  inspect!(844674400955615L.to_double(), content="844674400955615")
  inspect!(-844674400955615L.to_double(), content="-844674400955615")
}

test "UInt64::lnot test cases" {
  // Test case 1: Boundary case, testing the behavior with the maximum value of UInt64
  inspect!(UInt64::lnot(@uint64.max_value), content="0")

  // Test case 2: Boundary case, testing the behavior with the minimum value of UInt64
  inspect!(UInt64::lnot(@uint64.min_value), content="18446744073709551615")

  // Test case 3: Random case, testing with a random large value
  inspect!(UInt64::lnot(12345678901234567890UL), content="6101065172474983725")

  // Test case 4: Random case, testing with a random small value
  inspect!(UInt64::lnot(42UL), content="18446744073709551573")

  // Test case 5: Random case, testing with a value that has 1s in some bits
  inspect!(UInt64::lnot(0xAAAAAAAAAAAAAAAAUL), content="6148914691236517205")

  // Test case 6: Random case, testing with a value that has 0s in some bits
  inspect!(UInt64::lnot(0x5555555555555555UL), content="12297829382473034410")

  // Test case 7: Random case, testing with a value that has a mix of 1s and 0s
  inspect!(UInt64::lnot(0x123456789ABCDEF0UL), content="17134975606245761295")

  // Test case 8: Random case, testing with a value that has all 1s
  inspect!(UInt64::lnot(0xFFFFFFFFFFFFFFFFUL), content="0")
}

test "shift" {
  inspect!(1 << 2, content="4")
  inspect!(1UL << 2, content="4")
  // right shift
  inspect!(4 >> 2, content="1")
  inspect!(4UL >> 2, content="1")
  inspect!(2 >> 2, content="0")
  inspect!(-2 >> 2, content="-1")
  inspect!(2UL >> 2, content="0")
}

test "float" {
  fn f(x : Float) -> Float {
    x
  }

  inspect!(f(5.3) == 2.0, content="false")
  inspect!(f(5.3) + 2.0 == 7.3, content="true")
  inspect!((f(3.14) + 2.17).to_double(), content="5.310000419616699")
  inspect!((f(5.3) - 2.0).to_double(), content="3.3000001907348633")
  inspect!((f(2.0) - 5.3).to_double(), content="-3.3000001907348633")
  inspect!((f(5.3) - 5.3).to_double(), content="0")
  inspect!((f(5.3) * 2.0).to_double(), content="10.600000381469727")
  inspect!((f(-5.3) * 2.0).to_double(), content="-10.600000381469727")
  inspect!((f(-5.3) * -2.0).to_double(), content="10.600000381469727")
  inspect!((f(5.3) * -2.0).to_double(), content="-10.600000381469727")
  inspect!((f(5.3) / 2.0).to_double(), content="2.6500000953674316")
  inspect!((f(2.0) / 5.3).to_double(), content="0.37735846638679504")
  inspect!((f(2.12345) / 2.12345).to_double(), content="1")
  inspect!((f(2.12345) / -2.12345).to_double(), content="-1")
  inspect!((f(0) / 2.12345).to_double(), content="0")
  inspect!((3.6 : Float) != 0.6, content="true")
  inspect!((3.6 : Float).compare(0.6), content="1")
  inspect!((0.3 : Float).compare(0.6), content="-1")
  inspect!((0.3 : Float).compare(-0.6), content="1")
  inspect!((-0.3 : Float).compare(-0.6), content="1")
  inspect!((0.3 : Float).to_double() == 0.3, content="false")
  inspect!((0.3 : Float).reinterpret_as_int(), content="1050253722")
  inspect!(b'5'.to_float().to_double(), content="53")
  inspect!((123456).to_float().to_double(), content="123456")
  // inspect!((0.36 : Float).sqrt().to_double(), content="0.6000000238418579")
}

test "Int::to_double" {
  inspect!((10).to_double(), content="10")
  inspect!((20).to_double(), content="20")
}

test "Int::clz" {
  // Test for the smallest positive integer
  inspect!(Int::clz(1), content="31")

  // Test for the largest positive integer
  inspect!(Int::clz(2147483647), content="1")

  // Test for zero, which is an edge case
  inspect!(Int::clz(0), content="32")

  // Test for the smallest negative integer
  inspect!(Int::clz(-2147483648), content="0")

  // Test for the largest negative integer
  inspect!(Int::clz(-1), content="0")
  // Random cases to cover various scenarios
  inspect!(Int::clz(123456), content="15")
  inspect!(Int::clz(987654), content="12")
  inspect!(Int::clz(54321), content="16")
  inspect!(Int::clz(123456789), content="5")
  inspect!(Int::clz(987654321), content="2")
  inspect!(Int::clz(1024), content="21")
  inspect!(Int::clz(65536), content="15")
  inspect!(Int::clz(32768), content="16")
  inspect!(Int::clz(16384), content="17")
  inspect!(Int::clz(8192), content="18")
}

test "grouped test for boundary cases" {
  inspect!(UInt::clz(0x00000000U), content="32")
  inspect!(UInt::clz(0x80000000U), content="0")
  inspect!(UInt::clz(0x40000000U), content="1")
  inspect!(UInt::clz(0x20000000U), content="2")
  inspect!(UInt::clz(0x10000000U), content="3")
}

test "grouped test for random cases" {
  inspect!(UInt::clz(0x12345678U), content="3")
  inspect!(UInt::clz(0x87654321U), content="0")
  inspect!(UInt::clz(0xABCDEF01U), content="0")
  inspect!(UInt::clz(0x0FEDCBA9U), content="4")
  inspect!(UInt::clz(0x0000FFFFU), content="16")
  inspect!(UInt::clz(0xFFFF0000U), content="0")
}

test "grouped test for edge and random cases" {
  inspect!(UInt::clz(0x00000001U), content="31")
  inspect!(UInt::clz(0x00000002U), content="30")
  inspect!(UInt::clz(0x00000004U), content="29")
  inspect!(UInt::clz(0x00000008U), content="28")
  inspect!(UInt::clz(0x00000010U), content="27")
  inspect!(UInt::clz(0x00000020U), content="26")
  inspect!(UInt::clz(0x00000040U), content="25")
  inspect!(UInt::clz(0x00000080U), content="24")
  inspect!(UInt::clz(0x00000100U), content="23")
  inspect!(UInt::clz(0x00000200U), content="22")
  inspect!(UInt::clz(0x00000400U), content="21")
  inspect!(UInt::clz(0x00000800U), content="20")
  inspect!(UInt::clz(0x00001000U), content="19")
  inspect!(UInt::clz(0x00002000U), content="18")
  inspect!(UInt::clz(0x00004000U), content="17")
  inspect!(UInt::clz(0x00008000U), content="16")
  inspect!(UInt::clz(0x00010000U), content="15")
  inspect!(UInt::clz(0x00020000U), content="14")
  inspect!(UInt::clz(0x00040000U), content="13")
  inspect!(UInt::clz(0x00080000U), content="12")
  inspect!(UInt::clz(0x00100000U), content="11")
  inspect!(UInt::clz(0x00200000U), content="10")
  inspect!(UInt::clz(0x00400000U), content="9")
  inspect!(UInt::clz(0x00800000U), content="8")
  inspect!(UInt::clz(0x01000000U), content="7")
  inspect!(UInt::clz(0x02000000U), content="6")
  inspect!(UInt::clz(0x04000000U), content="5")
  inspect!(UInt::clz(0x08000000U), content="4")
  inspect!(UInt::clz(0x10000000U), content="3")
  inspect!(UInt::clz(0x20000000U), content="2")
  inspect!(UInt::clz(0x40000000U), content="1")
  inspect!(UInt::clz(0x80000000U), content="0")
}

test "grouped test for boundary cases" {
  // Test for the smallest positive normal float
  inspect!(Float::reinterpret_as_uint(1.17549435e-38), content="8388608")

  // Test for the largest positive normal float
  inspect!(Float::reinterpret_as_uint(3.40282347e+38), content="2139095039")

  // Test for the smallest positive subnormal float
  inspect!(Float::reinterpret_as_uint(1.40129846e-45), content="1")

  // Test for the largest positive subnormal float
  inspect!(Float::reinterpret_as_uint(1.17549421e-38), content="8388607")

  // Test for zero
  inspect!(Float::reinterpret_as_uint(0.0), content="0")

  // Test for negative zero
  inspect!(Float::reinterpret_as_uint(-0.0), content="2147483648")

  // Test for positive infinity
  inspect!(
    Float::reinterpret_as_uint((0x7F800000).reinterpret_as_float()),
    content="2139095040",
  )

  // Test for negative infinity
  inspect!(
    Float::reinterpret_as_uint((0xFF800000).reinterpret_as_float()),
    content="4286578688",
  )

  // Test for NaN
  inspect!(
    Float::reinterpret_as_uint((0x7FC00000).reinterpret_as_float()),
    content="2143289344",
  )
}

test "grouped test for random cases" {
  // Random float values
  inspect!(Float::reinterpret_as_uint(123.456), content="1123477881")
  inspect!(Float::reinterpret_as_uint(-123.456), content="3270961529")
  inspect!(Float::reinterpret_as_uint(0.000123), content="956365200")
  inspect!(Float::reinterpret_as_uint(-0.000123), content="3103848848")
  inspect!(Float::reinterpret_as_uint(987654321.0), content="1315666339")
  inspect!(Float::reinterpret_as_uint(-987654321.0), content="3463149987")
  inspect!(Float::reinterpret_as_uint(1.0e+30), content="1900671690")
  inspect!(Float::reinterpret_as_uint(-1.0e+30), content="4048155338")
}

test "Char::to_uint - Boundary Cases" {
  // Test for the boundary values of Char
  inspect!(Char::to_uint('\u{0}'), content="0")
  inspect!(Char::to_uint('\u{FFFF}'), content="65535")
}

test "Char::to_uint - Random Cases" {
  // Test for some random values of Char
  inspect!(Char::to_uint('a'), content="97")
  inspect!(Char::to_uint('A'), content="65")
  inspect!(Char::to_uint('1'), content="49")
  inspect!(Char::to_uint('!'), content="33")
  inspect!(Char::to_uint(' '), content="32")
  inspect!(Char::to_uint('中'), content="20013")
}

test "Char::to_uint - Edge Cases" {
  // Test for some edge cases
  inspect!(Char::to_uint('\u{0001}'), content="1")
  inspect!(Char::to_uint('\u{00FF}'), content="255")
  inspect!(Char::to_uint('\u{0100}'), content="256")
  inspect!(Char::to_uint('\u{FFFE}'), content="65534")
}

test "Char::to_uint - Special Characters" {
  // Test for special characters
  inspect!(Char::to_uint('\n'), content="10")
  inspect!(Char::to_uint('\t'), content="9")
  inspect!(Char::to_uint('\r'), content="13")
  inspect!(Char::to_uint('\\'), content="92")
  inspect!(Char::to_uint('\''), content="39")
}

test "Char::to_uint - Unicode Characters" {
  // Test for some Unicode characters
  inspect!(Char::to_uint('😀'), content="128512")
  inspect!(Char::to_uint('🌍'), content="127757")
  inspect!(Char::to_uint('⚡'), content="9889")
  inspect!(Char::to_uint('♫'), content="9835")
}

test "Int::to_uint64 - Boundary Cases" {
  inspect!(Int::to_uint64(0), content="0")
  inspect!(Int::to_uint64(1), content="1")
  inspect!(Int::to_uint64(-1), content="18446744073709551615")
  inspect!(Int::to_uint64(2147483647), content="2147483647")
  inspect!(Int::to_uint64(-2147483648), content="18446744071562067968")
}

test "Int::to_uint64 - Random Cases" {
  inspect!(Int::to_uint64(123456789), content="123456789")
  inspect!(Int::to_uint64(-987654321), content="18446744072721897295")
  inspect!(Int::to_uint64(987654321), content="987654321")
  inspect!(Int::to_uint64(-123456789), content="18446744073586094827")
}

test "Int::to_uint64 - Edge Cases with Zero" {
  inspect!(Int::to_uint64(0), content="0")
  inspect!(Int::to_uint64(-0), content="0")
}

test "Int::to_uint64 - Random Values" {
  inspect!(Int::to_uint64(1234567890), content="1234567890")
  inspect!(Int::to_uint64(-1234567890), content="18446744072474983726")
}

test "UInt::reinterpret_as_float roundtrip" {
  let values = [
    0x00000000U, // zero
     0x80000000U, // negative zero
     0x3F800000U, // 1.0
     0xBF800000U, // -1.0
     0x7F800000U, // positive infinity
     0xFF800000U, // negative infinity
     0x7FC00000U, // NaN
     0x00800000U, // smallest positive normal float
     0x7F7FFFFFU, // largest positive normal float
     0x00000001U, // smallest positive subnormal float
     0x007FFFFFU, // largest positive subnormal float
  ]
  for value in values {
    let float_value = value.reinterpret_as_float()
    let roundtrip_value = Float::reinterpret_as_uint(float_value)
    assert_eq!(roundtrip_value, value)
  }
}
