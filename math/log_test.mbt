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
test "lnf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, @float.neg_infinity,
    @float.not_a_number, @float.infinity,
  ]
  let libm_results : Array[Float] = [
    0, 0.6931471824645996, 1.0986123085021973, 1.3862943649291992, 1.6094379425048828,
    1.8718022108078003, 2.0149030685424805, 2.140066146850586, 2.2512917518615723,
    2.3513753414154053, -1.3862943649291992, 0.2231435477733612, 0.8109301924705505,
    1.1786550283432007, 1.4469189643859863, @float.not_a_number, @float.not_a_number,
    @float.infinity,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = lnf(x)
    let libm_res = libm_results[i]
    assert_true(
      (res.reinterpret_as_int() - libm_res.reinterpret_as_int()).abs() <= 2,
    )
  }
}

///|
test "ln_1p" {
  inspect(ln_1pf(0), content="0")
  inspect(ln_1pf(1), content="0.6931471824645996")
  inspect(ln_1pf(2), content="1.0986123085021973")
  inspect(ln_1pf(3), content="1.3862943649291992")
  inspect(ln_1pf(4), content="1.6094379425048828")
  inspect(ln_1pf(5), content="1.7917594909667969")
  inspect(ln_1pf(-0.5), content="-0.6931471824645996")
  inspect(ln_1pf(-1), content="-Infinity")
  inspect(ln_1pf(-2), content="NaN")
  inspect(ln_1pf(@float.not_a_number), content="NaN")
  inspect(ln_1pf(@float.infinity), content="Infinity")
  inspect(ln_1pf(@float.neg_infinity), content="NaN")
}

///|
test "log2 log10" {
  // log2
  assert_eq(log2(3.0), 1.584962500721156)
  assert_eq(log2(2.0), 1.0)
  assert_eq(log2(1.0), 0.0)
  assert_eq(log2(0.5), -1.0)
  assert_eq(log2(0.25), -2.0)
  assert_eq(log2(0.1), -3.321928094887362)

  // log10
  assert_eq(log10(0.2), -0.6989700043360187)
  assert_eq(log10(0.1), -1)
  assert_eq(log10(1.0), 0.0)
  assert_eq(log10(10.0), 1.0)
  assert_eq(log10(100.0), 2.0)
  assert_eq(log10(1000.0), 3.0)
  assert_eq(log10(3.0), 0.47712125471966244)
  assert_eq(log10(11.0), 1.041392685158225)
  assert_eq(log10(15.0), 1.1760912590556813)
}

///|
test "ln" {
  assert_true(ln(@double.not_a_number).is_nan())
  assert_true(ln(@double.infinity).is_pos_inf())
  assert_true(ln(@double.neg_infinity).is_nan())
  assert_true(ln(-1.0).is_nan())
  assert_true(ln(0.0).is_neg_inf())
  assert_true(ln(-0.0).is_neg_inf())
  assert_eq(ln(50.0), 3.912023005428146)
  assert_eq(ln(2.0), 0.6931471805599453)
  assert_eq(ln(1.1125369292536007e-308), -709.0895657128241)
  assert_eq(ln(5.562684646268003e-309), -709.782712893384)
}

///|
test "ln_1p" {
  assert_true(ln_1p(@double.not_a_number).is_nan())
  assert_true(ln_1p(@double.infinity).is_pos_inf())
  assert_true(ln_1p(@double.neg_infinity).is_nan())
  assert_true(ln_1p(-1.0).is_neg_inf())
  assert_eq(ln_1p(0.0), 0.0)
}
