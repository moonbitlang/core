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

test "Basic" {
  assert_eq!(@ryu.ryu_to_string(0.0), "0")
  assert_eq!(@ryu.ryu_to_string(-0.0), "0")
  assert_eq!(@ryu.ryu_to_string(1.e0), "1")
  assert_eq!(@ryu.ryu_to_string(-1.e0), "-1")
  assert_eq!(@ryu.ryu_to_string(0.0 / 0.0), "NaN")
  assert_eq!(@ryu.ryu_to_string(1.0 / 0.0), "Infinity")
  assert_eq!(@ryu.ryu_to_string(-1.0 / 0.0), "-Infinity")
  assert_eq!(@ryu.ryu_to_string(3.1415926), "3.1415926")
  assert_eq!(@ryu.ryu_to_string(1234000000000000.0), "1234000000000000")
}

test "Switch to Subnormal" {
  assert_eq!(
    @ryu.ryu_to_string(2.2250738585072014e-308),
    "2.2250738585072014e-308",
  )
  assert_eq!(
    @ryu.ryu_to_string(0x0010000000000000L.reinterpret_as_double()),
    "2.2250738585072014e-308",
  )
}

test "Min and Max" {
  assert_eq!(
    @ryu.ryu_to_string(0x7FEF_FFFF_FFFF_FFFFL.reinterpret_as_double()),
    "1.7976931348623157e+308",
  )
  assert_eq!(@ryu.ryu_to_string(1L.reinterpret_as_double()), "5e-324")
}

test "Lots of Trailing Zeros" {
  assert_eq!(
    @ryu.ryu_to_string(2.98023223876953125e-8),
    "2.9802322387695312e-8",
  )
}

test "Regression" {
  assert_eq!(@ryu.ryu_to_string(-2.109808898695963e16), "-21098088986959630")
  assert_eq!(@ryu.ryu_to_string(4.940656e-318), "4.940656e-318")
  assert_eq!(@ryu.ryu_to_string(1.18575755e-316), "1.18575755e-316")
  assert_eq!(@ryu.ryu_to_string(2.989102097996e-312), "2.989102097996e-312")
  assert_eq!(@ryu.ryu_to_string(9.0608011534336e15), "9060801153433600")
  assert_eq!(@ryu.ryu_to_string(4.708356024711512e18), "4708356024711512000")
  assert_eq!(@ryu.ryu_to_string(9.409340012568248e18), "9409340012568248000")
  assert_eq!(@ryu.ryu_to_string(1.2345678), "1.2345678")
  assert_eq!(
    @ryu.ryu_to_string(1.8531501765868567e21),
    "1.8531501765868567e+21",
  )
  assert_eq!(
    @ryu.ryu_to_string(-3.347727380279489e33),
    "-3.347727380279489e+33",
  )
  assert_eq!(@ryu.ryu_to_string(1.9430376160308388e16), "19430376160308388")
  assert_eq!(
    @ryu.ryu_to_string(-6.9741824662760956e19),
    "-69741824662760956000",
  )
  assert_eq!(@ryu.ryu_to_string(4.3816050601147837e18), "4381605060114783700")
}

test "Looks Like Pow5" {
  assert_eq!(
    @ryu.ryu_to_string(0x4830F0CF064DD592L.reinterpret_as_double()),
    "5.764607523034235e+39",
  )
  assert_eq!(
    @ryu.ryu_to_string(0x4840F0CF064DD592L.reinterpret_as_double()),
    "1.152921504606847e+40",
  )
  assert_eq!(
    @ryu.ryu_to_string(0x4850F0CF064DD592L.reinterpret_as_double()),
    "2.305843009213694e+40",
  )
}

test "Output Length" {
  assert_eq!(@ryu.ryu_to_string(1.0), "1")
  assert_eq!(@ryu.ryu_to_string(1.2), "1.2")
  assert_eq!(@ryu.ryu_to_string(1.23), "1.23")
  assert_eq!(@ryu.ryu_to_string(1.234), "1.234")
  assert_eq!(@ryu.ryu_to_string(1.2345), "1.2345")
  assert_eq!(@ryu.ryu_to_string(1.23456), "1.23456")
  assert_eq!(@ryu.ryu_to_string(1.234567), "1.234567")
  assert_eq!(@ryu.ryu_to_string(1.2345678), "1.2345678")
  assert_eq!(@ryu.ryu_to_string(1.23456789), "1.23456789")
  assert_eq!(@ryu.ryu_to_string(1.234567895), "1.234567895")
  assert_eq!(@ryu.ryu_to_string(1.2345678901), "1.2345678901")
  assert_eq!(@ryu.ryu_to_string(1.23456789012), "1.23456789012")
  assert_eq!(@ryu.ryu_to_string(1.234567890123), "1.234567890123")
  assert_eq!(@ryu.ryu_to_string(1.2345678901234), "1.2345678901234")
  assert_eq!(@ryu.ryu_to_string(1.23456789012345), "1.23456789012345")
  assert_eq!(@ryu.ryu_to_string(1.234567890123456), "1.234567890123456")
  assert_eq!(@ryu.ryu_to_string(1.2345678901234567), "1.2345678901234567")
}

test "32-bit chunking" {
  assert_eq!(@ryu.ryu_to_string(4.294967294), "4.294967294")
  assert_eq!(@ryu.ryu_to_string(4.294967295), "4.294967295")
  assert_eq!(@ryu.ryu_to_string(4.294967296), "4.294967296")
  assert_eq!(@ryu.ryu_to_string(4.294967297), "4.294967297")
  assert_eq!(@ryu.ryu_to_string(4.294967298), "4.294967298")
}

test "Min Max Shift" {
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 4, 0L)),
    "1.7800590868057611e-307",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 6, 0x0010000000000000L)),
    "1.424047269444609e-306",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 41, 0L)),
    "2.446494580089078e-296",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 40, 0x0010000000000000L)),
    "2.446494580089078e-296",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 1077, 0L)),
    "18014398509481984",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 1076, 0x0010000000000000L)),
    "18014398509481984",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 307, 0L)),
    "2.900835519859558e-216",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 306, 0x0010000000000000L)),
    "2.900835519859558e-216",
  )
  assert_eq!(
    @ryu.ryu_to_string(ieee_parts_to_double(false, 934, 0x000FA7161A4D6E0CL)),
    "3.196104012172126e-27",
  )
}

test "Small Integers" {
  // 2^53-1
  assert_eq!(@ryu.ryu_to_string(9007199254740991.0), "9007199254740991")
  // 2^53
  assert_eq!(@ryu.ryu_to_string(9007199254740992.0), "9007199254740992")
  assert_eq!(@ryu.ryu_to_string(1.0e+0), "1")
  assert_eq!(@ryu.ryu_to_string(1.2e+1), "12")
  assert_eq!(@ryu.ryu_to_string(1.23e+2), "123")
  assert_eq!(@ryu.ryu_to_string(1.234e+3), "1234")
  assert_eq!(@ryu.ryu_to_string(1.2345e+4), "12345")
  assert_eq!(@ryu.ryu_to_string(1.23456e+5), "123456")
  assert_eq!(@ryu.ryu_to_string(1.234567e+6), "1234567")
  assert_eq!(@ryu.ryu_to_string(1.2345678e+7), "12345678")
  assert_eq!(@ryu.ryu_to_string(1.23456789e+8), "123456789")
  assert_eq!(@ryu.ryu_to_string(1.23456789e+9), "1234567890")
  assert_eq!(@ryu.ryu_to_string(1.234567895e+9), "1234567895")
  assert_eq!(@ryu.ryu_to_string(1.2345678901e+10), "12345678901")
  assert_eq!(@ryu.ryu_to_string(1.23456789012e+11), "123456789012")
  assert_eq!(@ryu.ryu_to_string(1.234567890123e+12), "1234567890123")
  assert_eq!(@ryu.ryu_to_string(1.2345678901234e+13), "12345678901234")
  assert_eq!(@ryu.ryu_to_string(1.23456789012345e+14), "123456789012345")
  assert_eq!(@ryu.ryu_to_string(1.234567890123456e+15), "1234567890123456")
}

test "10^i" {
  assert_eq!(@ryu.ryu_to_string(1.0e-15), "1e-15")
  assert_eq!(@ryu.ryu_to_string(1.0e-14), "1e-14")
  assert_eq!(@ryu.ryu_to_string(1.0e-13), "1e-13")
  assert_eq!(@ryu.ryu_to_string(1.0e-12), "1e-12")
  assert_eq!(@ryu.ryu_to_string(1.0e-11), "1e-11")
  assert_eq!(@ryu.ryu_to_string(1.0e-10), "1e-10")
  assert_eq!(@ryu.ryu_to_string(1.0e-9), "1e-9")
  assert_eq!(@ryu.ryu_to_string(1.0e-8), "1e-8")
  assert_eq!(@ryu.ryu_to_string(1.0e-7), "1e-7")
  assert_eq!(@ryu.ryu_to_string(1.0e-6), "0.000001")
  assert_eq!(@ryu.ryu_to_string(1.0e-5), "0.00001")
  assert_eq!(@ryu.ryu_to_string(1.0e-4), "0.0001")
  assert_eq!(@ryu.ryu_to_string(1.0e-3), "0.001")
  assert_eq!(@ryu.ryu_to_string(1.0e-2), "0.01")
  assert_eq!(@ryu.ryu_to_string(1.0e-1), "0.1")
  assert_eq!(@ryu.ryu_to_string(1.0e+0), "1")
  assert_eq!(@ryu.ryu_to_string(1.0e+1), "10")
  assert_eq!(@ryu.ryu_to_string(1.0e+2), "100")
  assert_eq!(@ryu.ryu_to_string(1.0e+3), "1000")
  assert_eq!(@ryu.ryu_to_string(1.0e+4), "10000")
  assert_eq!(@ryu.ryu_to_string(1.0e+5), "100000")
  assert_eq!(@ryu.ryu_to_string(1.0e+6), "1000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+7), "10000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+8), "100000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+9), "1000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+10), "10000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+11), "100000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+12), "1000000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+13), "10000000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+14), "100000000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15), "1000000000000000")
}

test "10^15 + 10^i" {
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+0), "1000000000000001")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+1), "1000000000000010")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+2), "1000000000000100")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+3), "1000000000001000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+4), "1000000000010000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+5), "1000000000100000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+6), "1000000001000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+7), "1000000010000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+8), "1000000100000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+9), "1000001000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+10), "1000010000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+11), "1000100000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+12), "1001000000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+13), "1010000000000000")
  assert_eq!(@ryu.ryu_to_string(1.0e+15 + 1.0e+14), "1100000000000000")
}

test "Largest power of 2 <= 10^(i+1)" {
  assert_eq!(@ryu.ryu_to_string(8.0), "8")
  assert_eq!(@ryu.ryu_to_string(64.0), "64")
  assert_eq!(@ryu.ryu_to_string(512.0), "512")
  assert_eq!(@ryu.ryu_to_string(8192.0), "8192")
  assert_eq!(@ryu.ryu_to_string(65536.0), "65536")
  assert_eq!(@ryu.ryu_to_string(524288.0), "524288")
  assert_eq!(@ryu.ryu_to_string(8388608.0), "8388608")
  assert_eq!(@ryu.ryu_to_string(67108864.0), "67108864")
  assert_eq!(@ryu.ryu_to_string(536870912.0), "536870912")
  assert_eq!(@ryu.ryu_to_string(8589934592.0), "8589934592")
  assert_eq!(@ryu.ryu_to_string(68719476736.0), "68719476736")
  assert_eq!(@ryu.ryu_to_string(549755813888.0), "549755813888")
  assert_eq!(@ryu.ryu_to_string(8796093022208.0), "8796093022208")
  assert_eq!(@ryu.ryu_to_string(70368744177664.0), "70368744177664")
  assert_eq!(@ryu.ryu_to_string(562949953421312.0), "562949953421312")
  assert_eq!(@ryu.ryu_to_string(9007199254740992.0), "9007199254740992")
}

test "1000 * (Largest power of 2 <= 10^(i+1))" {
  assert_eq!(@ryu.ryu_to_string(8.0e+3), "8000")
  assert_eq!(@ryu.ryu_to_string(64.0e+3), "64000")
  assert_eq!(@ryu.ryu_to_string(512.0e+3), "512000")
  assert_eq!(@ryu.ryu_to_string(8192.0e+3), "8192000")
  assert_eq!(@ryu.ryu_to_string(65536.0e+3), "65536000")
  assert_eq!(@ryu.ryu_to_string(524288.0e+3), "524288000")
  assert_eq!(@ryu.ryu_to_string(8388608.0e+3), "8388608000")
  assert_eq!(@ryu.ryu_to_string(67108864.0e+3), "67108864000")
  assert_eq!(@ryu.ryu_to_string(536870912.0e+3), "536870912000")
  assert_eq!(@ryu.ryu_to_string(8589934592.0e+3), "8589934592000")
  assert_eq!(@ryu.ryu_to_string(68719476736.0e+3), "68719476736000")
  assert_eq!(@ryu.ryu_to_string(549755813888.0e+3), "549755813888000")
  assert_eq!(@ryu.ryu_to_string(8796093022208.0e+3), "8796093022208000")
}

test "boundary conditions" {
  // x = 1.0e7
  assert_eq!(@ryu.ryu_to_string(1.0e7), "10000000")
  // x < 1.0e7
  assert_eq!(@ryu.ryu_to_string(9999999.999999998), "9999999.999999998")
  // x = 1.0e-3
  assert_eq!(@ryu.ryu_to_string(0.001), "0.001")
  // x < 1.0e-3
  assert_eq!(@ryu.ryu_to_string(0.0009999999999999998), "0.0009999999999999998")
}

///|
// For testing purposes
fn ieee_parts_to_double(
  sign : Bool,
  ieeeExponent : Int,
  ieeeMantissa : Int64
) -> Double {
  ((sign.to_int64() << 63) | (ieeeExponent.to_int64() << 52) | ieeeMantissa).reinterpret_as_double()
}

test "double/ryu.mbt:90" {
  let value = 100L
  assert_eq!(value % 25L, 0L)
  assert_not_eq!(value % 125L, 0L)
}

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
  assert_eq!(vrIsTrailingZeros, true)
  assert_eq!(vmIsTrailingZeros, true)
  assert_eq!(vp, 10L)
}

test "double/ryu.mbt:90" {
  let value = 100L
  assert_eq!(value % 25L, 0L)
  assert_not_eq!(value % 125L, 0L)
}

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
  assert_eq!(vrIsTrailingZeros, true)
  assert_eq!(vmIsTrailingZeros, true)
  assert_eq!(vp, 10L)
}
