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

/// Creates a new empty priority queue.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::new()
/// ```
pub fn PriorityQueue::new[T : Compare]() -> PriorityQueue[T] {
  { len: 0, top: Nil }
}

/// Creates a new priority queue from an array.
/// 
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4, 5]
/// ```
pub fn PriorityQueue::from_array[T : Compare](
  arr : Array[T]
) -> PriorityQueue[T] {
  // CR: bad formatting  
  let len = arr.length()
  for i = 0, acc = Node::Nil {
    if i < len {
      continue i + 1, meld(acc, Cons(content=arr[i], sibling=Nil, child=Nil))
    } else {
      break { len, top: acc }
    }
  }
}

fn copy_node[T](x : Node[T]) -> Node[T] {
  match x {
    Nil => Nil
    Cons(_) as node =>
      Cons(
        content=node.content,
        sibling=copy_node(node.sibling),
        child=copy_node(node.child),
      )
  }
}

/// Return a copy of the queue.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::[1, 2, 3, 4]
/// let queue2 : PriorityQueue[Int] = PriorityQueue.copy()
/// ```
pub fn copy[T](self : PriorityQueue[T]) -> PriorityQueue[T] {
  let new_que : PriorityQueue[T] = { len: self.len, top: copy_node(self.top) }
  new_que
}

pub fn to_array[T : Compare](self : PriorityQueue[T]) -> Array[T] {
  let arr : Array[T] = []
  fn go(x : Node[T]) {
    match x {
      Cons(_) as node => {
        arr.push(node.content)
        go(node.sibling)
        go(node.child)
      }
      Nil => ()
    }
  }

  go(self.top)
  arr.sort_by(fn(x, y) { if x < y { 1 } else { -1 } })
  arr
}

pub fn as_iter[T : Compare](self : PriorityQueue[T]) -> Iter[T] {
  Iter::_unstable_internal_make(
    fn(yield) {
      let arr = self.to_array()
      for i = 0; i < arr.length(); i = i + 1 {
        if yield(arr[i]).not() {
          break false
        }
      } else {
        true
      }
    },
  )
}

fn meld[T : Compare](x : Node[T], y : Node[T]) -> Node[T] {
  match (x, y) {
    (Nil, _) => y
    (_, Nil) => x
    (Cons(_) as x_top, Cons(_) as y_top) =>
      if x_top.content > y_top.content {
        y_top.sibling = x_top.child
        x_top.child = y
        x
      } else {
        x_top.sibling = y_top.child
        y_top.child = x
        y
      }
  }
}

fn merges[T : Compare](x : Node[T]) -> Node[T] {
  match x {
    Nil => Nil
    Cons(~sibling, ..) =>
      match sibling {
        Nil => x
        Cons(sibling=next_sibling, ..) =>
          match next_sibling {
            Nil => meld(x, sibling)
            Cons(_) => meld(merges(next_sibling), meld(x, sibling))
          }
      }
  }
}

pub fn length[T](self : PriorityQueue[T]) -> Int {
  self.len
}

/// Pops the first value from the priority queue.
/// 
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4]
/// let first = queue.pop_exn() // 4
/// ```
/// @alert unsafe "Panic if the queue is empty."
pub fn pop_exn[T : Compare](self : PriorityQueue[T]) -> Unit {
  if self.len == 0 {
    abort("The PriorityQueue is empty!")
  }
  self.top = match self.top {
    Nil => Nil
    Cons(~child, ..) => merges(child)
  }
  self.len -= 1
}

/// Pops the first value from the priority queue, which returns None if the queue is empty.
/// 
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4]
/// let first = queue.pop() // Some(4)
/// ```
pub fn pop[T : Compare](self : PriorityQueue[T]) -> Option[T] {
  let result = self.peek()
  self.top = match self.top {
    Nil => Nil
    Cons(~child, ..) => {
      self.len -= 1
      merges(child)
    }
  }
  result
}

/// Adds a value to the priority queue.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::new()
/// queue.add(1)
/// ```
pub fn push[T : Compare](self : PriorityQueue[T], value : T) -> Unit {
  self.top = meld(self.top, Cons(content=value, sibling=Nil, child=Nil))
  self.len += 1
}

/// Peeks at the first value in the priority queue, which returns None if the priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = PriorityQueue::[1, 2, 3, 4]
/// let first = queue.peek() // Some(4)
/// ```
pub fn peek[T](self : PriorityQueue[T]) -> Option[T] {
  match self.top {
    Nil => None
    Cons(~content, ..) => Some(content)
  }
}

/// Clears the queue.
/// 
/// # Example
/// ```
/// let queue = PriorityQueue::[1, 2, 3, 4]
/// queue.clear()
/// ```
pub fn clear[T](self : PriorityQueue[T]) -> Unit {
  self.top = Nil
  self.len = 0
}

/// Checks if the priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : Priorityt[Int] = Priority::new()
/// let is_empty = queue.is_empty() // true
/// ```
pub fn is_empty[T](self : PriorityQueue[T]) -> Bool {
  self.len == 0
}
