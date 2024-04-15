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

/// Create an empty immutable stack.
///
/// # Example
///
/// ```
/// let s: ImmutableStack[Int] = ImmutableStack::new()
/// println(s) // ImmutableStack::[]
/// ```
pub fn ImmutableStack::new[T]() -> ImmutableStack[T] {
  { elements: Nil, len: 0 }
}

test "new" {
  let s : ImmutableStack[Int] = ImmutableStack::new()
  inspect(s, ~content="ImmutableStack::[]")?
}

/// Create a immutable stack based on all elements in list.
///
/// # Example
///
/// ```
/// let s = Stack::from_list(List::[1, 2, 3])
/// println(s) // ImmutableStack::[1, 2, 3]
/// ```
pub fn ImmutableStack::from_list[T](list : List[T]) -> ImmutableStack[T] {
  { elements: list, len: list.length() }
}

test "from_list" {
  let s = ImmutableStack::from_list(List::[1, 2, 3])
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s.len, ~content="3")?
}

/// Create a immutable stack based on all elements in array.
///
/// # Example
///
/// ```
/// let s: ImmutableStack[Int] = ImmutableStack::[1, 2, 3]
/// println(s) // Stack::[1, 2, 3]
/// ```
pub fn ImmutableStack::from_array[T](array : Array[T]) -> ImmutableStack[T] {
  { elements: List::from_array(array), len: array.length() }
}

test "from_array" {
  let s : ImmutableStack[Int] = ImmutableStack::[1, 2, 3]
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s.len, ~content="3")?
}

pub fn to_string[T : Show](self : ImmutableStack[T]) -> String {
  let mut res = "ImmutableStack::["
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
  let empty : ImmutableStack[Int] = new()
  inspect(empty, ~content="ImmutableStack::[]")?
  inspect(
    ImmutableStack::[1, 2, 3, 4, 5],
    ~content="ImmutableStack::[1, 2, 3, 4, 5]",
  )?
}

/// Push an element into the immutable stack.
/// 
/// # Example
///
/// ```
/// let s : ImmutableStack[Int]= ImmutableStack::new()
/// s.push(1) // ImmutableStack::[1]
/// ```
pub fn push[T](self : ImmutableStack[T], x : T) -> ImmutableStack[T] {
  { elements: Cons(x, self.elements), len: self.len + 1 }
}

test "push" {
  let s = ImmutableStack::new()
  inspect(s.push(1), ~content="ImmutableStack::[1]")?
  inspect(s.push(0).push(1), ~content="ImmutableStack::[1, 0]")?
  inspect(s, ~content="ImmutableStack::[]")?
}

/// Push a list into the stack.
/// 
/// # Example
///
/// ```
/// let s = ImmutableStack::new()
/// s.push_list(List::[1, 2, 3]) // ImmutableStack::[1, 2, 3]
/// ```
pub fn push_list[T](
  self : ImmutableStack[T],
  values : List[T]
) -> ImmutableStack[T] {
  { elements: values + self.elements, len: self.len + values.length() }
}

test "push_list" {
  let s = ImmutableStack::new()
  inspect(s.push_list(List::[1, 2, 3]), ~content="ImmutableStack::[1, 2, 3]")?
  inspect(
    s.push(0).push_list(List::[3, 2, 1]),
    ~content="ImmutableStack::[3, 2, 1, 0]",
  )?
  inspect(s, ~content="ImmutableStack::[]")?
}

/// Push an array into the stack.
/// 
/// # Example
///
/// ```
/// let s : ImmutableStack[Int] = ImmutableStack::new()
/// s.push_array([1, 2, 3]) // Stack::[3, 2, 1]
/// ```
pub fn push_array[T](
  self : ImmutableStack[T],
  values : Array[T]
) -> ImmutableStack[T] {
  {
    elements: loop values.length(), self.elements {
      index, ls =>
        if index == 0 {
          ls
        } else {
          continue index - 1, Cons(values[index - 1], ls)
        }
    },
    len: self.len + values.length(),
  }
}

test "push_array" {
  let s = ImmutableStack::new()
  inspect(s.push_array([1, 2, 3]), ~content="ImmutableStack::[1, 2, 3]")?
  inspect(
    s.push(0).push_array([3, 2, 1]),
    ~content="ImmutableStack::[3, 2, 1, 0]",
  )?
  inspect(s, ~content="ImmutableStack::[]")?
}

/// Push other stack into the current stack.
/// 
/// # Example
///
/// ```
/// let s = ImmutableStack::new()
/// let s1 = ImmutableStack::[1, 2, 3]
/// s.push_stack(s1) // ImmutableStack::[1, 2, 3]
/// ```
pub fn push_stack[T](
  self : ImmutableStack[T],
  other : ImmutableStack[T]
) -> ImmutableStack[T] {
  { elements: other.elements + self.elements, len: self.len + other.len }
}

test "push_stack" {
  let s = ImmutableStack::new()
  let s1 = ImmutableStack::[1, 2, 3]
  let s2 = ImmutableStack::[4, 5, 6]
  inspect(s.push_stack(s1), ~content="ImmutableStack::[1, 2, 3]")?
  inspect(
    s.push_stack(s1).push_stack(s2),
    ~content="ImmutableStack::[4, 5, 6, 1, 2, 3]",
  )?
  inspect(s, ~content="ImmutableStack::[]")?
  inspect(s1, ~content="ImmutableStack::[1, 2, 3]")?
}

/// Drop an element from the top of the immutable stack.
/// If there are elements in the stack, return `Some(stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s = ImmutableStack::[1, 2, 3]
/// let s1 : ImmutableStack[Int] = ImmutableStack::new()
/// println(s.drop()) // Some(ImmutableStack::[2, 3])
/// println(s) // ImmutableStack::[1, 2, 3]
/// println(s1.drop()) // None
/// ```
pub fn drop[T](self : ImmutableStack[T]) -> Option[ImmutableStack[T]] {
  match self.elements {
    Cons(_, tl) => Some({ elements: tl, len: self.len - 1 })
    Nil => None
  }
}

test "drop" {
  let s = ImmutableStack::[1, 2, 3]
  let s1 : ImmutableStack[Int] = ImmutableStack::new()
  inspect(s.drop(), ~content="Some(ImmutableStack::[2, 3])")?
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s.len, ~content="3")?
  inspect(s1.drop(), ~content="None")?
  inspect(s1, ~content="ImmutableStack::[]")?
  inspect(s1.len, ~content="0")?
}

/// Drop an element from the top of the immutable stack.
/// If there are elements in the stack, return the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s = ImmutableStack::[1, 2, 3]
/// let s1 : ImmutableStack[Int] = ImmutableStack::new()
/// println(s.drop_exn()) // ImmutableStack::[2, 3]
/// println(s) // ImmutableStack::[1, 2, 3]
/// println(s1.drop_exn()) // abort.
/// ```
/// @alert unsafe "Panic if the stack is empty."
pub fn drop_exn[T](self : ImmutableStack[T]) -> ImmutableStack[T] {
  match self.elements {
    Cons(_, tl) => { elements: tl, len: self.len - 1 }
    Nil => abort("drop of empty stack")
  }
}

test "drop_exn" {
  let s = ImmutableStack::[1, 2, 3]
  inspect(s.drop_exn(), ~content="ImmutableStack::[2, 3]")?
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s.len, ~content="3")?
}

/// Pop an element from the top of the immutable stack.
/// 
/// If there are elements in the stack, return `Some(the top element of the stack, stack)`, otherwise return `(None, stack)`.
/// 
/// # Example
/// ```
/// let s = ImmutableStack::[1, 2, 3]
/// println(s.pop().0) // Some(1)
/// ```
pub fn pop[T](self: ImmutableStack[T]) -> (Option[T], ImmutableStack[T]) {
  match self.elements {
    Cons(hd, tl) => (Some(hd), { elements: tl, len: self.len - 1 })
    Nil => (None, self)
  }
}

test "pop" {
  let s = ImmutableStack::[1, 2, 3]
  let s1 : ImmutableStack[Int] = ImmutableStack::new()
  inspect(s.pop().1, ~content="ImmutableStack::[2, 3]")?
  inspect(s.pop().0, ~content="Some(1)")?
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s1.pop().0, ~content="None")?
  inspect(s1.pop().1, ~content="ImmutableStack::[]")?
}

/// Pop an element from the top of the immutable stack.
/// 
/// If there are elements in the stack, return the top element of the stack and the stack, otherwise abort.
/// 
/// # Example
/// ```
/// let s = ImmutableStack::[1, 2, 3]
/// println(s.pop_exn().0) // 1
/// ```
/// 
/// @alert unsafe "Panic if the stack is empty."
pub fn pop_exn[T](self : ImmutableStack[T]) -> (T, ImmutableStack[T]) {
  match self.elements {
    Cons(hd, tl) => (hd, { elements: tl, len: self.len - 1 })
    Nil => abort("pop of empty stack")
  }
}

test "pop_exn" {
  let s = ImmutableStack::[1, 2, 3]
  inspect(s.pop_exn().1, ~content="ImmutableStack::[2, 3]")?
  inspect(s.pop_exn().0, ~content="1")?
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
}

/// Only the top element of the immutable stack is returned and will not be pop or drop.
/// If there are elements in the stack, return `Some(the top element of the stack)`, otherwise return `None`.
///
/// # Example
///
/// ```
/// let s = ImmutableStack::from_array([1, 2, 3])
/// println(s.peek()) // Some(1)
/// println(s) // ImmutableStack::[1, 2, 3]
/// ```
pub fn peek[T](self : ImmutableStack[T]) -> Option[T] {
  match self.elements {
    Cons(hd, _) => Some(hd)
    Nil => None
  }
}

test "peek" {
  let s = ImmutableStack::[1, 2, 3]
  inspect(s.drop_exn().drop_exn().drop_exn().peek(), ~content="None")?
  inspect(s.peek(), ~content="Some(1)")?
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s.len, ~content="3")?
}

/// Only the top element of the immutable stack is returned and will not be pop or drop.
/// If there are elements in the stack, return the top element of the stack, otherwise abort.
///
/// # Example
///
/// ```
/// let s = ImmutableStack::from_array([1, 2, 3])
/// let s1 : ImmutableStack[Int] = ImmutableStack::new()
/// println(s1.peek_exn()) // abort
/// println(s.peek_exn()) // 1
/// println(s) // ImmutableStack::[1, 2, 3]
/// ```
/// @alert unsafe "Panic if the stack is empty."
pub fn peek_exn[T](self : ImmutableStack[T]) -> T {
  match self.elements {
    Cons(hd, _) => hd
    Nil => abort("top of the empty stack")
  }
}

test "peek_exn" {
  let s : ImmutableStack[Int] = ImmutableStack::[1, 2, 3]
  inspect(s.peek_exn(), ~content="1")?
  inspect(s, ~content="ImmutableStack::[1, 2, 3]")?
  inspect(s.len, ~content="3")?
}

/// If immutable stack is empty, return true, otherwise return false.
///
/// # Example
///
/// ```
/// println(ImmutableStack::[1, 2, 3].is_empty()) // false
/// println(ImmutableStack::new().is_empty()) // true
/// ```
pub fn is_empty[T](self : ImmutableStack[T]) -> Bool {
  self.len == 0
}

test "is_empty" {
  let empty : ImmutableStack[Unit] = ImmutableStack::new()
  inspect(ImmutableStack::[1].drop_exn().is_empty(), ~content="true")?
  inspect(ImmutableStack::[1, 2, 3].is_empty(), ~content="false")?
  inspect(empty.is_empty(), ~content="true")?
}

/// Returns the number of elements of the Stack.
pub fn length[T](self : ImmutableStack[T]) -> Int {
  self.len
}

test "length" {
  inspect(ImmutableStack::[1, 2, 3].length(), ~content="3")?
}

/// Iterates over the elements of the stack from top to bottom.
/// 
/// # Example
/// ```
/// let s = ImmutableStack::[1, 2, 3]
/// s.iter(fn(i) { println(i) })'
/// ```
pub fn iter[T](self : ImmutableStack[T], f : (T) -> Unit) -> Unit {
  self.elements.iter(f)
}

test "iter" {
  let s : ImmutableStack[Int] = new()
  let mut sum = 0
  let mut sub = 0
  s.iter(fn(i) { sum = sum + i })
  inspect(sum, ~content="0")?
  inspect(s.push(1).push(2).push(3).peek_exn(), ~content="3")?
  sum = 0
  sub = s.push(1).push(2).push(3).peek_exn()
  s.push(1).push(2).push(3).iter(fn(i) { sum = sum + i })
  s.push(1).push(2).push(3).iter(fn(i) { sub = sub - i }) // 3 - 3 - 2 - 1
  inspect(sum, ~content="6")?
  inspect(sub, ~content="-3")?
}

/// Folds over the elements of the immtable stack from top to bottom.
/// 
/// # Example
/// ```
/// let s = ImmutableStack::[1, 2, 3]
/// let sum = s.fold(~init=0, fn(acc, i) { acc + i })
/// println(sum) // 6
/// ```
pub fn fold[T, U](self : ImmutableStack[T], ~init : U, f : (U, T) -> U) -> U {
  self.elements.fold_left(~init, f)
}

test "fold" {
  let s = ImmutableStack::[1, 2, 3]
  let sum = s.fold(~init=0, fn(acc, i) { acc + i })
  inspect(sum, ~content="6")?
}

/// Convert immutable stack to list.
///
/// # Example
///
/// ```
/// println(ImmutableStack::[1, 2, 3].to_list()) // List::[1, 2, 3]
/// ```
pub fn to_list[T](self : ImmutableStack[T]) -> List[T] {
  self.elements
}

test "to_list" {
  inspect(ImmutableStack::[3, 2, 1].to_list(), ~content="List::[3, 2, 1]")?
}

/// Convert immutable stack to array.
///
/// # Example
///
/// ```
/// println(Stack::[1, 2, 3].to_array()) // [1, 2, 3]
/// ```
pub fn to_array[T : Default](self : ImmutableStack[T]) -> Array[T] {
  self.elements.to_array()
}

test "to_array" {
  inspect(ImmutableStack::[3, 2, 1].to_array(), ~content="[3, 2, 1]")?
}

/// Compare two immutable stacks.
///
/// NOTE: Since the current standard library List lacks the equal or op_equal function, 
/// this function internally implements the equal function of List.
///
/// # Example
///
/// ```
/// println(ImmutableStack::[2, 4, 6].equal(ImmutableStack::[2, 4, 6])) // true
/// ```
pub fn equal[T : Eq](
  self : ImmutableStack[T],
  other : ImmutableStack[T]
) -> Bool {
  self.len == other.len && self.elements.equal(other.elements)
}

pub fn op_equal[T : Eq](
  self : ImmutableStack[T],
  other : ImmutableStack[T]
) -> Bool {
  self.equal(other)
}

test "equal" {
  inspect(
    ImmutableStack::[2, 4, 6].equal(ImmutableStack::[2, 4, 6]),
    ~content="true",
  )?
  inspect(
    ImmutableStack::[2, 4, 6].equal(ImmutableStack::[2, 4, 7]),
    ~content="false",
  )?
  inspect(
    ImmutableStack::[2, 4, 6] == ImmutableStack::[2, 4, 6],
    ~content="true",
  )?
  inspect(
    ImmutableStack::[2, 4, 6] == ImmutableStack::[2, 4, 7],
    ~content="false",
  )?
}
