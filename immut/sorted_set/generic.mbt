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

// This module implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(
    fn(yield) {
      match self {
        Empty => IterContinue
        Node(~left, ~right, ~value, ..) =>
          if left.iter().run(yield) == IterEnd {
            return IterEnd
          } else if yield(value) == IterEnd {
            return IterEnd
          } else if right.iter().run(yield) == IterEnd {
            return IterEnd
          } else {
            return IterContinue
          }
      }
    },
  )
}

///|
pub fn T::from_iter[A : Compare](iter : Iter[A]) -> T[A] {
  iter.fold(init=T::new(), fn(s, e) { s.add(e) })
}

test {
  @json.inspect!(of([2, 7, 1, 2, 3, 4, 5]), content=[1, 2, 3, 4, 5, 7])
}

///|
pub impl[A : Eq] Eq for T[A] with op_equal(self, other) -> Bool {
  // There's no `Iter::zip` (https://github.com/moonbitlang/core/issues/994#issuecomment-2350935193),
  // so we have to use the manual implementation below:
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop iter.next(), iter1.next() {
    None, None => true
    Some(a), Some(b) => {
      guard a == b else { break false }
      continue iter.next(), iter1.next()
    }
    _, _ => false
  }
}

///|
priv type InorderIterator[A] Array[T[A]]

///|
fn InorderIterator::new[A](root : T[A]) -> InorderIterator[A] {
  InorderIterator([])..move_left(root)
}

///|
fn InorderIterator::move_left[A](
  self : InorderIterator[A],
  node : T[A]
) -> Unit {
  loop node {
    Empty => ()
    Node(~left, ..) as curr => {
      self._.push(curr)
      continue left
    }
  }
}

///|
fn InorderIterator::next[A](self : InorderIterator[A]) -> A? {
  guard let Some(curr) = self._.pop() else { _ => return None }
  guard let Node(~right, ~value, ..) = curr
  self.move_left(right)
  Some(value)
}

test "InorderIterator" {
  let arr : FixedArray[_] = [1, 2, 3, 4, 5, 6, 7]
  let set = of(arr)
  let iter = InorderIterator::new(set)
  for i = 0; ; i = i + 1 {
    match iter.next() {
      None => break
      Some(value) => assert_eq!(value, arr[i])
    }
  }
}
