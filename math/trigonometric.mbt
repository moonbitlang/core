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

let tan_p = [
  -0x3325.B1A49E7E6F070EEA7F33, 0x1199EC.A5FC9DDCB62A659C2F5C, -0x111FEAD.3299175F331F9B486E14,
]

let tan_q = [
  1.0, 0x3571.4BDD66CAE3B4F57353EC, -0x1427BC.582ABC95B9AA3C9963BF, 0x17D98FC.2EAD8EF5BE3D475ECC36,
  -0x335FC07.97CB461BD8709633FE8F,
]

pub fn sin(x : Double) -> Double {
  if Double::is_inf(x) || Double::is_nan(x) {
    x
  } else {
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
      z + z * zz * (((((sin_[0] * zz + sin_[1]) * zz + sin_[2]) * zz + sin_[3]) *
      zz + sin_[4]) * zz + sin_[5])
    } * if sign { -1.0 } else { 1.0 }
  }
}

pub fn cos(x : Double) -> Double {
  if Double::is_inf(x) || Double::is_nan(x) {
    x
  } else {
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
      z + z * zz * (((((sin_[0] * zz + sin_[1]) * zz + sin_[2]) * zz + sin_[3]) *
      zz + sin_[4]) * zz + sin_[5])
    } else {
      1.0 - 0.5 * zz + zz * zz * (((((cos_[0] * zz + cos_[1]) * zz + cos_[2]) * zz +
      cos_[3]) * zz + cos_[4]) * zz + cos_[5])
    } * if sign { -1.0 } else { 1.0 }
  }
}

pub fn tan(x : Double) -> Double {
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
  let z = x_ - y * pi4a - y * pi4b - y * pi4c
  let mut zz = z * z
  zz = if zz > 1.0e-14 {
    z + z * (zz * ((tan_p[0] * zz + tan_p[1]) * zz + tan_p[2]) / ((((zz + tan_q[1]) *
    zz + tan_q[2]) * zz + tan_q[3]) * zz + tan_q[4]))
  } else {
    z
  }
  if j.land(2L) == 2L {
    zz = -1.0 / zz
  }
  if sign {
    -zz
  } else {
    zz
  }
}
