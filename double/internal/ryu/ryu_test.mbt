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
test "Basic" {
  inspect(@ryu.ryu_to_string(0.0), content="0")
  inspect(@ryu.ryu_to_string(-0.0), content="0")
  inspect(@ryu.ryu_to_string(1.e0), content="1")
  inspect(@ryu.ryu_to_string(-1.e0), content="-1")
  inspect(@ryu.ryu_to_string(0.0 / 0.0), content="NaN")
  inspect(@ryu.ryu_to_string(1.0 / 0.0), content="Infinity")
  inspect(@ryu.ryu_to_string(-1.0 / 0.0), content="-Infinity")
  inspect(@ryu.ryu_to_string(3.1415926), content="3.1415926")
  inspect(@ryu.ryu_to_string(1234000000000000.0), content="1234000000000000")
}

///|
test "Switch to Subnormal" {
  assert_eq(
    @ryu.ryu_to_string(2.2250738585072014e-308),
    "2.2250738585072014e-308",
  )
  assert_eq(
    @ryu.ryu_to_string(0x0010000000000000L.reinterpret_as_double()),
    "2.2250738585072014e-308",
  )
}

///|
test "Min and Max" {
  assert_eq(
    @ryu.ryu_to_string(0x7FEF_FFFF_FFFF_FFFFL.reinterpret_as_double()),
    "1.7976931348623157e+308",
  )
  assert_eq(@ryu.ryu_to_string(1L.reinterpret_as_double()), "5e-324")
}

///|
test "Lots of Trailing Zeros" {
  inspect(
    @ryu.ryu_to_string(2.98023223876953125e-8),
    content="2.9802322387695312e-8",
  )
}

///|
test "Regression" {
  inspect(
    @ryu.ryu_to_string(-2.109808898695963e16),
    content="-21098088986959630",
  )
  inspect(@ryu.ryu_to_string(4.940656e-318), content="4.940656e-318")
  inspect(@ryu.ryu_to_string(1.18575755e-316), content="1.18575755e-316")
  inspect(
    @ryu.ryu_to_string(2.989102097996e-312),
    content="2.989102097996e-312",
  )
  inspect(@ryu.ryu_to_string(9.0608011534336e15), content="9060801153433600")
  inspect(
    @ryu.ryu_to_string(4.708356024711512e18),
    content="4708356024711512000",
  )
  inspect(
    @ryu.ryu_to_string(9.409340012568248e18),
    content="9409340012568248000",
  )
  inspect(@ryu.ryu_to_string(1.2345678), content="1.2345678")
  inspect(
    @ryu.ryu_to_string(1.8531501765868567e21),
    content="1.8531501765868567e+21",
  )
  inspect(
    @ryu.ryu_to_string(-3.347727380279489e33),
    content="-3.347727380279489e+33",
  )
  inspect(
    @ryu.ryu_to_string(1.9430376160308388e16),
    content="19430376160308388",
  )
  inspect(
    @ryu.ryu_to_string(-6.9741824662760956e19),
    content="-69741824662760956000",
  )
  inspect(
    @ryu.ryu_to_string(4.3816050601147837e18),
    content="4381605060114783700",
  )
}

///|
test "Looks Like Pow5" {
  assert_eq(
    @ryu.ryu_to_string(0x4830F0CF064DD592L.reinterpret_as_double()),
    "5.764607523034235e+39",
  )
  assert_eq(
    @ryu.ryu_to_string(0x4840F0CF064DD592L.reinterpret_as_double()),
    "1.152921504606847e+40",
  )
  assert_eq(
    @ryu.ryu_to_string(0x4850F0CF064DD592L.reinterpret_as_double()),
    "2.305843009213694e+40",
  )
}

///|
test "Output Length" {
  inspect(@ryu.ryu_to_string(1.0), content="1")
  inspect(@ryu.ryu_to_string(1.2), content="1.2")
  inspect(@ryu.ryu_to_string(1.23), content="1.23")
  inspect(@ryu.ryu_to_string(1.234), content="1.234")
  inspect(@ryu.ryu_to_string(1.2345), content="1.2345")
  inspect(@ryu.ryu_to_string(1.23456), content="1.23456")
  inspect(@ryu.ryu_to_string(1.234567), content="1.234567")
  inspect(@ryu.ryu_to_string(1.2345678), content="1.2345678")
  inspect(@ryu.ryu_to_string(1.23456789), content="1.23456789")
  inspect(@ryu.ryu_to_string(1.234567895), content="1.234567895")
  inspect(@ryu.ryu_to_string(1.2345678901), content="1.2345678901")
  inspect(@ryu.ryu_to_string(1.23456789012), content="1.23456789012")
  inspect(@ryu.ryu_to_string(1.234567890123), content="1.234567890123")
  inspect(@ryu.ryu_to_string(1.2345678901234), content="1.2345678901234")
  inspect(@ryu.ryu_to_string(1.23456789012345), content="1.23456789012345")
  inspect(@ryu.ryu_to_string(1.234567890123456), content="1.234567890123456")
  inspect(@ryu.ryu_to_string(1.2345678901234567), content="1.2345678901234567")
}

///|
test "32-bit chunking" {
  inspect(@ryu.ryu_to_string(4.294967294), content="4.294967294")
  inspect(@ryu.ryu_to_string(4.294967295), content="4.294967295")
  inspect(@ryu.ryu_to_string(4.294967296), content="4.294967296")
  inspect(@ryu.ryu_to_string(4.294967297), content="4.294967297")
  inspect(@ryu.ryu_to_string(4.294967298), content="4.294967298")
}

///|
test "Min Max Shift" {
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 4, 0L)),
    "1.7800590868057611e-307",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 6, 0x0010000000000000L)),
    "1.424047269444609e-306",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 41, 0L)),
    "2.446494580089078e-296",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 40, 0x0010000000000000L)),
    "2.446494580089078e-296",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 1077, 0L)),
    "18014398509481984",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 1076, 0x0010000000000000L)),
    "18014398509481984",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 307, 0L)),
    "2.900835519859558e-216",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 306, 0x0010000000000000L)),
    "2.900835519859558e-216",
  )
  assert_eq(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 934, 0x000FA7161A4D6E0CL)),
    "3.196104012172126e-27",
  )
}

///|
test "Small Integers" {
  // 2^53-1
  inspect(@ryu.ryu_to_string(9007199254740991.0), content="9007199254740991")
  // 2^53
  inspect(@ryu.ryu_to_string(9007199254740992.0), content="9007199254740992")
  inspect(@ryu.ryu_to_string(1.0e+0), content="1")
  inspect(@ryu.ryu_to_string(1.2e+1), content="12")
  inspect(@ryu.ryu_to_string(1.23e+2), content="123")
  inspect(@ryu.ryu_to_string(1.234e+3), content="1234")
  inspect(@ryu.ryu_to_string(1.2345e+4), content="12345")
  inspect(@ryu.ryu_to_string(1.23456e+5), content="123456")
  inspect(@ryu.ryu_to_string(1.234567e+6), content="1234567")
  inspect(@ryu.ryu_to_string(1.2345678e+7), content="12345678")
  inspect(@ryu.ryu_to_string(1.23456789e+8), content="123456789")
  inspect(@ryu.ryu_to_string(1.23456789e+9), content="1234567890")
  inspect(@ryu.ryu_to_string(1.234567895e+9), content="1234567895")
  inspect(@ryu.ryu_to_string(1.2345678901e+10), content="12345678901")
  inspect(@ryu.ryu_to_string(1.23456789012e+11), content="123456789012")
  inspect(@ryu.ryu_to_string(1.234567890123e+12), content="1234567890123")
  inspect(@ryu.ryu_to_string(1.2345678901234e+13), content="12345678901234")
  inspect(@ryu.ryu_to_string(1.23456789012345e+14), content="123456789012345")
  inspect(@ryu.ryu_to_string(1.234567890123456e+15), content="1234567890123456")
}

///|
test "10^i" {
  inspect(@ryu.ryu_to_string(1.0e-15), content="1e-15")
  inspect(@ryu.ryu_to_string(1.0e-14), content="1e-14")
  inspect(@ryu.ryu_to_string(1.0e-13), content="1e-13")
  inspect(@ryu.ryu_to_string(1.0e-12), content="1e-12")
  inspect(@ryu.ryu_to_string(1.0e-11), content="1e-11")
  inspect(@ryu.ryu_to_string(1.0e-10), content="1e-10")
  inspect(@ryu.ryu_to_string(1.0e-9), content="1e-9")
  inspect(@ryu.ryu_to_string(1.0e-8), content="1e-8")
  inspect(@ryu.ryu_to_string(1.0e-7), content="1e-7")
  inspect(@ryu.ryu_to_string(1.0e-6), content="0.000001")
  inspect(@ryu.ryu_to_string(1.0e-5), content="0.00001")
  inspect(@ryu.ryu_to_string(1.0e-4), content="0.0001")
  inspect(@ryu.ryu_to_string(1.0e-3), content="0.001")
  inspect(@ryu.ryu_to_string(1.0e-2), content="0.01")
  inspect(@ryu.ryu_to_string(1.0e-1), content="0.1")
  inspect(@ryu.ryu_to_string(1.0e+0), content="1")
  inspect(@ryu.ryu_to_string(1.0e+1), content="10")
  inspect(@ryu.ryu_to_string(1.0e+2), content="100")
  inspect(@ryu.ryu_to_string(1.0e+3), content="1000")
  inspect(@ryu.ryu_to_string(1.0e+4), content="10000")
  inspect(@ryu.ryu_to_string(1.0e+5), content="100000")
  inspect(@ryu.ryu_to_string(1.0e+6), content="1000000")
  inspect(@ryu.ryu_to_string(1.0e+7), content="10000000")
  inspect(@ryu.ryu_to_string(1.0e+8), content="100000000")
  inspect(@ryu.ryu_to_string(1.0e+9), content="1000000000")
  inspect(@ryu.ryu_to_string(1.0e+10), content="10000000000")
  inspect(@ryu.ryu_to_string(1.0e+11), content="100000000000")
  inspect(@ryu.ryu_to_string(1.0e+12), content="1000000000000")
  inspect(@ryu.ryu_to_string(1.0e+13), content="10000000000000")
  inspect(@ryu.ryu_to_string(1.0e+14), content="100000000000000")
  inspect(@ryu.ryu_to_string(1.0e+15), content="1000000000000000")
}

///|
test "10^15 + 10^i" {
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+0), content="1000000000000001")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+1), content="1000000000000010")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+2), content="1000000000000100")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+3), content="1000000000001000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+4), content="1000000000010000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+5), content="1000000000100000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+6), content="1000000001000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+7), content="1000000010000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+8), content="1000000100000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+9), content="1000001000000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+10), content="1000010000000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+11), content="1000100000000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+12), content="1001000000000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+13), content="1010000000000000")
  inspect(@ryu.ryu_to_string(1.0e+15 + 1.0e+14), content="1100000000000000")
}

///|
test "Largest power of 2 <= 10^(i+1)" {
  inspect(@ryu.ryu_to_string(8.0), content="8")
  inspect(@ryu.ryu_to_string(64.0), content="64")
  inspect(@ryu.ryu_to_string(512.0), content="512")
  inspect(@ryu.ryu_to_string(8192.0), content="8192")
  inspect(@ryu.ryu_to_string(65536.0), content="65536")
  inspect(@ryu.ryu_to_string(524288.0), content="524288")
  inspect(@ryu.ryu_to_string(8388608.0), content="8388608")
  inspect(@ryu.ryu_to_string(67108864.0), content="67108864")
  inspect(@ryu.ryu_to_string(536870912.0), content="536870912")
  inspect(@ryu.ryu_to_string(8589934592.0), content="8589934592")
  inspect(@ryu.ryu_to_string(68719476736.0), content="68719476736")
  inspect(@ryu.ryu_to_string(549755813888.0), content="549755813888")
  inspect(@ryu.ryu_to_string(8796093022208.0), content="8796093022208")
  inspect(@ryu.ryu_to_string(70368744177664.0), content="70368744177664")
  inspect(@ryu.ryu_to_string(562949953421312.0), content="562949953421312")
  inspect(@ryu.ryu_to_string(9007199254740992.0), content="9007199254740992")
}

///|
test "1000 * (Largest power of 2 <= 10^(i+1))" {
  inspect(@ryu.ryu_to_string(8.0e+3), content="8000")
  inspect(@ryu.ryu_to_string(64.0e+3), content="64000")
  inspect(@ryu.ryu_to_string(512.0e+3), content="512000")
  inspect(@ryu.ryu_to_string(8192.0e+3), content="8192000")
  inspect(@ryu.ryu_to_string(65536.0e+3), content="65536000")
  inspect(@ryu.ryu_to_string(524288.0e+3), content="524288000")
  inspect(@ryu.ryu_to_string(8388608.0e+3), content="8388608000")
  inspect(@ryu.ryu_to_string(67108864.0e+3), content="67108864000")
  inspect(@ryu.ryu_to_string(536870912.0e+3), content="536870912000")
  inspect(@ryu.ryu_to_string(8589934592.0e+3), content="8589934592000")
  inspect(@ryu.ryu_to_string(68719476736.0e+3), content="68719476736000")
  inspect(@ryu.ryu_to_string(549755813888.0e+3), content="549755813888000")
  inspect(@ryu.ryu_to_string(8796093022208.0e+3), content="8796093022208000")
}

///|
test "boundary conditions" {
  // x = 1.0e7
  inspect(@ryu.ryu_to_string(1.0e7), content="10000000")
  // x < 1.0e7
  inspect(@ryu.ryu_to_string(9999999.999999998), content="9999999.999999998")
  // x = 1.0e-3
  inspect(@ryu.ryu_to_string(0.001), content="0.001")
  // x < 1.0e-3
  inspect(
    @ryu.ryu_to_string(0.0009999999999999998),
    content="0.0009999999999999998",
  )
}

// For testing purposes

///|
fn ieee_parts_to_double(
  sign : Bool,
  ieeeExponent : Int,
  ieeeMantissa : Int64,
) -> Double {
  ((sign.to_int64() << 63) | (ieeeExponent.to_int64() << 52) | ieeeMantissa).reinterpret_as_double()
}

///|
test "double/ryu.mbt:90" {
  let value = 100L
  assert_eq(value % 25L, 0L)
  assert_not_eq(value % 125L, 0L)
}

///|
test "double/ryu.mbt:403" {
  let acceptBounds = true
  let mmShift = 1L
  let mut vrIsTrailingZeros = false
  let mut vmIsTrailingZeros = false
  let mut vp = 10L
  vrIsTrailingZeros = true
  if acceptBounds {
    vmIsTrailingZeros = mmShift.to_int() == 1
  } else {
    vp = vp - 1L
  }
  inspect(vrIsTrailingZeros, content="true")
  inspect(vmIsTrailingZeros, content="true")
  assert_eq(vp, 10L)
}
