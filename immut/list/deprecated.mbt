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
#deprecated("use `@immut/list.from_json` instead")
#coverage.skip
pub fn[A : @json.FromJson] T::from_json(
  json : Json
) -> T[A] raise @json.JsonDecodeError {
  @json.from_json(json)
}

///|
/// Init of the list.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3, 4, 5]).init_(), @list.of([1, 2, 3, 4]))
/// ```
#deprecated
#coverage.skip
pub fn[A] init_(self : T[A]) -> T[A] {
  fn aux(self) {
    match self {
      Nil => Nil
      Cons(_, Nil) => Nil
      Cons(head, tail) => Cons(head, aux(tail))
    }
  }

  aux(self)
}

///|
/// Compares two lists for equality.
///
/// # Example
///
/// ```mbt
///   assert_eq(@list.of([1, 2, 3]) == @list.of([1, 2, 3]), true)
/// ```
#deprecated("use `==` instead")
pub fn[A : Eq] equal(self : T[A], other : T[A]) -> Bool {
  loop (self, other) {
    (Nil, Nil) => true
    (Cons(h, t), Cons(h1, t1)) => if h == h1 { continue (t, t1) } else { false }
    (_, _) => false
  }
}

///|
#deprecated("use `@immut/list.from_array` instead")
#coverage.skip
pub fn[A] T::from_array(arr : Array[A]) -> T[A] {
  from_array(arr)
}

///|
#deprecated("use `@immut/list.default` instead")
#coverage.skip
pub fn[X] T::default() -> T[X] {
  Nil
}

///|
#deprecated("use `@immut/list.from_iter` instead")
#coverage.skip
pub fn[A] T::from_iter(iter : Iter[A]) -> T[A] {
  from_iter(iter)
}

///|
#deprecated("use `@immut/list.of` instead")
#coverage.skip
pub fn[A] T::of(arr : FixedArray[A]) -> T[A] {
  of(arr)
}
