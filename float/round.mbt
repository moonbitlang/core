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

///|
let sign_mask : UInt = 0x8000_0000

///|
let exp_bias = 127

///|
let exp_bits = 8

///|
let frac_bits = 23

///|
pub fn trunc(self : Float) -> Float {
  let u32 = self.reinterpret_as_uint()
  let biased_exp = ((u32 >> frac_bits) & ((0x1U << exp_bits) - 1)).reinterpret_as_int()
  if biased_exp < exp_bias {
    return (u32 & sign_mask).reinterpret_as_float()
  } else if biased_exp >= exp_bias + frac_bits {
    return self
  }
  let mask_shift = biased_exp - exp_bias + exp_bits
  let trunc_mask = (sign_mask.reinterpret_as_int() >> mask_shift).reinterpret_as_uint()
  return (u32 & trunc_mask).reinterpret_as_float()
}

///|
pub fn ceil(self : Float) -> Float {
  let trunced = self.trunc()
  if self == trunced || self < 0.0 {
    trunced
  } else {
    trunced + 1.0
  }
}

///|
pub fn floor(self : Float) -> Float {
  let trunced = self.trunc()
  if self == trunced || self > 0.0 {
    trunced
  } else {
    trunced - 1.0
  }
}

///|
fn _int_part_parity(self : Float) -> Int {
  let u32 = self.reinterpret_as_uint()
  let biased_exp = ((u32 >> frac_bits) & ((0x1U << exp_bits) - 1)).reinterpret_as_int()
  if biased_exp < exp_bias || biased_exp > exp_bias + frac_bits {
    return 0
  } else if biased_exp == exp_bias + frac_bits {
    return (u32 & 1).reinterpret_as_int()
  }
  let mask_shift = biased_exp - exp_bias + exp_bits
  let parity_mask = sign_mask >> mask_shift
  return if (u32 & parity_mask) > 0 { 1 } else { 0 }
}

///|
// Round to nearest, ties to Even
pub fn round(self : Float) -> Float {
  let floor = floor(self)
  let diff = self - floor
  if diff > 0.5 {
    return floor + 1.0
  } else if diff < 0.5 {
    return floor
  } else if _int_part_parity(floor) == 0 {
    return floor
  } else {
    return floor + 1.0
  }
}
