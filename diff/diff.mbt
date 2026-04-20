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
  lhs_midpoint : Int // position of midpoint in sequence lhs
  rhs_midpoint : Int // position of midpoint in sequence rhs
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
  forward_search_diagonal~ : FixedArray[Int], // forward search diagonal array - stores farthest reachable point on each diagonal
  backward_search_diagonal~ : FixedArray[Int], // backward search diagonal array - stores nearest reachable point on each diagonal
  diagonal_shift~ : Int, // diagonal index shift: store diagonal k at [sh + k], including negative k and k±1/k±2 neighbors
  lhs~ : CompactedElements[T], // compacted elements for sequence lhs
  rhs~ : CompactedElements[T], // compacted elements for sequence rhs
  lhs_offset~ : Int, // starting position of sequence lhs - defines left boundary of search window
  lhs_limit~ : Int, // ending position of sequence lhs - defines right boundary of search window
  rhs_offset~ : Int, // starting position of sequence rhs - defines upper boundary of search window  
  rhs_limit~ : Int, // ending position of sequence rhs - defines lower boundary of search window
  too_expensive~ : Int, // computation cost threshold - use heuristic algorithm when exceeded
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
  cutoff : Int?, // computation cost threshold
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
    lhs_offset : Int, // starting position of current lhs processing
    lhs_limit : Int, // ending position of current lhs processing  
    rhs_offset : Int, // starting position of current rhs processing
    rhs_limit : Int, // ending position of current rhs processing
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
) -> FixedArray[Int] {
  let n = a.length()
  let present : Map[T, Bool] = Map::new(capacity=b.length())

  for i in 0..<b.length() {
    present[b[i]] = true
  }
  let ai = FixedArray::make(n, 0) // temporary storage for valid indices
  let mut k = 0 // valid element count

  for i in 0..<n {
    match present.get(a[i]) {
      Some(_) => {
        ai[k] = i // record original index of this element
        k += 1
      }
      None => () // doesn't exist in b, skip
    }
  }
  let result = FixedArray::make(k, 0)
  for i in 0..<k {
    result[i] = ai[i]
  }
  result
}

///|
/// Main function that computes diff between two arrays
fn[T : Eq + Hash] diff_(
  cutoff : Int?,
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
/// `iter_matches(old~, new~, cutoff?)` diffs `old` and `new` (as in /usr/bin/diff),
/// and returns index pair of longest common subsequence in increasing order. 
///
/// The `cutoff` is an upper bound on the minimum edit distance between `old~` and `new~`. When
/// `cutoff` is exceeded, `iter_matches` returns a correct, but not necessarily minimal
/// diff. It defaults to about `sqrt(old.length() + new.length())`.
fn[T : Eq + Hash] iter_matches(
  cutoff~ : Int?, // optional computation cost limit
  old~ : ArrayView[T], // original array
  new~ : ArrayView[T], // new array
) -> Iter2[Int, Int] {
  // First compute difference markers
  let (d1, d2) = diff_(cutoff, old, new)
  let mut i1 = 0
  let mut i2 = 0
  fn go() {
    // traverse two arrays, find unchanged element pairs
    if i1 >= d1.length() || i2 >= d2.length() {
      return None // reached end of arrays
    } else if !d1[i1] {
      // old[i1] unchanged
      if !d2[i2] {
        // new[i2] also unchanged - found matching pair
        let matching_pair = (i1, i2)
        i1 += 1
        i2 += 1
        return Some(matching_pair)
      } else {
        // new[i2] changed (insertion) - skip element in new
        i2 += 1
        go()
      }
    } else if !d2[i2] {
      // old[i1] changed but new[i2] didn't (deletion) - skip element in old  
      i1 += 1
      go()
    } else {
      // both elements changed - skip both and find next possible match
      i1 += 1
      i2 += 1
      go()
    }
  }

  Iter2::new(go)
}

///|
fn[T : Eq + Hash] append_myers_matches(
  matches : Array[(Int, Int)],
  cutoff : Int?,
  old : ArrayView[T],
  new : ArrayView[T],
  old_offset : Int,
  new_offset : Int,
) -> Unit {
  for old_idx, new_idx in iter_matches(cutoff~, old~, new~) {
    matches.push((old_offset + old_idx, new_offset + new_idx))
  }
}

///|
fn[T : Eq + Hash] append_patience_matches(
  matches : Array[(Int, Int)],
  cutoff : Int?,
  old : ArrayView[T],
  new : ArrayView[T],
  old_offset : Int,
  new_offset : Int,
) -> Unit {
  let anchors = unique_lcs(old~, new~)
  if anchors.length() == 0 {
    append_myers_matches(matches, cutoff, old, new, old_offset, new_offset)
    return
  }

  // Patience diff only selects one layer of unique anchors here.
  // Bram Cohen noted that recursively searching subranges did not feel
  // better in practice: https://bramcohen.livejournal.com/73318.html
  // so unmatched gaps fall back to Myers instead of recursing.
  let mut prev_old_idx = 0
  let mut prev_new_idx = 0
  for i in 0..<anchors.length() {
    let (old_idx, new_idx) = anchors[i]
    append_myers_matches(
      matches,
      cutoff,
      old.view(start=prev_old_idx, end=old_idx),
      new.view(start=prev_new_idx, end=new_idx),
      old_offset + prev_old_idx,
      new_offset + prev_new_idx,
    )
    matches.push((old_offset + old_idx, new_offset + new_idx))
    prev_old_idx = old_idx + 1
    prev_new_idx = new_idx + 1
  }

  append_myers_matches(
    matches,
    cutoff,
    old.view(start=prev_old_idx, end=old.length()),
    new.view(start=prev_new_idx, end=new.length()),
    old_offset + prev_old_idx,
    new_offset + prev_new_idx,
  )
}

///|
pub(all) enum DiffAlgorithm {
  Myers
  Patience
}

///|
fn[T : Eq + Hash] collect_matches(
  cutoff : Int?,
  old : ArrayView[T],
  new : ArrayView[T],
  algorithm : DiffAlgorithm,
) -> Array[(Int, Int)] {
  let matches = Array::new(capacity=old.length().min(new.length()))
  match algorithm {
    Patience => append_patience_matches(matches, cutoff, old, new, 0, 0)
    Myers => append_myers_matches(matches, cutoff, old, new, 0, 0)
  }
  matches
}

///|
pub struct Diff[T] {
  old : ArrayView[T]
  new : ArrayView[T]
  edits : Array[Edit]

  fn[T : Hash + Eq] new(
    old~ : ArrayView[T],
    new~ : ArrayView[T],
    cutoff? : Int,
    algorithm? : DiffAlgorithm,
  ) -> Diff[T]
}

///|
/// `Diff::new(old~, new~, cutoff?, algorithm?)` diffs `old` and `new`
/// (as in /usr/bin/diff),
/// and returns a `Diff[T]` bundling the source arrays with the edit script
/// that transforms `old` into `new`.
///
/// The `cutoff` is an upper bound on the minimum edit distance between `old~` and `new~`. When
/// `cutoff` is exceeded, the result is a correct, but not necessarily minimal
/// diff. It defaults to about `sqrt(old.length() + new.length())`.
///
/// The `algorithm` selects the diff strategy. `Myers` (the default) uses the
/// classic Myers O(ND) algorithm. `Patience` first finds elements unique to
/// both inputs as anchors, then runs Myers on the unmatched ranges between them.
///
fn[T : Hash + Eq] Diff::new(
  old~ : ArrayView[T],
  new~ : ArrayView[T],
  cutoff? : Int,
  algorithm? : DiffAlgorithm = Myers,
) -> Diff[T] {
  let result : Array[Edit] = Array::new(capacity=old.length() + new.length())
  let matches = collect_matches(cutoff, old, new, algorithm)
  let mut prev_old_idx = 0
  let mut prev_new_idx = 0
  let mut equal_old_idx = 0
  let mut equal_new_idx = 0
  let mut consecutive_equal_length = 0
  for pair in matches {
    let (old_idx, new_idx) = pair
    // emit delete
    if prev_old_idx != old_idx {
      if consecutive_equal_length != 0 {
        result.push(
          Equal(
            old_index=equal_old_idx,
            new_index=equal_new_idx,
            len=consecutive_equal_length,
          ),
        )
      }
      consecutive_equal_length = 0
      result.push(
        Delete(
          old_index=prev_old_idx,
          new_index=prev_new_idx,
          len=old_idx - prev_old_idx,
        ),
      )
      prev_old_idx = old_idx
    }
    // emit insert
    if prev_new_idx != new_idx {
      if consecutive_equal_length != 0 {
        result.push(
          Equal(
            old_index=equal_old_idx,
            new_index=equal_new_idx,
            len=consecutive_equal_length,
          ),
        )
      }
      consecutive_equal_length = 0
      result.push(
        Insert(
          old_index=prev_old_idx,
          new_index=prev_new_idx,
          len=new_idx - prev_new_idx,
        ),
      )
    }
    prev_old_idx = old_idx + 1
    prev_new_idx = new_idx + 1
    // emit equal
    if consecutive_equal_length == 0 {
      equal_old_idx = old_idx
      equal_new_idx = new_idx
      consecutive_equal_length = 1
    } else {
      consecutive_equal_length += 1
    }
  } nobreak {
    // emit remain equal
    if consecutive_equal_length != 0 {
      result.push(
        Equal(
          old_index=equal_old_idx,
          new_index=equal_new_idx,
          len=consecutive_equal_length,
        ),
      )
    }
    // emit remaining deletions
    if prev_old_idx != old.length() {
      result.push(
        Delete(
          old_index=prev_old_idx,
          new_index=prev_new_idx,
          len=old.length() - prev_old_idx,
        ),
      )
      // update prev_old_idx
      prev_old_idx = old.length()
    }

    // emit remaining insertions

    if prev_new_idx != new.length() {
      result.push(
        Insert(
          old_index=prev_old_idx,
          new_index=prev_new_idx,
          len=new.length() - prev_new_idx,
        ),
      )
    }
    return { old, new, edits: result }
  }
}

///|
pub fn[T] Diff::group(self : Diff[T], radius? : Int = 3) -> Array[Hunk[T]] {
  group_edits(self.edits, radius~, old=self.old, new=self.new)
}
