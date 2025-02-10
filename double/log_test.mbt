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
