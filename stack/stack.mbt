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

/// Create an empty stack.
///
/// # Example
///
/// ```
/// let s : Stack[Int] = Stack::new()
/// println(s) // Stack::[]
/// ```
pub fn Stack::new[T]() -> Stack[T] {
  { elements: Nil, len: 0 }
}

test "new" {
  let s : Stack[Int] = Stack::new()
  inspect(s, content="Stack::[]")?
}

/// Create a stack based on all elements in list.
///
/// # Example
///
/// ```
/// let s = Stack::from_list(List::[1, 2, 3])
/// println(s) // Stack::[1, 2, 3]
/// ```
pub fn Stack::from_list[T](list : List[T]) -> Stack[T] {
  { elements: list, len: list.length() }
}

test "from_list" {
  let s = Stack::from_list(List::[1, 2, 3])
  inspect(s, content="Stack::[1, 2, 3]")?
  inspect(s.len, content="3")?
}

/// Create a stack based on all elements in array.
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// println(s) // Stack::[3, 2, 1]
/// ```
pub fn Stack::from_array[T](array : Array[T]) -> Stack[T] {
  { elements: List::from_array(array), len: array.length() }
}

test "from_array" {
  let s = Stack::[1, 2, 3]
  inspect(s, content="Stack::[1, 2, 3]")?
  inspect(s.len, content="3")?
}

pub fn to_string[T : Show](self : Stack[T]) -> String {
  let mut res = "Stack::["
  self.elements.iteri(
    fn(i, t) {
      if i > 0 {
        res += ", "
      }
      res += t.to_string()
    },
  )
  res + "]"
}

test "to_string" {
  let empty : Stack[Int] = new()
  inspect(empty, content="Stack::[]")?
  inspect(Stack::[1, 2, 3, 4, 5], content="Stack::[1, 2, 3, 4, 5]")?
}

/// Create a stack based on another stack.
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// let s1 = Stack::from_stack(s)
/// println(s1) // output: Stack::[3, 2, 1]
/// ```
pub fn Stack::from_stack[T](other : Stack[T]) -> Stack[T] {
  { ..other }
}

test "from_stack" {
  let s = Stack::[1, 2, 3]
  let s1 = Stack::from_stack(s)
  inspect(s1.elements == s.elements, content="true")?
}

/// Clear all elements in Stack
/// 
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// s.clear()
/// println(s) // Stack::[]
/// ```
pub fn clear[T](self : Stack[T]) -> Unit {
  self.elements = Nil
  self.len = 0
}

test "clear" {
  let s = Stack::[1, 2, 3]
  s.clear()
  inspect(s, content="Stack::[]")?
}

/// Same as the `clear()`, but returns an cleared stack
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3].return_with_clear()
/// println(s) // Stack::[]
/// ```
pub fn return_with_clear[T](self : Stack[T]) -> Stack[T] {
  self.clear()
  self
}

test "return_with_clear" {
  let s = Stack::[1, 2, 3].return_with_clear()
  inspect(s, content="Stack::[]")?
}

/// Push an element into the stack.
/// 
/// # Example
///
/// ```
/// let s = Stack::new()
/// s.push(1)
/// println(s) // Stack::[1]
/// ```
pub fn push[T](self : Stack[T], x : T) -> Unit {
  self.elements = Cons(x, self.elements)
  self.len = self.len + 1
}

test "push" {
  let s = Stack::new()
  s.push(1)
  inspect(s, content="Stack::[1]")?
  inspect(s.len, content="1")?
}

/// Push a list into the stack.
/// 
/// # Example
///
/// ```
/// let s = Stack::new()
/// s.push_list(List::[1, 2, 3])
/// println(s) // Stack::[3, 2, 1]
/// ```
pub fn push_list[T](self : Stack[T], list : List[T]) -> Unit {
  list.iter(fn(i) { self.push(i) })
}

test "push_list" {
  let s = Stack::new()
  s.push_list(List::[1, 2, 3])
  inspect(s, content="Stack::[3, 2, 1]")?
  inspect(s.len, content="3")?
}

/// Push other stack into the current stack.
/// 
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// let s1 : Stack[Int] = Stack::new()
/// s1.push_stack(s)
/// println(s1) // Stack::[1, 2, 3]
/// ```
pub fn push_stack[T](self : Stack[T], stack : Stack[T]) -> Unit {
  stack.elements.iter(fn(i) { self.push(i) })
}

test "push_stack" {
  let s = Stack::[1, 2, 3]
  let s1 : Stack[Int] = Stack::new()
  s1.push_stack(s)
  inspect(s1, content="Stack::[3, 2, 1]")?
  inspect(s.len == s1.len, content="true")?
}

/// Push an array into the stack.
/// 
/// # Example
///
/// ```
/// let s : Stack[Int] = Stack::new()
/// s.push_array([1, 2, 3])
/// println(s) // Stack::[3, 2, 1]
/// ```
pub fn push_array[T](self : Stack[T], array : Array[T]) -> Unit {
  array.iter(fn(i) { self.push(i) })
}

test "push_array" {
  let s : Stack[Int] = Stack::new()
  s.push_array([1, 2, 3])
  inspect(s, content="Stack::[3, 2, 1]")?
  inspect(s.len, content="3")?
}

/// Pop an element from the top of the stack.
/// If there are elements in the stack, return `Some (the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// let s1 : Stack[Int] = Stack::new()
/// println(s.pop()) // Some(1)
/// println(s) // Stack::[2, 3]
/// println(s1.pop()) // None
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
  let s = Stack::[1, 2, 3]
  let s1 : Stack[Int] = Stack::new()
  inspect(s.pop(), content="Some(1)")?
  inspect(s, content="Stack::[2, 3]")?
  inspect(s.len, content="2")?
  inspect(s1.pop(), content="None")?
  inspect(s1, content="Stack::[]")?
  inspect(s1.len, content="0")?
}

/// Pop an element from the top of the stack.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// let s1 : Stack[Int] = Stack::new()
/// println(s.pop_exn()) // 1
/// println(s) // Stack::[2, 3]
/// println(s1.pop_exn()) // abort.
/// ```
/// @alert unsafe "Panic if the stack is empty."
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
  let s = Stack::[1, 2, 3]
  inspect(s.pop_exn(), content="1")?
  inspect(s, content="Stack::[2, 3]")?
  inspect(s.len, content="2")?
}

/// Drop the element at the top of the stack.
/// Like pop, but does not return elements and does nothing if the Stack is empty.
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// s.drop()
/// println(s) // Stack::[2, 3]
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
  let s = Stack::[1, 2, 3]
  s.drop()
  inspect(s, content="Stack::[2, 3]")?
  inspect(s.len, content="2")?
}

/// Drop the element at the top of the stack.
/// Like drop, but when the drop is successful, it returns `Ok(())`, and when it fails, it returns `Err(())`
///
/// # Example
///
/// ```
/// let s = Stack::[1, 2, 3]
/// let r = s.drop_result() // Ok(())
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
  let s = Stack::[1, 2, 3]
  let s1 : Stack[Int] = Stack::new()
  inspect(s1.drop_result() == Err(()), content="true")?
  inspect(s.drop_result() == Ok(()), content="true")?
  inspect(s, content="Stack::[2, 3]")?
  inspect(s.len, content="2")?
}

/// Only the top element of the stack is returned and will not be pop or drop.
/// If there are elements in the stack, return `Some (the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s = Stack::from_array([1, 2, 3])
/// println(s.peek()) // Some(1)
/// println(s) // Stack::[1, 2, 3]
/// ```
pub fn peek[T](self : Stack[T]) -> Option[T] {
  match self.elements {
    Cons(hd, _) => Some(hd)
    Nil => None
  }
}

test "peek" {
  let s = Stack::[1, 2, 3]
  inspect(s.peek(), content="Some(1)")?
  inspect(s, content="Stack::[1, 2, 3]")?
  inspect(s.len, content="3")?
}

/// Only the top element of the stack is returned and will not be pop or drop.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s = Stack::from_array([1, 2, 3])
/// let s1 : Stack[Int] = Stack::new()
/// println(s1.peek_exn()) // abort
/// println(s.peek_exn()) // 1
/// println(s) // Stack::[1, 2, 3]
/// ```
/// @alert unsafe "Panic if the stack is empty."
pub fn peek_exn[T](self : Stack[T]) -> T {
  match self.elements {
    Cons(hd, _) => hd
    Nil => abort("top of the empty stack")
  }
}

test "peek_exn" {
  let s : Stack[Int] = Stack::[1, 2, 3]
  inspect(s.peek_exn(), content="1")?
  inspect(s, content="Stack::[1, 2, 3]")?
  inspect(s.len, content="3")?
}

/// If stack is empty, return true, otherwise return false.
///
/// # Example
///
/// ```
/// println(Stack::[1, 2, 3].is_empty()) // false
/// println(Stack::new().is_empty()) // true
/// ```
pub fn is_empty[T](self : Stack[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let empty : Stack[Unit] = Stack::new()
  inspect(Stack::[1, 2, 3].is_empty(), content="false")?
  inspect(empty.is_empty(), content="true")?
}

/// Returns the number of elements of the Stack
pub fn length[T](self : Stack[T]) -> Int {
  self.len
}

/// Iterates over the elements of the stack from top to bottom.
/// 
/// # Example
/// ```
/// let s = Stack::[1, 2, 3]
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
  inspect(sum, content="0")?
  s.push(1)
  s.push(2)
  s.push(3)
  inspect(s.peek_exn(), content="3")?
  sum = 0
  sub = s.peek_exn()
  s.iter(fn(i) { sum = sum + i })
  s.iter(fn(i) { sub = sub - i }) // 3 - 3 - 2 - 1
  inspect(sum, content="6")?
  inspect(sub, content="-3")?
}

/// Folds over the elements of the stack from top to bottom.
/// 
/// # Example
/// ```
/// let s = Stack::[1, 2, 3]
/// let sum = s.fold(~init=0, fn(acc, i) { acc + i })
/// println(sum) // 6
/// ```
pub fn fold[T, U](self : Stack[T], ~init : U, f : (U, T) -> U) -> U {
  self.elements.fold_left(~init, f)
}

test "fold" {
  let s = Stack::[1, 2, 3]
  let sum = s.fold(init=0, fn(acc, i) { acc + i })
  inspect(sum, content="6")?
}

/// Convert stack to list.
///
/// # Example
///
/// ```
/// println(Stack::[1, 2, 3].to_list()) // List::[1, 2, 3]
/// ```
pub fn to_list[T](self : Stack[T]) -> List[T] {
  self.elements
}

test "to_list" {
  inspect(Stack::[3, 2, 1].to_list(), content="List::[3, 2, 1]")?
}

/// Convert stack to array.
///
/// # Example
///
/// ```
/// println(Stack::[1, 2, 3].to_array()) // [1, 2, 3]
/// ```
pub fn to_array[T : Default](self : Stack[T]) -> Array[T] {
  self.elements.to_array()
}

test "to_array" {
  inspect(Stack::[3, 2, 1].to_array(), content="[3, 2, 1]")?
}

/// Compare two stacks.
///
/// NOTE: Since the current standard library List lacks the equal or op_equal function, 
/// this function internally implements the equal function of List.
///
/// # Example
///
/// ```
/// println(Stack::[2, 4, 6].equal(Stack::[2, 4, 6])) // true
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
  inspect(Stack::[2, 4, 6].equal(Stack::[2, 4, 6]), content="true")?
  inspect(Stack::[2, 4, 6].equal(Stack::[2, 4, 7]), content="false")?
}
