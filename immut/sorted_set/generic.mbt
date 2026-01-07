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

// This package implements the set data structure.
// The types stored in set need to implement the Compare trait.
// All operations over sets are purely applicative (no side-effects).

///|
/// Iterate over the elements in the set in descending order.
///
/// # Example
///
/// ```mbt
///   let set = @sorted_set.from_array([1, 2, 3, 4, 5])
///   let result = set.rev_iter().collect()
///   assert_eq(result, [5, 4, 3, 2, 1])
/// ```
#alias(rev_iterator, deprecated)
pub fn[A] SortedSet::rev_iter(self : SortedSet[A]) -> Iter[A] {
  let mut curr_node = self
  let parents = []
  Iter::new(fn() {
    loop curr_node {
      Node(left~, right=Empty, value~, ..) => {
        curr_node = left
        Some(value)
      }
      Node(left~, right~, value~, ..) => {
        parents.push((value, left))
        continue right
      }
      Empty if parents.pop() is Some((value, left)) => {
        curr_node = left
        Some(value)
      }
      Empty => None
    }
  })
}

///|
#alias(iterator, deprecated)
pub fn[A] SortedSet::iter(self : SortedSet[A]) -> Iter[A] {
  let mut curr_node = self
  let parents = []
  Iter::new(fn() {
    loop curr_node {
      Node(left=Empty, right~, value~, size=_) => {
        curr_node = right
        Some(value)
      }
      Node(left~, right~, value~, size=_) => {
        parents.push((value, right))
        continue left
      }
      Empty if parents.pop() is Some((value, right)) => {
        curr_node = right
        Some(value)
      }
      Empty => None
    }
  })
}

///|
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[A : Compare] SortedSet::from_iter(iter : Iter[A]) -> SortedSet[A] {
  iter.fold(init=new(), (s, e) => s.add(e))
}

///|
test {
  @json.inspect(from_array([2, 7, 1, 2, 3, 4, 5]), content=[1, 2, 3, 4, 5, 7])
}

///|
pub impl[A : Eq] Eq for SortedSet[A] with equal(self, other) -> Bool {
  // There's no `Iter::zip` (https://github.com/moonbitlang/core/issues/994#issuecomment-2350935193),
  // so we have to use the manual implementation below:
  guard self.length() == other.length() else { return false }
  let iter = self.iter()
  let iter1 = other.iter()
  while iter.next() is Some(a) && iter1.next() is Some(b) {
    guard a == b else { break false }
  } else {
    true
  }
}

///|
pub impl[A : Compare] Compare for SortedSet[A] with compare(self, other) -> Int {
  let my_size = self.length()
  let other_size = other.length()
  guard my_size == other_size else { return my_size - other_size }
  let iter = self.iter()
  let iter1 = other.iter()
  while iter.next() is Some(a) && iter1.next() is Some(b) {
    let cmp = a.compare(b)
    guard cmp is 0 else { break cmp }
  } else {
    0
  }
}

///|
test "Eq - equal sets" {
  let s1 = from_array([1, 2, 3, 4, 5])
  let s2 = from_array([5, 4, 3, 2, 1])
  inspect(s1 == s2, content="true")
}

///|
test "Eq - different elements same size" {
  let s1 = from_array([1, 2, 3, 4, 5])
  let s2 = from_array([1, 2, 3, 4, 6])
  inspect(s1 == s2, content="false")
}

///|
test "Eq - different sizes" {
  let s1 = from_array([1, 2, 3])
  let s2 = from_array([1, 2, 3, 4, 5])
  inspect(s1 == s2, content="false")
}

///|
test "Eq - empty sets" {
  let s1 : SortedSet[Int] = new()
  let s2 : SortedSet[Int] = new()
  inspect(s1 == s2, content="true")
}

///|
test "Eq - one empty one not" {
  let s1 : SortedSet[Int] = new()
  let s2 = from_array([1])
  inspect(s1 == s2, content="false")
}

///|
test "Compare - equal sets" {
  let s1 = from_array([1, 2, 3])
  let s2 = from_array([3, 2, 1])
  inspect(s1.compare(s2), content="0")
}

///|
test "Compare - first smaller by size" {
  let s1 = from_array([1, 2])
  let s2 = from_array([1, 2, 3])
  inspect(s1.compare(s2) < 0, content="true")
}

///|
test "Compare - first larger by size" {
  let s1 = from_array([1, 2, 3, 4])
  let s2 = from_array([1, 2])
  inspect(s1.compare(s2) > 0, content="true")
}

///|
test "Compare - same size first smaller by elements" {
  let s1 = from_array([1, 2, 3])
  let s2 = from_array([1, 2, 4])
  inspect(s1.compare(s2) < 0, content="true")
}

///|
test "Compare - same size first larger by elements" {
  let s1 = from_array([1, 2, 5])
  let s2 = from_array([1, 2, 4])
  inspect(s1.compare(s2) > 0, content="true")
}

///|
test "Compare - empty sets" {
  let s1 : SortedSet[Int] = new()
  let s2 : SortedSet[Int] = new()
  inspect(s1.compare(s2), content="0")
}
