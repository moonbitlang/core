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
suberror ParserError {
  ParserError(at~ : Int, hint~ : String)
} derive(Debug)

///|
pub impl Show for ParserError with output(self, logger) {
  match self {
    ParserError(at~, hint~) => {
      logger.write_string("ParserError at position ")
      logger.write_object(at)
      logger.write_string(": ")
      logger.write_string(hint)
    }
  }
}

///|
const HINT_UNCLOSED_CHAR_CLASS = "Unclosed character class"

///|
const HINT_UNCLOSED_GROUP = "Unclosed group"

///|
const HINT_UNEXPECTED_CHAR = "Unexpected character"

///|
const HINT_QUANTIFIER_TOO_LARGE = "Quantifier too large"

///|
const HINT_INVALID_QUANTIFIER = "Invalid quantifier"

///|
const HINT_INVALID_ESCAPE = "Invalid escape sequence"

///|
const HINT_UNICODE_ESCAPE_NOT_ALLOWED = "Unicode escape sequences are not allowed"

///|
const HINT_BYTE_ESCAPE_NOT_ALLOWED = "Byte escape sequences are not allowed"

///|
const HINT_CHARACTER_OUT_OF_RANGE = "Character out of range"

///|
const HINT_INVALID_GROUP = "Invalid group"

///|
const HINT_UNSUPPORTED_LOOKAHEAD = "Unsupported lookahead assertion"

///|
const HINT_UNSUPPORTED_NEGATIVE_LOOKAHEAD = "Unsupported negative lookahead assertion"

///|
const HINT_UNSUPPORTED_LOOKBEHIND = "Unsupported lookbehind assertion"

///|
const HINT_UNSUPPORTED_NEGATIVE_LOOKBEHIND = "Unsupported negative lookbehind assertion"

///|
const HINT_INVALID_POSIX_CLASS = "Invalid POSIX character class"

///|
const HINT_BARE_POSIX_CLASS = "Invalid character class, bare POSIX character class not allowed"

///|
const HINT_UNSUPPORTED_POSIX_CLASS = "Unsupported POSIX character class"

///|
const HINT_CHAR_RANGE_OVER_SETS = "Character class range over sets"

///|
const HINT_INVALID_CHAR_RANGE = "Invalid character class range"

///|
const HINT_UNSUPPORTED_CLASS_SET_EXPRESSION = "Unsupported character class set expression"

///|
const HINT_UNSUPPORTED_POSSESSIVE_QUANTIFIER = "Unsupported possessive quantifier"

///|
const HINT_UNSUPPORTED_NESTED_CHAR_CLASS = "Unsupported nested character class"

///|
const HINT_USE_POSIX_CHARACTER_CLASS = "Use POSIX character class instead of \\w, \\W, \\d, \\D, \\s, \\S"
