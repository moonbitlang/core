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
extern "C" fn init_env() = "init_env"

///|
#cfg(platform="windows")
extern "C" fn next_entry() -> String = "next_entry"

///|
#cfg(platform="windows")
fn main {
  init_env()
  while next_entry() is entry && entry.length() > 0 {
    println(entry)
  }
}

///|
#cfg(not(platform="windows"))
extern "C" fn next_entry() -> Bytes = "next_entry"

///|
#cfg(not(platform="windows"))
fn main {
  init_env()
  while next_entry() is entry && entry.length() > 0 {
    println(@utf8.decode_lossy(entry))
  }
}

///|
#cfg(platform="windows")
let _unused : Unit = ignore(@utf8.encode(""))
