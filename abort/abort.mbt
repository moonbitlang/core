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
/// Aborts the program with an error message and never returns.
///
/// On native targets, the message is printed before panicking. On other targets,
/// the message is ignored.
///
/// # Example
/// ```mbt check
/// test "panic abort" {
///   ignore(abort("boom"))
/// }
/// ```
///
/// # Panics
/// Always panics.
#cfg(not(target="native"))
pub fn[T] abort(msg : String) -> T {
  let _ = msg
  panic_impl()
}

///|
#cfg(target="native")
/// Prints a string to standard output on native targets.
fn println(s : String) -> Unit = "%println"

///|
/// Aborts the program with an error message and never returns.
///
/// On native targets, the message is printed before panicking. On other targets,
/// the message is ignored.
///
/// # Example
/// ```mbt check
/// test "panic abort" {
///   ignore(abort("boom"))
/// }
/// ```
///
/// # Panics
/// Always panics.
#cfg(target="native")
pub fn[T] abort(msg : String) -> T {
  println(msg)
  panic_impl()
}

///|
/// Panics unconditionally using the runtime intrinsic and never returns.
fn[T] panic_impl() -> T = "%panic"
