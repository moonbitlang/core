// Copyright 2024 International Digital Economy Academy
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
fn debug_string[T : Show](t : T) -> String {
  let buf = StringBuilder::new(size_hint=50)
  t.output(buf)
  buf.to_string()
}

///|
pub fn assert_eq[T : Eq + Show](a : T, b : T, ~loc : SourceLoc = _) -> Unit! {
  if a != b {
    fail!("FAILED: \{loc} `\{a} == \{b}`")
  }
}

///|
pub fn assert_not_eq[T : Eq + Show](
  a : T,
  b : T,
  ~loc : SourceLoc = _
) -> Unit! {
  if not(a != b) {
    let a = debug_string(a)
    let b = debug_string(b)
    fail!("FAILED: \{loc} `\{a} != \{b}`")
  }
}

///|
pub fn assert_true(x : Bool, ~loc : SourceLoc = _) -> Unit! {
  if not(x) {
    fail!("FAILED: \{loc} `\{x}` is not true")
  }
}

///|
pub fn assert_false(x : Bool, ~loc : SourceLoc = _) -> Unit! {
  if x {
    let x = debug_string(x)
    fail!("FAILED: \{loc}: `\{x}` is not false")
  }
}
