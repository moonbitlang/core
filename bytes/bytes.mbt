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
/// ```
/// let b = @bytes.from_array([b'\x41', b'\x42'])
/// assert_eq!(b, b"AB")
/// ```
/// 
pub fn Bytes::from_array(arr : Array[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
/// Makes a new Bytes from a fixedarray.
pub fn Bytes::from_fixedarray(arr : FixedArray[Byte], len? : Int) -> Bytes {
  let len = match len {
    None => arr.length()
    Some(x) => x
  }
  Bytes::makei(len, fn(i) { arr[i] })
}

///|
/// Converts a Bytes to a fixedarray.
pub fn Bytes::to_fixedarray(self : Bytes, len? : Int) -> FixedArray[Byte] {
  let len = match len {
    None => self.length()
    Some(x) => x
  }
  let arr = FixedArray::make(len, Byte::default())
  for i in 0..<len {
    arr[i] = self[i]
  }
  arr
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
/// ```
/// let b = @bytes.of([b'\x41', b'\x42'])
/// assert_eq!(b, b"AB")
/// ```
/// TODO: marked as intrinsic, inline if it is constant
pub fn Bytes::of(arr : FixedArray[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
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
  Iter::new(fn(yield_) {
    for i = 0, len = self.length(); i < len; i = i + 1 {
      if yield_(self[i]) == IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
pub fn Bytes::default() -> Bytes {
  b""
}

///|
pub fn to_uint_be(self : Bytes) -> UInt {
  (self[0].to_uint() << 24) +
  (self[1].to_uint() << 16) +
  (self[2].to_uint() << 8) +
  self[3].to_uint()
}

///|
pub fn to_uint_le(self : Bytes) -> UInt {
  self[0].to_uint() +
  (self[1].to_uint() << 8) +
  (self[2].to_uint() << 16) +
  (self[3].to_uint() << 24)
}

///|
pub fn to_uint64_be(self : Bytes) -> UInt64 {
  (self[0].to_uint().to_uint64() << 56) +
  (self[1].to_uint().to_uint64() << 48) +
  (self[2].to_uint().to_uint64() << 40) +
  (self[3].to_uint().to_uint64() << 32) +
  (self[4].to_uint().to_uint64() << 24) +
  (self[5].to_uint().to_uint64() << 16) +
  (self[6].to_uint().to_uint64() << 8) +
  self[7].to_uint().to_uint64()
}

///|
pub fn to_uint64_le(self : Bytes) -> UInt64 {
  self[0].to_uint().to_uint64() +
  (self[1].to_uint().to_uint64() << 8) +
  (self[2].to_uint().to_uint64() << 16) +
  (self[3].to_uint().to_uint64() << 24) +
  (self[4].to_uint().to_uint64() << 32) +
  (self[5].to_uint().to_uint64() << 40) +
  (self[6].to_uint().to_uint64() << 48) +
  (self[7].to_uint().to_uint64() << 56)
}

///|
pub fn to_int_be(self : Bytes) -> Int {
  self.to_uint_be().reinterpret_as_int()
}

///|
pub fn to_int_le(self : Bytes) -> Int {
  self.to_uint_le().reinterpret_as_int()
}

///|
pub fn to_int64_be(self : Bytes) -> Int64 {
  self.to_uint64_be().reinterpret_as_int64()
}

///|
pub fn to_int64_le(self : Bytes) -> Int64 {
  self.to_uint64_le().reinterpret_as_int64()
}

///|
pub fn to_float_be(self : Bytes) -> Float {
  self.to_uint_be().reinterpret_as_float()
}

///|
pub fn to_float_le(self : Bytes) -> Float {
  self.to_uint_le().reinterpret_as_float()
}

///|
pub fn to_double_be(self : Bytes) -> Double {
  self.to_uint64_be().reinterpret_as_double()
}

///|
pub fn to_double_le(self : Bytes) -> Double {
  self.to_uint64_le().reinterpret_as_double()
}
