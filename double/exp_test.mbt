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
test "exp" {
  inspect!(@double.exp(1.0), content="2.718281828459045")
  inspect!(@double.exp(-1.0), content="0.36787944117144233")
  inspect!(@double.exp(1.0e-10), content="1.0000000001")
  inspect!(@double.exp(-1.0e-10), content="0.9999999999")
  inspect!(@double.exp(2.0), content="7.38905609893065")
  inspect!(@double.exp(-2.0), content="0.1353352832366127")
  inspect!(@double.exp(0.5), content="1.6487212707001282")
  inspect!(@double.exp(-0.5), content="0.6065306597126334")
  inspect!(@double.exp(5.0), content="148.4131591025766")
  inspect!(@double.exp(-5.0), content="0.006737946999085467")
  inspect!(@double.exp(10.0), content="22026.465794806718")
  inspect!(@double.exp(-10.0), content="0.00004539992976248485")
  inspect!(@double.exp(100.0), content="2.6881171418161356e+43")
  inspect!(@double.exp(-100.0), content="3.720075976020836e-44")
}

///|
test "exp - special values" {
  inspect!(@double.exp(@double.neg_infinity), content="0")
  inspect!(@double.exp(@double.infinity), content="Infinity")
  inspect!(@double.exp(@double.not_a_number), content="NaN")
  inspect!(@double.exp(0.0), content="1")
}

///|
test "exp - overflow & underflow" {
  inspect!(@double.exp(710.0), content="Infinity")
  inspect!(@double.exp(-745.14), content="0")
}
