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
fn Bytes::unsafe_blit(
  self : Bytes,
  dst_offset : Int,
  src : Bytes,
  src_offset : Int,
  length : Int
) = "$moonbit.unsafe_bytes_blit"

///|
/// Transfer bytes.
///
/// It copies `length` bytes from `src` begin at `src_offset`, to destination byte sequence `self` begin at `dst_offset`.
///
/// # Usage
/// ```
/// let b1 = Bytes::of_string("abcdef")
/// let b2 = Bytes::of_string("ABCDEF")
/// b1.blit(2, b2, 2, 2)
/// assert_eq!(b1.to_unchecked_string(), "aBcdef")
/// ```
pub fn Bytes::blit(
  self : Bytes,
  dst_offset : Int,
  src : Bytes,
  src_offset : Int,
  length : Int
) -> Unit {
  let dst_len = self.length()
  let src_len = src.length()
  guard length >= 0 &&
    dst_offset >= 0 &&
    src_offset >= 0 &&
    dst_offset + length <= dst_len &&
    src_offset + length <= src_len
  Bytes::unsafe_blit(self, dst_offset, src, src_offset, length)
}
