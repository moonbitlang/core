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
fn internal_get_cli_args() -> FixedArray[Bytes] = "$moonbit.get_cli_args"

///|
pub fn get_cli_args() -> Array[String] {
  fn utf8_bytes_to_mbt_string(bytes : Bytes) -> String {
    let res : Array[Char] = []
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
    String::from_array(res)
  }

  Array::from_fixed_array(
    internal_get_cli_args().map(fn {
      // Here we assume that the CLI arguments are encoded in well-formed UTF-8.
      arg => utf8_bytes_to_mbt_string(arg)
    }),
  )
}

///|
pub fn get_env_vars() -> Map[String, String] {
  // not implement yet
  panic()
}

///|
pub fn set_env_var(_key : String, _value : String) -> Unit {
  // not implement yet
  panic()
}

///|
pub extern "c" fn exit(code : Int) -> Unit = "exit"

///|
extern "c" fn time(ptr : Int) -> UInt64 = "time"

///|
pub fn now() -> UInt64 {
  time(0)
}
