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
test "cbrtf" {
  inspect(cbrtf(0), content="0")
  inspect(cbrtf(1), content="1")
  inspect(cbrtf(2), content="1.2599210739135742")
  inspect(cbrtf(3), content="1.4422495365142822")
  inspect(cbrtf(4), content="1.587401032447815")
  inspect(cbrtf(5), content="1.7099759578704834")
  inspect(cbrtf(-6), content="-1.8171205520629883")
  inspect(cbrtf(-7), content="-1.912931203842163")
  inspect(cbrtf(-8), content="-2")
  inspect(cbrtf(@float.not_a_number), content="NaN")
  inspect(cbrtf(@float.infinity), content="Infinity")
  inspect(cbrtf(@float.neg_infinity), content="-Infinity")
}

///|
test "hypotf" {
  inspect(hypotf(3, 4), content="5")
  inspect(hypotf(5, 12.0), content="13")
  inspect(hypotf(8, 15.0), content="17")
  inspect(hypotf(7, 24.0), content="25")
  inspect(hypotf(20, 21.0), content="29")
  inspect(hypotf(9, 40.0), content="41")
  inspect(hypotf(12, 35.0), content="37")
  inspect(hypotf(11, 60.0), content="61")
  inspect(hypotf(16, 63.0), content="65")
  inspect(hypotf(@float.not_a_number, 1.0), content="NaN")
  inspect(hypotf(1, @float.not_a_number), content="NaN")
  inspect(hypotf(@float.infinity, 1.0), content="Infinity")
  inspect(hypotf(1.0, @float.infinity), content="Infinity")
  inspect(hypotf(@float.neg_infinity, 1.0), content="Infinity")
  inspect(hypotf(1, @float.neg_infinity), content="Infinity")
}
