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

test "pow" (it : @test.T) {
  let value = [
    0.0,
    -0.0,
    0x0000000000000001UL.reinterpret_as_double(),
    -0x0000000000000001UL.reinterpret_as_double(),
    0x0000000000000002UL.reinterpret_as_double(),
    -0x0000000000000002UL.reinterpret_as_double(),
    0x0000000000000003UL.reinterpret_as_double(),
    -0x0000000000000003UL.reinterpret_as_double(),
    1.0e-300,
    -1.0e-300,
    1.0e-10,
    -1.0e-10,
    0.5,
    -0.5,
    1.0,
    -1.0,
    1.224744871,
    -1.224744871,
    1.732,
    -1.732,
    2.0,
    -2.0,
    2.718281828459045,
    -2.718281828459045,
    1024.0,
    -1024.0,
    1075.0,
    -1075.0,
    2048.0,
    -2048.0,
    2147483647.0,
    -2147483647.0,
    1.0e10,
    -1.0e10,
    1.0e300,
    -1.0e300,
    @double.infinity,
    @double.neg_infinity,
    @double.not_a_number,
  ]
  for x in value {
    for y in value {
      it.writeln("\{x} ** \{y} == \{@double.pow(x, y)}")
    }
  }
  it.snapshot!(filename="pow")
}
