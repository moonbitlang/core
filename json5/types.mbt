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

pub struct Position {
  line : Int // 1-based
  column : Int // 0-based
} derive(Eq, Debug)

pub enum ParseError {
  InvalidChar(Position, Char)
  InvalidEof
  InvalidNumber(Position, String)
  InvalidIdentEscape(Position)
} derive(Eq, Debug)

pub fn ParseError::to_string(self : ParseError) -> String {
  match self {
    ParseError::InvalidChar({ line, column }, c) =>
      "Invalid character \(c) at line \(line), column \(column)"
    ParseError::InvalidEof => "Unexpected end of file"
    ParseError::InvalidNumber({ line, column }, s) =>
      "Invalid number \(s) at line \(line), column \(column)"
    ParseError::InvalidIdentEscape({ line, column }) =>
      "Invalid escape sequence in identifier at line \(line), column \(column)"
  }
}
