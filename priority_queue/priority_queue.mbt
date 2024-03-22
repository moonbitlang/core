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

struct Cont[T] {
  content : T
  mut sibling : Node[T]
  mut child : Node[T]
}

enum Node[T] {
  Nil
  Cons(Cont[T])
}

struct PriorityQueue[T] {
  min : Bool
  mut len : Int
  mut top : Node[T]
}

pub fn PriorityQueue::new[T : Compare](~min : Bool = false) -> PriorityQueue[T] {
  { min, len: 0, top: Nil }
}

pub fn PriorityQueue::from_array[T : Compare](
  arr : Array[T],
  ~min : Bool = false
) -> PriorityQueue[T] {
  for i = 0, acc = (Nil : Node[T]); i < arr.length(); {
    continue i + 1,
      meld(acc, Cons({ content: arr[i], sibling: Nil, child: Nil }), min)
  } else {
    { min, len: arr.length(), top: acc }
  }
}

test "new" {
  let queue : PriorityQueue[Int] = new()
  @assertion.assert_eq(queue.len, 0)?
}

fn meld[T : Compare](x : Node[T], y : Node[T], min : Bool) -> Node[T] {
  match (x, y) {
    (Nil, _) => y
    (_, Nil) => x
    (Cons(x_top), Cons(y_top)) =>
      if if min {
        x_top.content < y_top.content
      } else {
        x_top.content > y_top.content
      } {
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

fn merges[T : Compare](x : Node[T], min : Bool) -> Node[T] {
  match x {
    Nil => Nil
    Cons(top) =>
      match top.sibling {
        Nil => x
        Cons(next_top) =>
          match next_top.sibling {
            Nil => meld(x, top.sibling, min)
            Cons(_) =>
              meld(
                merges(next_top.sibling, min),
                meld(x, top.sibling, min),
                min,
              )
          }
      }
  }
}

pub fn length[T](self : PriorityQueue[T]) -> Int {
  self.len
}

pub fn pop_exn[T : Compare](self : PriorityQueue[T]) -> Unit {
  if self.len == 0 {
    abort("The PriorityQueue is empty!")
  }
  self.top = match self.top {
    Nil => Nil
    Cons(top) => merges(top.child, self.min)
  }
  self.len -= 1
}

pub fn pop[T : Compare](self : PriorityQueue[T]) -> Option[T] {
  let result = self.top()
  self.top = match self.top {
    Nil => Nil
    Cons(top) => {
      self.len -= 1
      merges(top.child, self.min)
    }
  }
  result
}

pub fn insert[T : Compare](self : PriorityQueue[T], value : T) -> Unit {
  self.top = meld(
    self.top,
    Cons({ content: value, sibling: Nil, child: Nil }),
    self.min,
  )
  self.len += 1
}

pub fn top[T](self : PriorityQueue[T]) -> Option[T] {
  match self.top {
    Nil => None
    Cons(top) => Some(top.content)
  }
}
