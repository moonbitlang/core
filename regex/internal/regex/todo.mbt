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
  // In JS, this is parsed as two character classes with no characters
  // In Golang, this is parsed as one character class with `]` and `[`
  parse("[][]").ast
  |> inspect(
    content="Concat([CharClass([], neg=false), CharClass([], neg=false)])",
  )
}

///|
/// Reference: https://github.com/golang/go/issues/46123
test "to be fixed" {
  let result = parse("(|a)*").compile().execute("aaa")
  inspect(
    result.get(0),
    content=(
      #|Some("")
    ),
  )
  let result = parse("(|a)+").compile().execute("aaa")
  inspect(
    result.get(0),
    content=(
      #|Some("")
    ),
  )
}
