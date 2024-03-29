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

// This module provides a List-based Stack implementation.

struct Stack[T] {
  mut elements : List[T]
  mut len : Int
} derive(Debug, Show, Default)

/// Create an empty stack
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::new()
/// println(s) // output: {elements: Nil, len: 0}
/// ```
pub fn Stack::new[T]() -> Stack[T] {
  { elements: Nil, len: 0 }
}

test "new" {
  let s : Stack[Unit] = Stack::new()
  @test.eq(s.elements, Nil)?
}

/// Create a stack based on all elements in list
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
/// println(s) // output: {elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3}
/// ```
pub fn Stack::from_list[T](list : List[T]) -> Stack[T] {
  { elements: list.reverse(), len: list.length() }
}

test "from_list" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
  @test.eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @test.eq(s.len, 3)?
}

/// Create a stack based on all elements in array
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1, 2, 3]))
/// println(s) // output: {elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3}
/// ```
pub fn Stack::from_array[T](array : Array[T]) -> Stack[T] {
  { elements: List::from_array(array).reverse(), len: array.length() }
}

test "from_array" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @test.eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @test.eq(s.len, 3)?
}

/// Create a stack based on another stack
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
/// let s1: Stack[Int] = Stack::from_stack(s)
/// println(s1) // output: {elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3}
/// ```
pub fn Stack::from_stack[T](other : Stack[T]) -> Stack[T] {
  { ..other,  }
}

test "from_stack" {
  let s : Stack[Int] = Stack::from_list(Cons(3, Cons(2, Cons(1, Nil))))
  let s1 : Stack[Int] = Stack::from_stack(s)
  @test.eq(s1.elements, s.elements)?
}

/// Clear all elements in Stack
/// 
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
/// s.clear()
/// println(s) //output: {elements: Nil, len: 0}
/// ```
pub fn clear[T](self : Stack[T]) -> Unit {
  self.elements = Nil
  self.len = 0
}

test "clear" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
  s.clear()
  @test.eq(s.elements, Nil)?
}

/// Same as the `clear()`, but returns an cleared stack
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil)))).return_with_clear()
/// println(s) //output: {elements: Nil, len: 0}
/// ```
pub fn return_with_clear[T](self : Stack[T]) -> Stack[T] {
  self.clear()
  self
}

test "return_with_clear" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil)))).return_with_clear()
  @test.eq(s.elements, Nil)?
}

/// Returns a copy of the current Stack
/// 
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
/// let s1: Stack[Int] = s.copy()
/// println(s) // output: {elements: Cons(1, Cons(2, Cons(3, Nil))), len: 3}
/// ```
pub fn copy[T](self : Stack[T]) -> Stack[T] {
  { ..self,  }
}

test "copy" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
  let s1 : Stack[Int] = s.copy()
  @test.eq(s1.elements, s.elements)?
}

/// Push an element into the stack
/// 
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::new()
/// s.push(1)
/// println(s) // output: {elements: Cons(1, Nil), len: 1}
/// ```
pub fn push[T](self : Stack[T], x : T) -> Unit {
  self.elements = Cons(x, self.elements)
  self.len = self.len + 1
}

test "push" {
  let s : Stack[Int] = Stack::new()
  s.push(1)
  @test.eq(s.elements, Cons(1, Nil))?
  @test.eq(s.len, 1)?
}

/// Push a list into the stack
/// 
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::new()
/// s.push_list(Cons(1, Cons(2, Cons(3, Nil))))
/// println(s) // output: {elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3}
/// ```
pub fn push_list[T](self : Stack[T], list : List[T]) -> Unit {
  list.iter(fn(i) -> Unit { self.push(i) })
}

test "push_list" {
  let s : Stack[Int] = Stack::new()
  s.push_list(Cons(1, Cons(2, Cons(3, Nil))))
  @test.eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @test.eq(s.len, 3)?
}

/// Push other stack into the current stack
/// 
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_list(Cons(1, (Cons 2, Cons(3, Nil)))
/// let s1: Stack[Int] = Stack::new()
/// s1.push_stack(s)
/// println(s1) // output: {elements: Cons(1, Cons(2, Cons(3, Nil))), len: 3}
/// ```
pub fn push_stack[T](self : Stack[T], stack : Stack[T]) -> Unit {
  stack.elements.iter(fn(i) -> Unit { self.push(i) })
}

test "push_stack" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
  let s1 : Stack[Int] = Stack::new()
  s1.push_stack(s)
  @test.eq(s1.elements, Cons(1, Cons(2, Cons(3, Nil))))?
  @test.eq(s.len, s1.len)?
}

/// Push an array into the stack.
/// 
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::new()
/// s.push_array([1, 2, 3])
/// println(s) // output: {elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3}
/// ```
pub fn push_array[T](self : Stack[T], array : Array[T]) -> Unit {
  array.iter(fn(i) -> Unit { self.push(i) })
}

test "push_array" {
  let s : Stack[Int] = Stack::new()
  s.push_array([1, 2, 3])
  @test.eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @test.eq(s.len, 3)?
}

/// Pop an element from the top of the stack.
/// If there are elements in the stack, return `Some (the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// let s1: Stack[Int] = Stack::new()
/// println(s.pop()) // output: Some(1)
/// println(s) // output: { elements: Cons(2, Cons(1, Nil)), len: 2 }
/// println(s1.pop()) // output: None
/// ```
pub fn pop[T](self : Stack[T]) -> Option[T] {
  match self.elements {
    Cons(hd, tl) => {
      self.elements = tl
      self.len = self.len - 1
      Some(hd)
    }
    Nil => None
  }
}

test "pop" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  let s1 : Stack[Int] = Stack::new()
  @test.eq(s.pop(), Some(3))?
  @test.eq(s.elements, Cons(2, Cons(1, Nil)))?
  @test.eq(s.len, 2)?
  @test.eq(s1.pop(), None)?
  @test.eq(s1.elements, Nil)?
  @test.eq(s1.len, 0)?
}

/// Pop an element from the top of the stack.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// let s1: Stack[Int] = Stack::new()
/// println(s.pop_exn()) // output: 1
/// println(s) // output: { elements: Cons(2, Cons(1, Nil)), len: 2 }
/// println(s1.pop_exn()) // abort.
/// ```
pub fn pop_exn[T](self : Stack[T]) -> T {
  match self.elements {
    Cons(hd, tl) => {
      self.elements = tl
      self.len = self.len - 1
      hd
    }
    Nil => abort("pop of empty stack")
  }
}

test "pop_exn" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @test.eq(s.pop_exn(), 3)?
  @test.eq(s.elements, Cons(2, Cons(1, Nil)))?
  @test.eq(s.len, 2)?
}

/// Drop the element at the top of the stack.
/// Like pop, but does not return elements and does nothing if the Stack is empty.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// s.drop()
/// println(s) // output: { elements: Cons(2, Cons(3, Nil)), len: 2 }
/// ```
pub fn drop[T](self : Stack[T]) -> Unit {
  match self.elements {
    Cons(_hd, tl) => {
      self.elements = tl
      self.len = self.len - 1
    }
    Nil => ()
  }
}

test "drop" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  s.drop()
  @test.eq(s.elements, Cons(2, Cons(1, Nil)))?
  @test.eq(s.len, 2)?
}

/// Drop the element at the top of the stack.
/// Like drop, but when the drop is successful, it returns `Ok(())`, and when it fails, it returns `Err(())`
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// s.drop()
/// println(s) // output: { elements: Cons(2, Cons(3, Nil)), len: 2 }
/// ```
pub fn drop_result[T](self : Stack[T]) -> Result[Unit, Unit] {
  match self.elements {
    Cons(_hd, tl) => {
      self.elements = tl
      self.len = self.len - 1
      Ok(())
    }
    Nil => Err(())
  }
}

test "drop_result" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  let s1 : Stack[Int] = Stack::new()
  @test.eq(s1.drop_result(), Err(()))?
  @test.eq(s.drop_result(), Ok(()))?
  @test.eq(s.elements, Cons(2, Cons(1, Nil)))?
  @test.eq(s.len, 2)?
}

/// Only the top element of the stack is returned and will not be pop or drop.
/// If there are elements in the stack, return `Some (the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// println(s.peek()) // output: Some(3)
/// println(s) // output: { elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3 }
/// ```
pub fn peek[T](self : Stack[T]) -> Option[T] {
  match self.elements {
    Cons(hd, _) => Some(hd)
    Nil => None
  }
}

test "peek" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @test.eq(s.peek(), Some(3))?
  @test.eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @test.eq(s.len, 3)?
}

/// Only the top element of the stack is returned and will not be pop or drop.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// let s1: Stack[Int] = Stack::new()
/// println(s1.peek_exn()) // abort
/// println(s.peek_exn()) // output: 3
/// println(s) // output: { elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3 }
/// ```
pub fn peek_exn[T](self : Stack[T]) -> T {
  match self.elements {
    Cons(hd, _) => hd
    Nil => abort("top of the empty stack")
  }
}

test "peek_exn" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @test.eq(s.peek_exn(), 3)?
  @test.eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @test.eq(s.len, 3)?
}

/// If stack is empty, return true, otherwise return false.
///
/// # Example
///
/// ```
/// println(Stack::from_array([1, 2, 3]).is_empty()) // output: false
/// println(Stack::new().is_empty()) // output: true
/// ```
pub fn is_empty[T](self : Stack[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let empty : Stack[Unit] = Stack::new()
  @test.is_false(Stack::[1, 2, 3].is_empty())?
  @test.assert_true(empty.is_empty())?
}

/// Returns the number of elements of the Stack
pub fn length[T](self : Stack[T]) -> Int {
  self.len
}

/// Iterates over the elements of the stack from top to bottom.
/// 
/// # Example
/// ```
/// let s: Stack[Int] = Stack::from_array([1, 2, 3])
/// s.iter(fn(i) { println(i) })'
/// ```
pub fn iter[T](self : Stack[T], f : (T) -> Unit) -> Unit {
  self.elements.iter(f)
}

test "iter" {
  let s : Stack[Int] = new()
  let mut sum = 0
  let mut sub = 0
  s.iter(fn(i) { sum = sum + i })
  @test.eq(sum, 0)?
  s.push(1)
  s.push(2)
  s.push(3)
  @test.eq(s.peek_exn(), 3)?
  sum = 0
  sub = s.peek_exn()
  s.iter(fn(i) { sum = sum + i })
  s.iter(fn(i) { sub = sub - i }) // 3 - 3 - 2 - 1
  @test.eq(sum, 6)?
  @test.eq(sub, -3)?
}

/// Folds over the elements of the stack from top to bottom.
/// 
/// # Example
/// ```
/// let s: Stack[Int] = Stack::from_array([1, 2, 3])
/// let sum = s.fold(~init=0, fn(acc, i) { acc + i })
/// println(sum) // output: 6
/// ```
pub fn fold[T, U](self : Stack[T], ~init : U, f : (U, T) -> U) -> U {
  self.elements.fold(init, f)
}

test "fold" {
  let s : Stack[Int] = Stack::from_array([1, 2, 3])
  let sum = s.fold(~init=0, fn(acc, i) { acc + i })
  @test.eq(sum, 6)?
}

/// Convert stack to list
///
/// # Example
///
/// ```
/// println(Stack::[3, 2, 1].to_list()) // output: Cons(1, Cons(2, Cons(3, Nil)))
/// ```
pub fn to_list[T](self : Stack[T]) -> List[T] {
  self.elements
}

test "to_list" {
  @test.eq(
    Stack::[3, 2, 1].to_list(),
    Cons(1, Cons(2, Cons(3, Nil))),
  )?
}

/// Convert stack to array
///
/// # Example
///
/// ```
/// println(Stack::[3, 2, 1].to_array()) // output: [1, 2, 3]
/// ```
pub fn to_array[T : Default](self : Stack[T]) -> Array[T] {
  self.elements.to_array()
}

test "to_array" {
  @test.eq(Stack::[3, 2, 1].to_array(), [1, 2, 3])?
}

/// Compare two stacks.
///
/// NOTE: Since the current standard library List lacks the equal or op_equal function, 
/// this function internally implements the equal function of List.
///
/// # Example
///
/// ```
/// println(Stack::[2, 4, 6].equal(Stack::[2, 4, 6]))
/// // output: true
/// ```
pub fn equal[T : Eq](self : Stack[T], other : Stack[T]) -> Bool {
  if self.len == other.len {
    self.elements.equal(other.elements)
  } else {
    false
  }
}

pub fn op_equal[T : Eq](self : Stack[T], other : Stack[T]) -> Bool {
  self.equal(other)
}

test "equal" {
  @test.assert_true(Stack::[2, 4, 6].equal(Stack::[2, 4, 6]))?
  @test.is_false(Stack::[2, 4, 6].equal(Stack::[2, 4, 7]))?
}
