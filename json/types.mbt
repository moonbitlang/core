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

pub enum JsonValue {
  Null
  True
  False
  Number(Double)
  String(String)
  Array(Array[JsonValue])
  Object(Map[String, JsonValue])
} derive(Eq)

pub struct Position {
  line : Int // 1-based
  column : Int // 0-based
} derive(Eq)

pub enum ErrorData {
  InvalidChar(Position, Char)
  InvalidEof
  InvalidNumber(Position, String)
  InvalidIdentEscape(Position)
} derive(Eq)

pub type! ParseError ErrorData

pub fn ErrorData::to_string(self : ErrorData) -> String {
  match self {
    ErrorData::InvalidChar({ line, column }, c) =>
      "Invalid character '\(c)' at line \(line), column \(column)"
    ErrorData::InvalidEof => "Unexpected end of file"
    ErrorData::InvalidNumber({ line, column }, s) =>
      "Invalid number \(s) at line \(line), column \(column)"
    ErrorData::InvalidIdentEscape({ line, column }) =>
      "Invalid escape sequence in identifier at line \(line), column \(column)"
  }
}

pub impl Show for ErrorData with output(self, logger) {
  logger.write_string(self.to_string())
}

pub fn ParseError::to_string(self : ParseError) -> String {
  match self {
    ParseError(e) => e.to_string()
  }
}

pub impl Show for ParseError with output(self, logger) {
  logger.write_string(self.to_string())
}

pub fn op_equal(self : ParseError, other : ParseError) -> Bool {
  match (self, other) {
    (ParseError(e1), ParseError(e2)) => e1 == e2
  }
}

pub impl Show for JsonValue with output(self, logger) {
  match self {
    Null => logger.write_string("Null")
    True => logger.write_string("True")
    False => logger.write_string("False")
    Number(n) => {
      logger.write_string("Number(")
      Show::output(n, logger)
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

pub fn to_string(self : JsonValue) -> String {
  Show::to_string(self)
}
