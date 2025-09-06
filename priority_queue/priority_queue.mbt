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
/// Creates a new empty priority queue.
///
/// # Example
/// ```mbt
///   let queue : @priority_queue.T[Int] = @priority_queue.new()
///   assert_eq(queue.length(), 0)
/// ```
#as_free_fn
pub fn[A] T::new() -> T[A] {
  { len: 0, top: Nil }
}

///|
/// Creates a new priority queue from an array.
///
/// # Example
/// ```mbt
///   let queue = @priority_queue.of([1, 2, 3, 4, 5])
///   assert_eq(queue.length(), 5)
/// ```
#as_free_fn
pub fn[A : Compare] T::from_array(arr : Array[A]) -> T[A] {
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

///|
fn[A] copy_node(x : Node[A]) -> Node[A] {
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

///|
/// Return a copy of the queue.
///
/// # Example
/// ```mbt
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let queue2 = queue.copy()
/// inspect(queue2.length(), content="4")
/// ```
pub fn[A] copy(self : T[A]) -> T[A] {
  let new_que : T[A] = { len: self.len, top: copy_node(self.top) }
  new_que
}

///|
pub fn[A : Compare] to_array(self : T[A]) -> Array[A] {
  let arr = Array::new(capacity=self.len)
  let stack : Array[Node[A]] = [self.top]
  while stack.pop() is Some(node) {
    match node {
      Nil => ()
      Cons(content~, sibling~, child~) => {
        arr.push(content)
        stack.push(sibling)
        stack.push(child)
      }
    }
  }
  arr.sort()
  arr.rev_inplace()
  arr
}

///|
pub fn[A : Compare] iter(self : T[A]) -> Iter[A] {
  Iter::new(yield_ => {
    let arr = self.to_array()
    for i in 0..<arr.length() {
      if yield_(arr[i]) is IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
pub impl[A : ToJson + Compare] ToJson for T[A] with to_json(self) {
  let arr = []
  for x in self {
    arr.push(x.to_json())
  }
  Json::array(arr)
}

///|
#as_free_fn
pub fn[K : Compare] T::from_iter(iter : Iter[K]) -> T[K] {
  let s = new()
  iter.each(e => s.push(e))
  s
}

///|
fn[A : Compare] meld(x : Node[A], y : Node[A]) -> Node[A] {
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

///|
fn[A : Compare] merges(x : Node[A]) -> Node[A] {
  loop (x, Nil) {
    (Nil, acc) => acc
    (Cons(sibling=Nil, ..) as x, acc) => meld(acc, x)
    (Cons(sibling=Cons(sibling=s2, ..) as s1, ..) as x, acc) => {
      x.sibling = Nil
      s1.sibling = Nil
      continue (s2, meld(acc, meld(x, s1)))
    }
  }
}

///|
pub fn[A] length(self : T[A]) -> Int {
  self.len
}

///|
/// Pops the first value from the priority queue.
///
/// # Example
/// ```mbt
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// queue.unsafe_pop()
/// inspect(queue.length(), content="3")
/// ```
#internal(unsafe, "Panic if the queue is empty.")
pub fn[A : Compare] unsafe_pop(self : T[A]) -> Unit {
  self.top = match self.top {
    Nil => abort("The PriorityQueue is empty!")
    Cons(child~, ..) => merges(child)
  }
  self.len -= 1
}

///|
/// Pops the first value from the priority queue, which returns None if the queue is empty.
///
/// # Example
/// ```mbt
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let first = queue.pop() // Some(4)
/// inspect(first, content="Some(4)")
/// inspect(queue.length(), content="3")
/// ```
pub fn[A : Compare] pop(self : T[A]) -> A? {
  let result = self.peek()
  self.top = match self.top {
    Nil => Nil
    Cons(child~, ..) => {
      self.len -= 1
      merges(child)
    }
  }
  result
}

///|
/// Adds a value to the priority queue.
///
/// # Example
/// ```mbt
/// let queue = @priority_queue.new()
/// queue.push(1)
/// assert_eq(queue.length(), 1)
/// ```
pub fn[A : Compare] push(self : T[A], value : A) -> Unit {
  self.top = meld(self.top, Cons(content=value, sibling=Nil, child=Nil))
  self.len += 1
}

///|
/// Peeks at the first value in the priority queue, which returns None if the priority queue is empty.
///
/// # Example
/// ```mbt
///   let queue = @priority_queue.of([1, 2, 3, 4])
///   let first = queue.peek() // Some(4)
///   assert_eq(first, Some(4))
/// ```
pub fn[A] peek(self : T[A]) -> A? {
  match self.top {
    Nil => None
    Cons(content~, ..) => Some(content)
  }
}

///|
/// Clears the queue.
///
/// # Example
/// ```mbt
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// queue.clear()
/// assert_eq(queue.length(), 0)
/// ```
pub fn[A] clear(self : T[A]) -> Unit {
  self.top = Nil
  self.len = 0
}

///|
/// Checks if the priority queue is empty.
///
/// # Example
/// ```mbt
///   let queue : @priority_queue.T[Int] = @priority_queue.new()
///   assert_eq(queue.is_empty(), true)
/// ```
pub fn[A] is_empty(self : T[A]) -> Bool {
  self.len == 0
}

///|
#as_free_fn
pub fn[A : Compare] T::of(arr : FixedArray[A]) -> T[A] {
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

///|
test "meld_and_merges" {
  inspect(
    match meld(Cons(content=1, sibling=Nil, child=Nil), Nil) {
      Nil => false
      Cons(..) => true
    },
    content="true",
  )
}

///|
pub impl[A : Show + Compare] Show for T[A] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@priority_queue.of([", suffix="])")
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs,
) {
  let len : Int = if size == 0 { 0 } else { rs.next_positive_int() % size }
  for i = 0, acc = Node::Nil {
    if i < len {
      continue i + 1,
        meld(acc, Cons(content=X::arbitrary(i, rs), sibling=Nil, child=Nil))
    } else {
      break { len, top: acc }
    }
  }
}

///|
test "priority queue arbitrary" {
  let samples : Array[T[Int]] = @quickcheck.samples(20)
  inspect(
    samples[5:10],
    content="[@priority_queue.of([]), @priority_queue.of([]), @priority_queue.of([0]), @priority_queue.of([0, 0]), @priority_queue.of([3, 2, 1, 0, 0, 0, 0])]",
  )
  inspect(
    samples[11:15],
    content="[@priority_queue.of([0, 0, 0, -1, -2]), @priority_queue.of([8, 4, 0, 0, 0, 0, 0, 0, -2, -5]), @priority_queue.of([2, 0, 0, -1]), @priority_queue.of([0, 0])]",
  )
}

///|
pub impl[K] Default for T[K] with default() {
  new()
}
