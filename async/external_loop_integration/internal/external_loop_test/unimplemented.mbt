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
/// This package is not implemented on non-native backends
#cfg(not(target="native"))
pub let unimplemented : Unit = {
  let _ : (@cond_var.Cond) -> Unit = ignore
  let _ : (&@external_loop_integration.ExternalEventLoop) -> Unit = ignore
  ignore(@env.now())
}

///|
#cfg(target="wasm")
let _unused_wasm : Unit = {
  let _ : (@os_error.OsError) -> Unit = ignore
  let _ : (@fd_util.Fd) -> Unit = ignore
}

///|
#cfg(any(target="js", target="wasm-gc"))
let _unused_non_wasm : Unit = {
  ignore(@os_error.unimplemented)
  ignore(@fd_util.unimplemented)
}
