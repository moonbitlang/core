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

///|
priv type InorderIterator[K, V] Array[T[K, V]]

///|
fn InorderIterator::new[K, V](root : T[K, V]) -> InorderIterator[K, V] {
  InorderIterator([])..move_left(root)
}

///|
fn InorderIterator::move_left[K, V](
  self : InorderIterator[K, V],
  node : T[K, V]
) -> Unit {
  loop node {
    Empty => ()
    Tree(_, left, _, ..) as curr => {
      self._.push(curr)
      continue left
    }
  }
}

///|
fn InorderIterator::next[K, V](self : InorderIterator[K, V]) -> (K, V)? {
  guard let Some(curr) = self._.pop() else { _ => return None }
  guard let Tree(key, _, right, value~, ..) = curr
  self.move_left(right)
  Some((key, value))
}

test "InorderIterator" {
  let arr = [(1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (6, 6), (7, 7)]
  let set = from_array(arr)
  let iter = InorderIterator::new(set)
  for i = 0; ; i = i + 1 {
    match iter.next() {
      None => break
      Some(value) => assert_eq!(value, arr[i])
    }
  }
}
