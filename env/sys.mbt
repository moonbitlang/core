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
  @ffi.get_cli_args()
}

///|
pub fn get_env_vars() -> Map[String, String] {
  @ffi.get_env_vars()
}

///|
pub fn set_env_var(key : String, value : String) -> Unit {
  @ffi.set_env_var(key, value)
}

///|
pub fn exit(code : Int) -> Unit {
  @ffi.exit(code)
}

///|
pub fn now() -> UInt64 {
  @ffi.now()
}
