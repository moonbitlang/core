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
/// The pile array maintained while selecting a monotone chain of unique
/// matches.
///
/// The patience-sorting step only compares pile tops, so each pile stores the
/// current tail candidate for one subsequence length.
priv struct Piles(Array[Pile])

///|
fn Piles::is_empty(self : Piles) -> Bool {
  self.0.is_empty()
}

///|
/// Start a new pile with a single visible card.
fn Piles::put_back(self : Piles, singleton : BackPointer) -> Unit {
  self.0.push(Pile::new(singleton))
}

///|
fn Piles::last(self : Piles) -> Pile? {
  self.0.last()
}

///|
fn Piles::op_get(self : Piles, i : Int) -> Pile {
  self.0[i]
}

///|
/// Insert a unique-match candidate into the pile structure.
///
/// `new_idx` is the candidate index in `new~`. `place` points back into the
/// array returned by `find_unique`, so the chosen chain can later be mapped
/// back to `(old_idx, new_idx)` pairs.
fn Piles::put_by_binary_search(
  self : Piles,
  new_idx~ : Int,
  place~ : Int,
) -> Unit {
  let mut lo = -1
  let mut hi = self.0.length()
  while lo + 1 < hi {
    let mid = (lo + hi) / 2
    // Find the rightmost pile whose top still ends before `new_idx`.
    if self[mid].top().value.0 < new_idx {
      lo = mid
    } else {
      hi = mid
    }
  }
  if lo >= 0 {
    let prev = Some(self[lo].top())
    // Place the candidate on the next pile; appending a new pile means the
    // candidate extends the longest chain seen so far.
    if lo + 1 < self.0.length() {
      self[lo + 1].push(BackPointer::{ value: (new_idx, place), prev })
    } else {
      self.put_back(BackPointer::{ value: (new_idx, place), prev })
    }
  } else {
    // new_idx is smaller than all pile tops; place on pile 0 with no predecessor.
    self[0].push(BackPointer::{ value: (new_idx, place), prev: None })
  }
}
