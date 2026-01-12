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
priv enum Tree {
  Empty
  Node(l~ : Tree, lo~ : Rechar, hi~ : Rechar, r~ : Tree, w~ : Int)
}

///|
#inline
fn nw(tree : Tree) -> Int {
  match tree {
    Tree::Empty => 1
    Tree::Node(..) as n => n.w
  }
}

///|
#inline
fn nnw(l : Tree, lo : Rechar, hi : Rechar, r : Tree, w : Int) -> Tree {
  Node(l~, lo~, hi~, r~, w~)
}

///|
#inline
fn nn(l : Tree, lo : Rechar, hi : Rechar, r : Tree) -> Tree {
  nnw(l, lo, hi, r, nw(l) + nw(r))
}

///|
fn bal(l : Tree, lo : Rechar, hi : Rechar, r : Tree) -> Tree {
  let lw = nw(l)
  let rw = nw(r)
  if rw > 3 * lw {
    guard r is (Node(..) as r) else { panic() }
    let rlw = nw(r.l)
    let rrw = nw(r.r)
    if rlw < 2 * rrw {
      let lw = lw + rlw
      nnw(nnw(l, lo, hi, r.l, lw), r.lo, r.hi, r.r, lw + rrw)
    } else {
      guard r.l is (Node(..) as rl) else { panic() }
      let lw = lw + rlw
      let rw = nw(rl.r) + rrw
      nnw(
        nnw(l, lo, hi, rl.l, lw),
        rl.lo,
        rl.hi,
        nnw(rl.r, r.lo, r.hi, r.r, rw),
        lw + rw,
      )
    }
  } else if lw > 3 * rw {
    guard l is (Node(..) as l) else { panic() }
    let llw = nw(l.l)
    let lrw = nw(l.r)
    if lrw < 2 * llw {
      let rw = rw + lrw
      nnw(l.l, l.lo, l.hi, nnw(l.r, lo, hi, r, lrw + rw), llw + rw)
    } else {
      guard l.r is (Node(..) as lr) else { panic() }
      let lw = nw(lr.l) + llw
      let rw = rw + lrw
      nnw(
        nnw(l.l, l.lo, l.hi, lr.l, lw),
        lr.lo,
        lr.hi,
        nnw(lr.r, lo, hi, r, rw),
        lw + rw,
      )
    }
  } else {
    nn(l, lo, hi, r)
  }
}

///|
fn cat(l : Tree, r : Tree) -> Tree {
  match (l, r) {
    (Tree::Empty, r) => r
    (l, Tree::Empty) => l
    (Tree::Node(..) as l, Tree::Node(..) as r) => {
      fn go(r : Tree) -> Tree {
        match r {
          Empty => panic()
          Node(l=Empty, lo~, hi~, r~, ..) => nn(l, lo, hi, r)
          Node(l=Node(_) as l, lo~, hi~, r~, ..) => bal(go(l), lo, hi, r)
        }
      }

      go(r)
    }
  }
}

///|
fn build(arr : ArrayView[(Rechar, Rechar)], lo : Int, hi : Int) -> Tree {
  if lo > hi {
    Empty
  } else if lo == hi {
    let (l, h) = arr[lo]
    nn(Empty, l, h, Empty)
  } else {
    let mid = (lo + hi) / 2
    let (l, h) = arr[mid]
    let left = build(arr, lo, mid - 1)
    let right = build(arr, mid + 1, hi)
    nn(left, l, h, right)
  }
}
