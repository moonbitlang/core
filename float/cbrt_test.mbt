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
  inspect!((0 : Float).cbrt(), content="0")
  inspect!((1 : Float).cbrt(), content="1")
  inspect!((2 : Float).cbrt(), content="1.2599210739135742")
  inspect!((3 : Float).cbrt(), content="1.4422495365142822")
  inspect!((4 : Float).cbrt(), content="1.587401032447815")
  inspect!((5 : Float).cbrt(), content="1.7099759578704834")
  inspect!((-6 : Float).cbrt(), content="-1.8171205520629883")
  inspect!((-7 : Float).cbrt(), content="-1.912931203842163")
  inspect!((-8 : Float).cbrt(), content="-2")
  inspect!(@float.not_a_number.cbrt(), content="NaN")
  inspect!(@float.infinity.cbrt(), content="Infinity")
  inspect!(@float.neg_infinity.cbrt(), content="-Infinity")
}
