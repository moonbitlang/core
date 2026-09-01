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
/// A non-empty immutable hash set data structure
#unsafe_cycle_free
priv enum Node[A] {
  /// a subtree holding exactly one element, at any depth; carries the
  /// not-yet-consumed remainder of the element's path (only the head tag
  /// once every segment is consumed)
  Flat(A, @path.Path)
  /// collision bucket at maximum depth (all six path segments equal);
  /// always holds at least two elements — a lone element must be
  /// represented as `Flat`
  Leaf(A, @list.List[A])
  /// number of all its leaf > 1. If equals 1, it should be represented as `Flat`
  Branch(@sparse_array.SparseArray[Node[A]])
}

///|
#valtype
struct HashSet[A] {
  data : Node[A]?
} derive(Eq)
