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
#deprecated("use `_.to_array().rev_fold(...)` instead")
pub fn[A, B] List::rev_fold(self : List[A], init~ : B, f : (B, A) -> B) -> B {
  let xs = self.to_array()
  let mut acc = init
  for x in xs.rev_iter() {
    acc = f(acc, x)
  }
  acc
}

///|
#deprecated("use `_.rev().foldi(...)` instead")
pub fn[A, B] List::rev_foldi(
  self : List[A],
  init~ : B,
  f : (Int, B, A) -> B,
) -> B {
  self.rev().foldi(init~, (i, b, a) => f(i, b, a))
}

///|
#deprecated("use `unsafe_tail` instead")
pub fn[A] List::tail(self : List[A]) -> List[A] {
  match self {
    Empty => Empty
    More(_, tail~) => tail
  }
}
