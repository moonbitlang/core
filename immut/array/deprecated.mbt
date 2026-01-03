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
/// Physically copy the array.
/// Since it is an immutable data structure,
/// it is rarely the case that you would need this function.
/// 
#deprecated("We don't copy immutable array")
#coverage.skip
pub fn[A] T::copy(self : T[A]) -> T[A] {
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
