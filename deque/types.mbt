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
/// A double-ended queue (deque) backed by a growable circular buffer.
///
/// This implementation follows the Rust `VecDeque` design: only `head` and `len`
/// are stored, with `tail` computed on demand as `(head + len - 1) % cap`.
///
/// Layout:
/// ```text
/// Wrapped case (head + len > cap):
///   buf: [4, 5, _, _, _, 1, 2, 3]
///              ^        ^
///        (tail)       head
///   head = 5, len = 5, tail = (5 + 5 - 1) % 8 = 1
///   Logical order: [1, 2, 3, 4, 5]
///
/// Contiguous case (head + len <= cap):
///   buf: [_, 1, 2, 3, 4, 5, _, _]
///           ^           ^
///         head       (tail)
///   head = 1, len = 5, tail = (1 + 5 - 1) % 8 = 5
///   Logical order: [1, 2, 3, 4, 5]
///
/// Empty case (len == 0):
///   buf: [_, _, _, _]
///           ^
///         head (tail is undefined, not accessed)
/// ```
///
/// Invariants:
/// - `0 <= len <= buf.length()`
/// - `0 <= head < buf.length()`
/// - Element at index `i` is at `buf[(head + i) % buf.length()]`
/// - When `len > 0`: front is `buf[head]`, back is `buf[(head + len - 1) % cap]`
/// - When `len == 0`: no valid element, `head` can be any valid index
#alias(T, deprecated)
struct Deque[A] {
  /// Circular buffer storing elements. May contain uninitialized slots.
  mut buf : UninitializedArray[A]
  /// Number of elements currently in the deque.
  mut len : Int
  /// Index of the first element (front). Valid range: 0 <= head < buf.length().
  mut head : Int
}
