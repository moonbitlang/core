// Copyright 2024 International Digital Economy Academy
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

/// A bucket is a non-empty linked list of key-value pair,
/// used to resolve hash collision in HAMT
priv enum Bucket[T] {
  Just_One(T) // must be non-empty
  More(T, Bucket[T])
}

/// An immutable hash set data structure
enum T[A] {
  Empty
  Leaf(A) // optimize for the case of no collision
  Collision(Bucket[A]) // use a list of buckets to resolve collision
  Branch(@sparse_array.SparseArray[T[A]])
}
