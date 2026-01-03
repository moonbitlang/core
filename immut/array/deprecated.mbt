// Copyright 2026 International Digital Economy Academy
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
/// Physically copy the array.
/// Since it is an immutable data structure,
/// it is rarely the case that you would need this function.
/// 
#deprecated("We don't copy immutable array")
#coverage.skip
pub fn[A] T::copy(self : T[A]) -> T[A] {
  fn copy(t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(l.copy())
      Empty => Empty
      Node(node, sizes) =>
        Node(
          FixedArray::makei(node.length(), i => copy(node[i])),
          match sizes {
            Some(sizes) => Some(FixedArray::copy(sizes))
            None => None
          },
        )
    }
  }

  { tree: copy(self.tree), size: self.size, shift: self.shift }
}

///|
#warnings("-deprecated")
#deprecated("Use `T::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[A] T::from_iter(iter : Iter[A]) -> T[A] {
  let mut buf : FixedArray[A] = []
  let mut index = 0
  let leaves = []
  iter.each(x => if index == 0 {
    buf = FixedArray::make(branching_factor, x)
    index += 1
  } else if index < branching_factor {
    buf[index] = x
    index += 1
  } else {
    leaves.push(buf)
    index = 1
    buf = FixedArray::make(branching_factor, x)
  })
  if index == branching_factor {
    leaves.push(buf)
  } else if index > 0 {
    let res = FixedArray::make(index, buf[0])
    buf.blit_to(res, len=index)
    leaves.push(res)
  }
  let size = leaves.fold(init=0, (acc, xs) => acc + xs.length())
  let (shift, cap) = shift_cap_of_size(size)
  let tree = if size == 0 { Empty } else { from_leaves(leaves[:], cap) }
  { shift, tree, size }
}

///|
/// Return an internal iterator over the array.
#warnings("-deprecated")
#deprecated("Use `T::iterator()` to get an external iterator.")
pub fn[A] T::iter(self : T[A]) -> Iter[A] {
  self.tree.iterator().iter()
}
