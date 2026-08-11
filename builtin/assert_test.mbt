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
#warnings("-deprecated")
test "panic @test.assert_not_eq with equal values" {
  let str = "test"
  ignore(@test.assert_not_eq(str, str))
}

///|
test "panic assert_false with true" {
  ignore(assert_false(true))
}

///|
#warnings("-deprecated")
test "panic @test.assert_eq with unequal values" {
  ignore(@test.assert_eq(1, 2))
}

///|
test "panic assert_true with false" {
  ignore(assert_true(false))
}
