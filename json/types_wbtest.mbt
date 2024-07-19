// Copyright 2024 International Digital Economy Academy
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

test "ParseError::to_string coverage" {
  let invalidCharError = ParseError::InvalidChar(
    Position::{ line: 1, column: 0 },
    'a',
  )
  let invalidEofError = ParseError::InvalidEof
  let invalidNumberError = ParseError::InvalidNumber(
    Position::{ line: 1, column: 0 },
    "123abc",
  )
  let invalidIdentEscapeError = ParseError::InvalidIdentEscape(
    Position::{ line: 1, column: 0 },
  )
  @test.eq!(
    invalidCharError.to_string(),
    "Invalid character 'a' at line 1, column 0",
  )
  @test.eq!(invalidEofError.to_string(), "Unexpected end of file")
  @test.eq!(
    invalidNumberError.to_string(),
    "Invalid number 123abc at line 1, column 0",
  )
  @test.eq!(
    invalidIdentEscapeError.to_string(),
    "Invalid escape sequence in identifier at line 1, column 0",
  )
}
