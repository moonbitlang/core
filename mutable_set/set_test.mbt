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

/// Convert MutableSet[T] to List[T], the result must be ordered.
pub fn to_list[T : Compare](self : MutableSet[T]) -> List[T] {
  fn aux(set : Option[Node[T]], list : List[T]) {
    match set {
      None => list
      Some(node) =>
        match node.value {
          None => list
          Some(value) => aux(node.left, Cons(value, aux(node.right, list)))
        }
    }
  }

  aux(self.root, Nil)
}

test "to_list" {
  inspect(
    MutableSet::[7, 2, 9, 4, 5, 6, 3, 8, 1].to_list(),
    content="List::[1, 2, 3, 4, 5, 6, 7, 8, 9]",
  )?
  inspect((MutableSet::[] : MutableSet[Int]).to_list(), content="List::[]")?
}
