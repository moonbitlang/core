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
priv trait OpaqueValue {}

///|
#alias(T)
struct Bench {
  buffer : StringBuilder
  summaries : Array[Summary]
  mut _storage : &OpaqueValue
}

///|
#as_free_fn
pub fn Bench::new() -> Bench {
  let buffer = StringBuilder::new()
  let summaries = Array::new()
  { buffer, summaries, _storage: () }
}
