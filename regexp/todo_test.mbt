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
test "to be discussed" {
  // This should be allowed in some flavors where the `{` is considered a literal character
  guard (try? @regexp.compile("a{2")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidRepeatOp, source_fragment="")
    ),
  )
  // This should raise InvalidRepeatOp to align with golang
  guard (try? @regexp.compile("a++")) is Err(error)
  error
  |> inspect(
    content=(
      #|RegexpError(err=InvalidEscape, source_fragment="+")
    ),
  )
  // Behavior difference between Golang and JS
  // The current behavior aligns with Golang, where the last match is returned for each submatch
  // In JS, the submatch is matched only if the parent is matched
  let regex = @regexp.compile("((?<a>a)|(?<b>b))+")
  let result = regex.execute("ab")
  inspect(
    result.groups(),
    content=(
      #|{"a": "a", "b": "b"}
    ),
  )

  // Behavior difference between Golang and JS
  // The current behavior aligns with Golang
  // reference https://github.com/golang/go/issues/46123
  let regex = @regexp.compile("(|a)+")
  let result = regex.execute("aaa")
  inspect(
    result.get(0),
    content=(
      #|Some("")
    ),
  )
  let regex = @regexp.compile("(|a)*")
  let result = regex.execute("aaa")
  inspect(
    result.get(0),
    content=(
      #|Some("")
    ),
  )
}
