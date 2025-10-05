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
priv struct InorderIterator[A](Array[SortedSet[A]])

///|
fn[A] SortedSet::into_iterator(self : Self[A]) -> InorderIterator[A] {
  InorderIterator::new(self)
}

///|
fn[A] InorderIterator::new(root : SortedSet[A]) -> InorderIterator[A] {
  let it = InorderIterator([])
  it.move_left(root)
  it
}

///|
fn[A] InorderIterator::move_left(
  self : InorderIterator[A],
  node : SortedSet[A],
) -> Unit {
  loop node {
    Empty => ()
    Node(left~, ..) as curr => {
      self.0.push(curr)
      continue left
    }
  }
}

///|
fn[A] InorderIterator::next(self : Self[A]) -> A? {
  let InorderIterator(s) = self
  guard s.pop() is Some(curr) else { return None }
  guard curr is Node(right~, value~, ..)
  self.move_left(right)
  Some(value)
}

///|
test "InorderIterator" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6, 7]
  let set = of(arr)
  let iter = InorderIterator::new(set)
  for i = 0; ; i = i + 1 {
    match iter.next() {
      None => break
      Some(value) => assert_eq(value, arr[i])
    }
  }
}
