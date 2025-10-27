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
/// Reads a UInt64 from the bytes in little-endian byte order. This API is
/// unsafe because it has no bounds checking. Use this API with care when the
/// index is not aligned to 8 bytes.
#intrinsic("%bytes.unsafe_read_uint64_le")
pub fn Bytes::unsafe_read_uint64_le(bytes : Bytes, index : Int) -> UInt64 {
  let mut result : UInt64 = 0
  for i in 0..=7 {
    result = result | (bytes.unsafe_get(i + index).to_uint64() << (8 * i))
  }
  result
}

///|
#intrinsic("%bytes.unsafe_read_uint64_be")
pub fn Bytes::unsafe_read_uint64_be(bytes : Bytes, index : Int) -> UInt64 {
  let mut result : UInt64 = 0
  for i in 0..=7 {
    result = result | (bytes.unsafe_get(i + index).to_uint64() << (8 * (7 - i)))
  }
  result
}

///|
#intrinsic("%bytes.unsafe_read_uint32_le")
pub fn Bytes::unsafe_read_uint32_le(bytes : Bytes, index : Int) -> UInt {
  let mut result : UInt = 0
  for i in 0..=3 {
    result = result | (bytes.unsafe_get(i + index).to_uint() << (8 * i))
  }
  result
}

///|
#intrinsic("%bytes.unsafe_read_uint32_be")
pub fn Bytes::unsafe_read_uint32_be(bytes : Bytes, index : Int) -> UInt {
  let mut result : UInt = 0
  for i in 0..=3 {
    result = result | (bytes.unsafe_get(i + index).to_uint() << (8 * (3 - i)))
  }
  result
}

///|
// #intrinsic("%bytes.unsafe_read_uint16_le")
pub fn Bytes::unsafe_read_uint16_le(bytes : Bytes, index : Int) -> UInt16 {
  let mut result : UInt16 = 0
  for i in 0..=1 {
    result = result | (bytes.unsafe_get(i + index).to_uint16() << (8 * i))
  }
  result
}

///|
// #intrinsic("%bytes.unsafe_read_uint16_be")
pub fn Bytes::unsafe_read_uint16_be(bytes : Bytes, index : Int) -> UInt16 {
  let mut result : UInt16 = 0
  for i in 0..=1 {
    result = result | (bytes.unsafe_get(i + index).to_uint16() << (8 * (1 - i)))
  }
  result
}

///|
pub fn BytesView::unsafe_read_uint64_le(
  bytes : BytesView,
  index : Int,
) -> UInt64 {
  bytes.bytes().unsafe_read_uint64_le(bytes.start() + index)
}

///|
pub fn BytesView::unsafe_read_uint64_be(
  bytes : BytesView,
  index : Int,
) -> UInt64 {
  bytes.bytes().unsafe_read_uint64_be(bytes.start() + index)
}

///|
pub fn BytesView::unsafe_read_uint32_le(bytes : BytesView, index : Int) -> UInt {
  bytes.bytes().unsafe_read_uint32_le(bytes.start() + index)
}

///|
pub fn BytesView::unsafe_read_uint32_be(bytes : BytesView, index : Int) -> UInt {
  bytes.bytes().unsafe_read_uint32_be(bytes.start() + index)
}

///|
pub fn BytesView::unsafe_read_uint16_le(
  bytes : BytesView,
  index : Int,
) -> UInt16 {
  bytes.bytes().unsafe_read_uint16_le(bytes.start() + index)
}

///|
pub fn BytesView::unsafe_read_uint16_be(
  bytes : BytesView,
  index : Int,
) -> UInt16 {
  bytes.bytes().unsafe_read_uint16_be(bytes.start() + index)
}
