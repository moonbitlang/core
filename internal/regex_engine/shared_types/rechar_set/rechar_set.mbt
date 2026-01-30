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
struct RecharSet(Tree)

///|
pub fn RecharSet::empty() -> RecharSet {
  RecharSet(Empty)
}

///|
pub fn RecharSet::char(c : Rechar) -> RecharSet {
  RecharSet(nn(Empty, c, c, Empty))
}

///|
pub fn RecharSet::char_range(lo : Rechar, hi : Rechar) -> RecharSet {
  guard lo <= hi else { panic() }
  RecharSet(nn(Empty, lo, hi, Empty))
}

///|
pub fn RecharSet::is_empty(self : RecharSet) -> Bool {
  self.0 is Empty
}

///|
pub fn RecharSet::is_subset(self : RecharSet, other : RecharSet) -> Bool {
  difference(self.0, other.0) is Empty
}

///|
pub fn RecharSet::first_interval(self : RecharSet) -> (Rechar, Rechar)? {
  leftmost(self.0)
}

///|
pub fn RecharSet::last_interval(self : RecharSet) -> (Rechar, Rechar)? {
  rightmost(self.0)
}

///|
pub fn RecharSet::contains(self : RecharSet, c : Rechar) -> Bool {
  loop self.0 {
    Empty => false
    Node(l~, lo~, hi~, r~, ..) =>
      if c < lo {
        continue l
      } else if c > hi {
        continue r
      } else {
        true
      }
  }
}

///|
fn slice_from(t : Tree, c : Rechar) -> Tree {
  match t {
    Empty => Empty
    Node(l~, lo~, hi~, r~, ..) =>
      if c < lo {
        bal(slice_from(l, c), lo, hi, r)
      } else if c > hi {
        slice_from(r, c)
      } else {
        bal(Empty, c, hi, r)
      }
  }
}

///|
fn slice_until(t : Tree, c : Rechar) -> Tree {
  match t {
    Empty => Empty
    Node(l~, lo~, hi~, r~, ..) =>
      if c < lo {
        slice_until(l, c)
      } else if c > hi {
        bal(l, lo, hi, slice_until(r, c))
      } else {
        bal(l, lo, c, Empty)
      }
  }
}

///|
fn slice_before(t : Tree, c : Rechar) -> Tree {
  if c - 1 >= c {
    Empty
  } else {
    slice_until(t, c - 1)
  }
}

///|
fn slice_after(tree : Tree, c : Rechar) -> Tree {
  if c + 1 <= c {
    Empty
  } else {
    slice_from(tree, c + 1)
  }
}

///|
fn leftmost(t : Tree) -> (Rechar, Rechar)? {
  match t {
    Empty => None
    Node(l=Empty, lo~, hi~, ..) => Some((lo, hi))
    Node(l~, ..) => leftmost(l)
  }
}

///|
fn rightmost(t : Tree) -> (Rechar, Rechar)? {
  match t {
    Empty => None
    Node(lo~, hi~, r=Empty, ..) => Some((lo, hi))
    Node(r~, ..) => rightmost(r)
  }
}

///|
fn try_merge_left(lo : Rechar, t : Tree) -> (Rechar, Tree) {
  fn remove_leftmost(t : Tree) -> Tree {
    match t {
      Empty => panic()
      Node(l=Empty, r~, ..) => r
      Node(l~, lo~, hi~, r~, ..) => bal(remove_leftmost(l), lo, hi, r)
    }
  }

  if leftmost(t) is Some((lo2, hi2)) && hi2 + 1 >= lo {
    (lo2, remove_leftmost(t))
  } else {
    (lo, t)
  }
}

///|
fn try_merge_right(hi : Rechar, t : Tree) -> (Rechar, Tree) {
  fn remove_rightmost(t : Tree) -> Tree {
    match t {
      Empty => panic()
      Node(l~, r=Empty, ..) => l
      Node(l~, lo~, hi~, r~, ..) => bal(l, lo, hi, remove_rightmost(r))
    }
  }

  if rightmost(t) is Some((lo2, hi2)) && lo2 - 1 <= hi {
    (hi2, remove_rightmost(t))
  } else {
    (hi, t)
  }
}

///|
fn union(t1 : Tree, t2 : Tree) -> Tree {
  match (t1, t2) {
    (Empty, t) | (t, Empty) => t
    (Node(w=w1, ..), Node(w=w2, ..)) => {
      let (larger, smaller) = if w1 >= w2 { (t1, t2) } else { (t2, t1) }
      guard larger is Node(l~, lo~, hi~, r~, ..) else { panic() }

      // Handle left side
      let (lo, l) = {
        let p = lo - 1
        if p >= lo {
          // lo is minimum value, cannot have predecessor
          (lo, Empty)
        } else {
          let l = union(l, slice_before(smaller, lo))
          try_merge_left(lo, l)
        }
      }

      // Handle right side
      let (hi, r) = {
        let s = hi + 1
        if s <= hi {
          // hi is maximum value, cannot have successor
          (hi, Empty)
        } else {
          let r = union(r, slice_after(smaller, hi))
          try_merge_right(hi, r)
        }
      }
      bal(l, lo, hi, r)
    }
  }
}

///|
fn intersection(t1 : Tree, t2 : Tree) -> Tree {
  match (t1, t2) {
    (Empty, _) | (_, Empty) => Empty
    (Node(w=w1, ..), Node(w=w2, ..)) => {
      let (larger, smaller) = if w1 >= w2 { (t1, t2) } else { (t2, t1) }
      guard larger is Node(l~, lo~, hi~, r~, ..) else { panic() }
      let left = intersection(l, slice_before(smaller, lo))
      let right = intersection(r, slice_after(smaller, hi))
      let middle = slice_until(slice_from(smaller, lo), hi)
      cat(left, cat(middle, right))
    }
  }
}

///|
fn complement(t : Tree) -> Tree {
  fn aux(lo : Rechar, hi : Rechar, t : Tree) -> Tree {
    match t {
      Empty => nn(Empty, lo, hi, Empty)
      Node(l~, lo=ilo, hi=ihi, r~, ..) => {
        let left = {
          let p = ilo - 1
          if p < ilo {
            aux(lo, p, l)
          } else {
            Empty
          }
        }
        let right = {
          let s = ihi + 1
          if s > ihi {
            aux(s, hi, r)
          } else {
            Empty
          }
        }
        cat(left, right)
      }
    }
  }

  aux(-0x80000000, 0x7FFFFFFF, t)
}

///|
fn difference(t1 : Tree, t2 : Tree) -> Tree {
  intersection(t1, complement(t2))
}

///|
pub fn RecharSet::union(self : RecharSet, other : RecharSet) -> RecharSet {
  RecharSet(union(self.0, other.0))
}

///|
pub fn RecharSet::intersection(
  self : RecharSet,
  other : RecharSet,
) -> RecharSet {
  RecharSet(intersection(self.0, other.0))
}

///|
pub fn RecharSet::difference(self : RecharSet, other : RecharSet) -> RecharSet {
  RecharSet(difference(self.0, other.0))
}

///|
pub fn RecharSet::offset_by(self : RecharSet, f : (Int) -> Int) -> RecharSet {
  fn aux(t : Tree) -> Tree {
    match t {
      Empty => Empty
      Node(l~, lo~, hi~, r~, ..) => bal(aux(l), f(lo), f(hi), aux(r))
    }
  }

  RecharSet(aux(self.0))
}

///|
pub fn RecharSet::intervals(self : RecharSet) -> Iter[(Rechar, Rechar)] {
  let mut node = self.0
  let parents = []
  Iter::new(fn() {
    loop node {
      Node(l=Empty, lo~, hi~, r~, ..) => {
        node = r
        Some((lo, hi))
      }
      Node(l~, lo~, hi~, r~, ..) => {
        parents.push((lo, hi, r))
        continue l
      }
      Empty if parents.pop() is Some((lo, hi, r)) => {
        node = r
        Some((lo, hi))
      }
      Empty => None
    }
  })
}

///|
pub fn RecharSet::from_sorted_array(
  arr : ArrayView[(Rechar, Rechar)],
) -> RecharSet {
  RecharSet(build(arr, 0, arr.length() - 1))
}

///|
pub impl Add for RecharSet with add(self, other) {
  RecharSet::union(self, other)
}

///|
pub impl Sub for RecharSet with sub(self, other) {
  RecharSet::difference(self, other)
}

///|
pub impl BitAnd for RecharSet with land(self, other) {
  RecharSet::intersection(self, other)
}

///|
pub impl @debug.Debug for RecharSet with to_repr(self) {
  @debug.Debug::to_repr(self.intervals().to_array())
}
