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
test "log2 log10" {
  // log2
  inspect!(3.0.log2(), content="1.584962500721156")
  inspect!(2.0.log2(), content="1")
  inspect!(1.0.log2(), content="0")
  inspect!(0.5.log2(), content="-1")
  inspect!(0.25.log2(), content="-2")
  inspect!(0.1.log2(), content="-3.321928094887362")

  // log10
  inspect!(0.2.log10(), content="-0.6989700043360187")
  inspect!(15.0.log10(), content="1.1760912590556813")
}

///|
test "ln" {
  inspect!(not_a_number.ln(), content="NaN")
  inspect!(infinity.ln(), content="Infinity")
  inspect!(neg_infinity.ln(), content="NaN")
  inspect!((-1.0).ln(), content="NaN")
  inspect!(0.0.ln(), content="-Infinity")
  inspect!((-0.0).ln(), content="-Infinity")
  inspect!(50.0.ln(), content="3.912023005428146")
  inspect!(2.0.ln(), content="0.6931471805599453")
  inspect!(1.1125369292536007e-308.ln(), content="-709.0895657128241")
  inspect!(5.562684646268003e-309.ln(), content="-709.782712893384")
}

///|
test "ln_1p" {
  inspect!(0.0.ln_1p(), content="0")
  inspect!(1.0.ln_1p(), content="0.6931471805599453")
  inspect!(2.0.ln_1p(), content="1.0986122886681096")
  inspect!(10.0.ln_1p(), content="2.3978952727983707")
  inspect!(100.0.ln_1p(), content="4.61512051684126")
  inspect!(@double.not_a_number.ln_1p(), content="NaN")
  inspect!((-1.0).ln_1p(), content="-Infinity")
  inspect!((-2.0).ln_1p(), content="NaN")
  inspect!(@double.infinity.ln_1p(), content="Infinity")
  inspect!(@double.neg_infinity.ln_1p(), content="NaN")

  // precision tests
  let vals = [
    1.1, 2.2, 3.3, 4.4, 5.5, 6.6, 7.7, 8.8, 9.9, 10.0, 123.45, 234.56, 345.67, 456.78,
    567.89, 678.90, 789.01, 890.12, 901.23, 987.65, -0.12, -0.23, -0.34, -0.45, -0.56,
    -0.67, -0.78, -0.89, -0.90, -0.98,
  ]
  let ln_1p_res = [
    0.7419373447293773, 1.1631508098056809, 1.4586150226995167, 1.6863989535702286,
    1.8718021769015913, 2.028148247292285, 2.1633230256605382, 2.2823823856765264,
    2.388762789235098, 2.3978952727983707, 4.823904028813601, 5.46196565807637, 5.848373318805697,
    6.126388719364503, 6.343687093820427, 6.521945728532414, 6.672045603608801, 6.792479098536934,
    6.8048694764720015, 6.8963403761668385, -0.12783337150988489, -0.2613647641344075,
    -0.41551544396166584, -0.5978370007556204, -0.8209805520698303, -1.1086626245216111,
    -1.5141277326297757, -2.207274913189721, -2.302585092994046, -3.912023005428145,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_true!(ulp <= 1)
  }

  for i in 0..<vals.length() {
    high_accuracy_test!(ln_1p_res[i], vals[i].ln_1p())
  }
}
