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
/// Calculates the cube root of a number.
///
/// Parameters:
///
/// * `x` : The number for which to calculate the cube root.
///
/// Returns the cube root of `x`.
///
/// Special Cases:
///
/// * Return `NaN` if `x` is `NaN`.
/// * Return `±0` if `x` is `±0`.
/// * Return `Infinity` if `x` is `Infinity`.
/// * Return `-Infinity` if `x` is `-Infinity`.
///
/// Example
///
/// ```mbt check
/// test {
///   inspect(@math.cbrt(1.0), content="1")
///   inspect(@math.cbrt(3.0), content="1.4422495703074083")
///   inspect(@math.cbrt(-3.0), content="-1.4422495703074083")
///   inspect(@math.cbrt(10.0), content="2.154434690031884")
///   inspect(@math.cbrt(1000.0), content="10")
///   inspect(@math.cbrt(@double.not_a_number), content="NaN")
///   inspect(@math.cbrt(@double.infinity), content="Infinity")
///   inspect(@math.cbrt(@double.neg_infinity), content="-Infinity")
/// }
/// ```
pub fn cbrt(x : Double) -> Double {
  if x.is_inf() || x.is_nan() || x == 0.0 {
    return x
  }
  let b1 : UInt = 715094163 // B1 = (682-0.03306235651)*2**20
  let b2 : UInt = 696219795 // B2 = (664-0.03306235651)*2**20
  let c = 5.42857142857142815906e-01 // 19/35     = 0x3FE15F15, 0xF15F15F1
  let d = -7.05306122448979611050e-01 // -864/1225 = 0xBFE691DE, 0x2532C834
  let e = 1.41428571428571436819e+00 // 99/70     = 0x3FF6A0EA, 0x0EA0EA0F
  let f = 1.60714285714285720630e+00 // 45/28     = 0x3FF9B6DB, 0x6DB6DB6E
  let g = 3.57142857142857150787e-01 // 5/14      = 0x3FD6DB6D, 0xB6DB6DB7
  let hx = get_high_word(x).reinterpret_as_int()
  let sign = if x < 0.0 { true } else { false }
  let x = abs(x)
  let t = if hx < 0x00100000 {
    let t : UInt64 = 0x43500000_00000000
    let t : Double = t.reinterpret_as_double()
    let t = t * x
    set_high_word(0, get_high_word(t) / 3 + b2)
  } else {
    set_high_word(0, hx.reinterpret_as_uint() / 3 + b1)
  }
  let r = t * t / x
  let s = c + r * t
  let t = t * (g + f / (s + e + d / s))
  let t = set_high_word(0, get_high_word(t) + 0x00000001)
  let s = t * t
  let r = x / s
  let w = t + t
  let r = (r - t) / (w + r)
  let t = t + t * r
  if sign {
    -t
  } else {
    t
  }
}

///|
/// Calculates the square root of the sum of the squares of its arguments.
///
/// Parameters:
///
/// * `x` : The number to be used as the first argument.
/// * `y` : The number to be used as the second argument.
///
/// Returns the hypotenuse of a right-angled triangle whose legs are `x` and `y`.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(@math.hypot(3.0, 4.0), content="5")
///   inspect(@math.hypot(5.0, 12.0), content="13")
///   inspect(@math.hypot(8.0, 15.0), content="17")
///   inspect(@math.hypot(7.0, 24.0), content="25")
///   inspect(@math.hypot(@double.not_a_number, 1.0), content="NaN")
///   inspect(@math.hypot(1.0, @double.not_a_number), content="NaN")
///   inspect(@math.hypot(@double.infinity, 1.0), content="Infinity")
///   inspect(@math.hypot(1.0, @double.infinity), content="Infinity")
///   inspect(@math.hypot(@double.neg_infinity, 1.0), content="Infinity")
///   inspect(@math.hypot(1.0, @double.neg_infinity), content="Infinity")
/// }
/// ```
pub fn hypot(x : Double, y : Double) -> Double {
  if x.is_nan() || y.is_nan() {
    return @double.not_a_number
  }
  if x.is_inf() || y.is_inf() {
    return @double.infinity
  }
  let x = x.abs()
  let y = y.abs()
  let double_epsilon : Double = 0x0.0000000000001P-1022
  let (x, y) = if y > x { (y, x) } else { (x, y) }
  if x * double_epsilon >= y {
    return x
  }
  let r = y / x
  x * (1.0 + r * r).sqrt()
}
