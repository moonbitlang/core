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

pub fn iter[A](self : T[A]) -> Iter[A] {
  match self {
    Empty => Iter::empty()
    Node(~left, ~right, ~value, ..) =>
      left.iter().append(value).concat(right.iter())
  }
}

pub fn T::from_iter[A : Compare](iter : Iter[A]) -> T[A] {
  iter.fold(init=T::new(), fn(s, e) { s.add(e) })
}

test {
  let buf = Buffer::new(size_hint=20)
  of([2, 7, 1, 2, 3, 4, 5]).iter().each(
    fn { x => buf.write_string(x.to_string()) },
  )
  inspect!(buf, content="123457")
}
