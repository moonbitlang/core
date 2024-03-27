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
    if j.land(1L) == 1L {
      j += 1L
    }
    let y = j.to_double()
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
    if j.land(1L) == 1L {
      j += 1L
    }
    let y = j.to_double()
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
  let vf = [
    4.9790119248836735e+00, 7.7388724745781045e+00, -2.7688005719200159e-01, -5.0106036182710749e+00,
    9.6362937071984173e+00, 2.9263772392439646e+00, 5.2290834314593066e+00, 2.7279399104360102e+00,
    1.8253080916808550e+00, -8.6859247685756013e+00, 0.0, 1.0, pi / 2.0, pi,
  ]
  let sin_res = [
    -9.6466616586009283766724726e-01, 9.9338225271646545763467022e-01, -2.7335587039794393342449301e-01,
    9.5586257685042792878173752e-01, -2.099421066779969164496634e-01, 2.135578780799860532750616e-01,
    -8.694568971167362743327708e-01, 4.019566681155577786649878e-01, 9.6778633541687993721617774e-01,
    -6.734405869050344734943028e-01, 0.0, 8.414709848078965066591757e-01, 1.0, 0.0,
  ]
  for i = 0; i < vf.length(); i = i + 1 {
    @assertion.assert_true(imprecise_equal(sin(vf[i]), sin_res[i]))?
  }
}

test "cos" {
  let vf = [
    4.9790119248836735e+00, 7.7388724745781045e+00, -2.7688005719200159e-01, -5.0106036182710749e+00,
    9.6362937071984173e+00, 2.9263772392439646e+00, 5.2290834314593066e+00, 2.7279399104360102e+00,
    1.8253080916808550e+00, -8.6859247685756013e+00, 0.0, 1.0, pi / 2.0, pi,
  ]
  let cos_res = [
    2.634752140995199110787593e-01, 1.148551260848219865642039e-01, 9.6191297325640768154550453e-01,
    2.938141150061714816890637e-01, -9.777138189897924126294461e-01, -9.7693041344303219127199518e-01,
    4.940088096948647263961162e-01, -9.1565869021018925545016502e-01, -2.517729313893103197176091e-01,
    -7.39241351595676573201918e-01, 1.0, 5.403023058681398715411497e-01, 0.0, -1.0,
  ]
  for i = 0; i < vf.length(); i = i + 1 {
    @assertion.assert_true(imprecise_equal(cos(vf[i]), cos_res[i]))?
  }
}
