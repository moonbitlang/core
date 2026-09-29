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
#unsafe_cycle_free
priv struct Node[K, V] {
  mut key : K
  mut value : V
  mut left : Node[K, V]?
  mut right : Node[K, V]?
  mut height : Int
}

///|
struct SortedMap[K, V] {
  mut root : Node[K, V]?
  mut size : Int
  // Bumped by `remove` and `clear`, the only operations that can unlink a
  // node or give a node another key; it saturates instead of wrapping.
  // `update_or_default` compares it across its callback to tell whether the
  // node it found still holds its key.
  mut removals : Int
}
