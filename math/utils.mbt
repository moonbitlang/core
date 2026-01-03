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
fn abs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
let two_over_pi : ReadOnlyArray[Int] = [
  0xA2F983, 0x6E4E44, 0x1529FC, 0x2757D1, 0xF534DD, 0xC0DB62, 0x95993C, 0x439041,
  0xFE5163, 0xABDEBB, 0xC561B7, 0x246E3A, 0x424DD2, 0xE00649, 0x2EEA09, 0xD1921C,
  0xFE1DEB, 0x1CB129, 0xA73EE8, 0x8235F5, 0x2EBB44, 0x84E99C, 0x7026B4, 0x5F7E41,
  0x3991D6, 0x398353, 0x39F49C, 0x845F8B, 0xBDF928, 0x3B1FF8, 0x97FFDE, 0x05980F,
  0xEF2F11, 0x8B5A0A, 0x6D1F6D, 0x367ECF, 0x27CB09, 0xB74F46, 0x3F669E, 0x5FEA2D,
  0x7527BA, 0xC7EBE5, 0xF17B3D, 0x0739F7, 0x8A5292, 0xEA6BFB, 0x5FB11F, 0x8D5D08,
  0x560330, 0x46FC7B, 0x6BABF0, 0xCFBC20, 0x9AF436, 0x1DA9E3, 0x91615E, 0xE61B08,
  0x659985, 0x5F14A0, 0x68408D, 0xFFD880, 0x4D7327, 0x310606, 0x1556CA, 0x73A8C9,
  0x60E27B, 0xC08C6B,
]

///|
let pi_over_2 : ReadOnlyArray[Double] = [
  1.57079625129699707031e+00, // 0x3FF921FB, 0x40000000 */
   7.54978941586159635335e-08, // 0x3E74442D, 0x00000000 */
   5.39030252995776476554e-15, // 0x3CF84698, 0x80000000 */
   3.28200341580791294123e-22, // 0x3B78CC51, 0x60000000 */
   1.27065575308067607349e-29, // 0x39F01B83, 0x80000000 */
   1.22933308981111328932e-36, // 0x387A2520, 0x40000000 */
   2.73370053816464559624e-44, // 0x36E38222, 0x80000000 */
   2.16741683877804819444e-51, // 0x3569F31D, 0x00000000 */
]

///|
let npio2_hw : ReadOnlyArray[Int] = [
  0x3FF921FB, 0x400921FB, 0x4012D97C, 0x401921FB, 0x401F6A7A, 0x4022D97C, 0x4025FDBB,
  0x402921FB, 0x402C463A, 0x402F6A7A, 0x4031475C, 0x4032D97C, 0x40346B9C, 0x4035FDBB,
  0x40378FDB, 0x403921FB, 0x403AB41B, 0x403C463A, 0x403DD85A, 0x403F6A7A, 0x40407E4C,
  0x4041475C, 0x4042106C, 0x4042D97C, 0x4043A28C, 0x40446B9C, 0x404534AC, 0x4045FDBB,
  0x4046C6CB, 0x40478FDB, 0x404858EB, 0x404921FB,
]

///|
const PI_OVER_4 : Double = 0.785398163397448309616

///|
const PIO2_1 : Double = 1.5707963267341256e+00 // 0x3FF921FB, 0x54400000 */

///|
const PIO2_1T : Double = 6.0771005065061922e-11 // 0x3DD0B461, 0x1A600000 */

///|
const PIO2_2 : Double = 6.0771005063039660e-11 // 0x3DD0B461, 0x1A600000 */

///|
const PIO2_2T : Double = 2.0222662487959506e-21 // 0x3BA3198A, 0x2E037073 */

///|
const PIO2_3 : Double = 2.0222662487111665e-21 // 0x3BA3198A, 0x2E037073 */

///|
const PIO2_3T : Double = 8.4784276603688996e-32 // 0x397B839A, 0x252049C1 */

///|
const INV_PIO2 : Double = 6.3661977236758138e-01 // 0x3FE45F30, 0x6DC9C883 */

///|
const HALF : Double = 0.5

///|
const TWO24 : Double = 16777216.0 // 0x41700000, 0x00000000 */

///|
fn set_low_word(d : Double, v : UInt) -> Double {
  let bits : UInt64 = d.reinterpret_as_uint64()
  let bits = bits & 0xFFFF_FFFF_0000_0000
  let bits = bits | v.to_uint64()
  bits.reinterpret_as_double()
}

///|
fn set_high_word(d : Double, v : UInt) -> Double {
  let bits : UInt64 = d.reinterpret_as_uint64()
  let bits = bits & 0x0000_0000_FFFF_FFFF
  let bits = bits | (v.to_uint64() << 32)
  bits.reinterpret_as_double()
}

///|
fn get_high_word(x : Double) -> UInt {
  (x.reinterpret_as_uint64() >> 32).to_uint()
}

///|
fn get_low_word(x : Double) -> UInt {
  x.reinterpret_as_uint64().to_uint()
}

///|
const SQRT2 = 1.41421356237309504880168872420969807856967187537694807317667974

///|
const LN2 = 0.693147180559945309417232121458176568075500134360255254120680009

///|
const LN2_HI = 6.93147180369123816490e-01 // 3fe62e42 fee00000

///|
const LN2_LO = 1.90821492927058770002e-10 // 3dea39ef 35793c76

///|
fn normalize(f : Double) -> (Double, Int) {
  if f.abs() < @double.min_positive {
    return (f * (1L << 52).to_double(), -52)
  }
  (f, 0)
}

///|
fn frexp(f : Double) -> (Double, Int) {
  if f == 0.0 || f.is_inf() || f.is_nan() {
    return (f, 0)
  }
  let (norm_f, exp) = normalize(f)
  let u = norm_f.reinterpret_as_uint64()
  let exp = exp + ((u >> 52) & 0x7FF).to_int() - 1022
  let frac = ((u & (0x7FFUL << 52).lnot()) | (1022UL << 52)).reinterpret_as_double()
  return (frac, exp)
}
