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

///|
pub const PI = 0x3.243F6A8885A308CA8A54

///|
///@alert deprecated "Use `PI` instead"
pub let pi = 0x3.243F6A8885A308CA8A54

///|
pub fn sin(x : Double) -> Double {
  x.sin()
}

///|
pub fn cos(x : Double) -> Double {
  x.cos()
}

///|
pub fn tan(x : Double) -> Double {
  x.tan()
}

///|
let atan_p = [
  -8.750608600031904122785e-01, -1.615753718733365076637e+01, -7.500855792314704667340e+01,
  -1.228866684490136173410e+02, -6.485021904942025371773e+01,
]

///|
let atan_q = [
  2.485846490142306297962e+01, 1.650270098316988542046e+02, 4.328810604912902668951e+02,
  4.853903996359136964868e+02, 1.945506571482613964425e+02,
]

///|
let morebits = 6.123233995736765886130e-17

///|
let tan3pio8 = 2.41421356237309504880

///|
fn xatan(x : Double) -> Double {
  let z = x * x
  x *
  (
    z *
    (
      (((atan_p[0] * z + atan_p[1]) * z + atan_p[2]) * z + atan_p[3]) * z +
      atan_p[4]
    ) /
    (
      ((((z + atan_q[0]) * z + atan_q[1]) * z + atan_q[2]) * z + atan_q[3]) * z +
      atan_q[4]
    )
  ) +
  x
}

///|
fn satan(x : Double) -> Double {
  if x <= 0.66 {
    xatan(x)
  } else if x > tan3pio8 {
    PI / 2.0 - xatan(1.0 / x) + morebits
  } else {
    PI / 4.0 + xatan((x - 1.0) / (x + 1.0)) + 0.5 * morebits
  }
}

///|
pub fn atan(x : Double) -> Double {
  if Double::is_nan(x) || x == 0.0 {
    x
  } else if x > 0.0 {
    satan(x)
  } else {
    -satan(-x)
  }
}

///|
pub fn asin(x : Double) -> Double {
  if Double::is_nan(x) || x == 0.0 {
    x
  } else {
    let x_ = x.abs()
    if x_ > 1.0 {
      @double.not_a_number
    } else {
      let temp = (1.0 - x_ * x_).sqrt()
      (if x > 0.7 { PI / 2.0 - satan(temp / x_) } else { satan(x_ / temp) }) *
      x.signum()
    }
  }
}

///|
pub fn acos(x : Double) -> Double {
  if Double::is_nan(x) {
    x
  } else {
    PI / 2.0 - asin(x)
  }
}

///|
const SIGNBIT : UInt64 = 0x8000000000000000UL

///|
fn copysign(x : Double, y : Double) -> Double {
  // should check the sign bit to distinguish +0/-0
  if (y.reinterpret_as_uint64() & SIGNBIT) > 0 {
    -x.abs()
  } else {
    x.abs()
  }
}

///|
pub fn atan2(y : Double, x : Double) -> Double {
  if Double::is_nan(x) || Double::is_nan(y) {
    @double.not_a_number
  } else if y == 0 {
    if x >= 0 {
      copysign(0, y)
    } else {
      copysign(PI, y)
    }
  } else if x == 0 {
    copysign(PI / 2, y)
  } else if x.is_inf() {
    if x.is_pos_inf() {
      if y.is_inf() {
        copysign(PI / 4, y)
      } else {
        copysign(0, y)
      }
    } else if y.is_inf() {
      copysign(3.0 * PI / 4, y)
    } else {
      copysign(PI, y)
    }
  } else if y.is_inf() {
    copysign(PI / 2, y)
  } else {
    let q = atan(y / x)
    if x < 0 {
      if q <= 0 {
        q + PI
      } else {
        q - PI
      }
    } else {
      q
    }
  }
}
