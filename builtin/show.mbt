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
pub impl Show for String with output(self, logger) {
  logger.write_char('"')
  fn flush_segment(seg : Int, i : Int) {
    if i > seg {
      logger.write_substring(self, seg, i - seg)
    }
  }
  // The loop keeps two pieces of state:
  //   i   : the current scanning position
  //   seg : the beginning index of the current "plain" segment that has
  //         no escaping requirements. Whenever we meet a character that
  //         needs escaping, we flush the segment [seg, i) and reset seg.
  let len = self.length()
  for i = 0, seg = 0 {
    if i >= len {
      // If we reached the end of the string, flush any remaining segment
      // and break out of the loop.
      flush_segment(seg, i)
      break
    }
    let code = self.unsafe_charcode_at(i)
    match code {
      '"' | '\\' as c => {
        flush_segment(seg, i)
        logger..write_char('\\')..write_char(c.unsafe_to_char())
        // Advance both pointers: continue with next index, new segment starts after current char
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
          // has to be ascii  
          flush_segment(seg, i)
          logger
          ..write_string("\\u{")
          ..write_string(code.to_byte().to_hex())
          ..write_char('}')
          continue i + 1, i + 1
        } else {
          // Normal character, keep scanning; only advance index.
          continue i + 1, seg
        }
    }
  }
  logger.write_char('"')
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
///   inspect(str.escape(), content="\"Hello \\n\"")
/// }
/// ```
pub impl Show for String with to_string(self) {
  self
}

///|
/// Returns a valid MoonBit string literal representation of a string,
/// add quotes and escape special characters.
/// # Examples
/// 
/// ```mbt check
/// test {
///   let str = "Hello \n"
///   inspect(str.to_string(), content="Hello \n")
///   inspect(str.escape(), content="\"Hello \\n\"")
/// }
/// ```
pub fn String::escape(self : String) -> String {
  let buf = StringBuilder::new()
  Show::output(self, buf)
  buf.to_string()
}

///|
pub impl[X : Show] Show for X? with output(self, logger) {
  match self {
    None => logger.write_string("None")
    Some(arg) =>
      logger..write_string("Some(")..write_object(arg)..write_string(")")
  }
}

///|
pub impl[T : Show, E : Show] Show for Result[T, E] with output(self, logger) {
  match self {
    Ok(x) => logger..write_string("Ok(")..write_object(x)..write_string(")")
    Err(e) => logger..write_string("Err(")..write_object(e)..write_string(")")
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
