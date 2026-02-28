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
fn println_runtime(s : String) -> Unit = "%println"

///|
fn trim_single_trailing_newline(text : String) -> String {
  match text.strip_suffix("\n") {
    Some(view) => view.to_string()
    None => text
  }
}

///|
fn[T] print_and_exit_success(text : String) -> T {
  println_runtime(trim_single_trailing_newline(text))
  runtime_exit_success()
  panic()
}

///|
#cfg(target="native")
fn runtime_exit_success() -> Unit {
  runtime_exit_success_native()
}

///|
#cfg(target="js")
fn runtime_exit_success() -> Unit {
  runtime_exit_success_js()
}

///|
#cfg(target="wasm-gc")
fn runtime_exit_success() -> Unit {
  runtime_exit_success_wasm()
}

///|
#cfg(target="wasm")
fn runtime_exit_success() -> Unit {
  runtime_exit_success_wasm()
}
