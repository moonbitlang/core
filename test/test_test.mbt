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
struct DebugOnly(Int) derive(Eq, Debug)

///|
struct ShowOnly(Int) derive(Eq)

///|
impl Show for ShowOnly with output(self, logger) {
  let ShowOnly(value) = self
  logger.write_object(value)
}

///|
test " same_object call with the same object" {
  let s = "Hello"
  @test.same_object(s, s)
}

///|
test "panic same_object call with different objects" {
  let a = "1"
  let b = "2"
  @test.same_object(a, b)
}

///|
test "is_not called with the different objects" {
  let a = "1"
  let b = "2"
  @test.not_same_object(a, b)
}

///|
test "panic is_not called with the same object" {
  let s = "Hello"
  @test.not_same_object(s, s)
}

///|
test "assert_eq and assert_not_eq work for Debug-only types" {
  let first = DebugOnly(1)
  let second = DebugOnly(1)
  let third = DebugOnly(2)
  @test.assert_eq(first, second)
  @test.assert_not_eq(first, third)
}

///|
test "assert_same_object and assert_not_same_object work for Debug-only types" {
  let first = [DebugOnly(1)]
  let same = first
  let other = [DebugOnly(1)]
  @test.assert_same_object(first, same)
  @test.assert_not_same_object(first, other)
}

///|
test "legacy Show-based identity assertions still support Show-only types" {
  let first = [ShowOnly(1)]
  let same = first
  let other = [ShowOnly(1)]
  @test.same_object(first, same)
  @test.not_same_object(first, other)
}

///|
test "Test name" {
  let t = @test.new("sample")
  inspect(t.name(), content="sample")
}
