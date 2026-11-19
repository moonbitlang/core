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

// Scalar string/byte bridge follows moonbitlang/x/fs and core/env.
// The legacy host ABI reads the entire baseline into host memory.

///|
#external
priv type XStringReadHandle

///|
#external
priv type XStringCreateHandle

///|
#external
priv type XExternString

///|
fn begin_create_string() -> XStringCreateHandle = "__moonbit_fs_unstable" "begin_create_string"

///|
fn string_append_char(handle : XStringCreateHandle, ch : Char) = "__moonbit_fs_unstable" "string_append_char"

///|
fn finish_create_string(handle : XStringCreateHandle) -> XExternString = "__moonbit_fs_unstable" "finish_create_string"

///|
fn string_to_extern(s : String) -> XExternString {
  let handle = begin_create_string()
  for code_unit in s.code_units() {
    string_append_char(handle, code_unit.unsafe_to_char())
  }
  finish_create_string(handle)
}

///|
fn begin_read_string(s : XExternString) -> XStringReadHandle = "__moonbit_fs_unstable" "begin_read_string"

///|
/// Read one char from the string, returns -1 if the end of the string is reached.
/// The number returned is the unicode codepoint of the character.
fn string_read_char(handle : XStringReadHandle) -> Int32 = "__moonbit_fs_unstable" "string_read_char"

///|
fn finish_read_string(handle : XStringReadHandle) = "__moonbit_fs_unstable" "finish_read_string"

///|
fn string_from_extern(e : XExternString) -> String {
  let buf = StringBuilder()
  let handle = begin_read_string(e)
  while true {
    let ch = string_read_char(handle)
    if ch == -1 {
      break
    } else {
      buf.write_char(ch.unsafe_to_char())
    }
  }
  finish_read_string(handle)
  buf.to_string()
}

///|
#external
priv type ExternBytes

///|
#external
priv type Handle

///|
fn read_file(path : XExternString) -> Int32 = "__moonbit_fs_unstable" "read_file_to_bytes_new"

///|
fn exists(path : XExternString) -> Bool = "__moonbit_fs_unstable" "path_exists"

///|
fn file_content() -> ExternBytes = "__moonbit_fs_unstable" "get_file_content"

///|
fn error_message() -> XExternString = "__moonbit_fs_unstable" "get_error_message"

///|
fn begin_read(bytes : ExternBytes) -> Handle = "__moonbit_fs_unstable" "begin_read_byte_array"

///|
fn Handle::next(self : Handle) -> Int32 = "__moonbit_fs_unstable" "byte_array_read_byte"

///|
fn finish_read(handle : Handle) -> Unit = "__moonbit_fs_unstable" "finish_read_byte_array"

///|
#unsafe_skip_stub_check
fn platform() -> Int32 = "moonbitlang/async" "runtime/get_platform"

///|
fn file_host_is_unix() -> Bool {
  platform() != 2
}

///|
fn open(path : String) -> Handle? raise {
  let path = string_to_extern(path)
  // Match Moon's exists-then-read semantics. This ABI does not expose errno.
  if !exists(path) {
    return None
  }
  guard read_file(path) == 0 else { fail(string_from_extern(error_message())) }
  Some(begin_read(file_content()))
}

///|
#warnings("-unused_error_type")
fn Handle::read(
  self : Handle,
  buffer : FixedArray[Byte],
  offset : Int32,
  len : Int32,
  _position : Int64,
) -> Int32 raise {
  // The comparison reads sequentially. The host owns a whole-file byte array;
  // only copying into the guest is chunked. This is not bounded host memory.
  for i = 0; i < len; i = i + 1 {
    let byte = self.next()
    if byte < 0 {
      break i
    }
    buffer[offset + i] = byte.to_byte()
  } nobreak {
    len
  }
}

///|
#warnings("-unused_error_type")
fn Handle::close(self : Handle) -> Unit raise {
  finish_read(self)
}
