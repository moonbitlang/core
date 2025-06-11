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
/// Creates a new empty stack.
///
/// # Example
/// ```
/// test "new_stack_example" {
///   let stack : @stack.T[Int] = @stack.new()
///   assert_eq(stack.length(), 0)
/// }
/// ```
pub fn[A] new() -> T[A] {
  { data: [] }
}

///|
/// Creates a new stack from an array.
///
/// # Example
/// ```
/// test "from_array_example" {
///   let stack : @stack.T[Int] = @stack.from_array([1,2,3])
///   assert_eq(stack.length(), 3)
/// }
/// ```
pub fn[A] from_array(arr : Array[A]) -> T[A] {
  { data: arr }
}

///|
/// Creates a new stack from a fixed array.
pub fn[A] of(arr : FixedArray[A]) -> T[A] {
  from_array(Array::from_fixed_array(arr))
}

///|
pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@stack.of([", suffix="])")
}

///|
/// Pushes a value onto the stack.
pub fn[A] push(self : T[A], x : A) -> Unit {
  self.data.push(x)
}

///|
/// Pops the top value from the stack, panicking if empty.
#internal(unsafe, "Panics if the stack is empty.")
pub fn[A] unsafe_pop(self : T[A]) -> A {
  self.data.unsafe_pop()
}

///|
/// Pops the top value from the stack.
pub fn[A] pop(self : T[A]) -> A? {
  self.data.pop()
}

///|
/// Peeks the top value of the stack, panicking if empty.
#internal(unsafe, "Panics if the stack is empty.")
pub fn[A] unsafe_peek(self : T[A]) -> A {
  match self.data.last() {
    Some(v) => v
    None => abort("Stack is empty")
  }
}

///|
/// Peeks the top value of the stack.
pub fn[A] peek(self : T[A]) -> A? {
  self.data.last()
}

///|
/// Returns the number of elements in the stack.
pub fn[A] length(self : T[A]) -> Int {
  self.data.length()
}

///|
/// Returns true if the stack contains no elements.
pub fn[A] is_empty(self : T[A]) -> Bool {
  self.data.is_empty()
}

///|
/// Removes all elements from the stack.
pub fn[A] clear(self : T[A]) -> Unit {
  self.data.clear()
}

///|
/// Creates an iterator from the stack (top to bottom).
pub fn[A] iter(self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    for i = self.data.length() - 1; i >= 0; {
      if yield_(self.data[i]) == IterEnd {
        break IterEnd
      } else {
        continue i - 1
      }
    } else {
      IterContinue
    }
  })
}

///|
/// Creates a stack from an iterator.
pub fn[A] from_iter(iter : Iter[A]) -> T[A] {
  let s = new()
  iter.each(fn(e) { s.push(e) })
  s
}

///|
pub impl[X : @quickcheck.Arbitrary] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs,
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_iter
}
