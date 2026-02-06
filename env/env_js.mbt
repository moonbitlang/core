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
extern "js" fn has_process_env_internal() -> Bool =
  #| function() {
  #|   return typeof process !== "undefined" && typeof process.env !== "undefined";
  #| }

///|
fn get_env_var_internal(key : String) -> String? {
  if !has_process_env_internal() {
    return None
  }
  if is_env_var_exists_internal(key) {
    Some(get_env_var_internal_js(key))
  } else {
    None
  }
}

///|
extern "js" fn is_env_var_exists_internal(key : String) -> Bool =
  #| function(key) {
  #|   return key in process.env;
  #| }

///|
extern "js" fn get_env_var_internal_js(key : String) -> String =
  #| function(key) {
  #|   const env = process.env;
  #|   return env[key] || "";
  #| }

///|
fn get_env_vars_internal() -> Map[String, String] {
  if !has_process_env_internal() {
    return {}
  }
  let tmp = get_env_vars_internal_js()
  let res = {}
  for i = 0; i < tmp.length(); i = i + 2 {
    res[tmp[i]] = tmp[i + 1]
  }
  res
}

///|
extern "js" fn get_env_vars_internal_js() -> Array[String] =
  #| function() {
  #|   const env = process.env;
  #|   const result = [];
  #|   for (const key in env) {
  #|     result.push(key);
  #|     result.push(env[key]);
  #|   }
  #|   return result;
  #| }

///|
fn set_env_var_internal(key : String, value : String) -> Unit {
  if !has_process_env_internal() {
    return ()
  }
  set_env_var_internal_js(key, value)
}

///|
extern "js" fn set_env_var_internal_js(key : String, value : String) -> Unit =
  #| function(key, value) {
  #|   process.env[key] = value;
  #| }

///|
fn unset_env_var_internal(key : String) -> Unit {
  if !has_process_env_internal() {
    return ()
  }
  unset_env_var_internal_js(key)
}

///|
extern "js" fn unset_env_var_internal_js(key : String) -> Unit =
  #| function(key) {
  #|   delete process.env[key];
  #| }

///|
extern "js" fn exit_internal(code : Int) -> Unit =
  #| function(code) {
  #|   if (typeof process !== "undefined" && typeof process.exit === "function") {
  #|     process.exit(code);
  #|   }
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
