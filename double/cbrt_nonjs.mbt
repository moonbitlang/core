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

//
// origin: FreeBSD /usr/src/lib/msun/src/s_cbrt.c
// ====================================================
// Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
//
// Developed at SunSoft, a Sun Microsystems, Inc. business.
// Permission to use, copy, modify, and distribute this
// software is freely granted, provided that this notice
// is preserved.
// ====================================================
//

///|
/// Calculates the cube root of a number.
///
/// Parameters:
///
/// * `self` : The number for which to calculate the cube root.
///
/// Returns the cube root of `self`.
///
/// Special Cases:
///
/// * Return `NaN` if `self` is `NaN`.
/// * Return `±0` if `self` is `±0`.
/// * Return `Infinity` if `self` is `Infinity`.
/// * Return `-Infinity` if `self` is `-Infinity`.
///
/// Example
///
/// ```moonbit
///   inspect(1.0.cbrt(), content="1")
///   inspect(3.0.cbrt(), content="1.4422495703074083")
///   inspect((-3.0).cbrt(), content="-1.4422495703074083")
///   inspect(10.0.cbrt(), content="2.154434690031884")
///   inspect(1000.0.cbrt(), content="10")
///   inspect(@double.not_a_number.cbrt(), content="NaN")
///   inspect(@double.infinity, content="Infinity")
///   inspect(@double.neg_infinity, content="-Infinity")
/// ```
pub fn Double::cbrt(self : Double) -> Double {
  if self.is_inf() || self.is_nan() || self == 0.0 {
    return self
  }
  let b1 : UInt = 715094163 // B1 = (682-0.03306235651)*2**20
  let b2 : UInt = 696219795 // B2 = (664-0.03306235651)*2**20
  let c = 5.42857142857142815906e-01 // 19/35     = 0x3FE15F15, 0xF15F15F1
  let d = -7.05306122448979611050e-01 // -864/1225 = 0xBFE691DE, 0x2532C834
  let e = 1.41428571428571436819e+00 // 99/70     = 0x3FF6A0EA, 0x0EA0EA0F
  let f = 1.60714285714285720630e+00 // 45/28     = 0x3FF9B6DB, 0x6DB6DB6E
  let g = 3.57142857142857150787e-01 // 5/14      = 0x3FD6DB6D, 0xB6DB6DB7
  let hx = get_high_word(self).reinterpret_as_int()
  let sign = if self < 0.0 { true } else { false }
  let self = abs(self)
  let t = if hx < 0x00100000 {
    let t : UInt64 = 0x43500000_00000000
    let t : Double = t.reinterpret_as_double()
    let t = t * self
    set_high_word(0, get_high_word(t) / 3 + b2)
  } else {
    set_high_word(0, hx.reinterpret_as_uint() / 3 + b1)
  }
  let r = t * t / self
  let s = c + r * t
  let t = t * (g + f / (s + e + d / s))
  let t = set_high_word(0, get_high_word(t) + 0x00000001)
  let s = t * t
  let r = self / s
  let w = t + t
  let r = (r - t) / (w + r)
  let t = t + t * r
  if sign {
    -t
  } else {
    t
  }
}
