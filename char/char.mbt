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
pub impl Hash for Char with hash(self) { self.to_int() }

///|
pub impl Hash for Char with hash_combine(self, hasher) -> Unit {
  hasher.combine_char(self)
}

///|
pub fn to_be_bytes(self : Char) -> Bytes {
  self.to_uint().to_be_bytes()
}

///|
pub fn to_le_bytes(self : Char) -> Bytes {
  self.to_uint().to_le_bytes()
}
