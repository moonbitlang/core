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
test "ParseError::to_string coverage" {
  let invalidCharError = @json.InvalidChar(
    @json.Position::{ line: 1, column: 0 },
    'a',
  )
  let invalidEofError = @json.InvalidEof
  let invalidNumberError = @json.InvalidNumber(
    @json.Position::{ line: 1, column: 0 },
    "123abc",
  )
  let invalidIdentEscapeError = @json.InvalidIdentEscape(@json.Position::{
    line: 1,
    column: 0,
  })
  assert_eq!(
    invalidCharError.to_string(),
    "Invalid character 'a' at line 1, column 0",
  )
  assert_eq!(invalidEofError.to_string(), "Unexpected end of file")
  assert_eq!(
    invalidNumberError.to_string(),
    "Invalid number 123abc at line 1, column 0",
  )
  assert_eq!(
    invalidIdentEscapeError.to_string(),
    "Invalid escape sequence in identifier at line 1, column 0",
  )
}
