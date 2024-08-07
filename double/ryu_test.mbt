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

test "Basic" {
  @test.eq!(@double.to_string(0.0), "0.0")
  @test.eq!(@double.to_string(-0.0), "-0.0")
  @test.eq!(@double.to_string(1.e0), "1.0")
  @test.eq!(@double.to_string(-1.e0), "-1.0")
  @test.eq!(@double.to_string(0.0 / 0.0), "NaN")
  @test.eq!(@double.to_string(1.0 / 0.0), "Infinity")
  @test.eq!(@double.to_string(-1.0 / 0.0), "-Infinity")
  @test.eq!(@double.to_string(3.1415926), "3.1415926")
}

test "Switch to Subnormal" {
  @test.eq!(
    @double.to_string(2.2250738585072014e-308),
    "2.2250738585072014e-308",
  )
  @test.eq!(
    @double.to_string(0x0010000000000000L.reinterpret_as_double()),
    "2.2250738585072014e-308",
  )
}

test "Min and Max" {
  @test.eq!(
    @double.to_string(0x7FEF_FFFF_FFFF_FFFFL.reinterpret_as_double()),
    "1.7976931348623157e308",
  )
  @test.eq!(@double.to_string(1L.reinterpret_as_double()), "5.0e-324")
}

test "Lots of Trailing Zeros" {
  @test.eq!(@double.to_string(2.98023223876953125e-8), "2.9802322387695312e-8")
}

test "Regression" {
  @test.eq!(@double.to_string(-2.109808898695963e16), "-2.109808898695963e16")
  @test.eq!(@double.to_string(4.940656e-318), "4.940656e-318")
  @test.eq!(@double.to_string(1.18575755e-316), "1.18575755e-316")
  @test.eq!(@double.to_string(2.989102097996e-312), "2.989102097996e-312")
  @test.eq!(@double.to_string(9.0608011534336e15), "9.0608011534336e15")
  @test.eq!(@double.to_string(4.708356024711512e18), "4.708356024711512e18")
  @test.eq!(@double.to_string(9.409340012568248e18), "9.409340012568248e18")
  @test.eq!(@double.to_string(1.2345678), "1.2345678")
  @test.eq!(@double.to_string(1.8531501765868567e21), "1.8531501765868567e21")
  @test.eq!(@double.to_string(-3.347727380279489e33), "-3.347727380279489e33")
  @test.eq!(@double.to_string(1.9430376160308388e16), "1.9430376160308388e16")
  @test.eq!(@double.to_string(-6.9741824662760956e19), "-6.9741824662760956e19")
  @test.eq!(@double.to_string(4.3816050601147837e18), "4.3816050601147837e18")
}

test "Looks Like Pow5" {
  @test.eq!(
    @double.to_string(0x4830F0CF064DD592L.reinterpret_as_double()),
    "5.764607523034235e39",
  )
  @test.eq!(
    @double.to_string(0x4840F0CF064DD592L.reinterpret_as_double()),
    "1.152921504606847e40",
  )
  @test.eq!(
    @double.to_string(0x4850F0CF064DD592L.reinterpret_as_double()),
    "2.305843009213694e40",
  )
}

test "Output Length" {
  @test.eq!(@double.to_string(1.0), "1.0")
  @test.eq!(@double.to_string(1.2), "1.2")
  @test.eq!(@double.to_string(1.23), "1.23")
  @test.eq!(@double.to_string(1.234), "1.234")
  @test.eq!(@double.to_string(1.2345), "1.2345")
  @test.eq!(@double.to_string(1.23456), "1.23456")
  @test.eq!(@double.to_string(1.234567), "1.234567")
  @test.eq!(@double.to_string(1.2345678), "1.2345678")
  @test.eq!(@double.to_string(1.23456789), "1.23456789")
  @test.eq!(@double.to_string(1.234567895), "1.234567895")
  @test.eq!(@double.to_string(1.2345678901), "1.2345678901")
  @test.eq!(@double.to_string(1.23456789012), "1.23456789012")
  @test.eq!(@double.to_string(1.234567890123), "1.234567890123")
  @test.eq!(@double.to_string(1.2345678901234), "1.2345678901234")
  @test.eq!(@double.to_string(1.23456789012345), "1.23456789012345")
  @test.eq!(@double.to_string(1.234567890123456), "1.234567890123456")
  @test.eq!(@double.to_string(1.2345678901234567), "1.2345678901234567")
}

test "32-bit chunking" {
  @test.eq!(@double.to_string(4.294967294), "4.294967294")
  @test.eq!(@double.to_string(4.294967295), "4.294967295")
  @test.eq!(@double.to_string(4.294967296), "4.294967296")
  @test.eq!(@double.to_string(4.294967297), "4.294967297")
  @test.eq!(@double.to_string(4.294967298), "4.294967298")
}

test "Min Max Shift" {
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 4, 0L)),
    "1.7800590868057611e-307",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 6, 0x0010000000000000L)),
    "1.424047269444609e-306",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 41, 0L)),
    "2.446494580089078e-296",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 40, 0x0010000000000000L)),
    "2.446494580089078e-296",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 1077, 0L)),
    "1.8014398509481984e16",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 1076, 0x0010000000000000L)),
    "1.8014398509481984e16",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 307, 0L)),
    "2.900835519859558e-216",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 306, 0x0010000000000000L)),
    "2.900835519859558e-216",
  )
  @test.eq!(
    @double.to_string(ieee_parts_to_double(false, 934, 0x000FA7161A4D6E0CL)),
    "3.196104012172126e-27",
  )
}

test "Small Integers" {
  // 2^53-1
  @test.eq!(@double.to_string(9007199254740991.0), "9.007199254740991e15")
  // 2^53
  @test.eq!(@double.to_string(9007199254740992.0), "9.007199254740992e15")
  @test.eq!(@double.to_string(1.0e+0), "1.0")
  @test.eq!(@double.to_string(1.2e+1), "12.0")
  @test.eq!(@double.to_string(1.23e+2), "123.0")
  @test.eq!(@double.to_string(1.234e+3), "1234.0")
  @test.eq!(@double.to_string(1.2345e+4), "12345.0")
  @test.eq!(@double.to_string(1.23456e+5), "123456.0")
  @test.eq!(@double.to_string(1.234567e+6), "1234567.0")
  @test.eq!(@double.to_string(1.2345678e+7), "1.2345678e7")
  @test.eq!(@double.to_string(1.23456789e+8), "1.23456789e8")
  @test.eq!(@double.to_string(1.23456789e+9), "1.23456789e9")
  @test.eq!(@double.to_string(1.234567895e+9), "1.234567895e9")
  @test.eq!(@double.to_string(1.2345678901e+10), "1.2345678901e10")
  @test.eq!(@double.to_string(1.23456789012e+11), "1.23456789012e11")
  @test.eq!(@double.to_string(1.234567890123e+12), "1.234567890123e12")
  @test.eq!(@double.to_string(1.2345678901234e+13), "1.2345678901234e13")
  @test.eq!(@double.to_string(1.23456789012345e+14), "1.23456789012345e14")
  @test.eq!(@double.to_string(1.234567890123456e+15), "1.234567890123456e15")
}

test "10^i" {
  @test.eq!(@double.to_string(1.0e-15), "1.0e-15")
  @test.eq!(@double.to_string(1.0e-14), "1.0e-14")
  @test.eq!(@double.to_string(1.0e-13), "1.0e-13")
  @test.eq!(@double.to_string(1.0e-12), "1.0e-12")
  @test.eq!(@double.to_string(1.0e-11), "1.0e-11")
  @test.eq!(@double.to_string(1.0e-10), "1.0e-10")
  @test.eq!(@double.to_string(1.0e-9), "1.0e-9")
  @test.eq!(@double.to_string(1.0e-8), "1.0e-8")
  @test.eq!(@double.to_string(1.0e-7), "1.0e-7")
  @test.eq!(@double.to_string(1.0e-6), "1.0e-6")
  @test.eq!(@double.to_string(1.0e-5), "1.0e-5")
  @test.eq!(@double.to_string(1.0e-4), "1.0e-4")
  @test.eq!(@double.to_string(1.0e-3), "0.001")
  @test.eq!(@double.to_string(1.0e-2), "0.01")
  @test.eq!(@double.to_string(1.0e-1), "0.1")
  @test.eq!(@double.to_string(1.0e+0), "1.0")
  @test.eq!(@double.to_string(1.0e+1), "10.0")
  @test.eq!(@double.to_string(1.0e+2), "100.0")
  @test.eq!(@double.to_string(1.0e+3), "1000.0")
  @test.eq!(@double.to_string(1.0e+4), "10000.0")
  @test.eq!(@double.to_string(1.0e+5), "100000.0")
  @test.eq!(@double.to_string(1.0e+6), "1000000.0")
  @test.eq!(@double.to_string(1.0e+7), "1.0e7")
  @test.eq!(@double.to_string(1.0e+8), "1.0e8")
  @test.eq!(@double.to_string(1.0e+9), "1.0e9")
  @test.eq!(@double.to_string(1.0e+10), "1.0e10")
  @test.eq!(@double.to_string(1.0e+11), "1.0e11")
  @test.eq!(@double.to_string(1.0e+12), "1.0e12")
  @test.eq!(@double.to_string(1.0e+13), "1.0e13")
  @test.eq!(@double.to_string(1.0e+14), "1.0e14")
  @test.eq!(@double.to_string(1.0e+15), "1.0e15")
}

test "10^15 + 10^i" {
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+0), "1.000000000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+1), "1.00000000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+2), "1.0000000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+3), "1.000000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+4), "1.00000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+5), "1.0000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+6), "1.000000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+7), "1.00000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+8), "1.0000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+9), "1.000001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+10), "1.00001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+11), "1.0001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+12), "1.001e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+13), "1.01e15")
  @test.eq!(@double.to_string(1.0e+15 + 1.0e+14), "1.1e15")
}

test "Largest power of 2 <= 10^(i+1)" {
  @test.eq!(@double.to_string(8.0), "8.0")
  @test.eq!(@double.to_string(64.0), "64.0")
  @test.eq!(@double.to_string(512.0), "512.0")
  @test.eq!(@double.to_string(8192.0), "8192.0")
  @test.eq!(@double.to_string(65536.0), "65536.0")
  @test.eq!(@double.to_string(524288.0), "524288.0")
  @test.eq!(@double.to_string(8388608.0), "8388608.0")
  @test.eq!(@double.to_string(67108864.0), "6.7108864e7")
  @test.eq!(@double.to_string(536870912.0), "5.36870912e8")
  @test.eq!(@double.to_string(8589934592.0), "8.589934592e9")
  @test.eq!(@double.to_string(68719476736.0), "6.8719476736e10")
  @test.eq!(@double.to_string(549755813888.0), "5.49755813888e11")
  @test.eq!(@double.to_string(8796093022208.0), "8.796093022208e12")
  @test.eq!(@double.to_string(70368744177664.0), "7.0368744177664e13")
  @test.eq!(@double.to_string(562949953421312.0), "5.62949953421312e14")
  @test.eq!(@double.to_string(9007199254740992.0), "9.007199254740992e15")
}

test "1000 * (Largest power of 2 <= 10^(i+1))" {
  @test.eq!(@double.to_string(8.0e+3), "8000.0")
  @test.eq!(@double.to_string(64.0e+3), "64000.0")
  @test.eq!(@double.to_string(512.0e+3), "512000.0")
  @test.eq!(@double.to_string(8192.0e+3), "8192000.0")
  @test.eq!(@double.to_string(65536.0e+3), "6.5536e7")
  @test.eq!(@double.to_string(524288.0e+3), "5.24288e8")
  @test.eq!(@double.to_string(8388608.0e+3), "8.388608e9")
  @test.eq!(@double.to_string(67108864.0e+3), "6.7108864e10")
  @test.eq!(@double.to_string(536870912.0e+3), "5.36870912e11")
  @test.eq!(@double.to_string(8589934592.0e+3), "8.589934592e12")
  @test.eq!(@double.to_string(68719476736.0e+3), "6.8719476736e13")
  @test.eq!(@double.to_string(549755813888.0e+3), "5.49755813888e14")
  @test.eq!(@double.to_string(8796093022208.0e+3), "8.796093022208e15")
}

test "boundary conditions" {
  // x = 1.0e7
  @test.eq!(@double.to_string(1.0e7), "1.0e7")
  // x < 1.0e7
  @test.eq!(@double.to_string(9999999.999999998), "9999999.999999998")
  // x = 1.0e-3
  @test.eq!(@double.to_string(0.001), "0.001")
  // x < 1.0e-3
  @test.eq!(@double.to_string(0.0009999999999999998), "9.999999999999998e-4")
}

// For testing purposes
fn ieee_parts_to_double(
  sign : Bool,
  ieeeExponent : Int,
  ieeeMantissa : Int64
) -> Double {
  sign
  .to_int64()
  .lsl(63)
  .lor(ieeeExponent.to_int64().lsl(52))
  .lor(ieeeMantissa)
  .reinterpret_as_double()
}

test "double/ryu.mbt:90" {
  let value = 100L
  @test.eq!(value % 25L, 0L)
  @test.ne!(value % 125L, 0L)
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
  @test.eq!(vrIsTrailingZeros, true)
  @test.eq!(vmIsTrailingZeros, true)
  @test.eq!(vp, 10L)
}

test "double/ryu.mbt:90" {
  let value = 100L
  @test.eq!(value % 25L, 0L)
  @test.ne!(value % 125L, 0L)
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
  @test.eq!(vrIsTrailingZeros, true)
  @test.eq!(vmIsTrailingZeros, true)
  @test.eq!(vp, 10L)
}
