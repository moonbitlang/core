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

// Content-driven block planning (libdeflate's observation-divergence split,
// as adopted by lean-zip). Each input range is tokenized once with the full
// 32 KB history, then the token stream is
// partitioned where the literal/match observation distribution drifts —
// each segment is emitted as stored, fixed-Huffman or dynamic-Huffman data
// through the shared `emit_block`.

///|
/// Number of literal observation classes (libdeflate `NUM_LITERAL_OBSERVATION_TYPES`):
/// literals are bucketed by bits 7,6,0 — a cheap proxy separating
/// case/digit/punctuation regimes.
const SPLIT_NUM_LITERAL_CLASSES : Int32 = 8

///|
/// Total observation classes: 8 literal classes plus 2 match classes (short/long).
const SPLIT_NUM_CLASSES : Int32 = 10

///|
/// New observations between divergence checks (libdeflate `NUM_OBSERVATIONS_PER_BLOCK_CHECK`).
const SPLIT_CHECK_TOKENS : Int32 = 512

///|
/// Floor on block output bytes (libdeflate `MIN_BLOCK_LENGTH`): per-block tree
/// headers stop paying for themselves below this.
const SPLIT_MIN_BLOCK_BYTES : Int32 = 10000

///|
/// Unconditional cut ceiling on block output bytes (libdeflate `SOFT_MAX_BLOCK_LENGTH`).
const SPLIT_SOFT_MAX_BLOCK_BYTES : Int32 = 300000

///|
/// Divergence threshold numerator/denominator (libdeflate's 200/512): cut when
/// the sum of absolute probability deltas reaches ~39%.
const SPLIT_CUTOFF_NUM : Int32 = 200

///|
const SPLIT_CUTOFF_DEN : Int32 = 512

///|
/// Length bias divisor (libdeflate's `block_length / 4096` term): longer blocks
/// cut progressively easier, since a fresh tree amortizes better.
const SPLIT_BIAS_BYTES : Int32 = 4096

///|
/// Observation class of a packed token: literals map to 0–7 by bits 7,6,0;
/// matches map to 8 (length < 9) or 9.
#inline
fn split_token_class(tok : Int32) -> Int32 {
  // Branch-free form of: literals -> bits 7,6,0 (0..7); matches -> 8 + (len>=9).
  // `is_lit = (tok - 256) >> 31` is the arithmetic-shift mask: -1 (all ones)
  // for a literal, 0 for a match. The literal class is selected by `is_lit`,
  // the match class `8 + (len>=9)` (0 for a literal's len == 0, masked out) by
  // its complement, so no branch on the token kind.
  let lit = ((tok >> 5) & 6) | (tok & 1)
  let len = tok >> 16
  let is_lit = (tok - 256) >> 31
  let match_class = SPLIT_NUM_LITERAL_CLASSES + (1 - (((len - 9) >> 31) & 1))
  (lit & is_lit) | (match_class & (is_lit ^ -1))
}

///|
/// Output bytes a token contributes: 1 for a literal, the match length for a
/// reference.
#inline
fn split_token_bytes(tok : Int32) -> Int32 {
  // Branch-free form of `if tok < 256 { 1 } else { tok >> 16 }`: the
  // `(is_lit ^ -1)` mask is 0 for a literal (yielding 1) and -1 for a match
  // (yielding `1 + (len - 1)`).
  let is_lit = (tok - 256) >> 31
  1 + ((is_lit ^ -1) & ((tok >> 16) - 1))
}

///|
/// The divergence test (libdeflate `do_end_block_check`): cut when the recent
/// window's class distribution differs from the block-so-far distribution by
/// at least ~39% probability mass (less for long blocks). Integer-only; the
/// caller guarantees `old_tot > 0`.
fn split_end_block_check(
  old : FixedArray[Int32],
  old_tot : Int32,
  new : FixedArray[Int32],
  new_tot : Int32,
  block_bytes : Int32,
) -> Bool {
  let mut delta = 0
  for i in 0..<SPLIT_NUM_CLASSES {
    let a = new[i] * old_tot
    let b = old[i] * new_tot
    delta = delta + (a - b).abs()
  }
  let cutoff = new_tot * SPLIT_CUTOFF_NUM / SPLIT_CUTOFF_DEN * old_tot
  delta + block_bytes / SPLIT_BIAS_BYTES * old_tot >= cutoff
}

///|
/// Entropy-divergence cut points for a packed token stream: one pass,
/// accumulating per-class observation counts. Block-so-far (`old`) and
/// recent-window (`new`) histograms are compared every `SPLIT_CHECK_TOKENS`
/// tokens once the block and the remaining input are both at least
/// `SPLIT_MIN_BLOCK_BYTES` output bytes; on divergence the block is cut at the
/// next token boundary, otherwise the window merges into `old`. Blocks are
/// force-cut at `SPLIT_SOFT_MAX_BLOCK_BYTES`. Returns token indices where the
/// following block begins (strictly increasing, within `[1, tokens.length()]`).
fn choose_splits(tokens : Array[Int32]) -> Array[Int32] {
  let total_bytes = tokens.fold(init=0, (total, tok) => {
    total + split_token_bytes(tok)
  })
  let old = FixedArray::make(SPLIT_NUM_CLASSES, 0)
  let mut old_tot = 0
  let new = FixedArray::make(SPLIT_NUM_CLASSES, 0)
  let mut new_tot = 0
  let mut block_bytes = 0
  let mut done_bytes = 0
  let cuts : Array[Int32] = []
  for i, tok in tokens {
    let c = split_token_class(tok)
    new[c] = new[c] + 1
    new_tot = new_tot + 1
    let tb = split_token_bytes(tok)
    block_bytes = block_bytes + tb
    done_bytes = done_bytes + tb
    guard block_bytes >= SPLIT_MIN_BLOCK_BYTES &&
      total_bytes - done_bytes >= SPLIT_MIN_BLOCK_BYTES else {
      continue
    }
    let cut = block_bytes >= SPLIT_SOFT_MAX_BLOCK_BYTES ||
      (
        new_tot >= SPLIT_CHECK_TOKENS &&
        old_tot > 0 &&
        split_end_block_check(old, old_tot, new, new_tot, block_bytes)
      )
    guard !cut else {
      cuts.push(i + 1)
      old.fill(0)
      new.fill(0)
      old_tot = 0
      new_tot = 0
      block_bytes = 0
      continue
    }
    if new_tot >= SPLIT_CHECK_TOKENS {
      for j in 0..<SPLIT_NUM_CLASSES {
        old[j] = old[j] + new[j]
        new[j] = 0
      }
      old_tot = old_tot + new_tot
      new_tot = 0
    }
  }
  cuts
}

///|
/// Token-boundary cuts approximating the selected whole-buffer cadence:
/// cut at the first token whose start offset reaches each block-size
/// multiple. Used as the baseline when comparing estimated partition costs.
fn fixed_cadence_cuts(
  tokens : Array[Int32],
  all_pos : FixedArray[Int32],
  pos : Int32,
  block_size : Int32,
) -> Array[Int32] {
  let m = tokens.length()
  let cuts : Array[Int32] = []
  let end = all_pos[m]
  let mut target = next_block_target(pos, end, block_size)
  let mut k = 1
  while k < m {
    if all_pos[k] >= target {
      cuts.push(k)
      target = next_block_target(target, end, block_size)
    }
    k = k + 1
  }
  cuts
}

///|
/// Estimated cost of emitting `tokens` partitioned by `cuts`, using
/// `block_cost_bits`. Stored-block alignment and final bit padding are not
/// tracked across the partition.
fn partition_cost(
  tokens : Array[Int32],
  all_pos : FixedArray[Int32],
  cuts : Array[Int32],
) -> Int32 {
  let m = tokens.length()
  let mut total = 0
  let mut lo = 0
  for cut in cuts {
    let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
    let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
    range_freqs(tokens, lo, cut, ll_freq, d_freq)
    total = total + block_cost_bits(all_pos[cut] - all_pos[lo], ll_freq, d_freq)
    lo = cut
  }
  if lo < m {
    let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
    let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
    range_freqs(tokens, lo, m, ll_freq, d_freq)
    total = total + block_cost_bits(all_pos[m] - all_pos[lo], ll_freq, d_freq)
  }
  total
}

///|
/// Emit the token stream `tokens` (covering `data[start:processed)`) as blocks
/// cut at `cuts`, through the ordinary `emit_block`. `all_pos` maps token index
/// to the byte offset where it starts (with `all_pos[tokens.length()]` = end).
fn emit_split_blocks(
  w : BitWriter,
  data : BytesView,
  tokens : Array[Int32],
  all_pos : FixedArray[Int32],
  cuts : Array[Int32],
  n : Int32,
) -> Unit {
  let m = tokens.length()
  let mut lo = 0
  for cut in cuts {
    let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
    let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
    range_freqs(tokens, lo, cut, ll_freq, d_freq)
    w.emit_block(
      data,
      all_pos[lo],
      all_pos[cut],
      tokens[lo:cut],
      ll_freq,
      d_freq,
      is_final=all_pos[cut] >= n,
    )
    lo = cut
  }
  if lo < m {
    let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
    let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
    range_freqs(tokens, lo, m, ll_freq, d_freq)
    w.emit_block(
      data,
      all_pos[lo],
      all_pos[m],
      tokens[lo:m],
      ll_freq,
      d_freq,
      is_final=all_pos[m] >= n,
    )
  }
}

///|
/// Compress with content-driven block splitting: tokenize each master chunk
/// once (full 32 KB cross-block history), cut the token stream where the
/// symbol statistics drift, and select stored, fixed or dynamic encoding for
/// each segment.
/// A mid-tier between the fixed-cadence `deflate_all` and the offline zopfli
/// `deflate_all_optimal`.
/// `fast_store` is disabled by default. Enabling it can bypass this strategy
/// for heuristically incompressible input, trading output size for speed.
pub fn deflate_all_split(
  input : BytesView,
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Bytes {
  let lv = clamp_level(level)
  let w = BitWriter()
  let n = input.length()
  guard lv != 0 && !(fast_store && should_fast_store(input)) else {
    w.write_stored(input, 0, n, is_final=true)
    w.flush()
    return Bytes::from_array(w.out)
  }
  guard n != 0 else {
    w.emit_empty_block(input)
    w.flush()
    return Bytes::from_array(w.out)
  }
  let cfg = level_configs[lv]
  let block_size = 65535
  // Keep splitter chunks aligned with the ordinary whole-buffer cadence so
  // cost estimates compare partitions over the same tokenized range.
  let master_size = block_size
  let long_hash_bits = long_hash_bits_for_input(input)
  let finder = MatchFinder(input_size=n, long_hash_bits~)
  finder.reset_for_input(input, long_hash_bits~)
  let mut pos = 0
  for ;; {
    let target = next_block_target(pos, n, master_size)
    let tokens : Array[Int32] = []
    let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
    let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
    let processed = tokenize(
      input, finder, pos, target, cfg, tokens, ll_freq, d_freq,
    )
    let all_pos = token_positions(tokens, pos, processed)
    let split_cuts = choose_splits(tokens)
    // Compare adaptive and fixed-cadence partitions using the shared cost model.
    let fixed_cuts = fixed_cadence_cuts(tokens, all_pos, pos, block_size)
    let cuts = if partition_cost(tokens, all_pos, split_cuts) <
      partition_cost(tokens, all_pos, fixed_cuts) {
      split_cuts
    } else {
      fixed_cuts
    }
    emit_split_blocks(w, input, tokens, all_pos, cuts, n)
    pos = processed
    guard pos < n else { break }
  }
  w.flush()
  Bytes::from_array(w.out)
}
