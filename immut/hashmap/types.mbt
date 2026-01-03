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
using @path {type Path}

///|
/// An non-empty immutable hash set data structure
priv enum Node[K, V] {
  Flat(K, V, Path)
  Leaf(K, V, @list.List[(K, V)]) // use a list of buckets to resolve collision
  /// number of all its leaf > 1. If equals 1, it should be represented as `Flat`
  Branch(@sparse_array.SparseArray[Node[K, V]])
}

///|
#alias(T, deprecated)
struct HashMap[K, V](Node[K, V]?) derive(Eq)
