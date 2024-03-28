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

let pi4a = 0x0.C90FDA000000000011B5

let pi4b = 0x0.000000A2216800000988

let pi4c = 0x0.000000000000C234BE07

let pi = 0x3.243F6A8885A308CA8A54

let pi4 : Double = 4.0 / pi

let sin_ = [
  0x0.00000000AEC7E8FE9D35, -0x0.0000006B9796A4A487D, 0x0.00002E3BC6ACFA913766, -1.98412698295895385996e-4,
  0x0.02222222221EFA06A21A, -0x0.2AAAAAAAAAAA90C58591,
]

let cos_ = [
  -0x0.000000000C7D24D03C8, 0x0.00000008F74EBDA72B71, -0x0.0000049F93DFAB12FDC6,
  0x0.0001A01A019C844F3E07, -0x0.005B05B05B053E453C34, 0x0.0AAAAAAAAAAAA55A47E1,
]

pub fn sin(x : Double) -> Double {
  let mut sign = false
  let mut x_ = x
  if x_ < 0.0 {
    x_ = -x_
    sign = true
  }
  let mut j = (x_ * pi4).to_int64()
  if j.land(1L) == 1L {
    j += 1L
  }
  let y = j.to_double()
  j = j.land(7L)
  if j > 3L {
    sign = sign.not()
    j -= 4L
  }
  let z = x_ - y * pi4a - y * pi4b - y * pi4c
  let zz = z * z
  if j == 1L || j == 2L {
    1.0 - 0.5 * zz + zz * zz * (((((cos_[0] * zz + cos_[1]) * zz + cos_[2]) * zz +
    cos_[3]) * zz + cos_[4]) * zz + cos_[5])
  } else {
    z + z * zz * (((((sin_[0] * zz + sin_[1]) * zz + sin_[2]) * zz + sin_[3]) * zz +
    sin_[4]) * zz + sin_[5])
  } * if sign { -1.0 } else { 1.0 }
}

pub fn cos(x : Double) -> Double {
  let mut sign = false
  let x_ = x.abs()
  let mut j = (x_ * pi4).to_int64()
  if j.land(1L) == 1L {
    j += 1L
  }
  let y = j.to_double()
  j = j.land(7L)
  if j > 3L {
    sign = sign.not()
    j -= 4L
  }
  let z = x_ - y * pi4a - y * pi4b - y * pi4c
  if j > 1L {
    sign = sign.not()
  }
  let zz = z * z
  if j == 1L || j == 2L {
    z + z * zz * (((((sin_[0] * zz + sin_[1]) * zz + sin_[2]) * zz + sin_[3]) * zz +
    sin_[4]) * zz + sin_[5])
  } else {
    1.0 - 0.5 * zz + zz * zz * (((((cos_[0] * zz + cos_[1]) * zz + cos_[2]) * zz +
    cos_[3]) * zz + cos_[4]) * zz + cos_[5])
  } * if sign { -1.0 } else { 1.0 }
}

//Compare two Double values for equality within the allowed error range of 1e-11.
fn imprecise_equal(x : Double, y : Double) -> Bool {
  (x - y).abs() < 1.0e-10
}

test "sin" {
  let vf = [
    4.9790119248836735e+00, 7.7388724745781045e+00, -2.7688005719200159e-01, -5.0106036182710749e+00,
    9.6362937071984173e+00, 2.9263772392439646e+00, 5.2290834314593066e+00, 2.7279399104360102e+00,
    1.8253080916808550e+00, -8.6859247685756013e+00,
  ]
  let sin_res = [
    -9.6466616586009283766724726e-01, 9.9338225271646545763467022e-01, -2.7335587039794393342449301e-01,
    9.5586257685042792878173752e-01, -2.099421066779969164496634e-01, 2.135578780799860532750616e-01,
    -8.694568971167362743327708e-01, 4.019566681155577786649878e-01, 9.6778633541687993721617774e-01,
    -6.734405869050344734943028e-01,
  ]
  let sin_res_large = [
    -9.646661658548936063912e-01, 9.933822527198506903752e-01, -2.7335587036246899796e-01,
    9.55862576853689321268e-01, -2.099421066862688873691e-01, 2.13557878070308981163e-01,
    -8.694568970959221300497e-01, 4.01956668098863248917e-01, 9.67786335404528727927e-01,
    -6.7344058693131973066e-01,
  ]
  for i = 0; i < vf.length(); i = i + 1 {
    @assertion.assert_true(imprecise_equal(sin(vf[i]), sin_res[i]))?
    @assertion.assert_true(
      imprecise_equal(sin(100000.0 * pi + vf[i]), sin_res_large[i]),
    )?
  }
}

test "cos" {
  let vf = [
    4.9790119248836735e+00, 7.7388724745781045e+00, -2.7688005719200159e-01, -5.0106036182710749e+00,
    9.6362937071984173e+00, 2.9263772392439646e+00, 5.2290834314593066e+00, 2.7279399104360102e+00,
    1.8253080916808550e+00, -8.6859247685756013e+00,
  ]
  let cos_res = [
    2.634752140995199110787593e-01, 1.148551260848219865642039e-01, 9.6191297325640768154550453e-01,
    2.938141150061714816890637e-01, -9.777138189897924126294461e-01, -9.7693041344303219127199518e-01,
    4.940088096948647263961162e-01, -9.1565869021018925545016502e-01, -2.517729313893103197176091e-01,
    -7.39241351595676573201918e-01,
  ]
  let cos_res_large = [
    2.634752141185559426744e-01, 1.14855126055543100712e-01, 9.61912973266488928113e-01,
    2.9381411499556122552e-01, -9.777138189880161924641e-01, -9.76930413445147608049e-01,
    4.940088097314976789841e-01, -9.15658690217517835002e-01, -2.51772931436786954751e-01,
    -7.3924135157173099849e-01,
  ]
  for i = 0; i < vf.length(); i = i + 1 {
    @assertion.assert_true(imprecise_equal(cos(vf[i]), cos_res[i]))?
    @assertion.assert_true(
      imprecise_equal(cos(100000.0 * pi + vf[i]), cos_res_large[i]),
    )?
  }
}
