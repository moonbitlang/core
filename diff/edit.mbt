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
/// One step in an edit script that transforms `old` into `new`.
///
/// Every edit stores the positions in *both* original sequences at the moment
/// it applies: `old_index` and `new_index` are monotone cursors into `old` and
/// `new` — `Delete` advances only the old cursor (by `old_len`), `Insert` only
/// the new cursor (by `new_len`), and `Equal` advances both (by `len`). A
/// replacement is always emitted as a `Delete` followed by an `Insert` at the
/// same point; edits never have zero length, and adjacent edits of the same
/// kind are coalesced. Storing both coordinates keeps each edit
/// self-contained, so a slice of the script (a hunk) still knows its absolute
/// positions.
pub enum Edit {
  /// Delete `old_len` elements starting at `old_index` from `old`.
  ///
  /// `new_index` is the cursor position in `new` when this deletion applies;
  /// a deletion covers an empty range on the `new` side.
  Delete(old_index~ : Int, old_len~ : Int, new_index~ : Int)
  /// Insert `new_len` elements starting at `new_index` from `new`.
  ///
  /// `old_index` is the cursor position in `old` when this insertion applies;
  /// an insertion covers an empty range on the `old` side.
  Insert(old_index~ : Int, new_index~ : Int, new_len~ : Int)
  /// Keep `len` equal elements starting at `old_index` in `old` and `new_index`
  /// in `new`.
  Equal(old_index~ : Int, new_index~ : Int, len~ : Int)
} derive(Eq, @debug.Debug)

///|
/// Return the half-open range `[start, end)` covered by this edit in `old`.
///
/// Insertions consume no elements from `old`, so they map to an empty range.
fn Edit::old_range(self : Edit) -> (Int, Int) {
  match self {
    Insert(old_index~, ..) => (old_index, old_index)
    Delete(old_index~, old_len~, ..) => (old_index, old_index + old_len)
    Equal(old_index~, len~, ..) => (old_index, old_index + len)
  }
}

///|
/// Return the half-open range `[start, end)` covered by this edit in `new`.
///
/// Deletions consume no elements from `new`, so they map to an empty range.
fn Edit::new_range(self : Edit) -> (Int, Int) {
  match self {
    Insert(new_index~, new_len~, ..) => (new_index, new_index + new_len)
    Delete(new_index~, ..) => (new_index, new_index)
    Equal(new_index~, len~, ..) => (new_index, new_index + len)
  }
}

///|
fn[T] Edit::view_from(
  self : Edit,
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> ArrayView[T] {
  match self {
    Insert(new_index~, new_len~, ..) =>
      new.view(start=new_index, end=new_index + new_len)
    Delete(old_index~, old_len~, ..) =>
      old.view(start=old_index, end=old_index + old_len)
    Equal(old_index~, len~, ..) =>
      old.view(start=old_index, end=old_index + len)
  }
}

///|
/// Isolate change clusters by eliminating ranges with no changes.
///
/// This will leave holes behind in long periods of equal ranges so that
/// you can build things like unified diffs.
fn[T] group_edits(
  edits : Array[Edit],
  context? : Int = 3,
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> Array[Hunk[T]] {
  guard context >= 0 else { abort("context must be non-negative") }
  if edits.is_empty() {
    return []
  }
  let n = edits.length()
  let mut pending = Array::new()
  let result : Array[Hunk[T]] = Array::new()
  for i, edit in edits {
    match edit {
      Equal(old_index~, new_index~, len~) => {
        // Trim leading context for first edit
        let (old_index, new_index, len) = if i == 0 {
          let offset = len.saturating_sub(context)
          (old_index + offset, new_index + offset, len - offset)
        } else {
          (old_index, new_index, len)
        }
        // Trim trailing context for last edit
        let len = if i == n - 1 {
          len - len.saturating_sub(context)
        } else {
          len
        }
        // Split if this equal range is large enough
        if len > context * 2 {
          pending.push(Equal(old_index~, new_index~, len=context))
          result.push({ edits: pending, old, new })
          let offset = len.saturating_sub(context)
          pending = [
            Equal(
              old_index=old_index + offset,
              new_index=new_index + offset,
              len=len - offset,
            ),
          ]
        } else if len > 0 {
          pending.push(Equal(old_index~, new_index~, len~))
        }
      }
      _ => pending.push(edit)
    }
  }
  if !(pending is [] || pending is [Equal(_)]) {
    result.push({ edits: pending, old, new })
  }
  result
}

///|
fn Int::saturating_sub(self : Int, subtrahend : Int) -> Int {
  if self < subtrahend {
    0
  } else {
    self - subtrahend
  }
}
