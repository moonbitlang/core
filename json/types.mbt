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
/// Type `Position` used by this package APIs.
pub(all) struct Position {
  line : Int // 1-based
  column : Int // 0-based
} derive(Eq, ToJson, @debug.Debug)

///|
/// Error type `ParseError`.
pub(all) suberror ParseError {
  InvalidChar(Position, Char)
  InvalidEof
  InvalidNumber(Position, String)
  InvalidIdentEscape(Position)
  DepthLimitExceeded
} derive(Eq, ToJson, @debug.Debug)

///|
pub impl Show for ParseError with fn output(self, logger) {
  match self {
    InvalidChar({ line, column, }, c) =>
      logger <+
        $|Invalid character \{c.escape()} at line \{line}, column \{column}
    InvalidEof => logger <+ "Unexpected end of file"
    InvalidNumber({ line, column, }, s) =>
      logger <+
        $|Invalid number \{s} at line \{line}, column \{column}
    InvalidIdentEscape({ line, column, }) =>
      logger <+
        $|Invalid escape sequence in identifier at line \{line}, column \{column}
    DepthLimitExceeded =>
      logger <+
        $|Depth limit exceeded, please increase the max_nesting_depth parameter
  }
}

///|
#deprecated("Use Debug instead of Show for debugging purposes. See https://github.com/moonbitlang/core/blob/main/debug/README.mbt.md")
pub impl Show for Json

///|
#warnings("-deprecated")
pub impl Show for Json with fn output(self, logger) {
  match self {
    Null => logger <+ "Null"
    True => logger <+ "True"
    False => logger <+ "False"
    Number(n, repr~) => {
      fn write_contents(cb : &Logger) -> Unit {
        Show::output(n, cb)
        if repr is Some(repr) {
          cb.write_string(", repr=Some(")
          Show::output(repr, cb)
          cb.write_string(")")
        }
      }
      logger <+ "Number(\{cb => write_contents(cb)})"
    }
    String(s) => logger <+ "String(\{cb => Show::output(s, cb)})"
    Array(a) => logger <+ "Array(\{cb => Show::output(a, cb)})"
    Object(o) => logger <+ "Object(\{cb => Show::output(o, cb)})"
  }
}
