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
/// This function increase the scheduler priority of current thread to realtime on MacOS
/// to improve robustness of timing sensitive tests.
#cfg(target="native")
pub extern "C" fn increase_current_thread_priority() -> Unit = "increase_current_thread_priority"

///|
/// This function increase the scheduler priority of current thread to realtime on MacOS
/// to improve robustness of timing sensitive tests.
#cfg(not(target="native"))
pub fn increase_current_thread_priority() -> Unit {

}

///|
/// Build test utility in `async_io/internal/test_programs`, and return the path of the executable
#cfg(any(target="native", target="wasm"))
pub async fn build_test_program(name : String) -> String {
  let proc = @process.run("moon", [
    "build",
    "async_io/internal/test_programs/\{name}",
    "--target",
    "native",
    "--debug",
    "--target-dir",
    "_build/test_programs",
  ])
  if proc.exit_code != 0 {
    fail("failed to build test program `\{name}`: \{proc.exit_code}")
  }
  guard! @env.current_dir() is Some(cwd)
  "\{cwd}/_build/test_programs/native/debug/build/async_io/internal/test_programs/\{name}/\{name}.exe"
}

///|
#cfg(not(any(target="native", target="wasm")))
let _unused_import : Unit = {
  ignore(@process.unimplemented)
  ignore(@env.now())
}
