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

test "overflow" {
  // signed integer expected to be negative
  inspect!(0xC2B2AE3D, content="-1028477379")
  inspect!(0x85EBCA77, content="-2048144777")
  inspect!(0x80000000, content="-2147483648")
  // here it works as expected due to overflow
  inspect!(-0x80000000, content="-2147483648")
  inspect!(0x7fff_ffff, content="2147483647")
  inspect!(-0x7fff_ffff, content="-2147483647")
}

test "hash" {
  inspect!(hash(0), content="0")
  inspect!(hash(1), content="69681622")
  inspect!(hash(2), content="-236984087")
  inspect!(hash(3), content="-1057966777")
  inspect!(hash(4), content="-744398955")
  inspect!(hash(5), content="-482482911")
  inspect!(hash(6), content="-1506254959")
  inspect!(hash(7), content="1327878809")
  inspect!(hash(8), content="1120898975")
  inspect!(hash(9), content="1567958539")
  inspect!(hash(0x7fffffff), content="943411498")
  inspect!(hash(0x7fffffff + 1), content="963800214")
}

test "abs function coverage" {
  // Test cases for abs function
  @test.eq(abs(5), 5)!
  @test.eq(abs(-5), 5)!
  @test.eq(abs(0), 0)!
  @test.eq(abs(Int::min_value()), Int::min_value().abs())!
  @test.eq(abs(Int::max_value()), Int::max_value())!
}
