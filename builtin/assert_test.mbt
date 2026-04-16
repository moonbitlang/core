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
struct ShowOnly(Int) derive(Eq)

///|
impl Show for ShowOnly with output(self, logger) {
  let ShowOnly(value) = self
  logger.write_object(value)
}

///|
#warnings("-deprecated")
test "panic assert_not_eq with equal values" {
  let str = "test"
  ignore(assert_not_eq(str, str))
}

///|
test "panic assert_false with true" {
  ignore(assert_false(true))
}

///|
#warnings("-deprecated")
test "panic assert_eq with unequal values" {
  ignore(assert_eq(1, 2))
}

///|
test "panic assert_true with false" {
  ignore(assert_true(false))
}

///|
#warnings("-deprecated")
test "legacy assert_eq still works for Show-only types" {
  @builtin.assert_eq(ShowOnly(1), ShowOnly(1))
  @builtin.assert_not_eq(ShowOnly(1), ShowOnly(2))
}
