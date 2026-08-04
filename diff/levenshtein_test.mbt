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
/// Textbook full-matrix Levenshtein DP, used as the reference oracle.
fn reference_levenshtein(a : Array[Char], b : Array[Char]) -> Int {
  let m = a.length()
  let n = b.length()
  let dp = Array::makei(m + 1, _ => Array::makei(n + 1, j => j))
  for i in 0..<(m + 1) {
    dp[i][0] = i
  }
  for i in 1..<(m + 1) {
    for j in 1..<(n + 1) {
      let mut best = dp[i - 1][j - 1] +
        (if a[i - 1] == b[j - 1] { 0 } else { 1 })
      if dp[i - 1][j] + 1 < best {
        best = dp[i - 1][j] + 1
      }
      if dp[i][j - 1] + 1 < best {
        best = dp[i][j - 1] + 1
      }
      dp[i][j] = best
    }
  }
  dp[m][n]
}

///|
/// Verify the whole documented script contract — cursors advance
/// contiguously and cover both inputs, lengths are positive, `Equal` pairs
/// equal elements, `Replace` pairs unequal ones, adjacent same-kind edits are
/// coalesced, an `Insert` is never immediately followed by a `Delete` — and
/// that replaying the script on `old` rebuilds `new`. Returns the script
/// cost.
fn check_script(
  old : Array[Char],
  new : Array[Char],
  edits : Array[@diff.LevenshteinEdit],
) -> Int raise {
  let mut oi = 0
  let mut ni = 0
  let mut cost = 0
  let rebuilt : Array[Char] = []
  // 0 = delete, 1 = insert, 2 = equal, 3 = replace, -1 = none yet
  let mut prev_kind = -1
  for e in edits {
    match e {
      Delete(old_index~, old_len~, new_index~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(old_len > 0)
        assert_true(prev_kind != 0)
        // canonical scripts emit deletions before adjacent insertions
        assert_true(prev_kind != 1)
        oi += old_len
        cost += old_len
        prev_kind = 0
      }
      Insert(old_index~, new_index~, new_len~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(new_len > 0)
        assert_true(prev_kind != 1)
        for k in 0..<new_len {
          rebuilt.push(new[ni + k])
        }
        ni += new_len
        cost += new_len
        prev_kind = 1
      }
      Equal(old_index~, new_index~, len~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(len > 0)
        assert_true(prev_kind != 2)
        for k in 0..<len {
          assert_true(old[oi + k] == new[ni + k])
          rebuilt.push(old[oi + k])
        }
        oi += len
        ni += len
        prev_kind = 2
      }
      Replace(old_index~, new_index~, len~) => {
        assert_eq(old_index, oi)
        assert_eq(new_index, ni)
        assert_true(len > 0)
        assert_true(prev_kind != 3)
        for k in 0..<len {
          assert_true(old[oi + k] != new[ni + k])
          rebuilt.push(new[ni + k])
        }
        oi += len
        ni += len
        cost += len
        prev_kind = 3
      }
    }
  }
  assert_eq(oi, old.length())
  assert_eq(ni, new.length())
  assert_true(rebuilt == new)
  cost
}

///|
/// Encode a script as `(kind, old_index, new_index, len)` tuples where kind
/// is 0 = Equal, 1 = Replace, 2 = Delete, 3 = Insert, so scripts can be
/// compared against an oracle that cannot construct `LevenshteinEdit`.
fn to_tuples(
  edits : Array[@diff.LevenshteinEdit],
) -> Array[(Int, Int, Int, Int)] {
  edits.map(e => {
    match e {
      Equal(old_index~, new_index~, len~) => (0, old_index, new_index, len)
      Replace(old_index~, new_index~, len~) => (1, old_index, new_index, len)
      Delete(old_index~, old_len~, new_index~) =>
        (2, old_index, new_index, old_len)
      Insert(old_index~, new_index~, new_len~) =>
        (3, old_index, new_index, new_len)
    }
  })
}

///|
/// Oracle for the documented determinism contract: full suffix-distance
/// matrix, then a forward walk that at every cursor takes the diagonal
/// operation when it is optimal, else delete when optimal, else insert,
/// coalescing adjacent same-kind steps.
fn reference_canonical(
  a : Array[Char],
  b : Array[Char],
) -> Array[(Int, Int, Int, Int)] {
  let m = a.length()
  let n = b.length()
  let d = Array::makei(m + 1, _ => Array::make(n + 1, 0))
  for j in 0..<(n + 1) {
    d[m][j] = n - j
  }
  for i2 in 0..<m {
    let i = m - 1 - i2
    d[i][n] = m - i
    for j2 in 0..<n {
      let j = n - 1 - j2
      let mut best = d[i + 1][j + 1] + (if a[i] == b[j] { 0 } else { 1 })
      if d[i + 1][j] + 1 < best {
        best = d[i + 1][j] + 1
      }
      if d[i][j + 1] + 1 < best {
        best = d[i][j + 1] + 1
      }
      d[i][j] = best
    }
  }
  let out : Array[(Int, Int, Int, Int)] = []
  fn emit(kind : Int, oi : Int, ni : Int) {
    if out.length() > 0 {
      let (k, o, w, len) = out[out.length() - 1]
      if k == kind {
        out[out.length() - 1] = (k, o, w, len + 1)
        return
      }
    }
    out.push((kind, oi, ni, 1))
  }
  let mut i = 0
  let mut j = 0
  while i < m || j < n {
    if i < m &&
      j < n &&
      d[i][j] == d[i + 1][j + 1] + (if a[i] == b[j] { 0 } else { 1 }) {
      emit(if a[i] == b[j] { 0 } else { 1 }, i, j)
      i += 1
      j += 1
    } else if i < m && d[i][j] == d[i + 1][j] + 1 {
      emit(2, i, j)
      i += 1
    } else {
      emit(3, i, j)
      j += 1
    }
  }
  out
}

///|
/// UTF-16 code units of a string, for checking `edit_distance_str` against
/// the generic implementation.
fn units(s : String) -> Array[UInt16] {
  Array::makei(s.length(), i => s[i])
}

///|
test "edit_distance_str: code-unit semantics" {
  inspect(@diff.edit_distance_str("kitten", "sitting"), content="3")
  inspect(@diff.edit_distance_str("", ""), content="0")
  inspect(@diff.edit_distance_str("", "ab"), content="2")
  inspect(@diff.edit_distance_str("same", "same"), content="0")
  // an astral char is two units: unrelated astral substitution costs 2,
  // but astral chars sharing a high surrogate are one unit apart
  inspect(@diff.edit_distance_str("🙂", "🍎"), content="2")
  inspect(@diff.edit_distance_str("🍎", "🍏"), content="1")
  debug_inspect(
    @diff.edit_distance_str_within("kitten", "sitting", max_distance=3),
    content="Some(3)",
  )
  debug_inspect(
    @diff.edit_distance_str_within("kitten", "sitting", max_distance=2),
    content="None",
  )
  debug_inspect(
    @diff.edit_distance_str_within("a", "b", max_distance=-1),
    content="None",
  )
}

///|
test "edit_distance_str: differential against the generic implementation" {
  let pool = [
    "", "a", "b", "ab", "ba", "abc", "kitten", "sitting", "🍎", "🍏", "a🍎b",
    "🍎🍏", "🙂🍎", "x🙂", "🙂x", "aa🍎", "🍎aa",
  ]
  for x in pool {
    for y in pool {
      let expected = @diff.edit_distance(units(x), units(y))
      assert_eq(@diff.edit_distance_str(x, y), expected)
      for k in 0..<5 {
        match @diff.edit_distance_str_within(x, y, max_distance=k) {
          Some(d) => {
            assert_true(expected <= k)
            assert_eq(d, expected)
          }
          None => assert_true(expected > k)
        }
      }
    }
  }
}

///|
/// All strings over `alphabet` of length `0..=max_len`.
fn gen_strings(alphabet : Array[Char], max_len : Int) -> Array[Array[Char]] {
  let out : Array[Array[Char]] = [[]]
  let mut layer : Array[Array[Char]] = [[]]
  for _ in 0..<max_len {
    let next : Array[Array[Char]] = []
    for s in layer {
      for c in alphabet {
        let t = s.copy()
        t.push(c)
        next.push(t)
        out.push(t)
      }
    }
    layer = next
  }
  out
}

///|
test "edit_distance: distance basics" {
  inspect(
    @diff.edit_distance("kitten".to_array(), "sitting".to_array()),
    content="3",
  )
  inspect(
    @diff.edit_distance("flaw".to_array(), "lawn".to_array()),
    content="2",
  )
  inspect(@diff.edit_distance([1, 2, 3, 4], [1, 3, 2, 4]), content="2")
  inspect(
    @diff.edit_distance(([] : Array[Char]), ([] : Array[Char])),
    content="0",
  )
  inspect(@diff.edit_distance(([] : Array[Int]), [1, 2]), content="2")
  inspect(@diff.edit_distance([1, 2], ([] : Array[Int])), content="2")
  inspect(
    @diff.edit_distance("same".to_array(), "same".to_array()),
    content="0",
  )
}

///|
test "edit_distance: symmetric" {
  let pairs = [
    ("kitten", "sitting"),
    ("", "abc"),
    ("ab", "ba"),
    ("saturday", "sunday"),
  ]
  for pair in pairs {
    let (x, y) = pair
    assert_eq(
      @diff.edit_distance(x.to_array(), y.to_array()),
      @diff.edit_distance(y.to_array(), x.to_array()),
    )
  }
}

///|
test "edit_distance_within: thresholds and degenerate bounds" {
  let old = "kitten".to_array()
  let new = "sitting".to_array()
  debug_inspect(
    @diff.edit_distance_within(old, new, max_distance=3),
    content="Some(3)",
  )
  debug_inspect(
    @diff.edit_distance_within(old, new, max_distance=2),
    content="None",
  )
  debug_inspect(
    @diff.edit_distance_within(old, new, max_distance=1000000000),
    content="Some(3)",
  )
  debug_inspect(
    @diff.edit_distance_within(old, new, max_distance=-1),
    content="None",
  )
  debug_inspect(
    @diff.edit_distance_within(old, old, max_distance=0),
    content="Some(0)",
  )
  debug_inspect(
    @diff.edit_distance_within(old, new, max_distance=0),
    content="None",
  )
  // the length difference alone exceeds the bound
  debug_inspect(
    @diff.edit_distance_within(
      "ab".to_array(),
      "abcdef".to_array(),
      max_distance=3,
    ),
    content="None",
  )
}

///|
test "levenshtein_edits: canonical scripts" {
  // diagonal preferred at ties: both positions substitute, no indel pair
  debug_inspect(
    @diff.levenshtein_edits(old="ab".to_array(), new="ba".to_array()),
    content=(
      #|[Replace(old_index=0, new_index=0, len=2)]
    ),
  )
  // delete before insert around a kept middle
  debug_inspect(
    @diff.levenshtein_edits(old="abc".to_array(), new="bcd".to_array()),
    content=(
      #|[
      #|  Delete(old_index=0, old_len=1, new_index=0),
      #|  Equal(old_index=1, new_index=0, len=2),
      #|  Insert(old_index=3, new_index=2, new_len=1),
      #|]
    ),
  )
  debug_inspect(
    @diff.levenshtein_edits(old="kitten".to_array(), new="sitting".to_array()),
    content=(
      #|[
      #|  Replace(old_index=0, new_index=0, len=1),
      #|  Equal(old_index=1, new_index=1, len=3),
      #|  Replace(old_index=4, new_index=4, len=1),
      #|  Equal(old_index=5, new_index=5, len=1),
      #|  Insert(old_index=6, new_index=6, new_len=1),
      #|]
    ),
  )
}

///|
test "levenshtein_edits: repeated suffix does not pin the pairing" {
  // the greedy forward contract pairs old's 'a' with new[1], splitting the
  // insertions around it — not one Insert run followed by Equal at new[2]
  debug_inspect(
    @diff.levenshtein_edits(old="a".to_array(), new="baa".to_array()),
    content=(
      #|[
      #|  Insert(old_index=0, new_index=0, new_len=1),
      #|  Equal(old_index=0, new_index=1, len=1),
      #|  Insert(old_index=1, new_index=2, new_len=1),
      #|]
    ),
  )
}

///|
test "levenshtein_edits: degenerate inputs" {
  debug_inspect(
    @diff.levenshtein_edits(old=([] : Array[Char]), new=([] : Array[Char])),
    content="[]",
  )
  debug_inspect(
    @diff.levenshtein_edits(old=([] : Array[Char]), new="ab".to_array()),
    content=(
      #|[Insert(old_index=0, new_index=0, new_len=2)]
    ),
  )
  debug_inspect(
    @diff.levenshtein_edits(old="ab".to_array(), new=([] : Array[Char])),
    content=(
      #|[Delete(old_index=0, old_len=2, new_index=0)]
    ),
  )
  debug_inspect(
    @diff.levenshtein_edits(old="abc".to_array(), new="abc".to_array()),
    content=(
      #|[Equal(old_index=0, new_index=0, len=3)]
    ),
  )
}

///|
test "edit_distance: exhaustive differential against reference DP" {
  let pools = [gen_strings(['a', 'b'], 4), gen_strings(['a', 'b', 'c'], 3)]
  for pool in pools {
    for xs in pool {
      for ys in pool {
        let expected = reference_levenshtein(xs, ys)
        assert_eq(@diff.edit_distance(xs, ys), expected)
        let edits = @diff.levenshtein_edits(old=xs, new=ys)
        assert_eq(check_script(xs, ys, edits), expected)
        // the script must be THE canonical one, not just any minimal one
        assert_true(to_tuples(edits) == reference_canonical(xs, ys))
        for k in 0..<6 {
          match @diff.edit_distance_within(xs, ys, max_distance=k) {
            Some(d) => {
              assert_true(expected <= k)
              assert_eq(d, expected)
            }
            None => assert_true(expected > k)
          }
        }
      }
    }
  }
}
