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
/// A view over `source` filtered through a stable list of retained indices.
///
/// `indices[i]` stores the original position in `source` for the `i`th visible
/// element. This lets the Myers implementation skip values that cannot match
/// while still translating results back to the original coordinates.
priv struct CompactedElements[T]((ArrayView[T], FixedArray[Int]))

///|
/// Read the `index`th retained element.
fn[T] CompactedElements::op_get(self : CompactedElements[T], index : Int) -> T {
  let (source, indices) = self.0
  source[indices[index]]
}

///|
/// Map a retained position back to its original index in `source`.
fn[T] CompactedElements::get_index(
  self : CompactedElements[T],
  index : Int,
) -> Int {
  let (_, indices) = self.0
  indices[index]
}

///|
/// Return the number of retained elements visible through this compacted view.
fn[T] CompactedElements::indices_length(self : CompactedElements[T]) -> Int {
  self.0.1.length()
}

///|
/// Return the length of the underlying unfiltered source sequence.
fn[T] CompactedElements::source_length(self : CompactedElements[T]) -> Int {
  self.0.0.length()
}
