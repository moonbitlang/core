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
pub(all) struct Position {
  line : Int // 1-based
  column : Int // 0-based
} derive(Eq, ToJson)

///|
pub(all) suberror ParseError {
  InvalidChar(Position, Char)
  InvalidEof
  InvalidNumber(Position, String)
  InvalidIdentEscape(Position)
  DepthLimitExceeded
} derive(Eq, ToJson)

///|
pub impl Show for ParseError with output(self, logger) {
  match self {
    InvalidChar({ line, column }, c) =>
      logger
      ..write_string("Invalid character ")
      ..write_string(repr(c))
      ..write_string(" at line ")
      ..write_object(line)
      ..write_string(", column ")
      ..write_object(column)
    InvalidEof => logger.write_string("Unexpected end of file")
    InvalidNumber({ line, column }, s) =>
      logger
      ..write_string("Invalid number ")
      ..write_string(s)
      ..write_string(" at line ")
      ..write_object(line)
      ..write_string(", column ")
      ..write_object(column)
    InvalidIdentEscape({ line, column }) =>
      logger
      ..write_string("Invalid escape sequence in identifier at line ")
      ..write_object(line)
      ..write_string(", column ")
      ..write_object(column)
    DepthLimitExceeded =>
      logger.write_string(
        "Depth limit exceeded, please increase the max_nesting_depth parameter",
      )
  }
}

///|
pub impl Show for Json with output(self, logger) {
  match self {
    Null => logger.write_string("Null")
    True => logger.write_string("True")
    False => logger.write_string("False")
    Number(n, repr~) => {
      logger.write_string("Number(")
      Show::output(n, logger)
      if repr is Some(_) {
        logger.write_string(", repr=")
        Show::output(repr, logger)
      }
      logger.write_string(")")
    }
    String(s) => {
      logger.write_string("String(")
      Show::output(s, logger)
      logger.write_string(")")
    }
    Array(a) => {
      logger.write_string("Array(")
      Show::output(a, logger)
      logger.write_string(")")
    }
    Object(o) => {
      logger.write_string("Object(")
      Show::output(o, logger)
      logger.write_string(")")
    }
  }
}
