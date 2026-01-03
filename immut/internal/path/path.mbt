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
/// A `Path` represents a binary string divided into multiple segments,
/// which is used for traversing HAMT.
/// 
/// It consists of a 32-bit unsigned integer with a specific layout
/// (when SEGMENT_LENGTH = 5):
/// - The highest 2 bits are reserved as a head tag (0b11)
/// - The remaining bits are divided into segments of 5 bits each
///
/// For example, `Path::of(x) = 0b11_10000_10101_00100_11111_01010`
/// represents segments as [0b_10000, 0b_10101, 0b_00100, 0b_11111, 0b_01010]
pub(all) struct Path(UInt) derive(Eq)

///|
const SEGMENT_LENGTH : Int = 5

///|
const INDEX_MASK : UInt = (1 << SEGMENT_LENGTH) - 1

///|
const SEGMENT_NUM : Int = 32 / SEGMENT_LENGTH

///|
const HEAD_TAG : UInt = 0xffffffffU << (SEGMENT_LENGTH * SEGMENT_NUM)

///|
/// Creates a Path using the lowest (SEGMENT_LENGTH * SEGMENT_NUM)
/// bits of the key's hash.
pub fn[A : Hash] of(key : A) -> Path {
  key.hash().reinterpret_as_uint() | HEAD_TAG
}

///|
/// If SEGMENT_LENGTH == 5, MAX_TAIL == 0b11_11111
const MAX_TAIL : UInt = 0xffffffffU >> (SEGMENT_LENGTH * (SEGMENT_NUM - 1))

///|
/// Returns if the path contains only a single segment.
pub fn Path::is_last(self : Path) -> Bool {
  let Path(self) = self
  self <= MAX_TAIL
}

///|
/// Push the given `idx` as the last segment to `self`.
pub fn Path::push(self : Path, idx : Int) -> Path {
  let Path(self) = self
  (self << SEGMENT_LENGTH) | idx.reinterpret_as_uint()
}

///|
/// The last segment of `self`.
pub fn Path::idx(self : Path) -> Int {
  let Path(self) = self
  (self & INDEX_MASK).reinterpret_as_int()
}

///|
/// Removes last segment of `self`.
pub fn Path::next(self : Path) -> Path {
  let Path(self) = self
  self >> SEGMENT_LENGTH
}
