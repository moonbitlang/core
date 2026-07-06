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
struct Test {
  name : String
  buffer : StringBuilder
} derive(@debug.Debug)

///|
/// Create a new instance.
#alias(new, deprecated="Use `Test()` instead")
#as_free_fn
#as_free_fn(new, deprecated="Use `Test()` instead")
pub fn Test::Test(name : String) -> Test {
  { name, buffer: StringBuilder() }
}
