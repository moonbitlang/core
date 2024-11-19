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
let sign_mask : UInt64 = 0x8000_0000_0000_0000

let exp_bias = 1023

let exp_bits = 11

let frac_bits = 52

///|
pub fn trunc(self : Double) -> Double {
  let u32 = self.reinterpret_as_uint64()
  let biased_exp = ((u32 >> frac_bits) & ((0x1UL << exp_bits) - 1)).to_int()
  if biased_exp < exp_bias {
    return (u32 & sign_mask).reinterpret_as_double()
  } else if biased_exp >= exp_bias + frac_bits {
    return self
  }
  let mask_shift = biased_exp - exp_bias + exp_bits
  let trunc_mask = (sign_mask.reinterpret_as_int64() >> mask_shift).reinterpret_as_uint64()
  return (u32 & trunc_mask).reinterpret_as_double()
}

///|
pub fn ceil(self : Double) -> Double {
  let trunced = self.trunc()
  if self == trunced || self < 0.0 {
    trunced
  } else {
    trunced + 1.0
  }
}

///|
pub fn floor(self : Double) -> Double {
  let trunced = self.trunc()
  if self == trunced || self > 0.0 {
    trunced
  } else {
    trunced - 1.0
  }
}

///|
fn _int_part_parity(self : Double) -> Int {
  let u32 = self.reinterpret_as_uint64()
  let biased_exp = ((u32 >> frac_bits) & ((0x1UL << exp_bits) - 1)).to_int()
  if biased_exp < exp_bias || biased_exp > exp_bias + frac_bits {
    return 0
  } else if biased_exp == exp_bias + frac_bits {
    return (u32 & 1).to_int()
  }
  let mask_shift = biased_exp - exp_bias + exp_bits
  let parity_mask = sign_mask >> mask_shift
  return if (u32 & parity_mask) > 0 { 1 } else { 0 }
}

///|
// Round to nearest, ties to Even
pub fn round(self : Double) -> Double {
  let floor = floor(self)
  let ceil = floor + 1
  let diff = ceil - self - (self - floor)
  if diff > 0.0 {
    return floor
  } else if diff < 0.0 {
    return ceil
  } else if _int_part_parity(floor) == 0 {
    return floor
  } else {
    return ceil
  }
}
