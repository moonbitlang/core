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
/// `unique_lcs(old~, new~)` computes the chain of unique matching index pairs used by
/// patience diff.
///
/// It first collects elements that appear exactly once in both `old~` and `new~`, ordered
/// by their position in `old~`. It then runs the patience sorting step of patience diff on
/// the corresponding indices in `new~`, which is equivalent to finding the longest
/// increasing subsequence of those unique matches.
///
/// The returned `(old_idx, new_idx)` pairs are increasing in both arrays and serve as the
/// anchor matches for diffing the remaining unmatched ranges.
fn[T : Eq + Hash] unique_lcs(
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> ArrayView[(Int, Int)] {
  let matches = find_unique(old~, new~)
  let piles = Piles(Array::new(capacity=matches.length()))
  for place = 0; place < matches.length(); place = place + 1 {
    let (_, new_idx) = matches[place]
    // Each pile top stores `(new_idx, place)`: the candidate tail in `new~`
    // and the position needed to recover the original `(old_idx, new_idx)`
    // pair after backtracking.
    if piles.is_empty() {
      piles.put_back(BackPointer::{ value: (new_idx, place), prev: None })
    } else {
      piles.put_by_binary_search(new_idx~, place~)
    }
  }
  guard piles.last() is Some(head) else { return [] }
  // The top of the last pile ends one longest chain; following the
  // backpointers yields the full chain in order.
  let seq = []
  for pair in head.top().to_array().iter() {
    let (_, place) = pair
    seq.push(matches[place])
  }
  return seq
}
