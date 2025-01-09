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
pub(all) type XStringCreateHandle

///|
pub(all) type XStringReadHandle

///|
pub(all) type XExternString

///|
fn begin_create_string() -> XStringCreateHandle = "__moonbit_fs_unstable" "begin_create_string"

///|
fn string_append_char(handle : XStringCreateHandle, ch : Char) = "__moonbit_fs_unstable" "string_append_char"

///|
fn finish_create_string(handle : XStringCreateHandle) -> XExternString = "__moonbit_fs_unstable" "finish_create_string"

///|
pub fn string_to_extern(s : String) -> XExternString {
  let handle = begin_create_string()
  for i = 0; i < s.length(); i = i + 1 {
    string_append_char(handle, s[i])
  }
  finish_create_string(handle)
}

///|
fn begin_read_string(s : XExternString) -> XStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///| Read one char from the string, returns -1 if the end of the string is reached.
/// The number returned is the unicode codepoint of the character.
fn string_read_char(handle : XStringReadHandle) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
fn finish_read_string(handle : XStringReadHandle) = "__moonbit_fs_unstable" "finish_read_string"

///|
pub fn string_from_extern(e : XExternString) -> String {
  let buf = StringBuilder::new()
  let handle = begin_read_string(e)
  while true {
    let ch = string_read_char(handle)
    if ch == -1 {
      break
    } else {
      buf.write_char(Char::from_int(ch))
    }
  }
  finish_read_string(handle)
  buf.to_string()
}

///|
pub(all) type XStringArrayReadHandle

///|
pub(all) type XExternStringArray

///|
fn begin_read_string_array(sa : XExternStringArray) -> XStringArrayReadHandle = "__moonbit_fs_unstable" "begin_read_string_array"

///|
fn string_array_read_string(handle : XStringArrayReadHandle) -> XExternString = "__moonbit_fs_unstable" "string_array_read_string"

///|
fn finish_read_string_array(handle : XStringArrayReadHandle) = "__moonbit_fs_unstable" "finish_read_string_array"

///|
pub fn string_array_from_extern(e : XExternStringArray) -> Array[String] {
  let buf = Array::new()
  let handle = begin_read_string_array(e)
  while true {
    let extern_str = string_array_read_string(handle)
    let str = string_from_extern(extern_str)
    // keep "ffi_end_of_/string_array" same with moonrun
    if str == "ffi_end_of_/string_array" {
      break
    } else {
      buf.push(str)
    }
  }
  finish_read_string_array(handle)
  buf
}

///|
pub fn get_cli_args() -> Array[String] {
  let args = get_cli_args_ffi()
  string_array_from_extern(args)
}

///|
fn get_cli_args_ffi() -> XExternStringArray = "__moonbit_fs_unstable" "args_get"

///|
pub fn get_env_vars() -> Map[String, String] {
  let env = get_env_vars_ffi()
  let tmp = string_array_from_extern(env)
  let res = {}
  for i = 0; i < tmp.length(); i = i + 2 {
    res[tmp[i]] = tmp[i + 1]
  }
  res
}

///|
fn get_env_vars_ffi() -> XExternStringArray = "__moonbit_fs_unstable" "get_env_vars"

///|
pub fn set_env_var(key : String, value : String) -> Unit {
  let key = string_to_extern(key)
  let value = string_to_extern(value)
  set_env_var_ffi(key, value)
}

///|
fn set_env_var_ffi(key : XExternString, value : XExternString) = "__moonbit_fs_unstable" "set_env_var"

///|
pub fn exit(code : Int) = "__moonbit_sys_unstable" "exit"

///|
pub fn now() -> UInt64 = "__moonbit_time_unstable" "now"
