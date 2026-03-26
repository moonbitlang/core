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
/// Collect elements that occur exactly once in both sequences.
///
/// The returned pairs are sorted by `old~` index so `unique_lcs` can run the
/// patience-sorting step on the corresponding `new~` indices.
fn[T : Eq + Hash] find_unique(
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> Array[(Int, Int)] {
  // Track where a value first appears on each side and how often it appears.
  struct CountRecord {
    old_idx : Int
    mut old_count : Int
    mut new_idx : Int
    mut new_count : Int
  }
  let match_lines = @hashmap.new()
  for i = 0; i < old.length(); i = i + 1 {
    if match_lines.contains(old[i]) {
      let count_record : CountRecord = match_lines.get(old[i]).unwrap()
      count_record.old_count = count_record.old_count + 1
    } else {
      match_lines[old[i]] = CountRecord::{
        old_idx: i,
        old_count: 1,
        new_idx: -1,
        new_count: 0,
      }
    }
  }
  for i = 0; i < new.length(); i = i + 1 {
    if match_lines.contains(new[i]) {
      let count_record = match_lines.get(new[i]).unwrap()
      count_record.new_count = count_record.new_count + 1
      if count_record.new_idx == -1 {
        count_record.new_idx = i
      }
    }
  }
  // Only unique-on-both-sides values can serve as stable patience-diff
  // anchors.
  let match_lines = match_lines
    .iter()
    .filter(p => p.1.new_count == 1 && p.1.old_count == 1)
  let unique_match_lines = []
  for pair in match_lines {
    let (_, record) = pair
    unique_match_lines.push((record.old_idx, record.new_idx))
  }
  // Sorting by `old_idx` turns the LIS over `new_idx` into a common
  // subsequence in both arrays.
  unique_match_lines.sort_by_key(pair => pair.0)
  return unique_match_lines
}
