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
/// A partition is the midpoint of the shortest edit script for a specified portion of two
/// vectors.
///
/// `lhs_midpoint`, `rhs_midpoint` is the midpoint discovered. The diagonal number `lhs_midpoint - rhs_midpoint` 
/// equals the number of inserted elements minus the number of deleted elements (counting only elements before the midpoint).
///
/// `lo_minimal` is true iff the minimal edit script for the left half of the partition is
/// known; similarly for `hi_minimal`.
#valtype
priv struct Partition {
  lhs_midpoint : Int32 // position of midpoint in sequence lhs
  rhs_midpoint : Int32 // position of midpoint in sequence rhs
  lo_minimal : Bool // whether left half is optimal
  hi_minimal : Bool // whether right half is optimal
}

///|
/// Find the midpoint of the shortest edit script for a specified portion of the two
/// vectors.
///
/// Scan from the beginnings of the vectors, and simultaneously from the ends, doing a
/// breadth-first search through the space of edit-sequence. When the two searches meet, we
/// have found the midpoint of the shortest edit sequence.
///
/// If `find_minimal` is true, find the minimal edit script regardless of expense.
/// Otherwise, if the search is too expensive, use heuristics to stop the search and report
/// a suboptimal answer.
/// 
/// This function assumes that the first elements of the specified portions of the two
/// vectors do not match, and likewise that the last elements do not match. The caller must
/// trim matching elements from the beginning and end of the portions it is going to
/// specify.
///
/// If we return the "wrong" partitions, the worst this can do is cause suboptimal diff
/// output. It cannot cause incorrect diff output.
///
/// Parameter mapping to Myers algorithm concepts:
/// - `forward_search_diagonal~`: forward search diagonal array; for diagonal `k`,
///   `forward_search_diagonal[k]` stores the farthest reachable x coordinate
/// - `backward_search_diagonal~`: backward search diagonal array; for diagonal `k`,
///   `backward_search_diagonal[k]` stores the nearest reachable x coordinate
/// - `diagonal_shift~`: diagonal-to-array index shift. Diagonal `k` is stored at `sh + k`,
///   so negative diagonals are representable; with `sh = rhs_len + 1`, the algorithm can
///   safely access neighbor/sentinel diagonals `k±1` and `k±2`
/// - `lhs_offset~`, `lhs_limit~`: search range for sequence lhs `[lhs_offset, lhs_limit)`
/// - `rhs_offset~`, `rhs_limit~`: search range for sequence rhs `[rhs_offset, rhs_limit)`
/// - `too_expensive~`: computation cost upper limit, preventing algorithm from running too long in difficult cases
/// - `find_minimal~`: whether to force finding minimal edit script (regardless of computation cost)
/// 
fn[T : Eq] diag(
  forward_search_diagonal~ : FixedArray[Int32], // forward search diagonal array - stores farthest reachable point on each diagonal
  backward_search_diagonal~ : FixedArray[Int32], // backward search diagonal array - stores nearest reachable point on each diagonal
  diagonal_shift~ : Int32, // diagonal index shift: store diagonal k at [sh + k], including negative k and k±1/k±2 neighbors
  lhs~ : CompactedElements[T], // compacted elements for sequence lhs
  rhs~ : CompactedElements[T], // compacted elements for sequence rhs
  lhs_offset~ : Int32, // starting position of sequence lhs - defines left boundary of search window
  lhs_limit~ : Int32, // ending position of sequence lhs - defines right boundary of search window
  rhs_offset~ : Int32, // starting position of sequence rhs - defines upper boundary of search window  
  rhs_limit~ : Int32, // ending position of sequence rhs - defines lower boundary of search window
  too_expensive~ : Int32, // computation cost threshold - use heuristic algorithm when exceeded
  find_minimal~ : Bool, // optimality flag - whether optimal solution must be found
) -> Partition {
  // Calculate range of valid diagonals
  // In edit graph, diagonal k = x - y, valid range determined by search window
  let dmin = lhs_offset - rhs_limit // minimum valid diagonal - corresponds to maximum insertions
  let dmax = lhs_limit - rhs_offset // maximum valid diagonal - corresponds to maximum deletions
  let fmid = lhs_offset - rhs_offset // center diagonal for forward search - diagonal corresponding to starting point
  let bmid = lhs_limit - rhs_limit // center diagonal for backward search - diagonal corresponding to end point

  // Determine parity: whether southeast corner is on odd diagonal relative to northwest corner
  // This determines when forward and backward searches meet (they meet in same step only when parity differs)
  let odd = ((fmid - bmid) & 1) != 0

  // Initialize search starting points
  // diagonal_shift maps diagonal k to index diagonal_shift+k; with diagonal_shift=rhs_limit + 1 we can index diagonals in [-(rhs_limit + 1), lhs_limit + 1]
  forward_search_diagonal[diagonal_shift + fmid] = lhs_offset // forward search starts from (lhs_offset, rhs_offset)
  backward_search_diagonal[diagonal_shift + bmid] = lhs_limit // backward search starts from (lhs_limit, rhs_limit)

  // Main loop: alternate forward and backward search, increasing edit distance by one each time
  // c: current edit distance (search depth)
  // fmin, fmax: diagonal range for forward search
  // bmin, bmax: diagonal range for backward search
  for c = 1, fmin = fmid, fmax = fmid, bmin = bmid, bmax = bmid {
    // Extend diagonal range for forward search
    // Each iteration expands search range as edit distance increases by 1
    let fmin = if fmin > dmin {
      forward_search_diagonal[diagonal_shift + fmin - 2] = -1 // mark unused diagonal
      fmin - 1 // extend to next diagonal
    } else {
      fmin + 1 // boundary constraint
    }
    let fmax = if fmax < dmax {
      forward_search_diagonal[diagonal_shift + fmax + 2] = -1 // mark unused diagonal  
      fmax + 1 // extend to previous diagonal
    } else {
      fmax - 1 // boundary constraint
    }

    // Process all diagonals for forward search
    let mut forward_result : Partition? = None
    let mut d = fmax
    while d >= fmin {
      // Get farthest reachable points on adjacent diagonals
      // tlo: x coordinate on lower-left diagonal (d-1), position after deletion
      // thi: x coordinate on upper-right diagonal (d+1), position after insertion
      let tlo = forward_search_diagonal[diagonal_shift + d - 1]
      let thi = forward_search_diagonal[diagonal_shift + d + 1]

      // Choose better path: transfer from diagonal that reaches farther x coordinate
      // This embodies Myers algorithm's greedy strategy: prioritize paths that go farther
      let x = if tlo >= thi { tlo + 1 } else { thi }

      // Search for matching sequence along diagonal (Snake)
      // This is key optimization of Myers algorithm: freely extend matching elements
      let (x_cur, y_cur) = for x_cur = x, y_cur = x - d {
        if x_cur < lhs_limit && y_cur < rhs_limit && lhs[x_cur] == rhs[y_cur] {
          continue x_cur + 1, y_cur + 1
        } else {
          break (x_cur, y_cur)
        }
      }

      // Update farthest reachable point on current diagonal
      forward_search_diagonal[diagonal_shift + d] = x_cur

      // Check if meeting with backward search
      // Meeting conditions: parity matches && diagonal is in backward search range && forward/backward search points overlap
      if odd &&
        bmin <= d &&
        d <= bmax &&
        backward_search_diagonal[diagonal_shift + d] <=
        forward_search_diagonal[diagonal_shift + d] {
        forward_result = Some({
          lhs_midpoint: x_cur,
          rhs_midpoint: y_cur,
          lo_minimal: true, // forward path is optimal
          hi_minimal: true, // backward path is also optimal
        })
        break // found meeting point, exit early
      }
      d -= 2 // Myers algorithm characteristic: only check diagonals with same parity
    }

    // If forward search found solution, return directly
    match forward_result {
      Some(result) => break result
      None => ()
    }

    // Similarly extend diagonal range for backward search
    let bmin = if bmin > dmin {
      backward_search_diagonal[diagonal_shift + bmin - 2] = @int.MAX_VALUE // mark unused diagonal as max value
      bmin - 1
    } else {
      bmin + 1
    }
    let bmax = if bmax < dmax {
      backward_search_diagonal[diagonal_shift + bmax + 2] = @int.MAX_VALUE // mark unused diagonal as max value
      bmax + 1
    } else {
      bmax - 1
    }

    // Process all diagonals for backward search
    let mut backward_result : Partition? = None
    let mut d = bmax
    while d >= bmin {
      // Get nearest reachable points on adjacent diagonals (backward search in reverse direction)
      let tlo = backward_search_diagonal[diagonal_shift + d - 1]
      let thi = backward_search_diagonal[diagonal_shift + d + 1]

      // Backward search selection strategy: choose point with smaller x coordinate (closer to start)
      let x = if tlo < thi { tlo } else { thi - 1 }

      // Search backward for matching sequence (reverse Snake)
      let (x_cur, y_cur) = for x_cur = x, y_cur = x - d {
        if x_cur > lhs_offset &&
          y_cur > rhs_offset &&
          lhs[x_cur - 1] == rhs[y_cur - 1] {
          continue x_cur - 1, y_cur - 1
        } else {
          break (x_cur, y_cur)
        }
      }

      // Update nearest reachable point on current diagonal
      backward_search_diagonal[diagonal_shift + d] = x_cur

      // Check if meeting with forward search (meeting condition for even case)
      if !odd &&
        fmin <= d &&
        d <= fmax &&
        backward_search_diagonal[diagonal_shift + d] <=
        forward_search_diagonal[diagonal_shift + d] {
        backward_result = Some({
          lhs_midpoint: x_cur,
          rhs_midpoint: y_cur,
          lo_minimal: true,
          hi_minimal: true,
        })
        break
      }
      d -= 2
    }

    // If backward search found solution, return directly
    match backward_result {
      Some(result) => break result
      None => ()
    }

    // Heuristic handling: if computation cost too high, abandon finding optimal solution
    // This is important mechanism for Myers algorithm to handle difficult cases
    if !find_minimal && c >= too_expensive {
      // Find diagonal in forward search that maximizes x + y
      // This indicates processing maximum number of elements overall
      let mut fxybest = -1
      let mut fxbest = fmax
      let mut d = fmax
      while d >= fmin {
        let x = lhs_limit.min(forward_search_diagonal[diagonal_shift + d]) // limit to valid range
        let y = x - d
        let (x, y) = if rhs_limit < y {
          (rhs_limit + d, rhs_limit)
        } else {
          (x, y)
        }
        if fxybest < x + y {
          fxybest = x + y
          fxbest = x
        }
        d -= 2
      }

      // Find diagonal in backward search that minimizes x + y
      // This indicates reasonable partition point closest to start
      let mut bxybest = @int.MAX_VALUE
      let mut bxbest = bmax
      let mut d = bmax
      while d >= bmin {
        let x = lhs_offset.max(backward_search_diagonal[diagonal_shift + d]) // limit to valid range
        let y = x - d
        let (x, y) = if y < rhs_offset {
          (rhs_offset + d, rhs_offset)
        } else {
          (x, y)
        }
        if x + y < bxybest {
          bxybest = x + y
          bxbest = x
        }
        d -= 2
      }

      // Choose better heuristic partition point
      // Compare "quality" of forward and backward, choose side that processes more elements
      if lhs_limit + rhs_limit - bxybest < fxybest - (lhs_offset + rhs_offset) {
        break {
          lhs_midpoint: fxbest,
          rhs_midpoint: fxybest - fxbest,
          lo_minimal: true,
          hi_minimal: false, // right half is not optimal
        }
      } else {
        break {
          lhs_midpoint: bxbest,
          rhs_midpoint: bxybest - bxbest,
          lo_minimal: false, // left half is not optimal
          hi_minimal: true,
        }
      }
    } else {
      // Continue next round of search, edit distance increases by 1
      continue c + 1, fmin, fmax, bmin, bmax
    }
  }
}

///|
/// Main diff loop that computes the differences between two arrays
fn[T : Eq] diff_loop(
  cutoff : Int32?, // computation cost threshold
  lhs : CompactedElements[T],
  rhs : CompactedElements[T],
) -> (FixedArray[Bool], FixedArray[Bool]) {
  // Allocate working arrays for Myers algorithm
  // Array size is n+m+3, sufficient to contain all possible diagonals
  let forward_search_diagonal = FixedArray::make(
    lhs.indices_length() + rhs.indices_length() + 3,
    0,
  ) // forward search array
  let backward_search_diagonal = FixedArray::make(
    lhs.indices_length() + rhs.indices_length() + 3,
    0,
  ) // backward search array
  // shift k by rhs_indices.length()+1 so 
  // [-(rhs_indices.length()+1), lhs_indices.length()+1] -> [0, lhs_indices.length()+rhs_indices.length()+2]
  let diagonal_shift = rhs.indices_length() + 1
  // Determine computation cost threshold
  let too_expensive = match cutoff {
    Some(c) => c
    None => {
      // Default strategy: calculate reasonable threshold based on problem size
      // Use bit operations to quickly compute approximate square root
      let diags = lhs.indices_length() + rhs.indices_length() + 3
      for acc = 1, diags_cur = diags {
        if diags_cur != 0 {
          continue acc << 1, diags_cur >> 2
        } else {
          break acc.max(4096) // at least 4096, ensuring reasonable performance
        }
      }
    }
  }

  // Initialize change marker arrays
  // true indicates element is deleted/inserted, false indicates element unchanged
  let lhs_change_markers = FixedArray::make(lhs.source_length(), true)
  let rhs_change_markers = FixedArray::make(rhs.source_length(), true)

  // Preset common elements as unchanged
  for i in 0..<lhs.indices_length() {
    lhs_change_markers[lhs.get_index(i)] = false // lhs elements that also exist in rhs marked as unchanged
  }
  for j in 0..<rhs.indices_length() {
    rhs_change_markers[rhs.get_index(j)] = false // rhs elements that also exist in lhs marked as unchanged  
  }

  // Recursive function: implement divide-and-conquer strategy
  // Recursively apply Myers algorithm to each subregion
  fn loop_recursive(
    lhs_offset : Int32, // starting position of current lhs processing
    lhs_limit : Int32, // ending position of current lhs processing  
    rhs_offset : Int32, // starting position of current rhs processing
    rhs_limit : Int32, // ending position of current rhs processing
    find_minimal : Bool, // whether optimal solution needs to be found
  ) -> Unit {
    // Optimization: skip matching prefix
    // This is important optimization of Myers algorithm, reducing data to process
    let (lhs_offset, rhs_offset) = for lhs_offset = lhs_offset, rhs_offset = rhs_offset {
      if lhs_offset < lhs_limit &&
        rhs_offset < rhs_limit &&
        lhs[lhs_offset] == rhs[rhs_offset] {
        continue lhs_offset + 1, rhs_offset + 1
      } else {
        break (lhs_offset, rhs_offset)
      }
    }

    // Optimization: skip matching suffix
    let (lhs_limit, rhs_limit) = for lhs_limit = lhs_limit, rhs_limit = rhs_limit {
      if lhs_limit > lhs_offset &&
        rhs_limit > rhs_offset &&
        lhs[lhs_limit - 1] == rhs[rhs_limit - 1] {
        continue lhs_limit - 1, rhs_limit - 1
      } else {
        break (lhs_limit, rhs_limit)
      }
    }

    // Handle boundary cases
    if lhs_offset == lhs_limit {
      // Only insertions: A part exhausted, remaining B part all insertions
      for y in rhs_offset..<rhs_limit {
        rhs_change_markers[rhs.get_index(y)] = true
      }
    } else if rhs_offset == rhs_limit {
      // Only deletions: B part exhausted, remaining A part all deletions
      for x in lhs_offset..<lhs_limit {
        lhs_change_markers[lhs.get_index(x)] = true
      }
    } else {
      // General case: need to find partition point and recursively process
      let partition = diag(
        forward_search_diagonal~,
        backward_search_diagonal~,
        diagonal_shift~,
        lhs~,
        rhs~,
        lhs_offset~,
        lhs_limit~,
        rhs_offset~,
        rhs_limit~,
        too_expensive~,
        find_minimal~,
      )

      // Recursively process left half (before partition point)
      loop_recursive(
        lhs_offset,
        partition.lhs_midpoint,
        rhs_offset,
        partition.rhs_midpoint,
        partition.lo_minimal,
      )

      // Recursively process right half (after partition point)
      loop_recursive(
        partition.lhs_midpoint,
        lhs_limit,
        partition.rhs_midpoint,
        rhs_limit,
        partition.hi_minimal,
      )
    }
  }

  // Start recursively processing entire region
  loop_recursive(0, lhs.indices_length(), 0, rhs.indices_length(), false)
  (lhs_change_markers, rhs_change_markers)
}

///|
/// `make_indexer(a b)` returns an array of the indices of items of `a` which are also
/// present in `b`; this way, the main algorithm can skip items which, anyway, are
/// different. This improves the speed much without rewriting either input view.
fn[T : Eq + Hash] make_indexer(
  a : ArrayView[T],
  b : ArrayView[T],
) -> FixedArray[Int32] {
  let n = a.length()
  let present : Map[T, Bool] = Map([], capacity=b.length())

  for elem in b {
    present[elem] = true
  }
  let ai = FixedArray::make(n, 0) // temporary storage for valid indices
  let mut k = 0 // valid element count

  for i, elem in a {
    guard present.get(elem) is Some(_) else { () } // doesn't exist in b, skip
    ai[k] = i // record original index of this element
    k += 1
  }
  FixedArray::makei(k, i => ai[i])
}

///|
/// Main function that computes diff between two arrays
fn[T : Eq + Hash] diff_(
  cutoff : Int32?,
  lhs : ArrayView[T],
  rhs : ArrayView[T],
) -> (FixedArray[Bool], FixedArray[Bool]) {
  // Generate indexers: find elements that also exist in other array
  let lhs_indices = make_indexer(lhs, rhs) // indices of lhs elements that exist in rhs
  let rhs_indices = make_indexer(rhs, lhs) // indices of rhs elements that exist in lhs

  let lhs = CompactedElements((lhs, lhs_indices))
  let rhs = CompactedElements((rhs, rhs_indices))
  // Call main loop for difference computation
  diff_loop(cutoff, lhs, rhs)
}

///|
fn[T : Eq + Hash] append_myers_matches(
  builder : EditBuilder,
  cutoff : Int32?,
  old : ArrayView[T],
  new : ArrayView[T],
  old_offset : Int32,
  new_offset : Int32,
) -> Unit {
  if old.is_empty() || new.is_empty() {
    return
  }
  let (old_changed, new_changed) = diff_(cutoff, old, new)
  builder.append_unchanged_runs(
    old_changed, new_changed, old_offset, new_offset,
  )
}

///|
/// Pair unchanged elements in order, emitting adjacent matches as one run.
fn EditBuilder::append_unchanged_runs(
  self : EditBuilder,
  old_changed : FixedArray[Bool],
  new_changed : FixedArray[Bool],
  old_offset : Int32,
  new_offset : Int32,
) -> Unit {
  let mut i = 0
  let mut j = 0
  while i < old_changed.length() && j < new_changed.length() {
    if old_changed[i] {
      i += 1
    } else if new_changed[j] {
      j += 1
    } else {
      let start = i
      let new_start = j
      i += 1
      j += 1
      while i < old_changed.length() &&
            j < new_changed.length() &&
            !old_changed[i] &&
            !new_changed[j] {
        i += 1
        j += 1
      }
      self.push_run(old_offset + start, new_offset + new_start, i - start)
    }
  }
}

///|
fn[T : Eq + Hash] append_patience_matches(
  builder : EditBuilder,
  cutoff : Int32?,
  old : ArrayView[T],
  new : ArrayView[T],
  old_offset : Int32,
  new_offset : Int32,
) -> Unit {
  let anchors = unique_lcs(old~, new~)
  if anchors.is_empty() {
    append_myers_matches(builder, cutoff, old, new, old_offset, new_offset)
    return
  }

  // Patience diff only selects one layer of unique anchors here.
  // Bram Cohen noted that recursively searching subranges did not feel
  // better in practice: https://bramcohen.livejournal.com/73318.html
  // so unmatched gaps fall back to Myers instead of recursing.
  let mut prev_old_idx = 0
  let mut prev_new_idx = 0
  for (old_idx, new_idx) in anchors {
    append_myers_matches(
      builder,
      cutoff,
      old.exact_view(start=prev_old_idx, end=old_idx),
      new.exact_view(start=prev_new_idx, end=new_idx),
      old_offset + prev_old_idx,
      new_offset + prev_new_idx,
    )
    builder.push_run(old_offset + old_idx, new_offset + new_idx, 1)
    prev_old_idx = old_idx + 1
    prev_new_idx = new_idx + 1
  }

  append_myers_matches(
    builder,
    cutoff,
    old.exact_view(start=prev_old_idx, end=old.length()),
    new.exact_view(start=prev_new_idx, end=new.length()),
    old_offset + prev_old_idx,
    new_offset + prev_new_idx,
  )
}

///|
/// Diff algorithm used by `Diff::Diff`.
///
/// `Myers` computes a shortest edit script directly. `Patience` first uses
/// unique matching elements as anchors, then applies Myers to the ranges
/// between adjacent anchors.
///
/// This set may grow (e.g. a histogram variant); treat it as a configuration
/// input to construct rather than a type to match exhaustively.
#derive(Eq, @debug.Debug)
pub(all) enum DiffAlgorithm {
  Myers
  Patience
}

///|
/// A diff result containing the compared inputs and the edit script between
/// them.
///
/// The type is abstract: the edit script maintains invariants (edit ranges are
/// in bounds, monotone, and cover both inputs) that `group` relies on, so it is
/// only exposed as a read-only view via `edits`.
struct Diff[T] {
  old : ArrayView[T]
  new : ArrayView[T]
  edits : Array[Edit]
}

///|
/// The edit script that transforms `old` into `new`, as a read-only view.
pub fn[T] Diff::edits(self : Diff[T]) -> ArrayView[Edit] {
  self.edits
}

///|
/// The original input sequence, as passed to the constructor.
pub fn[T] Diff::old_view(self : Diff[T]) -> ArrayView[T] {
  self.old
}

///|
/// The updated input sequence, as passed to the constructor.
pub fn[T] Diff::new_view(self : Diff[T]) -> ArrayView[T] {
  self.new
}

///|
/// `Diff(old~, new~, cutoff?, algorithm?)` diffs `old` and `new`
/// (as in /usr/bin/diff),
/// and returns a `Diff[T]` bundling the source arrays with the edit script
/// that transforms `old` into `new`.
///
/// The `cutoff` is a budget in *edit-distance units*: as long as the minimum
/// edit distance stays within it, the result is minimal; beyond it the search
/// falls back to heuristics and the result is correct but not necessarily
/// minimal. The default is about the square root of the compacted input sizes
/// (elements present in both sequences), floored at 4096 so small inputs are
/// always minimal; values `<= 0` make the search rely on heuristics
/// immediately (still correct).
///
/// The `algorithm` selects the diff strategy. `Myers` (the default) uses the
/// classic Myers O(ND) algorithm. `Patience` first finds elements unique to
/// both inputs as anchors, then runs Myers on the unmatched ranges between them.
///
pub fn[T : Hash + Eq] Diff::Diff(
  old~ : ArrayView[T],
  new~ : ArrayView[T],
  cutoff? : Int32,
  algorithm~ : DiffAlgorithm = Myers,
) -> Diff[T] {
  let builder : EditBuilder = {
    edits: Array(capacity=old.length() + new.length()),
    old_pos: 0,
    new_pos: 0,
    equal_len: 0,
  }
  match algorithm {
    Patience => append_patience_matches(builder, cutoff, old, new, 0, 0)
    Myers => append_myers_matches(builder, cutoff, old, new, 0, 0)
  }
  builder.flush(old.length(), new.length())
  { old, new, edits: builder.edits, }
}

///|
/// The cursors point just past the last match. Adjacent matches form a single Equal edit.
priv struct EditBuilder {
  edits : Array[Edit]
  mut old_pos : Int32
  mut new_pos : Int32
  mut equal_len : Int32
}

///|
fn EditBuilder::push_run(
  self : EditBuilder,
  old_idx : Int32,
  new_idx : Int32,
  len : Int32,
) -> Unit {
  if self.old_pos != old_idx || self.new_pos != new_idx {
    self.flush(old_idx, new_idx)
  }
  self.old_pos = old_idx + len
  self.new_pos = new_idx + len
  self.equal_len += len
}

///|
fn EditBuilder::flush(
  self : EditBuilder,
  old_end : Int32,
  new_end : Int32,
) -> Unit {
  if self.equal_len > 0 {
    self.edits.push(
      Equal(
        old_index=self.old_pos - self.equal_len,
        new_index=self.new_pos - self.equal_len,
        len=self.equal_len,
      ),
    )
    self.equal_len = 0
  }
  if self.old_pos < old_end {
    self.edits.push(
      Delete(
        old_index=self.old_pos,
        old_len=old_end - self.old_pos,
        new_index=self.new_pos,
      ),
    )
  }
  if self.new_pos < new_end {
    self.edits.push(
      Insert(
        old_index=old_end,
        new_index=self.new_pos,
        new_len=new_end - self.new_pos,
      ),
    )
  }
}

///|
/// Group nearby edits into hunks, keeping `context` unchanged elements around
/// each change cluster (like `diff -U context`). `context` must be
/// non-negative; `context=0` emits hunks without surrounding context.
pub fn[T] Diff::group(self : Diff[T], context~ : Int32 = 3) -> Array[Hunk[T]] {
  group_edits(self.edits, context~, old=self.old, new=self.new)
}
