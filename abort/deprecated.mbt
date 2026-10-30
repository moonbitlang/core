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
/// Aborts execution with an error message. This function never returns.
///
/// JavaScript and native backends print the message to stderr before panicking.
/// Linear-memory Wasm does the same when linked with WASI support. Otherwise,
/// Wasm and Wasm GC trap without printing the message or requiring I/O imports.
#deprecated("Use `abort` from the prelude instead of `@abort.abort`")
pub fn[T] abort(msg : String) -> T = "%abort"
