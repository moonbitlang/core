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
/// Creates a new array that is a copy of the original array.
///
/// Parameters:
///
/// * `self` : The array to be copied. The type of elements in the array must be
/// `T`.
///
/// Returns a new array containing all elements from the original array in the
/// same order.
///
/// Example:
///
/// ```moonbit
/// test "copy" {
///   let original = [1, 2, 3]
///   let copied = original.copy()
///   inspect!(copied, content="[1, 2, 3]")
///   inspect!(physical_equal(original, copied), content="false")
/// }
/// ```
pub fn FixedArray::copy[T](self : FixedArray[T]) -> FixedArray[T] {
  let len = self.length()
  if len == 0 {
    []
  } else {
    let arr = FixedArray::make(len, self[0])
    FixedArray::unsafe_blit(arr, 0, self, 0, len)
    arr
  }
}

test "copy" {
  let a : FixedArray[_] = [1, 2, 3, 4]
  let b = a.copy()
  inspect!(b, content="[1, 2, 3, 4]")
  inspect!(physical_equal(b, a), content="false")
  let c = FixedArray::make(8, 0)
  a.blit_to(c, len=4, dst_offset=3)
  inspect!(c, content="[0, 0, 0, 1, 2, 3, 4, 0]")
  inspect!(([] : FixedArray[Int]).copy(), content="[]")
  a.blit_to(a, len=2, src_offset=1)
  inspect!(a, content="[2, 3, 3, 4]")
}

///|
/// Copy bytes from a @bytes.View into a fixed array of bytes.
///
/// Parameters:
///
/// * `self` : The destination fixed array of bytes.
/// * `bytes_offset` : The starting position in the destination array where bytes will be copied.
/// * `src` : The source View to copy from.
///
/// Throws a panic if:
/// * `bytes_offset` is negative
/// * The destination array is too small to hold all bytes from the source View
///
/// Example:
///
/// ```moonbit
///  let arr = FixedArray::make(4, b'\x00')
///  let view = b"\x01\x02\x03"[1:]
///  arr.blit_from_bytesview(1, view)
///  inspect!(arr, content="[b'\\x00', b'\\x02', b'\\x03', b'\\x00']")
/// ```
pub fn FixedArray::blit_from_bytesview(
  self : FixedArray[Byte],
  bytes_offset : Int,
  src : @bytes.View
) -> Unit {
  let src_len = src.length()
  guard bytes_offset >= 0 && bytes_offset + src_len - 1 < self.length()
  for i = 0, j = bytes_offset; i < src_len; i = i + 1, j = j + 1 {
    self[j] = src[i]
  }
}
