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
/// same as `Bytes::default`
#deprecated("Use `Bytes::default` instead")
#doc(hidden)
pub fn default() -> Bytes {
  b""
}

///|
/// Create from `fixedarray`.
#deprecated("Use `Bytes::from_array` instead")
#doc(hidden)
pub fn from_fixedarray(arr : FixedArray[Byte], len? : Int) -> Bytes {
  Bytes::from_array(arr[:len.unwrap_or(arr.length())])
}

///|
/// Create from `iter`.
#deprecated("Use `Bytes::from_iter` instead")
#alias(from_iterator, deprecated="Use `Bytes::from_iter` instead")
#doc(hidden)
pub fn from_iter(iter : Iter[Byte]) -> Bytes {
  Bytes::from_iter(iter)
}

///|
/// Function `of`.
#deprecated("Use `Bytes::from_array` instead")
#doc(hidden)
pub fn of(arr : ArrayView[Byte]) -> Bytes {
  Bytes::from_array(arr)
}

///|
/// Create from `array`.
#deprecated("Use `Bytes::from_array` instead")
#doc(hidden)
pub fn from_array(arr : ArrayView[Byte]) -> Bytes {
  Bytes::from_array(arr)
}

///|
/// Type `View` used by this package APIs.
#deprecated("@bytes.View is deprecated, use BytesView instead.")
pub type View = BytesView
