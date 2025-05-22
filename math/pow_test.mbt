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
  inspect!(scalbnf(1.5, 2), content="6")
  inspect!(scalbnf(2.0, -1), content="1")
  inspect!(scalbnf(3.0, 0), content="3")
  inspect!(scalbnf(1.0, 128), content="Infinity")
  inspect!(scalbnf(1.0, -150), content="0")
  inspect!(scalbnf(1.0, 254), content="Infinity")
  inspect!(scalbnf(1.0, -199), content="0")
  inspect!(scalbnf(1.0, 307), content="Infinity")
  inspect!(scalbnf(1.0, -296), content="0")
  inspect!(scalbnf(@float.infinity, 10), content="Infinity")
  inspect!(scalbnf(@float.not_a_number, 10), content="NaN")
  inspect!(scalbnf(0.0, 10), content="0")
}

///|
test "pow" {
  inspect!(powf(1.0, 3.0), content="1")
  inspect!(powf(-1.0, 3.0), content="-1")
  inspect!(powf(2.0, 3.0), content="8")
  inspect!(powf(-2.0, 3.0), content="-8")
  inspect!(powf(2.0, -3.0), content="0.125")
  inspect!(powf(-2.0, -3.0), content="-0.125")
  inspect!(powf(2.0, -3.14), content="0.1134398877620697")
  inspect!(powf(-2.0, -3.14), content="NaN")
  inspect!(powf(@float.infinity, 3.0), content="Infinity")
  inspect!(powf(@float.infinity, -3.0), content="0")
  inspect!(powf(@float.infinity, 0.0), content="1")
  inspect!(powf(@float.neg_infinity, 3.0), content="-Infinity")
  inspect!(powf(@float.neg_infinity, -3.0), content="0")
  inspect!(powf(@float.neg_infinity, 0.0), content="1")
  inspect!(powf(@float.not_a_number, 3.0), content="NaN")
}
