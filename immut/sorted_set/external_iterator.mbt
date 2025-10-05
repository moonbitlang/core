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
/// External iterator for in-order traversal of SortedSet.
/// Uses a closure-based design with a continuation tree for memory efficiency.
priv struct Iterator[A](() -> A?)

///|
/// Continuation tree for iterating through a SortedSet.
/// Encodes the remaining traversal state without needing a mutable stack.
/// - Leaf: No more elements to process
/// - More(left, right, value): Process left subtree, yield value, then right subtree
priv enum Tree[A] {
  Leaf
  More(Tree[A], SortedSet[A], A)
}

///|
fn[A] SortedSet::into_iterator(self : Self[A]) -> Iterator[A] {
  let mut next = self
  let mut cont : Tree[_] = Leaf
  Iterator(() => for t = next, k = cont {
    match t {
      Empty =>
        match k {
          Leaf => return None
          More(left, right, value) => {
            cont = left
            next = right
            return Some(value)
          }
        }
      Node(left~, right~, value~, ..) => continue left, More(k, right, value)
    }
  })
}

///|
fn[A] Iterator::next(self : Self[A]) -> A? {
  self()
}

///|
test "Iterator" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6, 7]
  let set = of(arr)
  let iter = set.into_iterator()
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
