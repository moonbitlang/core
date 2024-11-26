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

fn copy_sign(x : Double, y : Double) -> Double {
  if x < 0 {
    -y.abs()
  } else {
    y.abs()
  }
}

fn ldexp(frac : Double, exp_ : Double) -> Double {
  if frac == 0 {
    0
  } else if frac.is_inf() || frac.is_nan() {
    frac
  } else {
    let (frac, e) = normalize(frac)
    let mut exp = exp_
    exp += e.to_double()
    let mut x = frac.reinterpret_as_uint64()
    exp += (((x >> 52).to_int() & 0x7FF) - 1023).to_double()
    if exp < -1075 {
      copy_sign(0, frac)
    } else if exp > 1023 {
      if frac < 0 {
        neg_infinity
      } else {
        infinity
      }
    } else {
      let mut m : Double = 1
      if exp < -1022 {
        exp += 53
        m = 1.0 / (1 << 53).to_double()
      }
      x = x & (0x7FFUL << 52).lnot()
      x = x | ((exp + 1023.0).to_int64().reinterpret_as_uint64() << 52)
      m * x.reinterpret_as_double()
    }
  }
}

pub fn op_mod(self : Double, other : Double) -> Double {
  if other == 0 || self.is_inf() || self.is_nan() || other.is_nan() {
    not_a_number
  } else {
    let y = other.abs()
    let (yfr, yexp) = frexp(y)
    let mut r = self
    if self < 0 {
      r = -self
    }
    while r >= y {
      let (rfr, rexp_) = frexp(r)
      let mut rexp = rexp_
      if rfr < yfr {
        rexp -= 1
      }
      r = r - ldexp(y, (rexp - yexp).to_double())
    }
    if self < 0 {
      r = -r
    }
    r
  }
}
