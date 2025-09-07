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
/// Physically copy the array.
/// Since it is an immutable data structure,
/// it is rarely the case that you would need this function.
/// 
#deprecated("We don't copy immutable array")
#coverage.skip
pub fn[A] copy(self : T[A]) -> T[A] {
  fn copy(t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(l.copy())
      Empty => Empty
      Node(node, sizes) =>
        Node(
          FixedArray::makei(node.length(), i => copy(node[i])),
          match sizes {
            Some(sizes) => Some(FixedArray::copy(sizes))
            None => None
          },
        )
    }
  }

  { tree: copy(self.tree), size: self.size, shift: self.shift }
}

///|
/// Fold the array from left to right.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.fold((a, b) => { a + b }, init=0), 15)
/// ```
#deprecated("Use `fold` instead")
#coverage.skip
pub fn[A] fold_left(self : T[A], f : (A, A) -> A raise?, init~ : A) -> A raise? {
  self.fold(init~, f)
}

///|
/// Fold the array from right to left.
///
/// # Example
/// ```mbt
///   let v = @array.of([1, 2, 3, 4, 5])
///   assert_eq(v.rev_fold((a, b) => { a + b }, init=0), 15)
/// ```
#deprecated("Use `rev_fold` instead")
#coverage.skip
pub fn[A] fold_right(
  self : T[A],
  f : (A, A) -> A raise?,
  init~ : A,
) -> A raise? {
  self.rev_fold(init~, f)
}
