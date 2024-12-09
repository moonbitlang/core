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
pub let min_value : UInt64 = 0UL

///|
pub let max_value : UInt64 = 18446744073709551615UL

///| Convert an UInt64 into a 8 bytes long Bytes.
/// 
/// # Example
/// 
/// ```
/// let uint64_bytes = 1145141919810 |> UInt64::to_bytes
/// ```
pub fn to_bytes(self : UInt64) -> Bytes {
  let byte1 = self.to_byte()
  let byte2 = (self >> 8).to_byte()
  let byte3 = (self >> 16).to_byte()
  let byte4 = (self >> 24).to_byte()
  let byte5 = (self >> 32).to_byte()
  let byte6 = (self >> 40).to_byte()
  let byte7 = (self >> 48).to_byte()
  let byte8 = (self >> 56).to_byte()
  [byte1, byte2, byte3, byte4, byte5, byte6, byte7, byte8]
  |> Bytes::from_fixedarray
}
