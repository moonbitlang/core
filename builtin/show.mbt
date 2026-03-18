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
pub impl Show for Unit with output(_self, logger) {
  logger.write_string("()")
}

///|
pub impl Show for Bool with output(self, logger) {
  if self {
    logger.write_string("true")
  } else {
    logger.write_string("false")
  }
}

///|
pub impl Show for Int with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for Int64 with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for UInt with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for UInt64 with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for Byte with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
pub impl Show for UInt16 with output(self, logger) {
  logger.write_string(self.to_string())
}

///|
/// Convert a byte to a two-digit lowercase hexadecimal string.
///
/// Example:
///
/// ```mbt check
/// test {
///   inspect(Byte::to_hex(b'\x0f'), content="0f")
/// }
/// ```
pub fn Byte::to_hex(b : Byte) -> String {
  fn to_hex_digit(i : Byte) -> Char {
    if i < 10 {
      (i + '0').to_char()
    } else {
      (i + 'a' - 10).to_char()
    }
  }

  [to_hex_digit(b / 16), to_hex_digit(b % 16)]
}

///|
test "to_hex_digit" {
  inspect(Byte::to_hex(b'\xee'), content="ee")
  inspect(Byte::to_hex(b'\xf3'), content="f3")
}

///|
/// Returns the escaped representation of a string.
///
/// When `quote` is true (default), the result is wrapped in double quotes
/// like a MoonBit string literal.
///
/// Escape rules:
/// - Double quote and backslash are backslash-escaped: `\"`, `\\`
/// - Common control characters use named escapes: `\n`, `\r`, `\b`, `\t`
/// - Other control characters (< U+0020) use `\u{hex}` format
/// - All other characters are displayed as-is
///
/// ```mbt check
/// test {
///   inspect("Hello \n".escape(), content="\"Hello \\n\"")
///   inspect("Hello \n".escape(quote=false), content="Hello \\n")
/// }
/// ```
pub fn String::escape(self : String, quote? : Bool = true) -> String {
  let buf = StringBuilder::new()
  self[:].escape_to(buf, quote~)
  buf.to_string()
}

///|
/// Returns the escaped representation of a string view.
///
/// When `quote` is true (default), the result is wrapped in double quotes
/// like a MoonBit string literal.
///
/// Escape rules:
/// - Double quote and backslash are backslash-escaped: `\"`, `\\`
/// - Common control characters use named escapes: `\n`, `\r`, `\b`, `\t`
/// - Other control characters (< U+0020) use `\u{hex}` format
/// - All other characters are displayed as-is
///
/// ```mbt check
/// test {
///   inspect("Hello\nWorld"[:6].escape(), content="\"Hello\\n\"")
///   inspect("Hello\nWorld"[:6].escape(quote=false), content="Hello\\n")
/// }
/// ```
pub fn StringView::escape(self : StringView, quote? : Bool = true) -> String {
  let buf = StringBuilder::new()
  self.escape_to(buf, quote~)
  buf.to_string()
}

///|
fn StringView::escape_to(
  self : StringView,
  logger : &Logger,
  quote? : Bool = true,
) -> Unit {
  if quote {
    logger.write_char('"')
  }
  let len = self.length()
  fn flush_segment(seg : Int, i : Int) {
    if i > seg {
      logger.write_view(self[seg:i])
    }
  }
  for i = 0, seg = 0 {
    if i >= len {
      flush_segment(seg, i)
      break
    }
    let code = self.unsafe_get(i)
    match code {
      '"' | '\\' as c => {
        flush_segment(seg, i)
        logger.write_char('\\')
        logger.write_char(c.unsafe_to_char())
        continue i + 1, i + 1
      }
      '\n' => {
        flush_segment(seg, i)
        logger.write_string("\\n")
        continue i + 1, i + 1
      }
      '\r' => {
        flush_segment(seg, i)
        logger.write_string("\\r")
        continue i + 1, i + 1
      }
      '\b' => {
        flush_segment(seg, i)
        logger.write_string("\\b")
        continue i + 1, i + 1
      }
      '\t' => {
        flush_segment(seg, i)
        logger.write_string("\\t")
        continue i + 1, i + 1
      }
      code =>
        if code < ' ' {
          flush_segment(seg, i)
          logger.write_string("\\u{")
          logger.write_string(code.to_byte().to_hex())
          logger.write_char('}')
          continue i + 1, i + 1
        } else {
          continue i + 1, seg
        }
    }
  }
  if quote {
    logger.write_char('"')
  }
}

///|
pub impl Show for String with output(self, logger) {
  self[:].escape_to(logger)
}

///|
/// This is different from `Show::output`,
/// here it returns the original string without escaping.
/// The rationale is in string interpolation,
/// we want to show the original string, not the escaped one.
/// # Examples
///
/// ```mbt check
/// test {
///   let str = "Hello \n"
///   inspect(str.to_string(), content="Hello \n")
///   inspect(str.escape(quote=true), content="\"Hello \\n\"")
/// }
/// ```
pub impl Show for String with to_string(self) {
  self
}

///|
pub impl[X : Show] Show for X? with output(self, logger) {
  match self {
    None => logger.write_string("None")
    Some(arg) => {
      logger.write_string("Some(")
      logger.write_object(arg)
      logger.write_string(")")
    }
  }
}

///|
pub impl[T : Show, E : Show] Show for Result[T, E] with output(self, logger) {
  match self {
    Ok(x) => {
      logger.write_string("Ok(")
      logger.write_object(x)
      logger.write_string(")")
    }
    Err(e) => {
      logger.write_string("Err(")
      logger.write_object(e)
      logger.write_string(")")
    }
  }
}

///|
pub impl[X : Show] Show for FixedArray[X] with output(self, logger) {
  logger.write_iter(self.iter())
}

///|
pub impl[X : Show] Show for Array[X] with output(self, logger) {
  logger.write_iter(self.iter())
}
