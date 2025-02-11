// Copyright 2025 International Digital Economy Academy
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
  for i = 0; i < tmp.length(); i = i + 1 {
    res.push(utf8_bytes_to_mbt_string(tmp[i]))
  }
  res
}

///|
fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String {
  let res : Array[Char] = Array::new(capacity=bytes.length())
  let len = bytes.length()
  let mut i = 0
  while i < len {
    let mut c = bytes[i].to_int()
    if c < 0x80 {
      res.push(Char::from_int(c))
      i += 1
    } else if c < 0xE0 {
      if i + 1 >= len {
        break
      }
      c = ((c & 0x1F) << 6) | (bytes[i + 1].to_int() & 0x3F)
      res.push(Char::from_int(c))
      i += 2
    } else if c < 0xF0 {
      if i + 2 >= len {
        break
      }
      c = ((c & 0x0F) << 12) |
        ((bytes[i + 1].to_int() & 0x3F) << 6) |
        (bytes[i + 2].to_int() & 0x3F)
      res.push(Char::from_int(c))
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
      res.push(Char::from_int((c >> 10) + 0xD800))
      res.push(Char::from_int((c & 0x3FF) + 0xDC00))
      i += 4
    }
  }
  res.to_string()
}

///|
extern "c" fn time(ptr : Int) -> UInt64 = "time"

///|
fn now_internal() -> UInt64 {
  time(0)
}
