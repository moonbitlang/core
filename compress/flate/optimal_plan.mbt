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
const OPTIMAL_MASTER_BLOCK : Int32 = 262144

// Optimal block planning (zopfli-style block splitting). A greedy/lazy
// parse of each master chunk provides reference tokens; split points are
// searched by recursive narrowing (zopfli's FindMinimum) and inserted
// greedily while two blocks have a lower estimated cost than one, under a block
// budget. Segments are then re-parsed by the optimal parser, the splitting is
// repeated once on the optimal tokens (zopfli's blocksplittinglast), and the
// cheaper of the two groupings is emitted through the ordinary `emit_block` —
// planner and parser replaced, writer untouched, output standard DEFLATE.

///|
/// Most blocks the splitter may cut one master chunk into (zopfli's default).
const OPTIMAL_MAX_BLOCKS : Int32 = 15

///|
/// Estimated cost in bits of one block: the cheapest of
/// stored / fixed / dynamic, mirroring `emit_block`'s choice. Judges both
/// split candidates and squeeze iterations. Delegates the accounting to the
/// shared dynamic-length builder and `estimate_block_cost`.
fn block_cost_bits(
  byte_len : Int32,
  ll_freq_in : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  let ll_freq = FixedArray::make(286, 0)
  ll_freq_in.blit_to(ll_freq, len=286)
  ll_freq[256] += 1
  let lengths = build_dynamic_code_lengths(ll_freq, d_freq)
  let cost = estimate_block_cost(lengths, byte_len, ll_freq, d_freq)
  cost.stored.min(cost.fixed).min(cost.dynamic)
}

///|
/// Symbol frequencies of `tokens[lo:hi)`.
fn range_freqs(
  tokens : Array[Int32],
  lo : Int32,
  hi : Int32,
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Unit {
  ll_freq.fill(0, end=286)
  d_freq.fill(0, end=30)
  for k in lo..<hi {
    let tok = tokens[k]
    if tok < 256 {
      ll_freq[tok] += 1
    } else {
      let length = tok >> 16
      let distance = tok & 0xFFFF
      ll_freq[257 + len_to_idx[length]] += 1
      d_freq[dist_index(distance)] += 1
    }
  }
}

///|
/// Estimated block cost of `tokens[lo:hi)` covering `byte_len` input bytes.
fn split_range_cost(
  tokens : Array[Int32],
  lo : Int32,
  hi : Int32,
  byte_len : Int32,
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  range_freqs(tokens, lo, hi, ll_freq, d_freq)
  block_cost_bits(byte_len, ll_freq, d_freq)
}

///|
fn split_candidate_cost(
  tokens : Array[Int32],
  tok_pos : FixedArray[Int32],
  lo : Int32,
  hi : Int32,
  k : Int32,
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  split_range_cost(tokens, lo, k, tok_pos[k] - tok_pos[lo], ll_freq, d_freq) +
  split_range_cost(tokens, k, hi, tok_pos[hi] - tok_pos[k], ll_freq, d_freq)
}

///|
/// zopfli's FindMinimum: locate the split point inside (lo, hi) minimizing
/// the two halves' summed estimated cost, by sampling 9 evenly spaced candidates
/// and recursively narrowing to the winner's neighborhood; small intervals
/// are scanned exhaustively. Writes split index and cost to `result[0:2]`;
/// index -1 means the interval admits no interior point. The caller reuses the
/// pair so each candidate search does not allocate a return tuple.
fn find_best_split(
  tokens : Array[Int32],
  tok_pos : FixedArray[Int32],
  lo : Int32,
  hi : Int32,
  result : FixedArray[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Unit {
  let sample = 9
  let mut plo = lo + 1
  let mut phi = hi - 1
  let mut best_k = -1
  let mut best_cost = 0x3FFFFFFF
  while phi - plo > sample {
    let step = (phi - plo) / (sample + 1)
    let mut win_i = 0
    let mut win_k = plo
    let mut win_c = 0x3FFFFFFF
    for i in 0..<sample {
      let k = plo + (i + 1) * step
      let c = split_candidate_cost(tokens, tok_pos, lo, hi, k, ll_freq, d_freq)
      if c < win_c {
        win_c = c
        win_k = k
        win_i = i
      }
    }
    if win_c < best_cost {
      best_cost = win_c
      best_k = win_k
    }
    let nlo = if win_i == 0 { plo } else { plo + win_i * step }
    let nhi = if win_i == sample - 1 { phi } else { plo + (win_i + 2) * step }
    plo = nlo
    phi = nhi
  }
  for k in plo..<=phi {
    let c = split_candidate_cost(tokens, tok_pos, lo, hi, k, ll_freq, d_freq)
    if c < best_cost {
      best_cost = c
      best_k = k
    }
  }
  result[0] = best_k
  result[1] = best_cost
}

///|
/// Greedily insert split points (token indices) while a split still lowers
/// the estimated total cost, up to `OPTIMAL_MAX_BLOCKS` blocks. `tok_pos[k]` is
/// the byte offset where token k starts (with `tok_pos[m]` = chunk end).
fn plan_split_points(
  tokens : Array[Int32],
  tok_pos : FixedArray[Int32],
) -> Array[Int32] {
  let bounds : Array[Int32] = [0, tokens.length()]
  let split_result = FixedArray::make(2, 0)
  let ll_freq = FixedArray::make(286, 0)
  let d_freq = FixedArray::make(30, 0)
  while bounds.length() - 1 < OPTIMAL_MAX_BLOCKS {
    let mut best_gain = 0
    let mut best_seg = -1
    let mut best_k = -1
    for s in 0..<(bounds.length() - 1) {
      let lo = bounds[s]
      let hi = bounds[s + 1]
      if hi - lo < 16 {
        continue
      }
      let whole = split_range_cost(
        tokens,
        lo,
        hi,
        tok_pos[hi] - tok_pos[lo],
        ll_freq,
        d_freq,
      )
      find_best_split(tokens, tok_pos, lo, hi, split_result, ll_freq, d_freq)
      let k = split_result[0]
      let cost = split_result[1]
      if k >= 0 && whole - cost > best_gain {
        best_gain = whole - cost
        best_seg = s
        best_k = k
      }
    }
    if best_seg < 0 {
      break
    }
    bounds.insert(best_seg + 1, best_k)
  }
  bounds
}

///|
/// Total estimated cost of a grouping (consecutive bounds over `tokens`).
fn grouping_cost(
  tokens : Array[Int32],
  tok_pos : FixedArray[Int32],
  bounds : Array[Int32],
) -> Int32 {
  let mut total = 0
  let ll_freq = FixedArray::make(286, 0)
  let d_freq = FixedArray::make(30, 0)
  for s in 0..<(bounds.length() - 1) {
    let lo = bounds[s]
    let hi = bounds[s + 1]
    total = total +
      split_range_cost(
        tokens,
        lo,
        hi,
        tok_pos[hi] - tok_pos[lo],
        ll_freq,
        d_freq,
      )
  }
  total
}

///|
/// Byte offset where each token starts, with `positions[tokens.length()]`
/// pinned to `end`. A literal advances one byte; a match advances its length.
fn token_positions(
  tokens : Array[Int32],
  start : Int32,
  end : Int32,
) -> FixedArray[Int32] {
  let positions = FixedArray::make(tokens.length() + 1, 0)
  let mut p = start
  for k in 0..<tokens.length() {
    positions[k] = p
    let tok = tokens[k]
    p = p + (if tok < 256 { 1 } else { tok >> 16 })
  }
  positions[tokens.length()] = end
  positions
}

///|
/// Phase 1 for one master chunk: a cheap greedy reference parse (level-9
/// tuning), its split points, and an optimal parse of each segment,
/// concatenated into `tokens` with `joins` recording the phase-1 boundaries as
/// token indices. `chunk_end` may overhang `target` when a boundary match
/// straddled it.
priv struct OptimalChunk {
  tokens : Array[Int32]
  joins : Array[Int32]
  chunk_end : Int32
}

///|
fn optimal_parse_chunk(
  input : BytesView,
  finder : MatchFinder,
  pos : Int32,
  target : Int32,
  iterations : Int32,
) -> OptimalChunk {
  let gtoks : Array[Int32] = []
  let greedy_ll_freq = FixedArray::make(286, 0)
  let greedy_d_freq = FixedArray::make(30, 0)
  let processed = tokenize(
    input,
    finder,
    pos,
    target,
    level_configs[9],
    gtoks,
    greedy_ll_freq,
    greedy_d_freq,
  )
  let chunk_end = processed // a boundary match may overhang `target`
  let gtok_pos = token_positions(gtoks, pos, chunk_end)
  let bounds1 = plan_split_points(gtoks, gtok_pos)
  let tokens : Array[Int32] = []
  let joins : Array[Int32] = [0] // phase-1 boundaries, as optimal-token indices
  for s in 0..<(bounds1.length() - 1) {
    let a = gtok_pos[bounds1[s]]
    let b = gtok_pos[bounds1[s + 1]]
    let toks = tokenize_optimal(input, a, b, iterations)
    tokens.append(toks)
    joins.push(tokens.length())
  }
  { tokens, joins, chunk_end, }
}

///|
/// Phase 2 for one master chunk (zopfli's blocksplittinglast): re-split the
/// optimal tokens, then emit whichever grouping is cheaper by estimated cost
/// through the ordinary `emit_block`.
fn emit_optimal_chunk(
  w : BitWriter,
  input : BytesView,
  chunk : OptimalChunk,
  pos : Int32,
  n : Int32,
) -> Unit {
  let all = chunk.tokens
  let all_pos = token_positions(all, pos, chunk.chunk_end)
  let bounds2 = plan_split_points(all, all_pos)
  let bounds = if grouping_cost(all, all_pos, bounds2) <
    grouping_cost(all, all_pos, chunk.joins) {
    bounds2
  } else {
    chunk.joins
  }
  for s in 0..<(bounds.length() - 1) {
    let lo = bounds[s]
    let hi = bounds[s + 1]
    let ll_freq = FixedArray::make(286, 0)
    let d_freq = FixedArray::make(30, 0)
    range_freqs(all, lo, hi, ll_freq, d_freq)
    w.emit_block(
      input,
      all_pos[lo],
      all_pos[hi],
      all[lo:hi],
      ll_freq,
      d_freq,
      is_final=all_pos[hi] == n,
    )
  }
}

///|
/// Compress with zopfli-style effort: content-driven block splitting plus
/// iterated optimal parsing, with a second splitting pass over the optimal
/// tokens (blocksplittinglast). `iterations` is the squeeze count per block,
/// clamped to at least 1; the default is 15.
/// `fast_store` is disabled by default. Enabling it can bypass this strategy
/// for heuristically incompressible input, trading output size for speed.
pub fn deflate_all_optimal(
  input : BytesView,
  iterations~ : Int32 = 15,
  fast_store~ : Bool = false,
) -> Bytes {
  guard !fast_store || !should_fast_store(input) else {
    return deflate_all(input, level=0)
  }
  let iters = iterations.max(1)
  let w = BitWriter()
  let n = input.length()
  guard n != 0 else {
    w.emit_empty_block(input)
    w.flush()
    return Bytes::from_array(w.out)
  }
  let mut pos = 0
  let long_hash_bits = long_hash_bits_for_input(input)
  let finder = MatchFinder(input_size=n, long_hash_bits~)
  finder.reset_for_input(input, long_hash_bits~)
  for ;; {
    let target = next_block_target(pos, n, OPTIMAL_MASTER_BLOCK)
    let chunk = optimal_parse_chunk(input, finder, pos, target, iters)
    emit_optimal_chunk(w, input, chunk, pos, n)
    pos = chunk.chunk_end
    guard pos < n else { break }
  }
  w.flush()
  Bytes::from_array(w.out)
}
