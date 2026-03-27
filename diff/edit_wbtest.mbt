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
test "group_edit handles empty edits" {
  assert_true(
    group_edits([], old=([] : ArrayView[Int]), new=([] : ArrayView[Int])) is [],
  )
}

///|
test "group_edit splits long equal blocks into multiple hunks" {
  let edits : Array[Edit] = [
    Edit::Delete(old_index=0, new_index=0, old_len=1),
    Edit::Equal(old_index=1, new_index=0, len=10),
    Edit::Insert(old_index=11, new_index=10, new_len=2),
  ]
  let groups = group_edits(
    edits,
    old=([] : ArrayView[Int]),
    new=([] : ArrayView[Int]),
  )
  assert_eq(groups.length(), 2)
  assert_true(
    groups[0].edits
    is [
      Delete(old_index=0, new_index=0, old_len=1),
      Equal(old_index=1, new_index=0, len=3),
    ],
  )
  assert_true(
    groups[1].edits
    is [
      Equal(old_index=8, new_index=7, len=3),
      Insert(old_index=11, new_index=10, new_len=2),
    ],
  )
}

///|
test "range display for single and empty span" {
  inspect(
    HunkHeader::new([Equal(old_index=4, new_index=2, len=1)]).to_string(),
    content="@@ -5 +3 @@",
  )
  inspect(
    HunkHeader::new([Insert(old_index=4, new_index=2, new_len=1)]).to_string(),
    content="@@ -4,0 +3 @@",
  )
}

///|
test "range display spans replacement ending with insert" {
  inspect(
    HunkHeader::new([
      Delete(old_index=1, new_index=1, old_len=1),
      Insert(old_index=1, new_index=1, new_len=1),
    ]).to_string(),
    content="@@ -2 +2 @@",
  )
}
