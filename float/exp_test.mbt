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

test "exp" {
  inspect!((0.5 : Float).exp(), content="1.6487212181091309")
  inspect!((1.0 : Float).exp(), content="2.7182817459106445")
  inspect!((0.0 : Float).exp(), content="1")
  inspect!((2.0 : Float).exp(), content="7.389056205749512")
  inspect!((-1.0 : Float).exp(), content="0.3678794503211975")
  inspect!(@float.infinity.exp(), content="Infinity")
  inspect!(@float.neg_infinity.exp(), content="0")
  inspect!((89 : Float).exp(), content="Infinity")
  inspect!((-104 : Float).exp(), content="0")
}

test "exp - quickcheck" {
  let double : Array[Double] = @quickcheck.samples(4)
  inspect!(
    double,
    content="[0.12125190562607557, 0.2656190379663609, 0.7248184591724188, 0.8261703932281662]",
  )
  inspect!(
    double.map(fn(x) { x.exp() }),
    content="[1.1289092551447675, 1.3042380988330389, 2.064356300995553, 2.2845530266177425]",
  )
  let float = double.map(Double::to_float)
  inspect!(
    float,
    content="[0.1212519034743309, 0.26561903953552246, 0.7248184680938721, 0.8261703848838806]",
  )
  inspect!(
    float.map(fn(x) { x.exp() }),
    content="[1.1289092302322388, 1.3042380809783936, 2.0643563270568848, 2.284553050994873]",
  )
}
