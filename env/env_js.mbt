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
extern "js" fn get_cli_args_internal() -> Array[String] =
  #| function() {
  #|  if (typeof process !== "undefined" && typeof process.argv !== "undefined") {
  #|    return process.argv;
  #|  } else {
  #|    return [];
  #|  }
  #| }

///|
extern "js" fn now_internal() -> UInt64 =
  #| function() {
  #|   const nowMs = Date.now();
  #|   return ({ hi : Number(BigInt(nowMs) >> 32n), lo : nowMs & 0xFFFFFFFF });
  #| }

///|
extern "js" fn current_dir_internal() -> String? =
  #| function() {
  #|   if (typeof process !== "undefined" && typeof process.cwd === "function") {
  #|     return process.cwd();
  #|   } else {
  #|     return null;
  #|   }
  #| }

///|
fn get_env_var_internal(key : String) -> String? {
  if is_env_var_exists_internal(key) {
    Some(get_env_var_value_internal(key))
  } else {
    None
  }
}

///|
extern "js" fn is_env_var_exists_internal(key : String) -> Bool =
  #| function(key) {
  #|   if (typeof process === "undefined" || typeof process.env === "undefined") {
  #|     return false;
  #|   }
  #|   return Object.prototype.hasOwnProperty.call(process.env, key);
  #| }

///|
extern "js" fn get_env_var_value_internal(key : String) -> String =
  #| function(key) {
  #|   if (typeof process === "undefined" || typeof process.env === "undefined") {
  #|     return "";
  #|   }
  #|   const value = process.env[key];
  #|   return value === undefined ? "" : String(value);
  #| }

///|
fn get_env_vars_internal() -> Map[String, String] {
  let tmp = get_env_vars_array_internal()
  let res = {}
  for i = 0; i < tmp.length(); i = i + 2 {
    res[tmp[i]] = tmp[i + 1]
  }
  res
}

///|
extern "js" fn get_env_vars_array_internal() -> Array[String] =
  #| function() {
  #|   if (typeof process === "undefined" || typeof process.env === "undefined") {
  #|     return [];
  #|   }
  #|   const result = [];
  #|   for (const key in process.env) {
  #|     const value = process.env[key];
  #|     if (value !== undefined) {
  #|       result.push(key);
  #|       result.push(String(value));
  #|     }
  #|   }
  #|   return result;
  #| }

///|
fn set_env_var_internal(key : String, value : String) -> Unit {
  set_env_var_ffi(key, value)
}

///|
extern "js" fn set_env_var_ffi(key : String, value : String) -> Unit =
  #| function(key, value) {
  #|   if (typeof process !== "undefined" && typeof process.env !== "undefined") {
  #|     process.env[key] = value;
  #|   }
  #| }

///|
fn unset_env_var_internal(key : String) -> Unit {
  unset_env_var_ffi(key)
}

///|
extern "js" fn unset_env_var_ffi(key : String) -> Unit =
  #| function(key) {
  #|   if (typeof process !== "undefined" && typeof process.env !== "undefined") {
  #|     delete process.env[key];
  #|   }
  #| }
