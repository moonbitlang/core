// Copyright 2026 International Digital Economy Academy
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
test "UInt64::min, UInt64::max and UInt64::clamp" {
  @test.assert_eq(UInt64(1).min(2), 1)
  @test.assert_eq(UInt64(2).min(1), 1)
  @test.assert_eq(UInt64(2).max(1), 2)
  @test.assert_eq(UInt64(1).max(2), 2)
  @test.assert_eq(UInt64(1).clamp(min=0, max=2), 1)
  @test.assert_eq(UInt64(0).clamp(min=1, max=2), 1)
  @test.assert_eq(UInt64(3).clamp(min=1, max=2), 2)
  @test.assert_eq(UInt64(7).clamp(min=7, max=7), 7)
}

///|
test "UInt64::min, UInt64::max and UInt64::clamp at the extremes" {
  let zero = UInt64(0)
  let top = 0xFFFF_FFFF_FFFF_FFFFUL
  // 2^63 is negative when reinterpreted as Int64, so these pin unsigned order.
  let high_bit = 0x8000_0000_0000_0000UL
  let below_high_bit = 0x7FFF_FFFF_FFFF_FFFFUL
  @test.assert_eq(zero.min(top), zero)
  @test.assert_eq(top.min(zero), zero)
  @test.assert_eq(zero.max(top), top)
  @test.assert_eq(top.max(zero), top)
  @test.assert_eq(high_bit.min(below_high_bit), below_high_bit)
  @test.assert_eq(below_high_bit.max(high_bit), high_bit)
  @test.assert_eq(top.min(top), top)
  @test.assert_eq(top.clamp(min=zero, max=top), top)
  @test.assert_eq(zero.clamp(min=zero, max=top), zero)
  @test.assert_eq(top.clamp(min=zero, max=high_bit), high_bit)
  @test.assert_eq(zero.clamp(min=high_bit, max=top), high_bit)
  @test.assert_eq(high_bit.clamp(min=1, max=below_high_bit), below_high_bit)
  @test.assert_eq(below_high_bit.clamp(min=high_bit, max=top), high_bit)
  @test.assert_eq(top.clamp(min=top, max=top), top)
}

///|
test "panic UInt64::clamp with invalid range" {
  ignore(UInt64(1).clamp(min=2, max=1))
}

///|
test "panic UInt64::clamp with invalid range at the extremes" {
  ignore(UInt64(0).clamp(min=0xFFFF_FFFF_FFFF_FFFFUL, max=0))
}
