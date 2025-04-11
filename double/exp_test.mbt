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
test "exp" {
  inspect!(@double.exp(1.0), content="2.718281828459045")
  inspect!(@double.exp(-1.0), content="0.36787944117144233")
  inspect!(@double.exp(1.0e-10), content="1.0000000001")
  inspect!(@double.exp(-1.0e-10), content="0.9999999999")
  inspect!(@double.exp(2.0), content="7.38905609893065")
  inspect!(@double.exp(-2.0), content="0.1353352832366127")
  inspect!(@double.exp(0.5), content="1.6487212707001282")
  inspect!(@double.exp(-0.5), content="0.6065306597126334")
  inspect!(@double.exp(5.0), content="148.4131591025766")
  inspect!(@double.exp(-5.0), content="0.006737946999085467")
  inspect!(@double.exp(10.0), content="22026.465794806718")
  inspect!(@double.exp(-10.0), content="0.00004539992976248485")
  inspect!(@double.exp(100.0), content="2.6881171418161356e+43")
  inspect!(@double.exp(-100.0), content="3.720075976020836e-44")
}

///|
test "exp - special values" {
  inspect!(@double.exp(@double.neg_infinity), content="0")
  inspect!(@double.exp(@double.infinity), content="Infinity")
  inspect!(@double.exp(@double.not_a_number), content="NaN")
  inspect!(@double.exp(0.0), content="1")
}

///|
test "exp - overflow & underflow" {
  inspect!(@double.exp(710.0), content="Infinity")
  inspect!(@double.exp(-745.14), content="0")
}

///|
test "expm1" {
  inspect!(0.0.expm1(), content="0")
  inspect!(1.0.expm1(), content="1.718281828459045")
  inspect!(2.0.expm1(), content="6.38905609893065")
  inspect!((-1.0).expm1(), content="-0.6321205588285577")
  inspect!((-2.0).expm1(), content="-0.8646647167633873")
  inspect!(@double.not_a_number.expm1(), content="NaN")
  inspect!(@double.infinity.expm1(), content="Infinity")
  inspect!(@double.neg_infinity.expm1(), content="-1")
  let vals = [
    -10.0, -9.0, -8.0, -7.0, -6.0, -5.0, -4.0, -3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0,
    4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 1.23, 2.45, 3.67, 4.89, 5.67, 6.78, 7.89,
    8.90, 9.87, 10.98,
  ]
  let expm1_res = [
    -0.9999546000702375, -0.9998765901959134, -0.9996645373720975, -0.9990881180344455,
    -0.9975212478233336, -0.9932620530009145, -0.9816843611112658, -0.950212931632136,
    -0.8646647167633873, -0.6321205588285577, 0, 1.718281828459045, 6.38905609893065,
    19.085536923187668, 53.598150033144236, 147.4131591025766, 402.4287934927351,
    1095.6331584284585, 2979.9579870417283, 8102.083927575384, 22025.465794806718,
    2.4212295362896734, 10.588346719223392, 38.2519058603045, 131.95357405128274,
    289.03453439173467, 879.0687241078031, 2669.443920676805, 7330.973539155995,
    19340.338973747792, 58687.55427461758,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_true!(ulp <= 1)
  }

  for i in 0..<vals.length() {
    high_accuracy_test!(expm1_res[i], vals[i].expm1())
  }
}
