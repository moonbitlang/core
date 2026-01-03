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
priv struct Cons[A] {
  content : A
  mut next : Cons[A]?
} derive(Eq)

///|
/// A FIFO queue backed by a singly linked list of `Cons` cells.
///
/// Layout:
/// - `first` points to the head cell (front of the queue).
/// - `last` points to the tail cell (back of the queue) and its `next` is None.
/// - When empty, `first` and `last` are None and `length` is 0.
///
/// We keep both `first` and `last` so `pop` and `push` are O(1) without
/// scanning the list.
#alias(T, deprecated)
struct Queue[A] {
  /// Number of elements in the queue.
  mut length : Int
  /// Head cell (front) for O(1) peek/pop.
  mut first : Cons[A]?
  /// Tail cell (back) for O(1) push/append.
  mut last : Cons[A]?
}
