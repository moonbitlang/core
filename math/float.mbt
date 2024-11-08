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

trait Floating {
  asin(Self) -> Self
  // ideas: `as`
  // or use @math.Floating::asin(x)  
  acos(Self) -> Self
}

pub fn asin[T : Floating](x : T) -> T {
  x.asin()
}

pub fn acos[T : Floating](x : T) -> T {
  x.acos()
}

pub impl Floating for Double with asin(x) {
  if Double::is_inf(x) || Double::is_nan(x) || x == 0.0 {
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

pub impl Floating for Double with acos(x) {
  if Double::is_inf(x) || Double::is_nan(x) {
    x
  } else {
    PI / 2.0 - asin(x)
  }
}
