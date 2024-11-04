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
/// Makes a new Bytes with the given byte array.
/// 
/// # Usage
/// 
/// ```moonbit
/// let b = @bytes.from_array([b'\x41', b'\x00', b'\x42'])
/// ```
/// 
pub fn Bytes::from_array(arr : Array[Byte]) -> Bytes {
  let rv = Bytes::new(arr.length())
  for i = 0; i < arr.length(); i = i + 1 {
    rv[i] = arr[i]
  }
  rv
}

///|
pub fn Bytes::from_iter(iter : Iter[Byte]) -> Bytes {
  Bytes::from_array(iter.collect())
}

///|
/// Makes a new Bytes with the given byte fixedarray.
/// 
/// # Usage
/// 
/// ```moonbit
/// let b = @bytes.of([b'\x41', b'\x00', b'\x42'])
/// ```
/// TODO: marked as intrinsic, inline if it is constant
pub fn Bytes::of(arr : FixedArray[Byte]) -> Bytes {
  let rv = Bytes::new(arr.length())
  for i = 0; i < arr.length(); i = i + 1 {
    rv[i] = arr[i]
  }
  rv
}

///|
pub fn to_array(self : Bytes) -> Array[Byte] {
  let rv = Array::make(self.length(), b'0')
  for i = 0; i < self.length(); i = i + 1 {
    rv[i] = self[i]
  }
  rv
}

///|
pub fn iter(self : Bytes) -> Iter[Byte] {
  Iter::new(
    fn(yield) {
      for i = 0, len = self.length(); i < len; i = i + 1 {
        if yield(self[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

///|
pub fn Bytes::default() -> Bytes {
  b""
}
