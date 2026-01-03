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
/// Aborts the program with an error message. Always causes a panic, regardless
/// of the message provided.
///
/// Parameters:
///
/// * `message` : A string containing the error message to be displayed when
/// aborting.
///
/// Returns a value of type `T`. However, this function never actually returns a
/// value as it always causes a panic.
#cfg(not(target="native"))
pub fn[T] abort(msg : String) -> T {
  let _ = msg
  panic_impl()
}

///|
#cfg(target="native")
fn println(s : String) -> Unit = "%println"

///|
/// Aborts the program with an error message. Always causes a panic, regardless
/// of the message provided.
///
/// Parameters:
///
/// * `message` : A string containing the error message to be displayed when
/// aborting.
///
/// Returns a value of type `T`. However, this function never actually returns a
/// value as it always causes a panic.
#cfg(target="native")
pub fn[T] abort(msg : String) -> T {
  println(msg)
  panic_impl()
}

///|
fn[T] panic_impl() -> T = "%panic"
