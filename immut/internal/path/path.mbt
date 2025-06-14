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
/// A Path is a binary string divided into several segments, for example:
/// 0b11_10000_10101_00100_11111_01010
/// where the last segment is 10000, and the first segment is 01010.
pub(all) type Path UInt

///|
const SEGMENT_LENGTH : Int = 5

///|
const INDEX_MASK : UInt = (1 << SEGMENT_LENGTH) - 1

///|
const SEGMENT_NUM : Int = 32 / SEGMENT_LENGTH

///|
const HEAD_TAG : UInt = 0xffffffffU << (SEGMENT_LENGTH * SEGMENT_NUM)

///|
pub fn[A : Hash] of(key : A) -> Path {
  key.hash().reinterpret_as_uint() | HEAD_TAG
}

///|
/// If SEGMENT_LENGTH == 5, END == 0b11
const END : UInt = 0xffffffffU >> (SEGMENT_LENGTH * SEGMENT_NUM)

///|
pub fn Path::is_end(self : Path) -> Bool {
  let Path(self) = self
  self == END
}

///|
pub fn Path::push(self : Path, idx : Int) -> Path {
  let Path(self) = self
  (self << SEGMENT_LENGTH) | idx.reinterpret_as_uint()
}

///|
pub fn Path::idx(self : Path) -> Int {
  let Path(self) = self
  (self & INDEX_MASK).reinterpret_as_int()
}

///|
pub fn Path::next(self : Path) -> Path {
  let Path(self) = self
  self >> SEGMENT_LENGTH
}
