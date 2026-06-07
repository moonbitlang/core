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
test "int64 bit ops and counts" {
  let hi_only : Int64 = 0x1_0000_0000L
  let lo_only : Int64 = 8L
  @test.assert_eq(hi_only.clz(), 31)
  @test.assert_eq(hi_only.ctz(), 32)
  @test.assert_eq(lo_only.clz(), 60)
  @test.assert_eq(lo_only.ctz(), 3)
  @test.assert_eq((hi_only | lo_only).popcnt(), 2)
  @test.assert_eq(0xF0L & 0x0FL, 0L)
  @test.assert_eq(0xF0L | 0x0FL, 0xFFL)
  @test.assert_eq(0xF0L ^ 0x0FL, 0xFFL)
}

///|
test "int64 conversions and defaults" {
  let value : Int64 = 123L
  @test.assert_eq(value.to_int(), 123)
  @test.assert_eq(value.to_byte(), (123 : Byte))
  @test.assert_eq(value.to_uint16(), (123 : UInt16))
  @test.assert_eq((65535 : UInt16).to_int64(), 65535L)
  @test.assert_eq(Int64::default(), 0L)
  let u_hi : UInt64 = 0x1_0000_0000UL
  @test.assert_eq(u_hi.clz(), 31)
  @test.assert_eq(u_hi.ctz(), 32)
  @test.assert_eq(UInt64::trunc_double(1234567.89), 1234567UL)
}

///|
test "Int64::min, Int64::max and Int64::clamp" {
  @test.assert_eq(1L.min(2L), 1L)
  @test.assert_eq(2L.max(1L), 2L)
  @test.assert_eq(1L.clamp(min=0L, max=2L), 1L)
  @test.assert_eq((-1L).clamp(min=0L, max=2L), 0L)
  @test.assert_eq(3L.clamp(min=0L, max=2L), 2L)
}

///|
test "panic Int64::clamp with invalid range" {
  ignore(1L.clamp(min=2L, max=1L))
}
