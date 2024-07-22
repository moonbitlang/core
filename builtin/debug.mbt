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

/// **`Debug` trait is deprecated, use `Show` instead.**
pub trait Debug {
  debug_write(Self, Buffer) -> Unit
}

/// print a value to the console using [Debug], with a tailing newline
pub fn debug[X : Debug](x : X) -> Unit {
  let buf = Buffer::new()
  x.debug_write(buf)
  println_mono(buf.to_string())
}

pub fn debug_write(self : Unit, buf : Buffer) -> Unit {
  let _ = self
  buf.write_string("()")
}

pub fn debug_write(self : Bool, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Int, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Int64, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : UInt, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : UInt64, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write(self : Bytes, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub fn debug_write[X : Debug](self : X?, buf : Buffer) -> Unit {
  match self {
    None => buf.write_string("None")
    Some(arg) => {
      buf.write_string("Some(")
      arg.debug_write(buf)
      buf.write_string(")")
    }
  }
}

pub fn debug_write[T : Debug, E : Debug](
  self : Result[T, E],
  buf : Buffer
) -> Unit {
  match self {
    Ok(x) => {
      buf.write_string("Ok(")
      x.debug_write(buf)
      buf.write_string(")")
    }
    Err(e) => {
      buf.write_string("Err(")
      e.debug_write(buf)
      buf.write_string(")")
    }
  }
}

pub fn debug_write[X : Debug](self : Ref[X], buf : Buffer) -> Unit {
  buf.write_string("{val: ")
  self.val.debug_write(buf)
  buf.write_string("}")
}

pub fn debug_write[X : Debug](self : FixedArray[X], buf : Buffer) -> Unit {
  buf.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    self[i].debug_write(buf)
  }
  buf.write_char(']')
}

pub fn debug_write[X : Debug](self : Array[X], buf : Buffer) -> Unit {
  buf.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    self[i].debug_write(buf)
  }
  buf.write_char(']')
}

pub fn debug_write[X : Debug](self : ArrayView[X], buf : Buffer) -> Unit {
  buf.write_char('[')
  for i = 0; i < self.length(); i = i + 1 {
    if i > 0 {
      buf.write_string(", ")
    }
    self[i].debug_write(buf)
  }
  buf.write_char(']')
}

pub fn debug_write(self : String, buf : Buffer) -> Unit {
  buf.write_char('"')
  let mut segment_start = 0
  fn flush_segment(i : Int) {
    if i > segment_start {
      buf.write_sub_string(self, segment_start, i - segment_start)
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
        buf.write_char('\\')
        buf.write_char(c)
      }
      '\n' => {
        flush_segment(i)
        buf.write_string("\\n")
      }
      '\r' => {
        flush_segment(i)
        buf.write_string("\\r")
      }
      '\b' => {
        flush_segment(i)
        buf.write_string("\\b")
      }
      '\t' => {
        flush_segment(i)
        buf.write_string("\\t")
      }
      _ => {
        let code = c.to_int()
        if code < 0x20 {
          flush_segment(i)
          buf.write_char('\\')
          buf.write_char('x')
          buf.write_char(to_hex_digit(code / 16))
          buf.write_char(to_hex_digit(code % 16))
        }
      }
    }
  }
  flush_segment(self.length())
  buf.write_char('"')
}

pub fn debug_write[K : Debug, V : Debug](
  self : Map[K, V],
  buf : Buffer
) -> Unit {
  buf.write_char('{')
  loop 0, self.head {
    i, Some({ key, value, idx, .. }) => {
      let nxt = self.list[idx].next
      if i > 0 {
        // remove the trailing comma
        buf.write_string(", ")
        key.debug_write(buf)
        buf.write_string(": ")
        value.debug_write(buf)
        continue i + 1, nxt
      }
      key.debug_write(buf)
      buf.write_string(": ")
      value.debug_write(buf)
      continue i + 1, nxt
    }
    _, None => buf.write_char('}')
  }
}
