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
/// A FIFO queue backed by `@deque.Deque` (a growable circular buffer).
///
/// `push` appends to the back of the deque and `peek`/`pop` operate on the
/// front, so all queue operations are O(1) (amortized for `push`).
struct Queue[A] {
  inner : @deque.Deque[A]
}
