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

/// Convert array to list.
///
/// # Example
///
/// ```
/// [1, 2, 3, 4, 5].to_list()
/// ```
pub fn to_list[T](self : FixedArray[T]) -> List[T] {
  for i = self.length() - 1, list = List::Nil; i >= 0; {
    continue i - 1, List::Cons(self[i], list)
  } else {
    list
  }
}

test "to_list" {
  {
    let ls : List[Int] = ([] : FixedArray[_]).to_list()
    @assertion.assert_eq(ls, Nil)?
  }
  {
    let ls = ([3] : FixedArray[_]).to_list()
    @assertion.assert_eq(ls, Cons(3, Nil))?
  }
  let ls = ([1, 2, 3, 4, 5] : FixedArray[_]).to_list()
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))?
}
