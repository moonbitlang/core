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
fn get_error_message_ffi() -> XExternString = "__moonbit_fs_unstable" "get_error_message"

///|
fn get_error_message() -> String {
  string_from_extern(get_error_message_ffi())
}

///|
fn get_file_content_ffi() -> XExternByteArray = "__moonbit_fs_unstable" "get_file_content"

///|
fn read_file_to_bytes_ffi(path : XExternString) -> Int = "__moonbit_fs_unstable" "read_file_to_bytes_new"

///|
fn write_bytes_to_file_ffi(
  path : XExternString,
  content : XExternByteArray
) -> Int = "__moonbit_fs_unstable" "write_bytes_to_file_new"

///|
fn read_file_to_bytes_internal(path : String) -> Bytes! {
  let res = read_file_to_bytes_ffi(string_to_extern(path))
  guard res != -1 else { raise IOError(get_error_message()) }
  byte_array_from_extern(get_file_content_ffi())
}

///|
fn read_file_to_string_internal(
  path : String,
  encoding~ : String = "utf8"
) -> String! {
  guard encoding == "utf8" else {
    raise IOError(
      "Unsupported encoding: \{encoding}, only utf8 is supported for now",
    )
  }
  utf8_bytes_to_mbt_string(read_file_to_bytes_internal!(path))
}

///|
fn write_bytes_to_file_internal(path : String, content : Bytes) -> Unit! {
  let res = write_bytes_to_file_ffi(
    string_to_extern(path),
    byte_array_to_extern(content),
  )
  guard res != -1 else { raise IOError(get_error_message()) }

}

///|
fn write_string_to_file_internal(
  path : String,
  content : String,
  encoding~ : String = "utf8"
) -> Unit! {
  guard encoding == "utf8" else {
    raise IOError(
      "Unsupported encoding: \{encoding}, only utf8 is supported for now",
    )
  }
  write_bytes_to_file_internal!(path, mbt_string_to_utf8_bytes(content, false))
}

///|
priv type XStringCreateHandle

///|
priv type XExternString

///|
priv type XExternByteArray

///|
priv type XByteArrayCreateHandle

///|
priv type XByteArrayReadHandle

///|
fn begin_create_string() -> XStringCreateHandle = "__moonbit_fs_unstable" "begin_create_string"

///|
fn string_append_char(handle : XStringCreateHandle, ch : Char) = "__moonbit_fs_unstable" "string_append_char"

///|
fn finish_create_string(handle : XStringCreateHandle) -> XExternString = "__moonbit_fs_unstable" "finish_create_string"

///|
fn string_to_extern(s : String) -> XExternString {
  let handle = begin_create_string()
  for i = 0; i < s.length(); i = i + 1 {
    string_append_char(handle, s[i])
  }
  finish_create_string(handle)
}

///|
fn begin_read_byte_array(s : XExternByteArray) -> XByteArrayReadHandle = "__moonbit_fs_unstable" "begin_read_byte_array"

///|
fn byte_array_read_byte(handle : XByteArrayReadHandle) -> Int = "__moonbit_fs_unstable" "byte_array_read_byte"

///|
fn finish_read_byte_array(handle : XByteArrayReadHandle) = "__moonbit_fs_unstable" "finish_read_byte_array"

///|
fn begin_create_byte_array() -> XByteArrayCreateHandle = "__moonbit_fs_unstable" "begin_create_byte_array"

///|
fn byte_array_append_byte(handle : XByteArrayCreateHandle, ch : Int) = "__moonbit_fs_unstable" "byte_array_append_byte"

///|
fn finish_create_byte_array(
  handle : XByteArrayCreateHandle
) -> XExternByteArray = "__moonbit_fs_unstable" "finish_create_byte_array"

///|
fn byte_array_to_extern(s : Bytes) -> XExternByteArray {
  let handle = begin_create_byte_array()
  for i = 0; i < s.length(); i = i + 1 {
    byte_array_append_byte(handle, s[i].to_int())
  }
  finish_create_byte_array(handle)
}

///|
fn byte_array_from_extern(e : XExternByteArray) -> Bytes {
  let buf = Array::new()
  let handle = begin_read_byte_array(e)
  while true {
    let ch = byte_array_read_byte(handle)
    if ch == -1 {
      break
    } else {
      buf.push(ch.to_byte())
    }
  }
  finish_read_byte_array(handle)
  Bytes::from_array(buf)
}

///|
priv type XStringReadHandle

///|
fn begin_read_string(s : XExternString) -> XStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///| Read one char from the string, returns -1 if the end of the string is reached.
/// The number returned is the unicode codepoint of the character.
fn string_read_char(handle : XStringReadHandle) -> Int = "__moonbit_fs_unstable" "string_read_char"

///|
fn finish_read_string(handle : XStringReadHandle) = "__moonbit_fs_unstable" "finish_read_string"

///|
fn string_from_extern(e : XExternString) -> String {
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
