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
test "Result equality with Ok" {
  let result1 : Result[Int, String] = Result::Ok(1)
  let result2 = Result::Ok(1)
  let result3 = Result::Ok(2)
  assert_eq!(result1, result2)
  assert_not_eq!(result1, result3)
}

///|
test "Result equality with Err" {
  let result1 : Result[Int, String] = Result::Err("error")
  let result2 = Result::Err("error")
  let result3 = Result::Err("different error")
  assert_eq!(result1, result2)
  assert_not_eq!(result1, result3)
}

///|
test "Result equality mixed" {
  let okResult = Result::Ok(1)
  let errResult = Result::Err("error")
  assert_not_eq!(okResult, errResult)
}
