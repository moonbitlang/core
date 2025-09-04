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

// This package implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
pub fn[A] iter(self : SortedSet[A]) -> Iter[A] {
  Iter::new(yield_ => {
    fn go(t) {
      match t {
        Empty => IterContinue
        Node(left~, right~, value~, ..) =>
          if go(left) is IterEnd {
            IterEnd
          } else if yield_(value) is IterEnd {
            IterEnd
          } else {
            go(right)
          }
      }
    }

    go(self)
  })
}

///|
#as_free_fn
pub fn[A : Compare] SortedSet::from_iter(iter : Iter[A]) -> SortedSet[A] {
  iter.fold(init=new(), (s, e) => s.add(e))
}

///|
test {
  @json.inspect(of([2, 7, 1, 2, 3, 4, 5]), content=[1, 2, 3, 4, 5, 7])
}

///|
pub impl[A : Eq] Eq for SortedSet[A] with equal(self, other) -> Bool {
  // There's no `Iter::zip` (https://github.com/moonbitlang/core/issues/994#issuecomment-2350935193),
  // so we have to use the manual implementation below:
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop (iter.next(), iter1.next()) {
    (None, None) => true
    (Some(a), Some(b)) => {
      guard a == b else { break false }
      continue (iter.next(), iter1.next())
    }
    (_, _) => false
  }
}

///|
pub impl[A : Compare] Compare for SortedSet[A] with compare(self, other) -> Int {
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop (iter.next(), iter1.next()) {
    (None, None) => 0
    (Some(a), Some(b)) => {
      let cmp = a.compare(b)
      guard cmp == 0 else { break cmp }
      continue (iter.next(), iter1.next())
    }
    (Some(_), None) => 1
    (None, Some(_)) => -1
  }
}

///|
priv struct InorderIterator[A](Array[SortedSet[A]])

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
      let InorderIterator(self) = self
      self.push(curr)
      continue left
    }
  }
}

///|
fn[A] InorderIterator::next(self : InorderIterator[A]) -> A? {
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
