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
/// Whether parsing `s` raises a `ParseError`. The match is exhaustive over the
/// `ParseError` variants rather than a catch-all, so an unexpected error type
/// would fail to compile instead of being silently swallowed.
fn parse_raises(s : String) -> Bool {
  try {
    parse(s) |> ignore
    false
  } catch {
    InvalidChar(_, _)
    | InvalidEof
    | InvalidNumber(_, _)
    | InvalidIdentEscape(_)
    | DuplicateKey(_, _)
    | DepthLimitExceeded => true
  }
}

///|
test "invalid leading-minus inputs are rejected" {
  // '-' followed by a non-digit
  inspect(parse_raises("-x"), content="true")
  // '-' at end of input
  inspect(parse_raises("-"), content="true")
}

///|
test "unterminated string escape raises an error" {
  // a backslash at end of input has no escaped character to read
  inspect(parse_raises("\"\\"), content="true")
}
