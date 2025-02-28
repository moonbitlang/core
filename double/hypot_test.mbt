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
test "hypot" {
  inspect!(3.0.hypot(4), content="5")
  inspect!(6.0.hypot(8), content="10")
  inspect!(5.0.hypot(12), content="13")
  inspect!(7.0.hypot(24), content="25")
  inspect!(@double.not_a_number.hypot(2), content="NaN")
  inspect!(2.0.hypot(@double.not_a_number), content="NaN")
  inspect!(3.0.hypot(@double.infinity), content="Infinity")
  inspect!(@double.infinity.hypot(2), content="Infinity")

  // Precision Test
  let xs = [1.2, 2.3, 3.4, 4.5, 5.6]
  let ys = [-9.6, -8.5, -7.4, -6.3, -5.2]
  let hypot_res = [
    9.674709297958259, 8.584287972802404, 7.496665925596526, 6.413267497929586, 5.336665625650534,
    9.871676655968834, 8.805679985100525, 7.749193506423749, 6.7067130548428855,
    5.6859475903318, 10.184301645179211, 9.154780172128657, 8.143709228600933, 7.158910531638176,
    6.212889826803627, 10.602358228243375, 9.617692030835672, 8.66083136886985, 7.7420927403383635,
    6.876772498781678, 11.113955191559844, 10.178899744078432, 9.280086206496145,
    8.429116205154607, 7.6419892698171195,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_true!(ulp <= 1)
  }

  let mut i : Int = 0
  for x in xs {
    for y in ys {
      high_accuracy_test!(x.hypot(y), hypot_res[i])
      i = i + 1
    }
  }
}
