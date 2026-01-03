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
pub let max_value : UInt16 = 65535

///|
pub let min_value : UInt16 = 0

///|
#deprecated("Use `Int16::reinterpret_from_uint16` instead")
pub fn UInt16::reinterpret_as_int16(self : UInt16) -> Int16 {
  Int16::from_int(self.to_int())
}
