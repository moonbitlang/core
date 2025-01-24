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
/// Copies a sequence of bytes from a source byte sequence to a destination byte
/// sequence.
///
/// Parameters:
///
/// * `self` : The destination byte sequence where bytes will be copied to.
/// * `dst_offset` : The starting position in the destination sequence where
/// bytes will be written.
/// * `src` : The source byte sequence from which bytes will be copied.
/// * `src_offset` : The starting position in the source sequence from which
/// bytes will be read.
/// * `length` : The number of bytes to copy.
///
/// Throws a runtime error if:
///
/// * `length` is negative
/// * `dst_offset` is negative
/// * `src_offset` is negative
/// * The range `[dst_offset, dst_offset + length)` exceeds the length of the
/// destination sequence
/// * The range `[src_offset, src_offset + length)` exceeds the length of the
/// source sequence
///
/// Example:
///
/// ```moonbit
/// test "Bytes::blit" {
///   let dst = Bytes::of_string("Hello, world!")
///   let src = Bytes::of_string("MOONBIT")
///   dst.blit(14, src, 0, 8)
///   @json.inspect!(dst.to_unchecked_string(), content="Hello, MOONd!")
/// }
///
/// test "panic Bytes::blit/out_of_bounds" {
///   let dst = Bytes::of_string("Hello")
///   let src = Bytes::of_string("World")
///   ignore(dst.blit(6, src, 0, 20)) // Range exceeds destination length
/// }
/// ```
/// @alert deprecated "Bytes is about to be changed to immutable, use `FixedArray[Byte]` instead"
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
