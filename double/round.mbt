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

///|
let exp_bias = 1023

///|
let exp_bits = 11

///|
let frac_bits = 52

///|
pub fn trunc(self : Double) -> Double {
  let u64 = self.reinterpret_as_uint64()
  let biased_exp = ((u64 >> frac_bits) & ((0x1UL << exp_bits) - 1)).to_int()
  if biased_exp < exp_bias {
    return (u64 & sign_mask).reinterpret_as_double()
  } else if biased_exp >= exp_bias + frac_bits {
    return self
  }
  let mask_shift = biased_exp - exp_bias + exp_bits
  let trunc_mask = (sign_mask.reinterpret_as_int64() >> mask_shift).reinterpret_as_uint64()
  return (u64 & trunc_mask).reinterpret_as_double()
}

///|
pub fn ceil(self : Double) -> Double {
  let trunced = self.trunc()
  if self > trunced {
    return trunced + 1.0
  } else {
    return trunced
  }
}

///|
pub fn floor(self : Double) -> Double {
  let trunced = self.trunc()
  if self < trunced {
    return trunced - 1.0
  } else {
    return trunced
  }
}

///|
// Round to nearest, ties to Ceiling
pub fn round(self : Double) -> Double {
  floor(self + 0.5)
}
