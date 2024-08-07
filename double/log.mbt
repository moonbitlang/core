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

// ported from https://github.com/golang/go/blob/master/src/math/log.go

let sqrt2 = 1.41421356237309504880168872420969807856967187537694807317667974

let ln2 = 0.693147180559945309417232121458176568075500134360255254120680009

let ln10 = 2.30258509299404568401799145468436420760110148862877297603332790

let ln2_hi = 6.93147180369123816490e-01 // 3fe62e42 fee00000

let ln2_lo = 1.90821492927058770002e-10 // 3dea39ef 35793c76

let l1 = 6.666666666666735130e-01 // 3FE55555 55555593

let l2 = 3.999999999940941908e-01 // 3FD99999 9997FA04

let l3 = 2.857142874366239149e-01 // 3FD24924 94229359

let l4 = 2.222219843214978396e-01 // 3FCC71C5 1D8E78AF

let l5 = 1.818357216161805012e-01 // 3FC74664 96CB03DE

let l6 = 1.531383769920937332e-01 // 3FC39A09 D078C69F

let l7 = 1.479819860511658591e-01 // 3FC2F112 DF3E5244

fn normalize(f : Double) -> (Double, Int) {
  if f.abs() < Double::min_normal() {
    return (f * 1L.lsl(52).to_double(), -52)
  }
  (f, 0)
}

fn frexp(f : Double) -> (Double, Int) {
  if f == 0.0 || f.is_inf() || f.is_nan() {
    return (f, 0)
  }
  let (norm_f, exp) = normalize(f)
  let u = norm_f.reinterpret_as_i64()
  let exp = exp + u.lsr(52).land(0x7FFL).to_int() - 1022
  let frac = u
    .land(0x7FFL.lsl(52).lnot())
    .lor(1022L.lsl(52))
    .reinterpret_as_double()
  return (frac, exp)
}

pub fn ln(self : Double) -> Double {
  if self.is_nan() || self.is_inf() {
    return self
  } else if self < 0.0 {
    return Double::nan()
  } else if self == 0.0 {
    return Double::inf(-1)
  }
  let (f1, ki) = frexp(self)
  let (f, k) = if f1 < sqrt2 / 2.0 {
    (f1 * 2.0 - 1.0, (ki - 1).to_double())
  } else {
    (f1 - 1.0, ki.to_double())
  }
  let s = f / (2.0 + f)
  let s2 = s * s
  let s4 = s2 * s2
  let t1 = s2 * (l1 + s4 * (l3 + s4 * (l5 + s4 * l7)))
  let t2 = s4 * (l2 + s4 * (l4 + s4 * l6))
  let r = t1 + t2
  let hfsq = 0.5 * f * f
  k * ln2_hi - (hfsq - (s * (hfsq + r) + k * ln2_lo) - f)
}

pub fn log2(self : Double) -> Double {
  let (f, e) = frexp(self)
  if f == 0.5 {
    return e.to_double() - 1.0
  }
  ln(f) / ln2 + e.to_double()
}

pub fn log10(self : Double) -> Double {
  ln(self) / ln10
}

test "log2 log10" {
  // log2
  @test.eq!(3.0.log2(), 1.584962500721156)
  @test.eq!(2.0.log2(), 1.0)
  @test.eq!(1.0.log2(), 0.0)
  @test.eq!(0.5.log2(), -1.0)
  @test.eq!(0.25.log2(), -2.0)
  @test.eq!(0.1.log2(), -3.321928094887362)

  // log10
  @test.eq!(0.2.log10(), -0.6989700043360187)
  @test.eq!(15.0.log10(), 1.1760912590556811)
}

test "ln" {
  @test.is_true!(Double::nan().ln().is_nan())
  @test.is_true!(Double::inf(1).ln().is_pos_inf())
  @test.is_true!(Double::inf(-1).ln().is_neg_inf())
  @test.is_true!((-1.0).ln().is_nan())
  @test.is_true!(0.0.ln().is_neg_inf())
  @test.is_true!((-0.0).ln().is_neg_inf())
  @test.eq!(50.0.ln(), 3.912023005428146)
  @test.eq!(2.0.ln(), 0.6931471805599453)
  @test.eq!(1.1125369292536007e-308.ln(), -709.0895657128241)
  @test.eq!(5.562684646268003e-309.ln(), -709.782712893384)
  @test.is_true!(
    match frexp(0.0) {
      (0.0, 0) => true
      _ => false
    },
  )
  @test.is_true!(
    match frexp(Double::inf(1)) {
      (f, 0) => if f.is_pos_inf() { true } else { false }
      _ => false
    },
  )
  @test.is_true!(
    match frexp(Double::nan()) {
      (f, 0) => if f.is_nan() { true } else { false }
      _ => false
    },
  )
}
