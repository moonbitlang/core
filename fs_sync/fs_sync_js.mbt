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
extern "js" fn read_file_ffi(path : String) -> Int =
  #| function(path) {
  #|   fs = require('fs');
  #|   try {
  #|     const content = fs.readFileSync(path);
  #|     globalThis.fileContent = content;
  #|     return 0;
  #|   } catch (error) {
  #|     globalThis.errorMessage = error.message;
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn write_file_ffi(path : String, content : Bytes) -> Int =
  #| function(path, content) {
  #|   fs = require('fs');
  #|   try {
  #|     fs.writeFileSync(path, Buffer.from(content));
  #|     return 0;
  #|   } catch (error) {
  #|     globalThis.errorMessage = error.message;
  #|     return -1;
  #|   }
  #| }

///|
extern "js" fn get_file_content_ffi() -> FixedArray[Byte] =
  #| function() {
  #|   return globalThis.fileContent;
  #| }

///|
extern "js" fn get_error_message_ffi() -> String =
  #| function() {
  #|   return globalThis.errorMessage || '';
  #| }

///|
fn read_file_to_bytes_internal(path : String) -> Bytes! {
  let res = read_file_ffi(path)
  if res == -1 {
    raise IOError(get_error_message_ffi())
  }
  let content = get_file_content_ffi()
  Bytes::from_iter(content.iter())
}

fn read_file_to_string_internal(path : String, encoding~ : String = "utf8") -> String! {
  guard encoding == "utf8" else { raise IOError("Unsupported encoding: \{encoding}, only utf8 is supported for now") }
  let bytes = read_file_to_bytes_internal!(path)
  utf8_bytes_to_mbt_string(bytes)
}

///|
fn write_bytes_to_file_internal(path : String, content : Bytes) -> Unit! {
  let res = write_file_ffi(path, content)
  if res == -1 {
    raise IOError(get_error_message_ffi())
  }
}

fn write_string_to_file_internal(path : String, content : String, encoding~ : String = "utf8") -> Unit! {
  guard encoding == "utf8" else { raise IOError("Unsupported encoding: \{encoding}, only utf8 is supported for now") }
  let bytes = mbt_string_to_utf8_bytes(content, false)
  write_bytes_to_file_internal!(path, bytes)
}
