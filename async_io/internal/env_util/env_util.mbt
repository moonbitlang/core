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
#cfg(target="native")
extern "C" fn get_pid() -> UInt32 = "moonbit_rt_getpid"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_pid() -> UInt32 = "moonbitlang/async" "env_util/getpid"

///|
/// The PID of current process
#cfg(any(target="native", target="wasm"))
pub let current_process : UInt32 = get_pid()

///|
pub using @types {type Platform}

///|
#cfg(target="native")
extern "C" fn get_platform() -> Platform = "moonbit_rt_get_platform"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_platform() -> Platform = "moonbitlang/async" "runtime/get_platform"

///|
/// Current operating system.
/// A single WASM binary can be run of different operating systems,
/// so current OS information is only available at runtime.
#cfg(any(target="native", target="wasm"))
pub let platform : Platform = get_platform()
