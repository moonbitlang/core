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
  @assertion.assert_eq(s.elements, Nil)?
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
  @assertion.assert_eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @assertion.assert_eq(s.len, 3)?
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
  @assertion.assert_eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @assertion.assert_eq(s.len, 3)?
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
  @assertion.assert_eq(s1.elements, s.elements)?
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
pub fn clear[T](self : Stack[T]) {
  self.elements = Nil
  self.len = 0
}

test "clear" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
  s.clear()
  @assertion.assert_eq(s.elements, Nil)?
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
  @assertion.assert_eq(s.elements, Nil)?
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
  @assertion.assert_eq(s1.elements, s.elements)?
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
  @assertion.assert_eq(s.elements, Cons(1, Nil))?
  @assertion.assert_eq(s.len, 1)?
}

/// Push a list into the stack`
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
  @assertion.assert_eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @assertion.assert_eq(s.len, 3)?
}

/// Push other stack into the current stack`
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
  stack.iter(fn(i) -> Unit { self.push(i) })
}

test "push_stack" {
  let s : Stack[Int] = Stack::from_list(Cons(1, Cons(2, Cons(3, Nil))))
  let s1 : Stack[Int] = Stack::new()
  s1.push_stack(s)
  @assertion.assert_eq(s1.elements, Cons(1, Cons(2, Cons(3, Nil))))?
  @assertion.assert_eq(s.len, s1.len)?
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
  @assertion.assert_eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @assertion.assert_eq(s.len, 3)?
}

/// Pop an element from the top of the stack.
/// If there are elements in the stack, return `Some (the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// let s1: Stack[Int] = Stack::new()
/// println(s.pop_option()) // output: Some(1)
/// println(s) // output: { elements: Cons(2, Cons(1, Nil)), len: 2 }
/// println(s1.pop()) // output: None
/// ```
pub fn pop_option[T](self : Stack[T]) -> Option[T] {
  match self.elements {
    Cons(hd, tl) => {
      self.elements = tl
      self.len = self.len - 1
      Some(hd)
    }
    Nil => None
  }
}

test "pop_option" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  let s1 : Stack[Int] = Stack::new()
  @assertion.assert_eq(s.pop_option(), Some(3))?
  @assertion.assert_eq(s.elements, Cons(2, Cons(1, Nil)))?
  @assertion.assert_eq(s.len, 2)?
  @assertion.assert_eq(s1.pop_option(), None)?
  @assertion.assert_eq(s1.elements, Nil)?
  @assertion.assert_eq(s1.len, 0)?
}

/// Pop an element from the top of the stack.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// let s1: Stack[Int] = Stack::new()
/// println(s.pop()) // output: 1
/// println(s) // output: { elements: Cons(2, Cons(1, Nil)), len: 2 }
/// println(s1.pop()) // abort.
/// ```
pub fn pop[T](self : Stack[T]) -> T {
  match self.elements {
    Cons(hd, tl) => {
      self.elements = tl
      self.len = self.len - 1
      hd
    }
    Nil => abort("pop of empty stack")
  }
}

test "pop" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @assertion.assert_eq(s.pop(), 3)?
  @assertion.assert_eq(s.elements, Cons(2, Cons(1, Nil)))?
  @assertion.assert_eq(s.len, 2)?
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
  @assertion.assert_eq(s.elements, Cons(2, Cons(1, Nil)))?
  @assertion.assert_eq(s.len, 2)?
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
  @assertion.assert_eq(s1.drop_result(), Err(()))?
  @assertion.assert_eq(s.drop_result(), Ok(()))?
  @assertion.assert_eq(s.elements, Cons(2, Cons(1, Nil)))?
  @assertion.assert_eq(s.len, 2)?
}

/// Only the top element of the stack is returned and will not be pop or drop.
/// If there are elements in the stack, return `Some (the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// println(s.top_option()) // output: Some(3)
/// println(s) // output: { elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3 }
/// ```
pub fn top_option[T](self : Stack[T]) -> Option[T] {
  match self.elements {
    Cons(hd, _) => Some(hd)
    Nil => None
  }
}

test "top_option" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @assertion.assert_eq(s.top_option(), Some(3))?
  @assertion.assert_eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @assertion.assert_eq(s.len, 3)?
}

/// Only the top element of the stack is returned and will not be pop or drop.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s: Stack[Int] = Stack::from_array([1,2,3])
/// let s1: Stack[Int] = Stack::new()
/// println(s1.top()) // abort
/// println(s.top()) // output: 3
/// println(s) // output: { elements: Cons(3, Cons(2, Cons(1, Nil))), len: 3 }
/// ```
pub fn top[T](self : Stack[T]) -> T {
  match self.elements {
    Cons(hd, _) => hd
    Nil => abort("top of the empty stack")
  }
}

test "top" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  @assertion.assert_eq(s.top(), 3)?
  @assertion.assert_eq(s.elements, Cons(3, Cons(2, Cons(1, Nil))))?
  @assertion.assert_eq(s.len, 3)?
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
  @assertion.assert_false(Stack::[1, 2, 3].is_empty())?
  @assertion.assert_true(empty.is_empty())?
}

/// Returns the number of elements of the Stack
pub fn length[T](self : Stack[T]) -> Int {
  self.len
}

/// Iterates over the stack.
/// 
/// # Example
/// 
/// ```
/// Stack::from_array([1, 2, 3, 4, 5]).iter(print) // output: 54321
/// ```
pub fn iter[T](self : Stack[T], f : (T) -> Unit) -> Unit {
  self.elements.iter(f)
}

test "iter" {
  let s : Stack[Int] = Stack::[5, 4, 3, 2, 1]
  let mut i = 0
  let mut failed = false
  s.iter(fn(x) { i = i + 1; if x != i { failed = true } })
  if failed {
    return Err("iter test failed")
  }
}

/// Iterates over the list with index.
pub fn iteri[T](self : Stack[T], f : (Int, T) -> Unit) {
  self.elements.iteri(f)
}

test "iteri" {
  let mut v = 0
  let mut failed = false
  let s = Stack::[5, 4, 3, 2, 1]
  s.iteri(fn(i, x) { if x != v + 1 || i != v { failed = true }; v = v + 1 })
  if failed {
    return Err("iteri test failed")
  }
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
  @assertion.assert_eq(
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
  @assertion.assert_eq(Stack::[3, 2, 1].to_array(), [1, 2, 3])?
}

/// Fold the stack.
///
/// # Example
/// 
/// ```
/// let s = Stack::from_array([1, 2, 3, 4, 5]).fold(0, fn(acc, x) { acc + x })
/// println(s) // output: 15
/// ```
pub fn fold[T, U](self : Stack[T], initial : U, f : (U, T) -> U) -> U {
  self.elements.fold(initial, f)
}

test "fold" {
  @assertion.assert_eq(
    Stack::[1, 2, 3, 4, 5].fold(0, fn(acc, x) { acc + x }),
    15,
  )?
}

/// Filter the stack.
/// 
/// # Example
/// 
/// ```
/// println(Stack::from_array([1, 2, 3, 4, 5]).filter(fn(x){ x % 2 == 0}))
/// // output: Cons(4, Cons(2, Nil))
/// ```
pub fn filter[T](self : Stack[T], f : (T) -> Bool) -> Stack[T] {
  let elements = self.elements.filter(f)
  { elements, len: elements.length() }
}

test "filter" {
  let s = Stack::[1, 2, 3, 4, 5]
  let s2 = s.filter(fn(x) { x % 2 == 0 })
  @assertion.assert_eq(s2.elements, Cons(4, Cons(2, Nil)))?
  @assertion.assert_eq(s2.len, 2)?
}

/// Maps the stack.
/// 
/// # Example
/// 
/// ```
/// println(Stack::from_array([1, 2, 3]).map(fn(x){ x * 2})))
/// // output: { elements: Cons(6, Cons(4, Cons(2, Nil))), len: 3 }
/// ```
pub fn map[T, U](self : Stack[T], f : (T) -> U) -> Stack[U] {
  { elements: self.elements.map(f), len: self.len }
}

test "map" {
  let s = Stack::[1, 2, 3]
  @assertion.assert_eq(
    s.map(fn(x) { x * 2 }).elements,
    Cons(6, Cons(4, Cons(2, Nil))),
  )?
}

/// Checks if all elements of the list satisfy the predicate f.
/// If the list is empty, return true.
///
/// NOTE: Since the current standard library List lacks the forall function, 
/// this function internally implements the forall function of List.
///
/// # Example
///
/// ```
/// println(Stack::[2, 4, 6].forall(fn(element) -> Bool { element % 2 == 0 }))
/// // output: true
/// ```
pub fn forall[T](self : Stack[T], f : (T) -> Bool) -> Bool {
  fn list_forall(list : List[T]) -> Bool {
    match list {
      Nil => true
      Cons(h, t) => if f(h) { list_forall(t) } else { false }
    }
  }

  list_forall(self.elements)
}

test "forall" {
  @assertion.assert_true(
    Stack::[2, 4, 6].forall(fn(element) -> Bool { element % 2 == 0 }),
  )?
  @assertion.assert_false(
    Stack::[1, 3, 5].forall(fn(element) -> Bool { element % 2 == 0 }),
  )?
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
  fn list_eq(list1 : List[T], list2 : List[T]) -> Bool {
    match (list1, list2) {
      (Nil, Nil) => true
      (Cons(h1, t1), Cons(h2, t2)) =>
        if h1 == h2 {
          list_eq(t1, t2)
        } else {
          false
        }
      _ => false
    }
  }

  if self.len == other.len {
    list_eq(self.elements, other.elements)
  } else {
    false
  }
}

pub fn op_equal[T : Eq](self : Stack[T], other : Stack[T]) -> Bool {
  self.equal(other)
}

test "equal" {
  @assertion.assert_true(Stack::[2, 4, 6].equal(Stack::[2, 4, 6]))?
  @assertion.assert_false(Stack::[2, 4, 6].equal(Stack::[2, 4, 7]))?
}
