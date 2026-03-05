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
test "group_edits handles empty edits" {
  debug_inspect(
    @diff.group_edits([]),
    content=(
      #|[]
    ),
  )
}

///|
test "group_edits splits long equal blocks into multiple hunks" {
  let edits : Array[@diff.Edit] = [
    Delete(old_index=0, new_index=0, old_len=1),
    Equal(old_index=1, new_index=0, len=10),
    Insert(old_index=11, new_index=10, new_len=2),
  ]
  debug_inspect(
    @diff.group_edits(edits),
    content=(
      #|[
      #|  [
      #|    Delete(old_index=0, new_index=0, old_len=1),
      #|    Equal(old_index=1, new_index=0, len=3),
      #|  ],
      #|  [
      #|    Equal(old_index=8, new_index=7, len=3),
      #|    Insert(old_index=11, new_index=10, new_len=2),
      #|  ],
      #|]
    ),
  )
}

///|
test "range display for single and empty span" {
  inspect(
    @diff.HunkHeader::new([Equal(old_index=4, new_index=2, len=1)]).to_string(),
    content="@@ -5 +3 @@",
  )
  inspect(
    @diff.HunkHeader::new([Insert(old_index=4, new_index=2, new_len=1)]).to_string(),
    content="@@ -4,0 +3 @@",
  )
}
