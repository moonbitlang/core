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
test "log" {
  inspect!((1.0 : Float).ln(), content="0")
  inspect!((0.0 : Float).ln(), content="-Infinity")
  inspect!(@float.infinity.ln(), content="Infinity")
  inspect!((2.0 : Float).ln(), content="0.6931471824645996")
  inspect!((2.718 : Float).ln(), content="0.9998962879180908")
  inspect!((1.0e37 : Float).ln(), content="85.19564819335938")
  inspect!((-1.0 : Float).ln(), content="NaN")
}

///|
test "ln_1p" {
  inspect!((0 : Float).ln_1p(), content="0")
  inspect!((1 : Float).ln_1p(), content="0.6931471824645996")
  inspect!((2 : Float).ln_1p(), content="1.0986123085021973")
  inspect!((3 : Float).ln_1p(), content="1.3862943649291992")
  inspect!((4 : Float).ln_1p(), content="1.6094379425048828")
  inspect!((5 : Float).ln_1p(), content="1.7917594909667969")
  inspect!((-0.5 : Float).ln_1p(), content="-0.6931471824645996")
  inspect!((-1 : Float).ln_1p(), content="-Infinity")
  inspect!((-2 : Float).ln_1p(), content="NaN")
  inspect!(@float.not_a_number.ln_1p(), content="NaN")
  inspect!(@float.infinity.ln_1p(), content="Infinity")
  inspect!(@float.neg_infinity.ln_1p(), content="NaN")
}
