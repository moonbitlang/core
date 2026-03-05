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
pub enum Edit {
  Delete(old_index~ : Int, new_index~ : Int, old_len~ : Int)
  Insert(old_index~ : Int, new_index~ : Int, new_len~ : Int)
  Equal(mut old_index~ : Int, mut new_index~ : Int, mut len~ : Int)
}

///|
pub impl @debug.Debug for Edit with to_repr(self) {
  match self {
    Insert(old_index~, new_index~, new_len~) =>
      @debug.Repr::ctor("Insert", [
        (Some("old_index"), @debug.Repr::integer(old_index.to_string())),
        (Some("new_index"), @debug.Repr::integer(new_index.to_string())),
        (Some("new_len"), @debug.Repr::integer(new_len.to_string())),
      ])
    Delete(old_index~, new_index~, old_len~) =>
      @debug.Repr::ctor("Delete", [
        (Some("old_index"), @debug.Repr::integer(old_index.to_string())),
        (Some("new_index"), @debug.Repr::integer(new_index.to_string())),
        (Some("old_len"), @debug.Repr::integer(old_len.to_string())),
      ])
    Equal(old_index~, new_index~, len~) =>
      @debug.Repr::ctor("Equal", [
        (Some("old_index"), @debug.Repr::integer(old_index.to_string())),
        (Some("new_index"), @debug.Repr::integer(new_index.to_string())),
        (Some("len"), @debug.Repr::integer(len.to_string())),
      ])
  }
}

///|
pub enum EditTag {
  Delete
  Insert
  Equal
}

///|
fn Edit::old_range(self : Edit) -> (Int, Int) {
  match self {
    Insert(old_index~, ..) => (old_index, old_index)
    Delete(old_index~, old_len~, ..) => (old_index, old_index + old_len)
    Equal(old_index~, len~, ..) => (old_index, old_index + len)
  }
}

///|
fn Edit::new_range(self : Edit) -> (Int, Int) {
  match self {
    Insert(new_index~, new_len~, ..) => (new_index, new_index + new_len)
    Delete(new_index~, ..) => (new_index, new_index)
    Equal(new_index~, len~, ..) => (new_index, new_index + len)
  }
}

///|
pub fn[T] Edit::take_tagged_view_from(
  self : Edit,
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> (EditTag, ArrayView[T]) {
  match self {
    Insert(new_index~, new_len~, ..) =>
      (Insert, new.view(start=new_index, end=new_index + new_len))
    Delete(old_index~, old_len~, ..) =>
      (Delete, old.view(start=old_index, end=old_index + old_len))
    Equal(old_index~, len~, ..) =>
      (Equal, old.view(start=old_index, end=old_index + len))
  }
}

///|
/// Isolate change clusters by eliminating ranges with no changes.
///
/// This will leave holes behind in long periods of equal ranges so that
/// you can build things like unified diffs.
///
/// This function may mutate `edits` in place when trimming context from the
/// leading and trailing `Equal` entries. If you need to keep the original edit
/// script unchanged, clone it before calling `group_edits`.
pub fn group_edits(edits : Array[Edit], radius? : Int = 3) -> Array[Hunk] {
  if edits.is_empty() {
    return []
  }
  let mut pending_group = Array::new()
  let result = Array::new()

  // cut first equal sequence to size limit
  if edits[0] is (Equal(_) as first_edit) {
    let offset = first_edit.len.saturating_sub(radius)
    first_edit.old_index += offset
    first_edit.new_index += offset
    first_edit.len -= offset
  }

  // cut last equal sequence to size limit
  if edits.last() is Some(Equal(_) as last_edit) {
    last_edit.len -= last_edit.len.saturating_sub(radius)
  }
  for edit in edits {
    if edit is (Equal(_) as edit) {
      // End the current group and start a new one whenever
      // there is a large range with no changes.
      if edit.len > radius * 2 {
        pending_group.push(
          Edit::Equal(
            old_index=edit.old_index,
            new_index=edit.new_index,
            len=radius,
          ),
        )
        result.push(Hunk(pending_group))
        let offset = edit.len.saturating_sub(radius)
        pending_group = [
          Edit::Equal(
            old_index=edit.old_index + offset,
            new_index=edit.new_index + offset,
            len=edit.len - offset,
          ),
        ]
        continue
      }
    }
    pending_group.push(edit)
  }
  if !(pending_group is [] || pending_group is [Equal(_)]) {
    result.push(Hunk(pending_group[:]))
  }
  return result
}

///|
fn Int::saturating_sub(self : Int, subtrahend : Int) -> Int {
  if self < subtrahend {
    0
  } else {
    self - subtrahend
  }
}
