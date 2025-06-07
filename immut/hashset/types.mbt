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
typealias @sparse_array.T as SpArr

///|
typealias @list.T as List

///|
typealias @path.T as Path

///|
/// Represents a non-empty set
priv enum Node[A] {
  Flat(A, Path)
  /// depth == 6
  Leaf(A, List[A])
  /// drpth < 6 and
  /// number of all its leaf > 1. If equals 1, it should be represented as `Flat`
  Branch(SpArr[Node[A]])
}

///|
type T[A] Node[A]? derive(Eq, Hash)
