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

///|
fn top12(x : Float) -> UInt {
  x.reinterpret_as_uint() >> 20
}

///|
fn __math_xflowf(sign : UInt, y : Float) -> Float {
  return (if sign != 0 { -y } else { y }) * y
}

///|
fn __math_oflowf(sign : UInt) -> Float {
  return __math_xflowf(sign, 0x1.0p97)
}

///|
fn __math_uflowf(sign : UInt) -> Float {
  return __math_xflowf(sign, 0x1.0p-95)
}

///|
let exp2f_table_bits = 5

///|
priv struct Exp2fData {
  tab : FixedArray[UInt64]
  shift : Double
  invln2_scaled : Double
  poly_scaled : FixedArray[Double]
}

///|
let expf_n : UInt64 = (1 << exp2f_table_bits).to_uint64()

///|
let exp2f_data_n : Double = (1 << exp2f_table_bits).to_double()

///|
let exp2f_data : Exp2fData = {
  tab: [
    0x3ff0000000000000, 0x3fefd9b0d3158574, 0x3fefb5586cf9890f, 0x3fef9301d0125b51,
    0x3fef72b83c7d517b, 0x3fef54873168b9aa, 0x3fef387a6e756238, 0x3fef1e9df51fdee1,
    0x3fef06fe0a31b715, 0x3feef1a7373aa9cb, 0x3feedea64c123422, 0x3feece086061892d,
    0x3feebfdad5362a27, 0x3feeb42b569d4f82, 0x3feeab07dd485429, 0x3feea47eb03a5585,
    0x3feea09e667f3bcd, 0x3fee9f75e8ec5f74, 0x3feea11473eb0187, 0x3feea589994cce13,
    0x3feeace5422aa0db, 0x3feeb737b0cdc5e5, 0x3feec49182a3f090, 0x3feed503b23e255d,
    0x3feee89f995ad3ad, 0x3feeff76f2fb5e47, 0x3fef199bdd85529c, 0x3fef3720dcef9069,
    0x3fef5818dcfba487, 0x3fef7c97337b9b5f, 0x3fefa4afa2a490da, 0x3fefd0765b6e4540,
  ],
  shift: 0x1.8p+52,
  invln2_scaled: 0x1.71547652b82fep+0 * exp2f_data_n,
  poly_scaled: [
    0x1.c6af84b912394p-5 / exp2f_data_n / exp2f_data_n / exp2f_data_n,
    0x1.ebfce50fac4f3p-3 / exp2f_data_n / exp2f_data_n,
    0x1.62e42ff0c52d6p-1 / exp2f_data_n,
  ],
}
