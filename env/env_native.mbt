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
fn mbt_string_to_utf8_bytes(str : String, append_nul : Bool) -> Bytes {
  let res : Array[Byte] = []
  let len = str.length()
  let mut i = 0
  while i < len {
    let mut c = str.code_unit_at(i).to_int()
    if 0xD800 <= c && c <= 0xDBFF {
      c -= 0xD800
      i = i + 1
      let l = str.code_unit_at(i).to_int() - 0xDC00
      c = (c << 10) + l + 0x10000
    }
    if c < 0x80 {
      res.push(c.to_byte())
    } else if c < 0x800 {
      res.push((0xc0 + (c >> 6)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else if c < 0x10000 {
      res.push((0xe0 + (c >> 12)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    } else {
      res.push((0xf0 + (c >> 18)).to_byte())
      res.push((0x80 + ((c >> 12) & 0x3f)).to_byte())
      res.push((0x80 + ((c >> 6) & 0x3f)).to_byte())
      res.push((0x80 + (c & 0x3f)).to_byte())
    }
    i = i + 1
  }
  if append_nul {
    res.push((0).to_byte())
  }
  Bytes::from_array(res)
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

///|
fn get_env_var_internal(key : String) -> String? {
  let key = mbt_string_to_utf8_bytes(key, true)
  if get_env_var_exists_ffi(key) {
    Some(utf8_bytes_to_mbt_string(get_env_var_ffi(key)))
  } else {
    None
  }
}

///|
#borrow(_key)
extern "c" fn get_env_var_ffi(_key : Bytes) -> Bytes = "moonbit_rt_get_env_var"

///|
#borrow(_key)
extern "c" fn get_env_var_exists_ffi(_key : Bytes) -> Bool = "moonbit_rt_get_env_var_exists"

///|
fn get_env_vars_internal() -> Map[String, String] {
  let env_vars = get_env_vars_ffi()
  let res = {}
  for i = 0; i < env_vars.length(); i = i + 2 {
    res[utf8_bytes_to_mbt_string(env_vars[i])] = utf8_bytes_to_mbt_string(
      env_vars[i + 1],
    )
  }
  res
}

///|
extern "c" fn get_env_vars_ffi() -> FixedArray[Bytes] = "moonbit_rt_get_env_vars"

///|
fn set_env_var_internal(key : String, value : String) -> Unit {
  set_env_var_ffi(
    mbt_string_to_utf8_bytes(key, true),
    mbt_string_to_utf8_bytes(value, true),
  )
}

///|
#borrow(_key, _value)
extern "c" fn set_env_var_ffi(_key : Bytes, _value : Bytes) -> Unit = "moonbit_rt_set_env_var"

///|
fn unset_env_var_internal(key : String) -> Unit {
  unset_env_var_ffi(mbt_string_to_utf8_bytes(key, true))
}

///|
#borrow(_key)
extern "c" fn unset_env_var_ffi(_key : Bytes) -> Unit = "moonbit_rt_unset_env_var"
