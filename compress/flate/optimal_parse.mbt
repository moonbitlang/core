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

// Optimal LZ77 parsing (zopfli-style "squeeze"): the drop-in counterpart to
// the greedy/lazy parser in lz77.mbt, plugged into the same
// (tokens, frequencies) seam. The parse is a cost-driven shortest path over
// the token graph: every position may step one literal or any reachable
// match, with edge weights in bits. Real costs depend on the Huffman tables,
// which depend on the parse — so the parse is iterated: each round's
// frequencies build length-limited Huffman codes (the writer's own
// `gen_huffman`) whose code lengths become the next round's costs, and the
// cheapest parse seen (by estimated block cost) wins.

///|
/// One Pareto-frontier entry among the matches at a position: lengths in
/// (previous entry's len, len] are reachable at `dist`, the smallest distance
/// achieving them (the chain walks nearest-first, so the first candidate
/// reaching a new length has the minimal distance for it).
#valtype
priv struct MatchRange {
  len : Int32
  dist : Int32
}

///|
// The optimal parser builds its own match frontiers for each input range.
fn insert_optimal_pos(
  data : BytesView,
  head : FixedArray[Int32],
  prev : FixedArray[Int32],
  i : Int32,
  n : Int32,
  seed_from : Int32,
) -> Unit {
  if has_bytes_from(i, 3, n) {
    let h = hash3(data, i)
    prev[i - seed_from] = head[h]
    head[h] = i
  }
}

///|
/// Maximum chain candidates examined per position.
const OPTIMAL_MAX_CHAIN : Int32 = 8192

///|
/// The match frontier at every position of `data[start:end)`, computed once
/// and reused by every squeeze iteration. Matches never extend past `end`
/// (the planner chose exact bounds). The window-eligible suffix of
/// `data[0:start)` is seeded as history so back-references may cross block
/// boundaries.
fn collect_matches(
  data : BytesView,
  start : Int32,
  end : Int32,
) -> FixedArray[Array[MatchRange]] {
  let seed_from = (start - WINDOW_SIZE).max(0)
  let head = FixedArray::make(1 << HASH_BITS, -1)
  let prev = FixedArray::make((end - seed_from).max(1), -1)
  let n = data.length()
  for j in seed_from..<start {
    insert_optimal_pos(data, head, prev, j, n, seed_from)
  }
  // The shared empty placeholder is never mutated: each slot is replaced
  // with its own frontier before the completed table is read.
  let out : FixedArray[Array[MatchRange]] = FixedArray::make(end - start, [])
  for i in start..<end {
    let frontier : Array[MatchRange] = []
    let limit = (end - i).min(258)
    if limit >= 3 && has_bytes_from(i, 3, n) {
      let h = hash3(data, i)
      let mut cand = head[h]
      let mut best = 2
      let mut steps = 0
      while cand >= 0 && steps < OPTIMAL_MAX_CHAIN && i - cand <= 32768 {
        let l = if match_candidate_can_beat(data, cand, i, best, limit) {
          match_len_up_to(data, cand, i, limit)
        } else {
          best
        }
        if l > best {
          frontier.push({ len: l, dist: i - cand, })
          best = l
          if l >= limit {
            break
          }
        }
        cand = prev[cand - seed_from]
        steps = steps + 1
      }
    }
    insert_optimal_pos(data, head, prev, i, n, seed_from)
    out[i - start] = frontier
  }
  out
}

///|
/// Trace the shortest path recorded in `len_choice`/`dist_choice` back from
/// the end of `data[start:start+m)`, then replay it forward into `tokens`,
/// tallying the literal/length and distance symbols consumed.
fn replay_tokens(
  data : BytesView,
  start : Int32,
  m : Int32,
  len_choice : FixedArray[Int32],
  dist_choice : FixedArray[Int32],
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Unit {
  let steps : Array[Int32] = []
  let mut o = m
  while o > 0 {
    steps.push(o)
    o = o - len_choice[o]
  }
  let mut pos = start
  for at in steps.rev_iter() {
    let l = len_choice[at]
    if l == 1 && dist_choice[at] == 0 {
      let b = data[pos].to_int()
      tokens.push(b)
      ll_freq[b] += 1
    } else {
      tokens.push(pack_match_token(l, dist_choice[at]))
      ll_freq[257 + len_to_idx[l]] += 1
      d_freq[dist_index(dist_choice[at])] += 1
    }
    pos = pos + l
  }
}

///|
/// One shortest-path pass: bit costs in, parse out. `costs[o]` is the minimal
/// bits to encode `data[start:start+o)`; each position relaxes a literal edge
/// and every frontier match length.
fn squeeze_parse(
  data : BytesView,
  start : Int32,
  end : Int32,
  matches : FixedArray[Array[MatchRange]],
  ll_cost : FixedArray[Int32],
  d_cost : FixedArray[Int32],
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Unit {
  let m = end - start
  let inf = 0x3FFFFFFF
  let costs = FixedArray::make(m + 1, inf)
  let len_choice = FixedArray::make(m + 1, 0)
  let dist_choice = FixedArray::make(m + 1, 0)
  costs[0] = 0
  for o in 0..<m {
    let base = costs[o]
    let i = start + o
    let lc = base + ll_cost[data[i].to_int()]
    if lc < costs[o + 1] {
      costs[o + 1] = lc
      len_choice[o + 1] = 1
      dist_choice[o + 1] = 0
    }
    let fr = matches[o]
    let mut lo = 3
    for k in 0..<fr.length() {
      let e = fr[k]
      let didx = dist_index(e.dist)
      let dbits = d_cost[didx] + dist_extra[didx]
      for l in lo..<=e.len {
        let lidx = len_to_idx[l]
        let c = base + ll_cost[257 + lidx] + len_extra[lidx] + dbits
        if c < costs[o + l] {
          costs[o + l] = c
          len_choice[o + l] = l
          dist_choice[o + l] = e.dist
        }
      }
      lo = e.len + 1
    }
  }
  replay_tokens(
    data, start, m, len_choice, dist_choice, tokens, ll_freq, d_freq,
  )
}

///|
/// Turn a parse's symbol frequencies into the next round's bit costs: real
/// length-limited Huffman code lengths (the same construction the writer
/// uses), with unused symbols priced at the maximum length so the parse may
/// still explore them.
fn stats_to_costs(
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
  ll_cost : FixedArray[Int32],
  d_cost : FixedArray[Int32],
) -> Unit {
  let ll_freq_eob = FixedArray::make(286, 0)
  ll_freq.blit_to(ll_freq_eob, len=286)
  ll_freq_eob[256] += 1
  let ll_len = FixedArray::make(286, 0)
  gen_huffman(ll_freq_eob, 286, 15, ll_len)
  let dd_len = FixedArray::make(30, 0)
  gen_huffman(d_freq, 30, 15, dd_len)
  for s in 0..<286 {
    ll_cost[s] = if ll_len[s] == 0 { 15 } else { ll_len[s] }
  }
  for d in 0..<30 {
    d_cost[d] = if dd_len[d] == 0 { 15 } else { dd_len[d] }
  }
}

///|
/// Iterated optimal parse of `data[start:end)`: squeeze under fixed-table
/// costs first, then re-derive costs from each round's own statistics,
/// keeping the cheapest parse seen (judged by estimated block cost).
fn tokenize_optimal(
  data : BytesView,
  start : Int32,
  end : Int32,
  iterations : Int32,
) -> Array[Int32] {
  let matches = collect_matches(data, start, end)
  let mut ll_cost = FixedArray::makei(286, s => fixed_litlen_info[s] & 0xF)
  let mut d_cost = FixedArray::make(30, 5)
  let mut best_bits = 0x3FFFFFFF
  let mut best_tokens : Array[Int32]? = None
  for _it in 0..<iterations {
    let toks : Array[Int32] = []
    let ll_freq = FixedArray::make(286, 0)
    let d_freq = FixedArray::make(30, 0)
    squeeze_parse(
      data, start, end, matches, ll_cost, d_cost, toks, ll_freq, d_freq,
    )
    let bits = block_cost_bits(end - start, ll_freq, d_freq)
    if bits < best_bits {
      best_bits = bits
      best_tokens = Some(toks)
    }
    let nl = FixedArray::make(286, 0)
    let nd = FixedArray::make(30, 0)
    stats_to_costs(ll_freq, d_freq, nl, nd)
    ll_cost = nl
    d_cost = nd
  }
  best_tokens.unwrap()
}
