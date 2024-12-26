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
/// @alert deprecated "Use `String::trim_start` instead"
/// @coverage.skip
pub fn trim_left(self : String, trim_set : String) -> String {
  self.trim_start(trim_set)
}

///|
/// @alert deprecated "Use `String::trim_end` instead"
/// @coverage.skip
pub fn trim_right(self : String, trim_set : String) -> String {
  self.trim_end(trim_set)
}
