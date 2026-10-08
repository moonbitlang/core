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
test "Error display without importing error" {
  let error : Error = Failure("test error")
  let to_string = Error::to_string
  inspect(
    to_string(error),
    content=(
      #|Failure(test error)
    ),
  )
  inspect(
    error.to_string(),
    content=(
      #|Failure(test error)
    ),
  )
  inspect(
    error,
    content=(
      #|Failure(test error)
    ),
  )
}

///|
test "Error JSON without importing error" {
  let error : Error = Failure("test error")
  debug_inspect(
    Json(error),
    content="Array([String(\"Failure\"), String(\"test error\")])",
  )
}
