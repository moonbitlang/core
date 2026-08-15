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
/// Central QuickCheck knobs, shared by every property in this file so the
/// suite's CI cost is tunable in one place. With these settings the whole
/// diff package tests in well under a second per target.
const QC_COUNT : UInt = 200

///|
const QC_MAX_SIZE : UInt = 100

///|
/// The repetitive two-symbol property deliberately uses longer sequences,
/// since repetition is what stresses the Myers diagonal bookkeeping.
const QC_LONG_MAX_SIZE : UInt = 200

///|
/// The kind of the edit preceding the current one while scanning a script.
/// Used to enforce the documented adjacency rules: adjacent edits of the
/// same kind must be coalesced, and a replacement is emitted as `Delete`
/// before `Insert`, so a delete may never directly follow an insert.
enum PrevEdit {
  ScriptStart
  DeleteRun
  InsertRun
  EqualRun
  ReplaceRun
}

///|
/// Clamp every element into a small alphabet (`mask` must be `2^k - 1`).
/// A small alphabet forces repeated elements, which is where diff algorithms
/// actually have to work; unrelated random arrays share almost nothing.
fn confine(a : Array[Int], mask : Int) -> Array[Int] {
  a.map(x => x & mask)
}

///|
/// Derive a second sequence from `base` by applying small random edits
/// (insert, delete, substitute, duplicate a block, move a block, append,
/// swap, no-op), so generated pairs share nontrivial structure.
fn mutate(
  base : Array[Int],
  ops : Array[(Int, Int, Int)],
  mask : Int,
) -> Array[Int] {
  let out = base.copy()
  for op in ops {
    let kind = op.0 & 7
    let pos = op.1 & 0x3FFFFFFF
    let value = op.2 & mask
    match kind {
      0 => out.insert(pos % (out.length() + 1), value)
      1 => if !out.is_empty() { out.remove(pos % out.length()) |> ignore }
      2 => if !out.is_empty() { out[pos % out.length()] = value }
      3 =>
        // duplicate a short block right after itself
        if !out.is_empty() {
          let start = pos % out.length()
          let stop = (start + (op.2 & 3) + 1).min(out.length())
          let block : Array[Int] = []
          for k in start..<stop {
            block.push(out[k])
          }
          for i, x in block {
            out.insert(stop + i, x)
          }
        }
      4 =>
        // move a short block to the front
        if !out.is_empty() {
          let start = pos % out.length()
          let stop = (start + (op.2 & 3) + 1).min(out.length())
          let block : Array[Int] = []
          for k in start..<stop {
            block.push(out[k])
          }
          for _ in start..<stop {
            out.remove(start) |> ignore
          }
          for i, x in block {
            out.insert(i, x)
          }
        }
      5 => out.push(value)
      6 =>
        if out.length() >= 2 {
          let i = pos % out.length()
          let j = pos / 3 % out.length()
          let t = out[i]
          out[i] = out[j]
          out[j] = t
        }
      _ => () // no-op keeps some pairs identical
    }
  }
  out
}

///|
/// Check every documented invariant of a `Diff` edit script against its
/// inputs: both cursors advance contiguously from zero and cover both inputs
/// completely, no edit has zero length, adjacent edits of the same kind are
/// coalesced, a replacement is `Delete` before `Insert` (never the reverse),
/// `Equal` runs pair equal elements — and replaying the script (keep for
/// `Equal`, skip for `Delete`, emit for `Insert`) reproduces `new` exactly.
fn script_ok(
  old : Array[Int],
  new : Array[Int],
  edits : ArrayView[@diff.Edit],
) -> Bool {
  let out : Array[Int] = []
  let mut oi = 0
  let mut ni = 0
  let mut prev : PrevEdit = ScriptStart
  for e in edits {
    match e {
      Delete(old_index~, old_len~, new_index~) => {
        if old_index != oi || new_index != ni || old_len <= 0 {
          return false
        }
        if oi + old_len > old.length() {
          return false
        }
        // adjacent deletes are coalesced; a replacement is Delete then
        // Insert, so a delete directly after an insert must not appear
        if prev is (DeleteRun | InsertRun) {
          return false
        }
        oi += old_len
        prev = DeleteRun
      }
      Insert(old_index~, new_index~, new_len~) => {
        if old_index != oi || new_index != ni || new_len <= 0 {
          return false
        }
        if ni + new_len > new.length() {
          return false
        }
        if prev is InsertRun {
          return false
        }
        for k in ni..<(ni + new_len) {
          out.push(new[k])
        }
        ni += new_len
        prev = InsertRun
      }
      Equal(old_index~, new_index~, len~) => {
        if old_index != oi || new_index != ni || len <= 0 {
          return false
        }
        if oi + len > old.length() || ni + len > new.length() {
          return false
        }
        if prev is EqualRun {
          return false
        }
        for k in 0..<len {
          if old[oi + k] != new[ni + k] {
            return false
          }
          out.push(old[oi + k])
        }
        oi += len
        ni += len
        prev = EqualRun
      }
    }
  }
  oi == old.length() && ni == new.length() && out == new
}

///|
/// The insert/delete cost of an edit script: every inserted or deleted
/// element counts 1, so a replacement costs 2.
fn indel_cost(edits : ArrayView[@diff.Edit]) -> Int {
  let mut cost = 0
  for e in edits {
    match e {
      Delete(old_len~, ..) => cost += old_len
      Insert(new_len~, ..) => cost += new_len
      Equal(..) => ()
    }
  }
  cost
}

///|
/// Same well-formedness-plus-replay check for a Levenshtein script, with the
/// extra `Replace` rules: it advances both cursors, pairs elements
/// one-to-one, and every pair is unequal. The documented tie-break — a
/// deletion is always emitted before an adjacent insertion — is also checked.
fn lev_ok(
  old : Array[Int],
  new : Array[Int],
  edits : Array[@diff.LevenshteinEdit],
) -> Bool {
  let out : Array[Int] = []
  let mut oi = 0
  let mut ni = 0
  let mut prev : PrevEdit = ScriptStart
  for e in edits {
    match e {
      Delete(old_index~, old_len~, new_index~) => {
        if old_index != oi || new_index != ni || old_len <= 0 {
          return false
        }
        if oi + old_len > old.length() {
          return false
        }
        if prev is (DeleteRun | InsertRun) {
          return false
        }
        oi += old_len
        prev = DeleteRun
      }
      Insert(old_index~, new_index~, new_len~) => {
        if old_index != oi || new_index != ni || new_len <= 0 {
          return false
        }
        if ni + new_len > new.length() {
          return false
        }
        if prev is InsertRun {
          return false
        }
        for k in ni..<(ni + new_len) {
          out.push(new[k])
        }
        ni += new_len
        prev = InsertRun
      }
      Equal(old_index~, new_index~, len~) => {
        if old_index != oi || new_index != ni || len <= 0 {
          return false
        }
        if oi + len > old.length() || ni + len > new.length() {
          return false
        }
        if prev is EqualRun {
          return false
        }
        for k in 0..<len {
          if old[oi + k] != new[ni + k] {
            return false
          }
          out.push(old[oi + k])
        }
        oi += len
        ni += len
        prev = EqualRun
      }
      Replace(old_index~, new_index~, len~) => {
        if old_index != oi || new_index != ni || len <= 0 {
          return false
        }
        if oi + len > old.length() || ni + len > new.length() {
          return false
        }
        if prev is ReplaceRun {
          return false
        }
        for k in 0..<len {
          if old[oi + k] == new[ni + k] {
            return false
          }
          out.push(new[ni + k])
        }
        oi += len
        ni += len
        prev = ReplaceRun
      }
    }
  }
  oi == old.length() && ni == new.length() && out == new
}

///|
/// The cost of a Levenshtein script: every inserted, deleted, or replaced
/// element counts exactly 1.
fn lev_cost(edits : Array[@diff.LevenshteinEdit]) -> Int {
  let mut cost = 0
  for e in edits {
    match e {
      Delete(old_len~, ..) => cost += old_len
      Insert(new_len~, ..) => cost += new_len
      Replace(len~, ..) => cost += len
      Equal(..) => ()
    }
  }
  cost
}

///|
fn old_span(e : @diff.Edit) -> (Int, Int) {
  match e {
    Delete(old_index~, old_len~, ..) => (old_index, old_index + old_len)
    Insert(old_index~, ..) => (old_index, old_index)
    Equal(old_index~, len~, ..) => (old_index, old_index + len)
  }
}

///|
fn new_span(e : @diff.Edit) -> (Int, Int) {
  match e {
    Delete(new_index~, ..) => (new_index, new_index)
    Insert(new_index~, new_len~, ..) => (new_index, new_index + new_len)
    Equal(new_index~, len~, ..) => (new_index, new_index + len)
  }
}

///|
/// The unified-diff range text documented for hunk headers. Non-empty
/// ranges use 1-based line numbers, and single-line ranges omit the
/// length. An empty range is anchored to the line *before* the range, so
/// its rendered anchor is that previous line's 1-based number — legally
/// `0` when the range sits before the first line, as in `@@ -0,0 +1 @@`
/// for an insertion at the start of a file.
fn range_text(start : Int, len : Int) -> String {
  if len == 1 {
    (start + 1).to_string()
  } else if len == 0 {
    "\{start},0"
  } else {
    "\{start + 1},\{len}"
  }
}

///|
/// Apply a grouped hunk list back onto `old` as a patch tool would: copy the
/// untouched elements between hunks from `old`, replay each hunk's edits,
/// and require the result to be exactly `new`. Along the way check that each
/// hunk is non-empty and internally contiguous, that its edits have positive
/// lengths, that the gaps between hunks align on both sides, that
/// `old_view`/`new_view` are the complete inputs, that the header matches
/// the documented `@@ -a,b +c,d @@` numbering, and that `render` emits one
/// line per element plus the header.
fn hunks_ok(
  old : Array[Int],
  new : Array[Int],
  hunks : Array[@diff.Hunk[Int]],
) -> Bool {
  let out : Array[Int] = []
  let mut oi = 0
  for h in hunks {
    if h.old_view().length() != old.length() ||
      h.new_view().length() != new.length() {
      return false
    }
    let edits = h.edits()
    if edits.length() == 0 {
      return false
    }
    let (start_old, _) = old_span(edits[0])
    let (start_new, _) = new_span(edits[0])
    // elements between hunks are unchanged and must align on both sides
    if start_old < oi || start_old - oi != start_new - out.length() {
      return false
    }
    for k in oi..<start_old {
      out.push(old[k])
    }
    let mut co = start_old
    let mut cn = start_new
    let mut elems = 0
    for e in edits {
      match e {
        Delete(old_index~, old_len~, new_index~) => {
          if old_index != co || new_index != cn || old_len <= 0 {
            return false
          }
          if co + old_len > old.length() {
            return false
          }
          co += old_len
          elems += old_len
        }
        Insert(old_index~, new_index~, new_len~) => {
          if old_index != co || new_index != cn || new_len <= 0 {
            return false
          }
          if cn + new_len > new.length() {
            return false
          }
          for k in cn..<(cn + new_len) {
            out.push(new[k])
          }
          cn += new_len
          elems += new_len
        }
        Equal(old_index~, new_index~, len~) => {
          if old_index != co || new_index != cn || len <= 0 {
            return false
          }
          if co + len > old.length() || cn + len > new.length() {
            return false
          }
          for k in 0..<len {
            if old[co + k] != new[cn + k] {
              return false
            }
            out.push(old[co + k])
          }
          co += len
          cn += len
          elems += len
        }
      }
    }
    let expected_header = "@@ -\{range_text(start_old, co - start_old)} +\{range_text(start_new, cn - start_new)} @@"
    if h.header() != expected_header {
      return false
    }
    let mut lines = 0
    for c in h.render(show=x => x.to_string()) {
      if c == '\n' {
        lines += 1
      }
    }
    if lines != 1 + elems {
      return false
    }
    oi = co
  }
  for k in oi..<old.length() {
    out.push(old[k])
  }
  out == new
}

///|
/// The `Delete`/`Insert` edits of a script, in order.
fn changes(edits : ArrayView[@diff.Edit]) -> Array[@diff.Edit] {
  let out : Array[@diff.Edit] = []
  for e in edits {
    match e {
      Equal(..) => ()
      _ => out.push(e)
    }
  }
  out
}

///|
fn to_text(a : Array[Int]) -> String {
  let buf = StringBuilder::new()
  for x in a {
    buf.write_char(
      match x & 3 {
        0 => 'a'
        1 => 'b'
        2 => 'c'
        _ => 'd'
      },
    )
  }
  buf.to_string()
}

///|
test "quickcheck: myers scripts are well-formed and replay old into new" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)])) => {
      let old = confine(input.0, 3)
      let new = mutate(old, input.1, 3)
      let forward = @diff.Diff(old~, new~)
      let backward = @diff.Diff(old=new, new=old)
      script_ok(old, new, forward.edits()) &&
      script_ok(new, old, backward.edits())
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: patience scripts are well-formed and replay old into new" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)])) => {
      let old = confine(input.0, 3)
      let new = mutate(old, input.1, 3)
      let forward = @diff.Diff(old~, new~, algorithm=Patience)
      let backward = @diff.Diff(old=new, new=old, algorithm=Patience)
      script_ok(old, new, forward.edits()) &&
      script_ok(new, old, backward.edits())
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: tiny cutoffs force heuristics but stay sound" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)], Int)) => {
      let old = confine(input.0, 3)
      let new = mutate(old, input.1, 3)
      let cutoff = input.2 & 3 // 0 relies on heuristics immediately
      script_ok(old, new, @diff.Diff(old~, new~, cutoff~).edits()) &&
      script_ok(
        old,
        new,
        @diff.Diff(old~, new~, cutoff~, algorithm=Patience).edits(),
      )
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: repetitive two-symbol inputs stress the diagonal bookkeeping" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)])) => {
      let old = confine(input.0, 1)
      let new = mutate(old, input.1, 1)
      script_ok(old, new, @diff.Diff(old~, new~).edits()) &&
      script_ok(old, new, @diff.Diff(old~, new~, algorithm=Patience).edits())
    },
    count=QC_COUNT,
    max_size=QC_LONG_MAX_SIZE,
  )
}

///|
test "quickcheck: degenerate pairs produce canonical scripts" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int])) => {
      let a = confine(input.0, 3)
      let b = confine(input.1, 3)
      let empty : Array[Int] = []
      let same = @diff.Diff(old=a, new=a)
      guard script_ok(a, a, same.edits()) && same.edits() is ([] | [Equal(..)]) else {
        return false
      }
      let del = @diff.Diff(old=a, new=empty)
      guard script_ok(a, empty, del.edits()) &&
        del.edits() is ([] | [Delete(..)]) else {
        return false
      }
      let ins = @diff.Diff(old=empty, new=a)
      guard script_ok(empty, a, ins.edits()) &&
        ins.edits() is ([] | [Insert(..)]) else {
        return false
      }
      // a prefix pair and a suffix pair
      let ab = a.copy()
      ab.append(b)
      script_ok(a, ab, @diff.Diff(old=a, new=ab).edits()) &&
      script_ok(ab, b, @diff.Diff(old=ab, new=b).edits())
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: minimal myers cost brackets the levenshtein distance" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)])) => {
      let old = confine(input.0, 3)
      let new = mutate(old, input.1, 3)
      // The default cutoff is at least 4096, far above any distance these
      // inputs can reach, so the Myers script is minimal for its metric: a
      // replacement costs 2 here and 1 in Levenshtein, hence the bracket.
      let cost = indel_cost(@diff.Diff(old~, new~).edits())
      let lev = @diff.edit_distance(old, new)
      lev <= cost && cost <= 2 * lev && (cost == 0) == (old == new)
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: levenshtein scripts replay and cost exactly the distance" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)])) => {
      let old = confine(input.0, 3)
      let new = mutate(old, input.1, 3)
      let edits = @diff.levenshtein_edits(old~, new~)
      lev_ok(old, new, edits) &&
      lev_cost(edits) == @diff.edit_distance(old, new)
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: levenshtein degenerate scripts match their contract" {
  @quickcheck.check(
    (a : Array[Int]) => {
      let a = confine(a, 3)
      let empty : Array[Int] = []
      @diff.levenshtein_edits(old=a, new=a) is ([] | [Equal(..)]) &&
      @diff.levenshtein_edits(old=a, new=empty) is ([] | [Delete(..)]) &&
      @diff.levenshtein_edits(old=empty, new=a) is ([] | [Insert(..)])
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: edit distance is a metric on correlated triples" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)], Array[(Int, Int, Int)])) => {
      let a = confine(input.0, 3)
      let b = mutate(a, input.1, 3)
      let c = mutate(b, input.2, 3)
      let dab = @diff.edit_distance(a, b)
      let low = (a.length() - b.length()).abs()
      let high = a.length().max(b.length())
      dab == @diff.edit_distance(b, a) &&
      (dab == 0) == (a == b) &&
      low <= dab &&
      dab <= high &&
      @diff.edit_distance(a, c) <= dab + @diff.edit_distance(b, c)
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: banded distance agrees with the full distance" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)], Int)) => {
      let a = confine(input.0, 3)
      let b = mutate(a, input.1, 3)
      let d = @diff.edit_distance(a, b)
      let max = input.2 & 15
      let expected = if d <= max { Some(d) } else { None }
      @diff.edit_distance_within(a, b, max_distance=max) == expected &&
      @diff.edit_distance_within(a, b, max_distance=d) == Some(d) &&
      (d == 0 || @diff.edit_distance_within(a, b, max_distance=d - 1) is None)
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: string distance matches the generic distance on ascii" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)], Int)) => {
      let a = confine(input.0, 3)
      let b = mutate(a, input.1, 3)
      let sa = to_text(a)
      let sb = to_text(b)
      let d = @diff.edit_distance(a, b)
      let max = input.2 & 15
      let expected = if d <= max { Some(d) } else { None }
      @diff.edit_distance_str(sa, sb) == d &&
      @diff.edit_distance_str_within(sa, sb, max_distance=max) == expected
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}

///|
test "quickcheck: grouped hunks apply as a patch and keep every change" {
  @quickcheck.check(
    (input : (Array[Int], Array[(Int, Int, Int)], Int)) => {
      let old = confine(input.0, 3)
      let new = mutate(old, input.1, 3)
      let context = input.2 & 3 // includes context=0
      let algorithm : @diff.DiffAlgorithm = if (input.2 & 4) == 0 {
        Myers
      } else {
        Patience
      }
      let d = @diff.Diff(old~, new~, algorithm~)
      let hunks = d.group(context~)
      hunks_ok(old, new, hunks) &&
      ({
        let hunk_changes : Array[@diff.Edit] = []
        for h in hunks {
          hunk_changes.append(changes(h.edits()))
        }
        hunk_changes == changes(d.edits())
      })
    },
    count=QC_COUNT,
    max_size=QC_MAX_SIZE,
  )
}
