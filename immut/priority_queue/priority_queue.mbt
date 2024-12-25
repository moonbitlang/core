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

///|
/// Creates a new empty immutable priority queue.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn T::new[A : Compare]() -> T[A] {
  { body: Empty, len: 0 }
}

///|
/// Creates a new immutable priority queue from an array.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4, 5])
/// assert_eq!(queue.length(), 5)
/// ```
pub fn T::from_array[A : Compare](arr : Array[A]) -> T[A] {
  let len = arr.length()
  for i = 0, acc = Cont::Empty {
    if i < len {
      continue i + 1, meld(acc, Node(arr[i], Nil))
    } else {
      break { body: acc, len: arr.length() }
    }
  }
}

///|
pub fn to_array[A : Compare](self : T[A]) -> Array[A] {
  let arr : Array[A] = []
  fn go(x : Cont[A]) {
    match x {
      Node(v, child) => {
        arr.push(v)
        loop child {
          Nil => ()
          Cons(x, xs) => {
            go(x)
            continue xs
          }
        }
      }
      Empty => ()
    }
  }

  go(self.body)
  arr.sort_by(fn(x, y) { if x < y { 1 } else { -1 } })
  arr
}

///|
pub fn iter[A : Compare](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    let arr = self.to_array()
    for i = 0; i < arr.length(); i = i + 1 {
      if yield_(arr[i]) == IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
pub fn T::from_iter[A : Compare](iter : Iter[A]) -> T[A] {
  iter.fold(init=T::new(), fn(s, e) { s.push(e) })
}

///|
fn meld[A : Compare](l : Cont[A], r : Cont[A]) -> Cont[A] {
  match (l, r) {
    (Empty, _) => r
    (_, Empty) => l
    (Node(x, left), Node(y, right)) =>
      if x > y {
        Node(x, Cons(r, left))
      } else {
        Node(y, Cons(l, right))
      }
  }
}

///|
fn merges[A : Compare](x : @list.T[Cont[A]]) -> Cont[A] {
  loop x, Empty {
    Nil, acc => acc
    Cons(t, rest), acc => continue rest, meld(t, acc)
  }
}

///|
/// Pops the first value from the immutable priority queue, which returns None if the queue is empty.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let first = queue.pop()
/// assert_eq!(first, Some(@priority_queue.of([1, 2, 3])))
/// ```
pub fn pop[A : Compare](self : T[A]) -> T[A]? {
  match self.body {
    Empty => None
    Node(_, ts) => Some({ body: merges(ts), len: self.len - 1 })
  }
}

///|
/// Pops the first value from the immutable priority queue.
/// 
/// Panics if the queue is empty.
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let first = queue.unsafe_pop()
/// assert_eq!(first, @priority_queue.of([1, 2, 3]))
/// ```
pub fn unsafe_pop[A : Compare](self : T[A]) -> T[A] {
  match self.body {
    Empty => abort("The ImmutablePriorityQueue is empty!")
    Node(_, ts) => { body: merges(ts), len: self.len - 1 }
  }
}

///|
/// @alert deprecated "Use `unsafe_pop` instead"
/// @coverage.skip
pub fn pop_exn[A : Compare](self : T[A]) -> T[A] {
  unsafe_pop(self)
}

///|
/// Adds a value to the immutable priority queue.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn push[A : Compare](self : T[A], value : A) -> T[A] {
  { body: meld(self.body, Node(value, Nil)), len: self.len + 1 }
}

///|
/// Peeks at the first value in the immutable priority queue, which returns None if the immutable priority queue is empty.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// assert_eq!(queue.peek(), Some(4))
/// ```
pub fn peek[A](self : T[A]) -> A? {
  match self.body {
    Empty => None
    Node(v, _) => Some(v)
  }
}

///|
/// Checks if the immutable priority queue is empty.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.is_empty(), true)
/// assert_eq!(queue.push(1).is_empty(), false)
/// ```
pub fn is_empty[A](self : T[A]) -> Bool {
  match self.body {
    Empty => true
    _ => false
  }
}

///|
/// Return the length of the immutable priority queue.
/// 
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.length(), 0)
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn length[A](self : T[A]) -> Int {
  self.len
}

///|
pub fn T::of[A : Compare](arr : FixedArray[A]) -> T[A] {
  let len = arr.length()
  for i = 0, acc = Cont::Empty {
    if i < len {
      continue i + 1, meld(acc, Node(arr[i], Nil))
    } else {
      break { body: acc, len: arr.length() }
    }
  }
}

///|
pub impl[A : Show + Compare] Show for T[A] with output(self, logger) {
  logger.write_iter(
    self.iter(),
    prefix="@immut/priority_queue.of([",
    suffix="])",
  )
}

///|
pub impl[X : @quickcheck.Arbitrary + Compare] @quickcheck.Arbitrary for T[X] with arbitrary(
  size,
  rs
) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub impl[A : Compare] Eq for T[A] with op_equal(self, other) {
  self.length() == other.length() && self.to_array() == other.to_array()
}

///|
pub impl[A : Hash + Compare] Hash for T[A] with hash_combine(self, hasher) {
  for e in self {
    hasher.combine(e)
  }
}

test "meld" {
  inspect!(meld(Empty, of([1]).body), content="Node(1, @list.of([]))")
  inspect!(meld(of([1]).body, Empty), content="Node(1, @list.of([]))")
  inspect!(
    meld(of([1]).body, of([2]).body),
    content="Node(2, @list.of([Node(1, @list.of([]))]))",
  )
}

test "merges" {
  inspect!(
    match merges((Nil : @list.T[Cont[Int]])) {
      Empty => true
      _ => false
    },
    content="true",
  )
}
