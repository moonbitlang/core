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
// #intrinsic("%bytes.unsafe_write_uint64_le")
pub fn unsafe_write_uint64_le(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt64,
) -> Unit {
  for i in 0..=7 {
    bytes.unsafe_set(i + index, (value >> (8 * i)).to_byte())
  }
}

///|
// #intrinsic("%bytes.unsafe_write_uint64_be")
pub fn unsafe_write_uint64_be(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt64,
) -> Unit {
  for i in 0..=7 {
    bytes.unsafe_set(i + index, (value >> (8 * (7 - i))).to_byte())
  }
}

///|
// #intrinsic("%bytes.unsafe_write_uint32_le")
pub fn unsafe_write_uint32_le(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt,
) -> Unit {
  for i in 0..=3 {
    bytes.unsafe_set(i + index, (value >> (8 * i)).to_byte())
  }
}

///|
// #intrinsic("%bytes.unsafe_write_uint32_be")
pub fn unsafe_write_uint32_be(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt,
) -> Unit {
  for i in 0..=3 {
    bytes.unsafe_set(i + index, (value >> (8 * (3 - i))).to_byte())
  }
}

///|
// #intrinsic("%bytes.unsafe_write_uint16_le")
pub fn unsafe_write_uint16_le(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt16,
) -> Unit {
  for i in 0..=1 {
    bytes.unsafe_set(i + index, (value >> (8 * i)).to_byte())
  }
}

///|
// #intrinsic("%bytes.unsafe_write_uint16_be")
pub fn unsafe_write_uint16_be(
  bytes : FixedArray[Byte],
  index : Int,
  value : UInt16,
) -> Unit {
  for i in 0..=1 {
    bytes.unsafe_set(i + index, (value >> (8 * (1 - i))).to_byte())
  }
}
