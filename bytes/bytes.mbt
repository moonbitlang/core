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

/// Makes a new Bytes with the given integer array.
/// 
/// Each integer in the array must be a 0~255 (inclusive) number.
/// 
/// # Usage
/// 
/// ```moonbit
/// let b = Bytes::[65, 66, 67]
/// ```
/// 
pub fn Bytes::from_array(arr : Array[Int]) -> Bytes {
  let rv = Bytes::make(arr.length(), b'\x00')
  for i = 0; i < arr.length(); i = i + 1 {
    rv[i] = arr[i].to_byte()
  }
  rv
}
