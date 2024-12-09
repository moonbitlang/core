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
pub let min_value : UInt = 0U

///|
pub let max_value : UInt = 4294967295U

///|
pub fn to_int64(self : UInt) -> Int64 {
  self.to_uint64().reinterpret_as_int64()
}

///|
pub fn UInt::default() -> UInt {
  0
}

///| Convert an UInt into a 4 bytes long Bytes.
/// 
/// # Example
/// 
/// ```
/// let uint_bytes = 114514 |> UInt::to_bytes
/// ```
pub fn to_bytes(self : UInt) -> Bytes {
  let byte1 = self.to_byte()
  let byte2 = (self >> 8).to_byte()
  let byte3 = (self >> 16).to_byte()
  let byte4 = (self >> 24).to_byte()
  [byte1, byte2, byte3, byte4] |> Bytes::from_fixedarray
}
