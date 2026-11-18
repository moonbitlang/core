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
#external
priv type SystemErrorMap

///|
#module("node:util")
extern "js" fn get_system_error_map() -> SystemErrorMap = "getSystemErrorMap"

///|
// Keep initialization inside the function so unused error support can be removed.
extern "js" fn cached_system_error_map(
  get_map : () -> SystemErrorMap,
) -> SystemErrorMap =
  #| function cached(getMap) {
  #|   return cached.map ??= getMap();
  #| }

///|
extern "js" fn SystemErrorMap::name(
  self : SystemErrorMap,
  code : Int32,
) -> String =
  #| (map, code) => map.get(code)?.[0] ?? ""

///|
extern "js" fn SystemErrorMap::message(
  self : SystemErrorMap,
  code : Int32,
) -> String =
  #| (map, code) => map.get(code)?.[1] ?? `Unknown system error ${code}`

///|
/// Return the Node.js system error name, or an empty string for an unknown code.
#internal(internal, "for internal use only")
pub fn errno_to_name(errno : Int32) -> String {
  cached_system_error_map(get_system_error_map).name(errno)
}

///|
/// Return a text description for a Node.js system error number.
#internal(internal, "for internal use only")
pub fn errno_to_string(errno : Int32) -> String {
  cached_system_error_map(get_system_error_map).message(errno)
}
