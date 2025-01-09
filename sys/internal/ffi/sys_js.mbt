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
pub fn get_cli_args() -> Array[String] {
  get_cli_args_internal()
}

///|
extern "js" fn get_cli_args_internal() -> Array[String] =
  #| function() {
  #|  return process.argv;
  #| }

///|
pub fn get_env_vars() -> Map[String, String] {
  let tmp = get_env_vars_internal()
  let res = {}
  for i = 0; i < tmp.length(); i = i + 2 {
    res[tmp[i]] = tmp[i + 1]
  }
  res
}

///|
extern "js" fn get_env_vars_internal() -> Array[String] =
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
pub fn set_env_var(key : String, value : String) -> Unit {
  set_env_var_internal(key, value)
}

///|
extern "js" fn set_env_var_internal(key : String, value : String) -> Unit =
  #| function(key, value) {
  #|   process.env[key] = value;
  #| }

///|
pub extern "js" fn exit(code : Int) -> Unit =
  #| function(code) {
  #|   process.exit(code);
  #| }

///|
pub extern "js" fn now() -> UInt64 =
  #| function() {
  #|   const nowMs = Date.now();
  #|   return ({ hi : Number(BigInt(nowMs) >> 32n), lo : nowMs & 0xFFFFFFFF });
  #| }
