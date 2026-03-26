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
/// A node in the predecessor chain recovered from the patience-sorting phase.
///
/// `value` stores the current pile entry, and `prev` points to the entry chosen
/// from the previous pile so the final increasing chain can be reconstructed
/// once the last pile is known.
priv struct BackPointer[T] {
  value : T
  prev : BackPointer[T]?
}

///|
/// Materialize the predecessor chain ending at `self`, preserving left-to-right
/// subsequence order.
fn[T] BackPointer::to_array(self : BackPointer[T]) -> Array[T] {
  let result = []
  let mut self = self
  while self.prev is Some(prev) {
    result.push(self.value)
    self = prev
  }
  result.push(self.value)
  return result.rev()
}
