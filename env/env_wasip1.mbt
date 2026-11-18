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
fn get_cli_args_internal() -> Array[String] {
  let count : FixedArray[Int32] = [0]
  let size : FixedArray[Int32] = [0]
  guard wasi_args_sizes_get(count, size) == 0 else {
    abort("env.args: WASI args_sizes_get failed")
  }
  if count[0] == 0 {
    return []
  }
  let pointers = FixedArray::make(count[0], 0)
  let buffer = Bytes::make(size[0], b'\x00')
  guard wasi_args_get(pointers, buffer) == 0 else {
    abort("env.args: WASI args_get failed")
  }
  decode_wasi_strings(pointers, buffer)
}

///|
fn get_wasi_env_entries() -> Array[String] {
  let count : FixedArray[Int32] = [0]
  let size : FixedArray[Int32] = [0]
  guard wasi_environ_sizes_get(count, size) == 0 else {
    abort("env: WASI environ_sizes_get failed")
  }
  if count[0] == 0 {
    return []
  }
  let pointers = FixedArray::make(count[0], 0)
  let buffer = Bytes::make(size[0], b'\x00')
  guard wasi_environ_get(pointers, buffer) == 0 else {
    abort("env: WASI environ_get failed")
  }
  decode_wasi_strings(pointers, buffer)
}

///|
fn get_env_var_internal(key : String) -> String? {
  for entry in get_wasi_env_entries() {
    if entry.find("=") is Some(separator) && entry[:separator] == key {
      return Some(entry[separator + 1:].to_owned())
    }
  }
  None
}

///|
fn get_env_vars_internal() -> Map[String, String] {
  let result = Map([])
  for entry in get_wasi_env_entries() {
    if entry.find("=") is Some(separator) {
      result[entry[:separator].to_owned()] = entry[separator + 1:].to_owned()
    }
  }
  result
}

///|
// WASI returns absolute pointers; strings need not be packed in table order.
fn decode_wasi_strings(
  pointers : FixedArray[Int32],
  buffer : Bytes,
) -> Array[String] {
  let base = wasi_buffer_address(buffer)
  [
    for pointer in pointers => {
      let start = pointer - base
      guard start >= 0 && start < buffer.length() else {
        abort("env: invalid WASI string pointer")
      }
      let mut end = start
      while end < buffer.length() && buffer[end] != b'\x00' {
        end += 1
      }
      guard end < buffer.length() else {
        abort("env: unterminated WASI string")
      }
      @utf8.decode_lossy(buffer[start:end])
    }
  ]
}

///|
#borrow(buffer)
extern "wasm" fn wasi_buffer_address(buffer : Bytes) -> Int32 =
  #| (func (param i32) (result i32) (local.get 0))

///|
#unsafe_skip_stub_check
#borrow(count, size)
fn wasi_args_sizes_get(
  count : FixedArray[Int32],
  size : FixedArray[Int32],
) -> Int32 = "wasi_snapshot_preview1" "args_sizes_get"

///|
#unsafe_skip_stub_check
#borrow(pointers, buffer)
fn wasi_args_get(pointers : FixedArray[Int32], buffer : Bytes) -> Int32 = "wasi_snapshot_preview1" "args_get"

///|
#unsafe_skip_stub_check
#borrow(count, size)
fn wasi_environ_sizes_get(
  count : FixedArray[Int32],
  size : FixedArray[Int32],
) -> Int32 = "wasi_snapshot_preview1" "environ_sizes_get"

///|
#unsafe_skip_stub_check
#borrow(pointers, buffer)
fn wasi_environ_get(pointers : FixedArray[Int32], buffer : Bytes) -> Int32 = "wasi_snapshot_preview1" "environ_get"
