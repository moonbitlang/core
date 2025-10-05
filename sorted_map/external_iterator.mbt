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
/// External iterator for in-order traversal of SortedMap.
/// Uses a closure-based design with a continuation tree for memory efficiency.
priv struct Iterator[K, V](() -> (K, V)?)

///|
/// Continuation tree for iterating through a SortedMap.
/// Encodes the remaining traversal state without needing a mutable stack.
/// - Leaf: No more elements to process
/// - More(left, right, key, value): Process left subtree, yield (key, value), then right subtree
priv enum Tree[K, V] {
  Leaf
  More(Tree[K, V], Node[K, V]?, K, V)
}

///|
fn[K, V] SortedMap::into_iterator(self : Self[K, V]) -> Iterator[K, V] {
  let mut next = self.root
  let mut cont : Tree[_, _] = Leaf
  Iterator(() => for t = next, k = cont {
    match t {
      None =>
        match k {
          Leaf => return None
          More(left, right, key, value) => {
            cont = left
            next = right
            return Some((key, value))
          }
        }
      Some(node) =>
        continue node.left, More(k, node.right, node.key, node.value)
    }
  })
}

///|
fn[K, V] Iterator::next(self : Self[K, V]) -> (K, V)? {
  self()
}

///|
test "Iterator" {
  let arr = [(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7)]
  let map = from_array(arr)
  let iter = map.into_iterator()
  for i = 0; i < arr.length(); i = i + 1 {
    match iter.next() {
      Some(value) => {
        guard value == arr[i] else {
          fail("Mismatch at index \{i}: expected \{arr[i]}, got \{value}")
        }
      }
      None => fail("Expected value at index \{i}, got None")
    }
  }
  // Verify iterator is exhausted
  guard iter.next() is None else {
    fail("Expected None after exhausting iterator")
  }
}
