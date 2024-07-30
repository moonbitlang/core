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

pub impl Show for Unit with output(_self, logger) { logger.write_string("()") }

pub impl Show for Bool with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for Int with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for Int64 with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for UInt with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for UInt64 with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for Byte with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for Bytes with output(self, logger) {
  logger.write_string(self.to_string())
}

pub impl Show for String with output(self, logger) {
  logger.write_char('"')
  let mut segment_start = 0
  fn flush_segment(i : Int) {
    if i > segment_start {
      logger.write_sub_string(self, segment_start, i - segment_start)
    }
    segment_start = i + 1
  }

  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  for i = 0; i < self.length(); i = i + 1 {
    let c = self[i]
    match c {
      '"' | '\\' => {
        flush_segment(i)
        logger.write_char('\\')
        logger.write_char(c)
      }
      '\n' => {
        flush_segment(i)
        logger.write_string("\\n")
      }
      '\r' => {
        flush_segment(i)
        logger.write_string("\\r")
      }
      '\b' => {
        flush_segment(i)
        logger.write_string("\\b")
      }
      '\t' => {
        flush_segment(i)
        logger.write_string("\\t")
      }
      _ => {
        let code = c.to_int()
        if code < 0x20 {
          flush_segment(i)
          logger.write_char('\\')
          logger.write_char('x')
          logger.write_char(to_hex_digit(code / 16))
          logger.write_char(to_hex_digit(code % 16))
        }
      }
    }
  }
  flush_segment(self.length())
  logger.write_char('"')
}

pub impl Show for String with to_string(self) { self }

pub impl[X : Show] Show for X? with output(self, logger) {
  match self {
    None => logger.write_string("None")
    Some(arg) => {
      logger.write_string("Some(")
      arg.output(logger)
      logger.write_string(")")
    }
  }
}

pub impl[T : Show, E : Show] Show for Result[T, E] with output(self, logger) {
  match self {
    Ok(x) => {
      logger.write_string("Ok(")
      x.output(logger)
      logger.write_string(")")
    }
    Err(e) => {
      logger.write_string("Err(")
      e.output(logger)
      logger.write_string(")")
    }
  }
}

pub impl[X : Show] Show for Ref[X] with output(self, logger) {
  logger.write_string("{val: ")
  self.val.output(logger)
  logger.write_string("}")
}

pub impl[X : Show] Show for FixedArray[X] with output(self, logger) {
  logger.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    self[i].output(logger)
  }
  logger.write_char(']')
}

pub impl[X : Show] Show for Array[X] with output(self, logger) {
  logger.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    self[i].output(logger)
  }
  logger.write_char(']')
}

pub impl[X : Show] Show for ArrayView[X] with output(self, logger) {
  logger.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      logger.write_string(", ")
    }
    self[i].output(logger)
  }
  logger.write_char(']')
}

/// Convert Char to String
/// @intrinsic %char.to_string
pub fn to_string(self : Char) -> String {
  // let bytes = Bytes::new(4)
  // let len = bytes.set_utf16_char(0, self)
  // bytes.sub_string(0, len)
  Show::to_string(self)
}

pub impl Show for Char with output(self, logger) {
  fn to_hex_digit(i : Int) -> Char {
    if i < 10 {
      Char::from_int('0'.to_int() + i)
    } else {
      Char::from_int('a'.to_int() + (i - 10))
    }
  }

  logger.write_char('\'')
  match self {
    '\'' | '\\' => {
      logger.write_char('\\')
      logger.write_char(self)
    }
    '\n' => logger.write_string("\\n")
    '\r' => logger.write_string("\\r")
    '\b' => logger.write_string("\\b")
    '\t' => logger.write_string("\\t")
    _ => {
      let code = self.to_int()
      if code < 0x20 {
        logger.write_char('\\')
        logger.write_char('x')
        logger.write_char(to_hex_digit(code / 16))
        logger.write_char(to_hex_digit(code % 16))
      } else {
        logger.write_char(self)
      }
    }
  }
  logger.write_char('\'')
}
