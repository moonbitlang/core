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
test "scalbn" {
  inspect!((1.5 : Float).scalbn(2), content="6")
  inspect!((2.0 : Float).scalbn(-1), content="1")
  inspect!((3.0 : Float).scalbn(0), content="3")
  inspect!((1.0 : Float).scalbn(128), content="Infinity")
  inspect!((1.0 : Float).scalbn(-150), content="0")
  inspect!((1.0 : Float).scalbn(254), content="Infinity")
  inspect!((1.0 : Float).scalbn(-199), content="0")
  inspect!((1.0 : Float).scalbn(307), content="Infinity")
  inspect!((1.0 : Float).scalbn(-296), content="0")
  inspect!(infinity.scalbn(10), content="Infinity")
  inspect!(not_a_number.scalbn(10), content="NaN")
  inspect!((0.0 : Float).scalbn(10), content="0")
}
