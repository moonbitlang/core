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
fn get_cli_args_ffi() -> FixedArray[Bytes] = "$moonbit.get_cli_args"

///|
fn get_cli_args_internal() -> Array[String] {
  let tmp = get_cli_args_ffi()
  let res = Array::new(capacity=tmp.length())
  for i in 0..<tmp.length() {
    res.push(utf8_bytes_to_mbt_string(tmp[i]))
  }
  res
}

///|
fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String {
  let res = StringBuilder::new()
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    // zero byte indicates end of string
    if c == 0 {
      break
    } else if c < 0x80 {
      res.write_char(c.unsafe_to_char())
      i += 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.write_char(c.unsafe_to_char())
      i += 3
    } else {
      if i + 3 >= len {
        break
      }
      c = ((c & 0x07) << 18) |
        ((bytes[i + 1].to_int() & 0x3F) << 12) |
        ((bytes[i + 2].to_int() & 0x3F) << 6) |
        (bytes[i + 3].to_int() & 0x3F)
      c -= 0x10000
      res.write_char(((c >> 10) + 0xD800).unsafe_to_char())
      res.write_char(((c & 0x3FF) + 0xDC00).unsafe_to_char())
      i += 4
    }
  }
  res.to_string()
}

///|
extern "c" fn time(ptr : Int) -> UInt64 = "time"

///|
fn now_internal() -> UInt64 {
  // time returns seconds since 1970-01-01 00:00:00 UTC
  // to be consistent with other backends, we convert to milliseconds
  time(0) * 1000
}

///|
#borrow(ptr)
extern "c" fn getcwd(ptr : Bytes, size : Int) -> Int = "getcwd"

///|
fn current_dir_internal() -> String? {
  // TODO: On Windows getcwd may fail if the path is too long(Windows allows paths up to 32k characters)
  let buf = Bytes::new(4096)
  let res = getcwd(buf, buf.length())
  if res == 0 {
    None
  } else {
    Some(utf8_bytes_to_mbt_string(buf))
  }
}
