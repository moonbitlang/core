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
priv type File_Handler

///|
fn fopen_ffi(path : Bytes, mode : Bytes) -> File_Handler = "$moonbit.fopen_ffi"

///|
fn is_null(ptr : File_Handler) -> Int = "$moonbit.is_null"

///|
fn fread_ffi(ptr : Bytes, size : Int, nitems : Int, stream : File_Handler) -> Int = "$moonbit.fread_ffi"

///|
fn fwrite_ffi(ptr : Bytes, size : Int, nitems : Int, stream : File_Handler) -> Int = "$moonbit.fwrite_ffi"

///|
fn get_error_message_ffi() -> Bytes = "$moonbit.get_error_message"

///|
fn fseek_ffi(file : File_Handler, offset : Int, whence : Int) -> Int = "$moonbit.fseek_ffi"

///|
fn ftell_ffi(file : File_Handler) -> Int = "$moonbit.ftell_ffi"

///|
fn fflush_ffi(stream : File_Handler) -> Int = "$moonbit.fflush_ffi"

///|
fn fclose_ffi(file : File_Handler) -> Int = "$moonbit.fclose_ffi"

///|
fn get_error_message() -> String {
  utf8_bytes_to_mbt_string(get_error_message_ffi())
}

///|
fn read_file_to_bytes_internal(path : String) -> Bytes! {
  let file = fopen_ffi(mbt_string_to_utf8_bytes(path, true), b"rb")
  guard is_null(file) == 0 else { raise IOError(get_error_message()) }
  guard fseek_ffi(file, 0, 2) == 0 else { raise IOError(get_error_message()) }
  let size = ftell_ffi(file)
  guard size != -1 else { raise IOError(get_error_message()) }
  guard fseek_ffi(file, 0, 0) == 0 else { raise IOError(get_error_message()) }
  let bytes = Bytes::make(size, 0)
  let bytes_read = fread_ffi(bytes, 1, size, file)
  guard bytes_read == size else { raise IOError(get_error_message()) }
  guard fclose_ffi(file) == 0 else { raise IOError(get_error_message()) }
  bytes
}

fn read_file_to_string_internal(path : String, encoding~ : String = "utf8") -> String! {
  guard encoding == "utf8" else { raise IOError("Unsupported encoding: \{encoding}, only utf8 is supported for now") }
  utf8_bytes_to_mbt_string(read_file_to_bytes_internal!(path))
}

///|
fn write_bytes_to_file_internal(path : String, content : Bytes) -> Unit! {
  let file = fopen_ffi(mbt_string_to_utf8_bytes(path, true), b"wb")
  guard is_null(file) == 0 else { raise IOError(get_error_message()) }
  let bytes_written = fwrite_ffi(content, 1, content.length(), file)
  guard bytes_written == content.length() else { raise IOError(get_error_message()) }
  guard fflush_ffi(file) == 0 else { raise IOError(get_error_message()) }
  guard fclose_ffi(file) == 0 else { raise IOError(get_error_message()) }
}

fn write_string_to_file_internal(path : String, content : String, encoding~ : String = "utf8") -> Unit! {
  guard encoding == "utf8" else { raise IOError("Unsupported encoding: \{encoding}, only utf8 is supported for now") }
  let bytes = mbt_string_to_utf8_bytes(content, false)
  write_bytes_to_file_internal!(path, bytes)
}
