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
/// Creates a new empty immutable priority queue.
///
/// # Example
/// ```
/// let queue = @priority_queue.new()
/// assert_eq!(queue.push(1).length(), 1)
/// ```
pub fn new[A : Compare]() -> T[A] {
  { node: Empty, size: 0 }
}

///|
/// Creates a new immutable priority queue from an array.
///
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4, 5])
/// assert_eq!(queue.length(), 5)
/// ```
pub fn from_array[A : Compare](array : Array[A]) -> T[A] {
  let mut pq = new()
  for i in 0..<array.length() {
    pq = pq.push(array[i])
  }
  pq
}

///|
pub fn to_array[A : Compare](self : T[A]) -> Array[A] {
  let arr : Array[A] = []
  fn go(x : T[A]) {
    match x.node {
      Empty => return
      Leaf(a) => arr.push(a)
      Branch(a, left=l, right=r) => {
        arr.push(a)
        go(l)
        go(r)
      }
    }
  }

  go(self)
  arr.sort_by(fn(x, y) { if x < y { 1 } else { -1 } })
  arr
}

///|
pub fn iter[A : Compare](self : T[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    let arr = self.to_array()
    for i in 0..<arr.length() {
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
  iter.fold(init=new(), fn(s, e) { s.push(e) })
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
  match self.node {
    Empty => None
    Leaf(_) => Some({ node: Empty, size: 0 })
    Branch(_) => {
      let value = self.find_element()
      let temp = self.delet_leaf()
      Some(temp.change_element(value).down(value))
    }
  }
}

///|
fn change_element[A : Compare](self : T[A], value : A) -> T[A] {
  {
    node: match self.node {
      Empty => Empty
      Leaf(_) => Leaf(value)
      Branch(_, left~, right~) => Branch(value, left~, right~)
    },
    size: self.size,
  }
}

///|
fn find_element[A : Compare](self : T[A]) -> A {
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(a) => a
    Branch(_, left=l, right=r) =>
      if r.size == 0 {
        l.top()
      } else {
        let deep = deepth(self.size)
        let full_right = (1 << (deep - 2)) - 1
        if r.size == full_right {
          l.find_element()
        } else {
          r.find_element()
        }
      }
  }
}

///|
fn delet_leaf[A : Compare](self : T[A]) -> T[A] {
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(_) => { node: Empty, size: 0 }
    Branch(a, left=l, right=r) =>
      if r.size == 0 {
        { node: Leaf(a), size: 1 }
      } else {
        let deep = deepth(self.size)
        let full_right = (1 << (deep - 2)) - 1
        if r.size == full_right {
          { node: Branch(a, left=l.delet_leaf(), right=r), size: self.size - 1 }
        } else {
          { node: Branch(a, left=l, right=r.delet_leaf()), size: self.size - 1 }
        }
      }
  }
}

///|
fn down[A : Compare](self : T[A], value : A) -> T[A] {
  match self.node {
    Empty => { node: Empty, size: 0 }
    Leaf(_) => { node: Leaf(value), size: 1 }
    Branch(_, left=l, right=r) =>
      if (r.size == 0 && l.top() <= value) ||
        (value >= l.top() && value >= r.top()) {
        { node: Branch(value, left=l, right=r), size: self.size }
      } else if r.size == 0 && l.top() > value {
        {
          node: Branch(l.top(), left={ node: Leaf(value), size: 1 }, right={
            node: Empty,
            size: 0,
          }),
          size: self.size,
        }
      } else if l.top() < r.top() {
        { node: Branch(r.top(), left=l, right=r.down(value)), size: self.size }
      } else {
        { node: Branch(l.top(), left=l.down(value), right=r), size: self.size }
      }
  }
}

///|
fn deepth(num : Int) -> Int {
  loop num, 0 {
    0, cnt => cnt
    n, cnt => continue n >> 1, cnt + 1
  }
}

///|
/// Pops the first value from the immutable priority queue.
///
/// @alert unsafe "Panics if the queue is empty."
/// # Example
/// ```
/// let queue = @priority_queue.of([1, 2, 3, 4])
/// let first = queue.unsafe_pop()
/// assert_eq!(first, @priority_queue.of([1, 2, 3]))
/// ```
pub fn unsafe_pop[A : Compare](self : T[A]) -> T[A] {
  match self.node {
    Empty => abort("Priority queue is empty!")
    Leaf(_) => { node: Empty, size: 0 }
    Branch(_) => {
      let value = self.find_element()
      let temp = self.delet_leaf()
      temp.change_element(value).down(value)
    }
  }
}

///|
#deprecated("Use `unsafe_pop` instead")
#coverage.skip
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
  match self.node {
    Empty => { node: Leaf(value), size: 1 }
    Leaf(a) =>
      {
        node: Branch(
          @math.maximum(a, value),
          left={ node: Leaf(@math.minimum(a, value)), size: 1 },
          right={ node: Empty, size: 0 },
        ),
        size: 2,
      }
    Branch(a, left=l, right=r) =>
      if r.size == 0 {
        {
          node: Branch(@math.maximum(a, value), left=l, right={
            node: Leaf(@math.minimum(a, value)),
            size: 1,
          }),
          size: 3,
        }
      } else {
        let deep = deepth(self.size)
        let full = (1 << (deep - 1)) - 1
        if (l.size == full && r.size == full) || l.size < full {
          let ll = l.push(value)
          {
            node: if value > a {
              Branch(value, left=ll.change_element(a), right=r)
            } else {
              Branch(a, left=ll, right=r)
            },
            size: self.size + 1,
          }
        } else {
          let rr = r.push(value)
          {
            node: if value > a {
              Branch(value, left=l, right=rr.change_element(a))
            } else {
              Branch(a, left=l, right=rr)
            },
            size: self.size + 1,
          }
        }
      }
  }
}

///|
pub fn top[A : Compare](self : T[A]) -> A {
  match self.node {
    Empty => abort("Empty")
    Leaf(a) => a
    Branch(a, ..) => a
  }
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
  match self.node {
    Empty => None
    Leaf(a) => Some(a)
    Branch(a, ..) => Some(a)
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
  self.node is Empty
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
  self.size
}

///|
pub fn of[A : Compare](arr : FixedArray[A]) -> T[A] {
  let mut pq = new()
  for i in 0..<arr.length() {
    pq = pq.push(arr[i])
  }
  pq
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
