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

let reduce_threshold : Double = (1).lsl(29).to_double()

let pi4a : Double = 7.85398125648498535156e-1

let pi4b : Double = 3.77489470793079817668e-8

let pi4c : Double = 2.69515142907905952645e-15

let pi : Double = 3.141592653589793

let sin_ : Array[Double] = [
  1.58962301576546568060e-10, -2.50507477628578072866e-8, 2.75573136213857245213e-6,
  -1.98412698295895385996e-4, 8.33333333332211858878e-3, -1.66666666666666307295e-1,
]

let cos_ : Array[Double] = [
  -1.13585365213876817300e-11, 2.08757008419747316778e-9, -2.75573141792967388112e-7,
  2.48015872888517045348e-5, -1.38888888888730564116e-3, 4.16666666666665929218e-2,
]

fn trig_reduce(x : Double) -> (Int64, Double) {
  let pi4 : Double = pi / 4.0
  if x < pi4 {
    (0L, x)
  } else {
    let j = x.reinterpret_as_i64() % 8L
    let z = x - j.reinterpret_as_double()
    (j, z)
  }
}

pub fn sin(x : Double) -> Double {
  let mut sign : Bool = false
  let mut x_ = x
  if x_ < 0.0 {
    x_ = -x_
    sign = true
  }
  let (j, z) : (Int64, Double) = if x_ >= reduce_threshold {
    let (j_, z_) = trig_reduce(x_)
    if j_ > 3L {
      sign = sign.not()
      (j_ - 4L, z_)
    } else {
      (j_, z_)
    }
  } else {
    let mut j = (x_ * (4.0 / pi)).to_int64()
    let mut y = j.to_double()
    if j.land(1L) == 1L {
      j += 1L
      y += 1.0
    }
    j = j.land(7L)
    if j > 3L {
      sign = sign.not()
      (j - 4L, x_ - y * pi4a - y * pi4b - y * pi4c)
    } else {
      (j, x_ - y * pi4a - y * pi4b - y * pi4c)
    }
  }
  let zz : Double = z * z
  if j == 1L || j == 2L {
    1.0 - 0.5 * zz + zz * zz * (((((cos_[0] * zz + cos_[1]) * zz + cos_[2]) * zz +
    cos_[3]) * zz + cos_[4]) * zz + cos_[5])
  } else {
    z + z * zz * (((((sin_[0] * zz + sin_[1]) * zz + sin_[2]) * zz + sin_[3]) * zz +
    sin_[4]) * zz + sin_[5])
  } * if sign { -1.0 } else { 1.0 }
}

pub fn cos(x : Double) -> Double {
  let mut sign : Bool = false
  let x_ = x.abs()
  let (j, z) = if x_ >= reduce_threshold {
    let (j_, z_) = trig_reduce(x_)
    if j_ > 3L {
      sign = sign.not()
      (j_ - 4L, z_)
    } else {
      (j_, z_)
    }
  } else {
    let mut j = (x_ * (4.0 / pi)).to_int64()
    let mut y = j.to_double()
    if j.land(1L) == 1L {
      j += 1L
      y += 1.0
    }
    j = j.land(7L)
    if j > 3L {
      sign = sign.not()
      (j - 4L, x_ - y * pi4a - y * pi4b - y * pi4c)
    } else {
      (j, x_ - y * pi4a - y * pi4b - y * pi4c)
    }
  }
  if j > 1L {
    sign = sign.not()
  }
  let zz : Double = z * z
  if j == 1L || j == 2L {
    z + z * zz * (((((sin_[0] * zz + sin_[1]) * zz + sin_[2]) * zz + sin_[3]) * zz +
    sin_[4]) * zz + sin_[5])
  } else {
    1.0 - 0.5 * zz + zz * zz * (((((cos_[0] * zz + cos_[1]) * zz + cos_[2]) * zz +
    cos_[3]) * zz + cos_[4]) * zz + cos_[5])
  } * if sign { -1.0 } else { 1.0 }
}

//Compare two Double values for equality within the allowed error range of 1e-12.
fn imprecise_equal(x : Double, y : Double) -> Bool {
  (x - y).abs() < 1.0e-12
}

test "sin" {
  @assertion.assert_true(imprecise_equal(sin(0.0), 0.0))?
  @assertion.assert_true(imprecise_equal(sin(1.0), 0.841470984807896))?
  @assertion.assert_true(imprecise_equal(sin(pi / 2.0), 1.0))?
  @assertion.assert_true(imprecise_equal(sin(pi), 0.0))?
}

test "cos" {
  @assertion.assert_true(imprecise_equal(cos(0.0), 1.0))?
  @assertion.assert_true(imprecise_equal(cos(1.0), 0.540302305868140))?
  @assertion.assert_true(imprecise_equal(cos(pi / 2.0), 0.0))?
  @assertion.assert_true(imprecise_equal(cos(pi), -1.0))?
}
