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

/// Extensible buffer.
///
/// It provides accumulative concatenation of strings in linear time.
/// The capacity of buffer will automatically expand as necessary.
///
/// # Usage
///
/// ```
/// let buf = Buffer::new(size_hint=100)
/// buf.write_string("Tes")
/// buf.write_char("t")
/// println(buf.to_string()) // output: Test
/// ```
struct Buffer {
  mut bytes : Bytes
  mut len : Int
  initial_bytes : Bytes
}

pub fn expect(
  self : Buffer,
  ~content : String = "",
  ~loc : SourceLoc = _,
  ~args_loc : ArgsLoc = _
) -> Unit!InspectError {
  let current = self.to_string()
  self.reset()
  if current != content {
    fn repr(s : String) -> String {
      let buf = Buffer::new()
      Show::output(s, buf)
      buf.to_string()
    }

    let loc = repr(loc.to_string())
    let args_loc = repr(args_loc.to_json())
    let expect = repr(content)
    let actual = repr(current)
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}}",
    )
  }
}

/// Expand the buffer size if capacity smaller than required space.
fn grow_if_necessary(self : Buffer, required : Int) -> Unit {
  // TODO: get rid of mut
  let mut enough_space = self.bytes.length()
  if enough_space <= 0 {
    enough_space = 1
  }
  // double the enough_space until it larger than required
  while enough_space < required {
    enough_space = enough_space * 2
  }
  if enough_space != self.bytes.length() {
    let new_bytes = Bytes::new(enough_space)
    blit(new_bytes, 0, self.bytes, 0, self.len)
    self.bytes = new_bytes
  }
}

/// Return a new String contains the data in buffer.
pub fn to_string(self : Buffer) -> String {
  self.bytes.sub_string(0, self.len)
}

/// Create a buffer with initial capacity (in bytes).
pub fn Buffer::new(~size_hint : Int = 0) -> Buffer {
  let initial = if size_hint < 1 { 1 } else { size_hint }
  let bytes = Bytes::new(initial)
  { bytes, len: 0, initial_bytes: bytes }
}

/// Write a string into buffer.
pub fn write_string(self : Buffer, value : String) -> Unit {
  self.grow_if_necessary(self.len + value.length() * 2)
  self.bytes.blit_from_string(self.len, value, 0, value.length())
  self.len = self.len + value.length() * 2
}

/// Write a sub-string into buffer.
pub fn write_sub_string(
  self : Buffer,
  value : String,
  start : Int,
  len : Int
) -> Unit {
  if start < 0 || len < 0 || start + len > value.length() {
    abort("Buffer::write_sub_string")
  }
  self.grow_if_necessary(self.len + len * 2)
  self.bytes.blit_from_string(self.len, value, start, len)
  self.len = self.len + len * 2
}

/// Write a char into buffer.
pub fn write_char(self : Buffer, value : Char) -> Unit {
  self.grow_if_necessary(self.len + 4)
  let inc = self.bytes.set_utf16_char(self.len, value)
  self.len = self.len + inc
}

/// Write a byte into buffer.
pub fn write_byte(self : Buffer, value : Byte) -> Unit {
  self.grow_if_necessary(self.len + 1)
  self.bytes[self.len] = value
  self.len += 1
}

pub fn reset(self : Buffer) -> Unit {
  self.bytes = self.initial_bytes
  self.len = 0
}

pub fn to_bytes(self : Buffer) -> Bytes {
  let bytes = Bytes::new(self.len)
  bytes.blit(0, self.bytes, 0, self.len)
  bytes
}

pub impl Show for Buffer with output(self, logger) {
  logger.write_string(self.to_string())
}
