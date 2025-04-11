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
test "hyperbolic" {
  // sinh
  inspect!(@math.sinh(1), content="1.1752011936438014")
  inspect!(@math.sinh(2), content="3.626860407847019")

  // cosh
  inspect!(@math.cosh(1), content="1.5430806348152437")
  inspect!(@math.cosh(2), content="3.7621956910836314")

  // tanh
  inspect!(@math.tanh(1), content="0.7615941559557649")
  inspect!(@math.tanh(2), content="0.9640275800758169")
}

///|
test "inverse hyperbolic" {
  // asinh
  inspect!(@math.asinh(1), content="0.881373587019543")
  inspect!(@math.asinh(2), content="1.4436354751788103")

  // acosh
  inspect!(@math.acosh(2), content="1.3169578969248166")
  inspect!(@math.acosh(5.5), content="2.3895264345742184")

  // atanh
  inspect!(@math.atanh(0.3), content="0.30951960420311175")
  inspect!(@math.atanh(0.5), content="0.5493061443340548")
}
