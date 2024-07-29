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
pub fn T::new[A : Compare]() -> T[A] {
  { len: 0, top: Nil }
}

/// Creates a new priority queue from an array.
/// 
/// # Example
/// ```
/// let queue = of([1, 2, 3, 4, 5])
/// ```
pub fn T::from_array[A : Compare](arr : Array[A]) -> T[A] {
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

fn copy_node[A](x : Node[A]) -> Node[A] {
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
/// let queue : PriorityQueue[Int] = of([1, 2, 3, 4])
/// let queue2 : PriorityQueue[Int] = PriorityQueue.copy()
/// ```
pub fn copy[A](self : T[A]) -> T[A] {
  let new_que : T[A] = { len: self.len, top: copy_node(self.top) }
  new_que
}

pub fn to_array[A : Compare](self : T[A]) -> Array[A] {
  let arr : Array[A] = []
  fn go(x : Node[A]) {
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

pub fn iter[A : Compare](self : T[A]) -> Iter[A] {
  Iter::new(
    fn(yield) {
      let arr = self.to_array()
      for i = 0; i < arr.length(); i = i + 1 {
        if yield(arr[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

pub fn T::from_iter[K : Compare](iter : Iter[K]) -> T[K] {
  let s = T::new()
  iter.each(fn(e) { s.push(e) })
  s
}

fn meld[A : Compare](x : Node[A], y : Node[A]) -> Node[A] {
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

fn merges[A : Compare](x : Node[A]) -> Node[A] {
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

pub fn length[A](self : T[A]) -> Int {
  self.len
}

/// Pops the first value from the priority queue.
/// 
/// # Example
/// ```
/// let queue = of([1, 2, 3, 4])
/// let first = queue.pop_exn() // 4
/// ```
/// @alert unsafe "Panic if the queue is empty."
pub fn pop_exn[A : Compare](self : T[A]) -> Unit {
  self.top = match self.top {
    Nil => abort("The PriorityQueue is empty!")
    Cons(~child, ..) => merges(child)
  }
  self.len -= 1
}

/// Pops the first value from the priority queue, which returns None if the queue is empty.
/// 
/// # Example
/// ```
/// let queue = of([1, 2, 3, 4])
/// let first = queue.pop() // Some(4)
/// ```
pub fn pop[A : Compare](self : T[A]) -> A? {
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
pub fn push[A : Compare](self : T[A], value : A) -> Unit {
  self.top = meld(self.top, Cons(content=value, sibling=Nil, child=Nil))
  self.len += 1
}

/// Peeks at the first value in the priority queue, which returns None if the priority queue is empty.
/// 
/// # Example
/// ```
/// let queue : PriorityQueue[Int] = of([1, 2, 3, 4])
/// let first = queue.peek() // Some(4)
/// ```
pub fn peek[A](self : T[A]) -> A? {
  match self.top {
    Nil => None
    Cons(~content, ..) => Some(content)
  }
}

/// Clears the queue.
/// 
/// # Example
/// ```
/// let queue = of([1, 2, 3, 4])
/// queue.clear()
/// ```
pub fn clear[A](self : T[A]) -> Unit {
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
pub fn is_empty[A](self : T[A]) -> Bool {
  self.len == 0
}

pub fn T::of[A : Compare](arr : FixedArray[A]) -> T[A] {
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

test "meld_and_merges" {
  inspect!(
    match meld(Cons(content=1, sibling=Nil, child=Nil), Nil) {
      Nil => false
      Cons(..) => true
    },
    content="true",
  )
}

pub impl[A : Show + Compare] Show for T[A] with output(self, logger) {
  logger.write_string("@priority_queue.of(")
  Show::output(self.to_array(), logger)
  logger.write_char(')')
}

pub fn to_string[A : Show + Compare](self : T[A]) -> String {
  Show::to_string(self)
}
