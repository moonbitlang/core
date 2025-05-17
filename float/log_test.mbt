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
    let res = x.ln()
    let libm_res = libm_results[i]
    assert_true!(
      iabs(res.reinterpret_as_int() - libm_res.reinterpret_as_int()) <= 2,
    )
  }
}

///|
test "ln_1pf Test" {
  let data : Array[Float] = [
    1, 2, 3, 4, 5, 6.5, 7.5, 8.5, 9.5, 10.5, 0.25, 1.25, 2.25, 3.25, 4.25, @float.neg_infinity,
    @float.not_a_number, @float.infinity,
  ]
  let libm_results : Array[Float] = [
    0.6931471824645996, 1.0986123085021973, 1.3862943649291992, 1.6094379425048828,
    1.7917594909667969, 2.0149030685424805, 2.140066146850586, 2.2512917518615723,
    2.3513753414154053, 2.4423470497131348, 0.2231435477733612, 0.8109301924705505,
    1.1786550283432007, 1.4469189643859863, 1.6582280397415161, @float.not_a_number,
    @float.not_a_number, @float.infinity,
  ]
  for i in 0..<data.length() {
    let x = data[i]
    let res = x.ln_1p()
    let libm_res = libm_results[i]
    assert_true!(
      iabs(res.reinterpret_as_int() - libm_res.reinterpret_as_int()) <= 2,
    )
  }
}
