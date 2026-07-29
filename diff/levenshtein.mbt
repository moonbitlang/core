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
/// The distance functions are implemented in `internal/edit_distance` so
/// that lightweight consumers (e.g. `argparse` suggestions) can use them
/// without depending on the diff package; this package is their public
/// home. The substitution-aware edit script below stays here because its
/// `LevenshteinEdit` type is public concrete API.
pub using @edit_distance {
  edit_distance,
  edit_distance_within,
  edit_distance_str,
  edit_distance_str_within,
}

///|
/// One step in a Levenshtein edit script that transforms `old` into `new`.
///
/// Unlike `Edit`, a Levenshtein script may pair changed elements one-to-one
/// as substitutions: `Replace` covers `old[old_index:old_index+len]` and
/// `new[new_index:new_index+len]`, pairing `old[old_index+k]` with
/// `new[new_index+k]`; every such pair is unequal, while `Equal` pairs only
/// equal elements.
///
/// The same dual-cursor conventions as `Edit` apply: indices are relative to
/// the views passed to `levenshtein_edits` (not any underlying array), every
/// edit stores both cursor positions at the moment it applies, `Delete`
/// advances only the old cursor, `Insert` only the new cursor, and `Equal` /
/// `Replace` advance both by `len`. The script covers both inputs completely,
/// all lengths are positive, and adjacent edits of the same kind are
/// coalesced.
pub enum LevenshteinEdit {
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
  /// Keep `len` equal elements starting at `old_index` in `old` and
  /// `new_index` in `new`.
  Equal(old_index~ : Int, new_index~ : Int, len~ : Int)
  /// Substitute `len` elements starting at `old_index` in `old` with the
  /// `len` elements starting at `new_index` in `new`, pairing them
  /// one-to-one; every pair is unequal.
  Replace(old_index~ : Int, new_index~ : Int, len~ : Int)
} derive(Eq, @debug.Debug)

///|
/// Length of the longest common prefix of `old` and `new`.
fn[T : Eq] common_prefix_len(old : ArrayView[T], new : ArrayView[T]) -> Int {
  let max = if old.length() < new.length() {
    old.length()
  } else {
    new.length()
  }
  let mut i = 0
  while i < max && old[i] == new[i] {
    i += 1
  }
  i
}

///|
/// `levenshtein_edits(old~, new~)` returns a minimal Levenshtein edit script
/// transforming `old` into `new`, including substitutions; its cost — the
/// sum of `Replace` `len`, `Delete` `old_len`, and `Insert` `new_len`, every
/// edited element contributing exactly 1 — equals `edit_distance(old, new)`.
///
/// The script is deterministic: scanning forward, whenever several operations
/// begin a minimum-cost remaining script, the diagonal one (`Equal` or
/// `Replace`) is preferred, then `Delete`, then `Insert`. In particular a
/// deletion is always emitted before an adjacent insertion. The distance is
/// symmetric, but scripts need not mirror when the inputs are swapped,
/// because deletion wins that tie.
///
/// Degenerate cases: two empty views yield `[]`; if exactly one side is
/// empty, the script is a single `Insert` or `Delete`; equal inputs yield a
/// single `Equal`.
///
/// Runs in `O(m * n)` time and memory (one byte per cell), after trimming
/// the common prefix. The common suffix is deliberately not trimmed: pinning
/// its pairing up front can disagree with the forward-greedy contract when
/// the suffix repeats near an insertion or deletion. Inputs whose trimmed
/// sizes would need a matrix larger than `2^31 - 1` cells abort. For the
/// distance alone, use `edit_distance` or `edit_distance_within`, which need
/// only two rows.
///
/// # Example
/// ```mbt check
/// test {
///   let edits = @diff.levenshtein_edits(
///     old="fable".to_array(),
///     new="table".to_array(),
///   )
///   debug_inspect(
///     edits,
///     content=(
///       #|[
///       #|  Replace(old_index=0, new_index=0, len=1),
///       #|  Equal(old_index=1, new_index=1, len=4),
///       #|]
///     ),
///   )
/// }
/// ```
pub fn[T : Eq] levenshtein_edits(
  old~ : ArrayView[T],
  new~ : ArrayView[T],
) -> Array[LevenshteinEdit] {
  let prefix = common_prefix_len(old, new)
  let a = old.view(start=prefix)
  let b = new.view(start=prefix)
  let m = a.length()
  let n = b.length()
  // widen before any arithmetic so the guard itself cannot overflow
  guard (m.to_int64() + 1L) * (n.to_int64() + 1L) <= @int.MAX_VALUE.to_int64() else {
    abort("levenshtein_edits: input too large")
  }
  let width = n + 1
  // Fill suffix distances bottom-up with two rolling rows, recording in `bp`
  // the operation the forward-greedy contract picks at each cell:
  // 0 = diagonal (Equal/Replace), 1 = delete, 2 = insert.
  let bp : FixedArray[Byte] = FixedArray::make((m + 1) * width, 0)
  let mut next_row = FixedArray::makei(width, j => n - j)
  for j in 0..<n {
    // bottom row: only inserts remain
    bp[m * width + j] = 2
  }
  let mut row = FixedArray::make(width, 0)
  for i2 in 0..<m {
    let i = m - 1 - i2
    // right column: only deletes remain
    row[n] = m - i
    bp[i * width + n] = 1
    for j2 in 0..<n {
      let j = n - 1 - j2
      let diag = next_row[j + 1] + (if a[i] == b[j] { 0 } else { 1 })
      let del = next_row[j] + 1
      let ins = row[j + 1] + 1
      let mut best = diag
      let mut dir : Byte = 0
      if del < best {
        best = del
        dir = 1
      }
      if ins < best {
        best = ins
        dir = 2
      }
      row[j] = best
      bp[i * width + j] = dir
    }
    let t = next_row
    next_row = row
    row = t
  }
  // Walk the recorded choices forward, coalescing runs. The trimmed prefix
  // cannot merge with the walk's edits: a nonempty remainder never starts
  // with an equal pair.
  let edits : Array[LevenshteinEdit] = []
  if prefix > 0 {
    edits.push(Equal(old_index=0, new_index=0, len=prefix))
  }
  let mut i = 0
  let mut j = 0
  while i < m || j < n {
    match bp[i * width + j] {
      0 => {
        let eq = a[i] == b[j]
        let start_i = i
        let start_j = j
        let mut len = 0
        while i < m && j < n && bp[i * width + j] == 0 && (a[i] == b[j]) == eq {
          i += 1
          j += 1
          len += 1
        }
        if eq {
          edits.push(
            Equal(old_index=prefix + start_i, new_index=prefix + start_j, len~),
          )
        } else {
          edits.push(
            Replace(
              old_index=prefix + start_i,
              new_index=prefix + start_j,
              len~,
            ),
          )
        }
      }
      1 => {
        let start_i = i
        let mut len = 0
        while i < m && bp[i * width + j] == 1 {
          i += 1
          len += 1
        }
        edits.push(
          Delete(old_index=prefix + start_i, old_len=len, new_index=prefix + j),
        )
      }
      _ => {
        let start_j = j
        let mut len = 0
        while j < n && bp[i * width + j] == 2 {
          j += 1
          len += 1
        }
        edits.push(
          Insert(old_index=prefix + i, new_index=prefix + start_j, new_len=len),
        )
      }
    }
  }
  edits
}
