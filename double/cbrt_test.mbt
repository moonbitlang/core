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
test "cbrt" {
  inspect!(1.0.cbrt(), content="1")
  inspect!(3.0.cbrt(), content="1.4422495703074083")
  inspect!((-3.0).cbrt(), content="-1.4422495703074083")
  inspect!(10.0.cbrt(), content="2.154434690031884")
  inspect!(1000.0.cbrt(), content="10")
  inspect!(not_a_number.cbrt(), content="NaN")
  inspect!(infinity, content="Infinity")
  inspect!(neg_infinity, content="-Infinity")
  let vals = [
    -2.1, -3.2, -4.3, -5.4, -6.5, -7.6, -8.7, -9.8, -10.9, -11.1, 1.2, 2.3, 3.4,
    4.5, 5.6, 6.7, 7.8, 8.9, 9.1, 10.2, 1357.9, 2468.0, 3579.1, 4680.2, 5791.3, 6802.4,
    7913.5, 8024.6, 9135.7, 10246.8,
  ]
  let cbrt_res = [
    -1.2805791649874942, -1.4736125994561546, -1.6261333316791686, -1.7544106429277198,
    -1.866255578408624, -1.966095144983117, -2.0567101162059633, -2.139974961130159,
    -2.217220230966632, -2.23069910447562, 1.0626585691826111, 1.3200061217959125,
    1.5036945962049748, 1.6509636244473134, 1.7758080034852013, 1.885203631020986,
    1.9831924826807747, 2.072351098059261, 2.087759478663449, 2.168702885250197,
    11.073610986450177, 13.513931662736733, 15.29647205313303, 16.72713148617636,
    17.95802978703349, 18.947593347990452, 19.927655294373867, 20.02047902332293,
    20.9048606324266, 21.72014665034662,
  ]
  fn high_accuracy_test(expect : Double, actual : Double) -> Unit!Error {
    let ulp = (expect.reinterpret_as_int64() - actual.reinterpret_as_int64()).abs()
    assert_true!(ulp <= 1)
  }

  for i in 0..<vals.length() {
    high_accuracy_test!(vals[i].cbrt(), cbrt_res[i])
  }
}
