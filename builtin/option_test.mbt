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
test {
  assert_eq((Option::None : Unit?), Option::None)
  assert_eq(Option::Some(1), Option::Some(1))
  assert_not_eq(Option::Some(1), Option::Some(2))
  assert_not_eq(Option::None, Option::Some(1))
  assert_not_eq(Option::Some(1), Option::None)
}

///|
test "to_string for Option None" {
  let x : Int? = None
  inspect(x.to_string(), content="None")
}

///|
test "to_string for Option Some" {
  let x : Int? = Some(42)
  inspect(x.to_string(), content="Some(42)")
}
