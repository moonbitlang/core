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
  inspect!(a.land(b), content="1")
  inspect!((0xffff_ffff).land(0xa000_0000) == 0xa000_0000, content="true")
  inspect!((0xffff_ffff).land(0x0) == 0, content="true")
  inspect!((0xffff_ffff).land(0xffff_ffff) == 0xffff_ffff, content="true")
}

/// test Int::lor
test "Int::lor should perform bitwise OR operation" {
  inspect!((0b101).lor(0b011) == 0b111, content="true")
  inspect!((0xffff_ffff).lor(0xa000_0000) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff).lor(0x0) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff).lor(0xffff_ffff) == 0xffff_ffff, content="true")
}

/// test Int::lxor
test "Int::lxor should perform bitwise XOR operation" {
  inspect!((0b101).lxor(0b011) == 0b110, content="true")
  inspect!((0xffff_ffff).lxor(0xa000_0000) == 0x5fff_ffff, content="true")
  inspect!((0xffff_ffff).lxor(0x0) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff).lxor(0xffff_ffff) == 0, content="true")
}

/// test Int::lsl
test "Int::lsl should perform left shift operation" {
  inspect!((7).lsl(1), content="14")
  inspect!((0b101).lsl(1) == 0b1010, content="true")
  inspect!((0xffff_ffff).lsl(1) == 0xffff_fffe, content="true")
  inspect!((0xffff_ffff).lsl(0) == 0xffff_ffff, content="true")
  inspect!((0xffff_ffff).lsl(3), content="-8")
  let arr = Array::make(33, 0).mapi(fn { i, _ => i })
  inspect!(
    arr,
    content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32]",
  )
  let r = arr.map(fn { i => (0xffff_ffff).lsl(i) })
  // note when shifting 32 bits or more, it returns the original value
  inspect!(
    r,
    content="[-1, -2, -4, -8, -16, -32, -64, -128, -256, -512, -1024, -2048, -4096, -8192, -16384, -32768, -65536, -131072, -262144, -524288, -1048576, -2097152, -4194304, -8388608, -16777216, -33554432, -67108864, -134217728, -268435456, -536870912, -1073741824, -2147483648, -1]",
  )
  inspect!((7).lsl(32), content="7")
}

test "uint test" {
  inspect!(100U == 100U, content="true")
  inspect!(0U < 100U, content="true")
  inspect!(100U > 0U, content="true")
  inspect!(2147483648U.to_int(), content="-2147483648")
  inspect!((-2147483648).to_uint(), content="2147483648")
  inspect!((2147483648U + 1000000000U).to_uint64(), content="3147483648")
  inspect!(2147483647U + 1U, content="2147483648")
  inspect!(0U - 1U, content="4294967295")
  inspect!(2147483647U * 2U, content="4294967294")
  inspect!(0x80000000U / 2U, content="1073741824")
  inspect!(4294967295U % 17U, content="0")
  inspect!(0xFFFFFFFFU.land(0xFFFFU), content="65535")
  inspect!(0xFF00U.lor(0xFFU), content="65535")
  inspect!(0xFFFF00U.lxor(0xFF00FFU), content="65535")
  inspect!(0x1U.lsl(31), content="2147483648")
  inspect!(2147483648U.lsr(31), content="1")
  // to_byte
  let u = 0xDEADBEEFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xEF'")
  let u = 0x87654321U
  let b = u.to_byte()
  inspect!(b, content="b'\\x21'")
  let u = 0xFFFFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xFF'")
  let u = 0xFFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xFF'")
  let u = 0x12345678U
  let b = u.to_byte()
  inspect!(b, content="b'\\x78'")
  let u = 0U
  let b = u.to_byte()
  inspect!(b, content="b'\\x00'")
}

test "uint64 test" {
  inspect!(100UL == 100UL, content="true")
  inspect!(0UL < 100UL, content="true")
  inspect!(100UL > 0UL, content="true")
  inspect!(9223372036854775808UL.to_int64(), content="-9223372036854775808")
  inspect!((-9223372036854775808L).to_uint64(), content="9223372036854775808")
  inspect!((9223372036854775808UL + 1UL).to_uint(), content="1")
  inspect!((9223372036854775808UL + 1UL).to_int(), content="1")
  inspect!(9223372036854775808UL + 1UL, content="9223372036854775809")
  inspect!(0UL - 1UL, content="18446744073709551615")
  inspect!(9223372036854775808UL * 2UL, content="0")
  inspect!(0x8000000000000000UL / 2UL, content="4611686018427387904")
  inspect!(18446744073709551615UL % 17UL, content="0")
  inspect!(0xFFFFFFFFUL.land(0xFFFFUL), content="65535")
  inspect!(0xFF00UL.lor(0xFFUL), content="65535")
  inspect!(0xFFFF00UL.lxor(0xFF00FFUL), content="65535")
  inspect!(0x1UL.lsl(63), content="9223372036854775808")
  inspect!(9223372036854775808UL.lsr(63), content="1")
}

test "to double" {
  inspect!(10.0.reinterpret_as_i64(), content="4621819117588971520")
  inspect!(10.0.reinterpret_as_u64(), content="4621819117588971520")
  inspect!(20.0.reinterpret_as_i64(), content="4626322717216342016")
  inspect!(20.0.reinterpret_as_u64(), content="4626322717216342016")
}
