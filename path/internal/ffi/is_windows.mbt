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
/// Checks whether the platform is Windows.
#cfg(target="js")
pub extern "js" fn is_windows() -> Bool =
  #|function () {
  #|  return typeof process !== "undefined" && process.platform === "win32";
  #|};

///|
#cfg(any(target="wasm", target="wasm-gc"))
#unsafe_skip_stub_check
fn get_platform() -> Int32 = "moonbitlang/async" "runtime/get_platform"

///|
/// Checks whether the platform is Windows.
#cfg(any(target="wasm", target="wasm-gc"))
pub fn is_windows() -> Bool {
  get_platform() == 2
}

///|
/// Checks whether the platform is Windows.
#cfg(all(target="native", platform="windows"))
pub fn is_windows() -> Bool {
  true
}

///|
/// Checks whether the platform is Windows.
#cfg(all(target="native", not(platform="windows")))
pub fn is_windows() -> Bool {
  false
}
