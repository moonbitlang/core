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
fn Error::to_string(self : Error) -> String = "%error.to_string"

///|
pub impl Show for Error with fn to_string(self) {
  Error::to_string(self)
}

///|
fn Error::to_json(self : Error) -> Json = "%error.to_json"

///|
pub impl ToJson for Error with fn to_json(self) {
  self.to_json()
}
