// Copyright 2024 International Digital Economy Academy
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

test "pow" {
  inspect!(@double.pow(2.0, 0.0), content="1")
  inspect!(@double.pow(-2.0, 0.0), content="1")
  inspect!(@double.pow(2.0, -0.0), content="1")
  inspect!(@double.pow(-2.0, -0.0), content="1")
  inspect!(@double.pow(2.0, 0.5), content="1.4142135623730951")
  inspect!(@double.pow(-2.0, 0.5), content="NaN")
  inspect!(@double.pow(2.0, -0.5), content="0.7071067811865475")
  inspect!(@double.pow(-2.0, -0.5), content="NaN")
  inspect!(@double.pow(2.0, 1.0), content="2")
  inspect!(@double.pow(-2.0, 1.0), content="-2")
  inspect!(@double.pow(2.0, -1.0), content="0.5")
  inspect!(@double.pow(-2.0, -1.0), content="-0.5")
  inspect!(@double.pow(2.0, 2.0), content="4")
  inspect!(@double.pow(-2.0, 2.0), content="4")
  inspect!(@double.pow(2.0, -2.0), content="0.25")
  inspect!(@double.pow(-2.0, -2.0), content="0.25")
  inspect!(@double.pow(2.0, 2.5), content="5.65685424949238")
  inspect!(@double.pow(-2.0, 2.5), content="NaN")
  inspect!(@double.pow(2.0, -2.5), content="0.17677669529663687")
  inspect!(@double.pow(-2.0, -2.5), content="NaN")
}

test "pow/zero" {
  inspect!(@double.pow(0.0, 0.0), content="1")
  inspect!(@double.pow(-0.0, 0.0), content="1")
  inspect!(@double.pow(0.0, -0.0), content="1")
  inspect!(@double.pow(-0.0, -0.0), content="1")
  inspect!(@double.pow(0.0, 1.2), content="0")
  inspect!(@double.pow(-0.0, 1.2), content="0")
  inspect!(@double.pow(0.0, -1.2), content="Infinity")
  inspect!(@double.pow(-0.0, -1.2), content="Infinity")
}

test "pow/fraction" {
  inspect!(@double.pow(2.5, 0.0), content="1")
  inspect!(@double.pow(2.5, 2.5), content="9.882117688026185")
  inspect!(@double.pow(-2.5, 2.5), content="NaN")
  inspect!(@double.pow(2.5, -2.5), content="0.10119288512538814")
  inspect!(@double.pow(-2.5, -2.5), content="NaN")
}

test "pow/xflow" {
  inspect!(@double.pow(2.0, 1024.0), content="Infinity")
  inspect!(@double.pow(2.0, -2048.0), content="0")
  inspect!(@double.pow(0.5, 2048.0), content="0")
  inspect!(@double.pow(0.5, -1024.0), content="Infinity")
  inspect!(@double.pow(1.0001, 1.0e10), content="Infinity")
  inspect!(@double.pow(1.0001, -1.0e10), content="0")
  inspect!(@double.pow(1.0001, 1.0e38), content="Infinity")
  inspect!(@double.pow(1.0001, -1.0e38), content="0")
  inspect!(@double.pow(1.0e10, 1.0e10), content="Infinity")
  inspect!(@double.pow(1.0e10, -1.0e10), content="0")
  inspect!(@double.pow(1.0e10, 1.0e38), content="Infinity")
  inspect!(@double.pow(1.0e10, -1.0e38), content="0")
}

test "pow/base-special" {
  inspect!(@double.pow(@double.not_a_number, 3.14), content="NaN")
  inspect!(@double.pow(@double.not_a_number, 3.0), content="NaN")
  inspect!(@double.pow(@double.not_a_number, -3.0), content="NaN")
  inspect!(@double.pow(@double.infinity, 3.14), content="Infinity")
  inspect!(@double.pow(@double.infinity, -3.0), content="0")
  inspect!(@double.pow(@double.neg_infinity, 2.0), content="Infinity")
  inspect!(@double.pow(@double.neg_infinity, 3.0), content="-Infinity")
}

test "pow/exp-special" {
  inspect!(@double.pow(3.14, @double.not_a_number), content="NaN")
  inspect!(@double.pow(3.14, @double.infinity), content="Infinity")
  inspect!(@double.pow(3.14, @double.neg_infinity), content="0")
}
