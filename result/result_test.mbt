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
test "Result unwrap should return Ok value" {
  let ok_result : Result[Int, Error] = Ok(42)
  assert_eq(ok_result.unwrap(), 42)
  assert_eq(ok_result.unwrap_or_error(), 42)
}

///|
test "bind with Err" {
  let x : Result[Int, String] = Err("error")
  let y = x.bind(v => Ok(v * 7))
  assert_eq(y, Err("error"))
}

///|
test "wrap0 with error" {
  let f : () -> Int raise Failure = () => raise Failure::Failure("error")
  let result = try? f()
  inspect(
    result,
    content=(
      #|Err(Failure("error"))
    ),
  )
}

///|
test "wrap2 with error result" {
  let f : (Int, Int) -> Unit raise Failure = (_, _) => raise Failure::Failure(
    "error",
  )
  let r = try? f(1, 2)
  inspect(
    r,
    content=(
      #|Err(Failure("error"))
    ),
  )
}
