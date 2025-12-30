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
/// A double-ended queue (deque) backed by a growable circular buffer.
///
/// Layout:
/// ```text
/// Non-contiguous case (head > tail, wrapped around):
///   buf: [4, 5, _, _, _, 1, 2, 3]
///              ^        ^
///            tail     head
///   Logical order: [1, 2, 3, 4, 5]
///
/// Contiguous case (head <= tail):
///   buf: [_, 1, 2, 3, 4, 5, _, _]
///           ^           ^
///         head        tail
///   Logical order: [1, 2, 3, 4, 5]
///
/// Empty case (len == 0):
///   buf: [_, _, _, _]
///           ^
///       head=tail (both point to same slot, value is undefined)
/// ```
///
/// Invariants:
/// - `len` is the number of elements in the deque (0 <= len <= buf.length())
/// - When `len == 0`: `head` and `tail` point to the same slot (value undefined)
/// - When `len > 0`: `head` points to the first element, `tail` points to the last
/// - Both `head` and `tail` always point to occupied slots (not the next empty slot)
/// - Elements are stored circularly: index `i` maps to `buf[(head + i) % buf.length()]`
/// - `tail == (head + len - 1) % buf.length()` when `len > 0`
#alias(T, deprecated)
struct Deque[A] {
  /// Circular buffer storing elements. May contain uninitialized slots.
  mut buf : UninitializedArray[A]
  /// Number of elements currently in the deque.
  mut len : Int
  /// Index of the first element (front). When empty, equals `tail`.
  mut head : Int
  /// Index of the last element (back). When empty, equals `head`.
  mut tail : Int
}
