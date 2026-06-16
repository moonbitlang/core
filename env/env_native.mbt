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
/// On Windows, we use native `W` series unicode API,
/// which return string in UTF-16 directly,
/// so no need for extra encoding phase here.
///
/// Note: technically path etc. may not be invalid UTF-16 on Windows,
///   but this should be extremely rare in practice.
///   If we need to fix this case, a validation or encoding phase can be added.
#cfg(platform="windows")
priv struct OsString(String)

///|
/// On non-Windows platforms, path etc. are essentially binary data,
/// and we assume they contain UTF-8 encoded text here.
#cfg(not(platform="windows"))
priv struct OsString(Bytes)

///|
#cfg(platform="windows")
fn OsString::to_string(self : OsString) -> String {
  self.0
}

///|
#cfg(not(platform="windows"))
fn OsString::to_string(self : OsString) -> String {
  @utf8.decode_lossy(self.0)
}

///|
#cfg(platform="windows")
fn OsString::from_string(str : String) -> OsString {
  OsString(str)
}

///|
#cfg(not(platform="windows"))
fn OsString::from_string(str : String) -> OsString {
  OsString(@utf8.encode(str))
}

///|
extern "C" fn get_cli_args_ffi() -> FixedArray[OsString] = "moonbit_rt_get_cli_args"

///|
fn get_cli_args_internal() -> Array[String] {
  [
    for t in get_cli_args_ffi() => t.to_string()
  ]
}

///|
extern "c" fn now_internal() -> UInt64 = "moonbit_get_ms_since_epoch"

///|
extern "c" fn getcwd() -> OsString = "moonbit_rt_get_current_dir"

///|
fn current_dir_internal() -> String? {
  let res = getcwd().to_string()
  // Valid current working directory can never be empty.
  // So the runtime API use empty return value to indicate failure.
  if res is "" {
    None
  } else {
    Some(res)
  }
}

///|
fn get_env_var_internal(key : String) -> String? {
  let key = OsString::from_string(key)
  let exists = @ref.Ref(false)
  let value = get_env_var_ffi(key, exists)
  if exists.val {
    Some(value.to_string())
  } else {
    None
  }
}

///|
#borrow(key, exists)
extern "c" fn get_env_var_ffi(
  key : OsString,
  exists : @ref.Ref[Bool],
) -> OsString = "moonbit_rt_get_env_var2"

///|
fn get_env_vars_internal() -> Map[String, String] {
  let env_vars = get_env_vars_ffi()
  let res = Map([])
  for i = 0; i < env_vars.length(); i = i + 2 {
    res[env_vars[i].to_string()] = env_vars[i + 1].to_string()
  }
  res
}

///|
extern "c" fn get_env_vars_ffi() -> FixedArray[OsString] = "moonbit_rt_get_env_vars2"

///|
fn set_env_var_internal(key : String, value : String) -> Unit {
  set_env_var_ffi(OsString::from_string(key), OsString::from_string(value))
}

///|
#borrow(key, value)
extern "c" fn set_env_var_ffi(key : OsString, value : OsString) -> Unit = "moonbit_rt_set_env_var2"

///|
fn unset_env_var_internal(key : String) -> Unit {
  unset_env_var_ffi(OsString::from_string(key))
}

///|
#borrow(key)
extern "c" fn unset_env_var_ffi(key : OsString) -> Unit = "moonbit_rt_unset_env_var2"

///|
#cfg(target_os="windows")
fn rand_internal(n : Int) -> Bytes? {
  if n <= 0 {
    return Some(b"")
  }
  let buf = Bytes::new(n)
  let word = Bytes::new(4)
  let mut offset = 0
  while offset < n {
    let rc = rand_s(word)
    if rc != 0 {
      return None
    }
    for i = 0; i < 4 && offset + i < n; i = i + 1 {
      buf[offset + i] = word[i]
    }
    offset += 4
  }
  Some(buf)
}

///|
#cfg(target_os="windows")
#borrow(value)
extern "c" fn rand_s(value : Bytes) -> Int = "rand_s"

///|
#cfg(not(target_os="windows"))
fn rand_internal(n : Int) -> Bytes? {
  if n <= 0 {
    return Some(b"")
  }
  let buf : FixedArray[Byte] = FixedArray::make(n, b'\x00')
  let chunk : FixedArray[Byte] = FixedArray::make(256, b'\x00')
  let mut offset = 0
  while offset < n {
    let len = if n - offset < 256 { n - offset } else { 256 }
    let rc = getentropy(chunk, len.reinterpret_as_uint())
    if rc != 0 {
      return None
    }
    for i = 0; i < len; i = i + 1 {
      buf[offset + i] = chunk[i]
    }
    offset += len
  }
  Some(Bytes::from_array(buf))
}

///|
#cfg(not(target_os="windows"))
#borrow(buf)
extern "c" fn getentropy(buf : FixedArray[Byte], len : UInt) -> Int = "getentropy"

///|
#cfg(platform="windows")
let _supressed_unused_warning_windows : Unit = ignore(@utf8.encode(""))
