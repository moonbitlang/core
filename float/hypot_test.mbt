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
  inspect!((3.0 : Float).hypot(4.0), content="5")
  inspect!((5.0 : Float).hypot(12.0), content="13")
  inspect!((8.0 : Float).hypot(15.0), content="17")
  inspect!((7.0 : Float).hypot(24.0), content="25")
  inspect!((20.0 : Float).hypot(21.0), content="29")
  inspect!((9.0 : Float).hypot(40.0), content="41")
  inspect!((12.0 : Float).hypot(35.0), content="37")
  inspect!((11.0 : Float).hypot(60.0), content="61")
  inspect!((16.0 : Float).hypot(63.0), content="65")
  inspect!(@float.not_a_number.hypot(1.0), content="NaN")
  inspect!((1.0 : Float).hypot(@float.not_a_number), content="NaN")
  inspect!(@float.infinity.hypot(1.0), content="Infinity")
  inspect!((1.0 : Float).hypot(@float.infinity), content="Infinity")
  inspect!(@float.neg_infinity.hypot(1.0), content="Infinity")
  inspect!((1.0 : Float).hypot(@float.neg_infinity), content="Infinity")
}
