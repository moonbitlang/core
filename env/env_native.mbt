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
    res.push(@utf8.decode_lossy(tmp[i]))
  }
  res
}

///|
fn get_env_var_internal(key : String) -> String? {
  let key_bytes = @utf8.encode(key)
  if get_env_var_exists_ffi(key_bytes) {
    Some(@utf8.decode_lossy(get_env_var_ffi(key_bytes)))
  } else {
    None
  }
}

///|
#borrow(_key)
extern "C" fn get_env_var_ffi(_key : Bytes) -> Bytes = "get_env_var"

///|
#borrow(_key)
extern "C" fn get_env_var_exists_ffi(_key : Bytes) -> Bool = "get_env_var_exists"

///|
fn get_env_vars_internal() -> Map[String, String] {
  let tmp = get_env_vars_ffi()
  let res = {}
  for i = 0; i < tmp.length(); i = i + 2 {
    let key = @utf8.decode_lossy(tmp[i])
    let value = @utf8.decode_lossy(tmp[i + 1])
    res[key] = value
  }
  res
}

///|
extern "C" fn get_env_vars_ffi() -> FixedArray[Bytes] = "get_env_vars"

///|
fn set_env_var_internal(key : String, value : String) -> Unit {
  set_env_var_ffi(@utf8.encode(key), @utf8.encode(value))
}

///|
#borrow(_key, _value)
extern "C" fn set_env_var_ffi(_key : Bytes, _value : Bytes) -> Unit = "set_env_var"

///|
fn unset_env_var_internal(key : String) -> Unit {
  unset_env_var_ffi(@utf8.encode(key))
}

///|
#borrow(_key)
extern "C" fn unset_env_var_ffi(_key : Bytes) -> Unit = "unset_env_var"

///|
extern "C" fn exit_internal(code : Int) = "exit"

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
    let mut end = buf.length()
    for i in 0..<buf.length() {
      if buf[i] == b'\x00' {
        end = i
        break
      }
    }
    Some(@utf8.decode_lossy(buf[:end]))
  }
}
