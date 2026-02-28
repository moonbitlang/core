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
#cfg(target="wasm-gc")
fn runtime_wasm_exit(code : Int) -> Unit = "__moonbit_sys_unstable" "exit"

///|
#cfg(target="wasm-gc")
fn runtime_exit_success_wasm() -> Unit {
  runtime_wasm_exit(0)
}

///|
#cfg(target="wasm")
fn runtime_wasm_exit(code : Int) -> Unit = "__moonbit_sys_unstable" "exit"

///|
#cfg(target="wasm")
fn runtime_exit_success_wasm() -> Unit {
  runtime_wasm_exit(0)
}
