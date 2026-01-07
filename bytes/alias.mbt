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
/// A `BytesView` represents a view into a section of a `Bytes` without copying the data.
///
/// # Example
/// 
/// ```mbt check
/// test {
///   let bs = b"\x00\x01\x02\x03\x04\x05"
///   let bv = bs[1:4]
///   inspect(bv.length(), content="3")
///   assert_eq(bv[0], b'\x01')
///   assert_eq(bv[1], b'\x02')
///   assert_eq(bv[2], b'\x03')
/// }
/// ```
#builtin.valtype
#deprecated("Use `BytesView` instead")
pub type View = BytesView

///|
/// same as `Bytes::default`
pub fn default() -> Bytes {
  b""
}

///|
#deprecated("Use `Bytes::from_array` instead")
pub fn from_fixedarray(arr : FixedArray[Byte], len? : Int) -> Bytes {
  Bytes::from_array(arr[:len.unwrap_or(arr.length())])
}

///|
#deprecated("Use `Bytes::from_iter` instead")
#alias(from_iterator, deprecated="Use `Bytes::from_iter` instead")
pub fn from_iter(iter : Iter[Byte]) -> Bytes {
  Bytes::from_iter(iter)
}

///|
#deprecated("Use `Bytes::from_array` instead")
pub fn of(arr : ArrayView[Byte]) -> Bytes {
  Bytes::from_array(arr)
}

///|
#deprecated("Use `Bytes::from_array` instead")
pub fn from_array(arr : ArrayView[Byte]) -> Bytes {
  Bytes::from_array(arr)
}
