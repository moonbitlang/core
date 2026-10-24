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
const HASH_BITS : Int32 = 15

// LZ77 parsing stage of the encode pipeline: bytes in, tokens (literals and
// length/distance matches) plus symbol frequencies out. In modern terms,
// `tokenize` bundles the match finder (3-byte heads and 4-byte hash chains), the parsing
// policy (greedy or lazy, tuned per compression level), and the symbol tally
// (frequency tables, already in Huffman-symbol space).
//
// This is the designated seam for alternative LZ77 parsers (see the roadmap):
// encoder effort is invisible in the DEFLATE format, so anything that produces
// the same (tokens, frequencies) shape can replace `tokenize` wholesale.

///|
const WINDOW_MASK : Int32 = WINDOW_SIZE - 1

///|
// The streaming input ring holds the 32 KiB match window plus one accepted
// block and its lookahead. It is mirrored so a 16-byte SIMD load at its end
// can continue into the duplicate half without a wrap branch.
const STREAM_RING_SIZE : Int32 = 65536

///|
const STREAM_RING_MASK : Int32 = STREAM_RING_SIZE - 1

///|
const STREAM_RING_STORAGE_SIZE : Int32 = STREAM_RING_SIZE * 2

///|
/// Per-level baseline search tuning, adopted from zlib's configuration table.
/// The default level uses the distance-aware parser below; its initial and
/// lookahead search budgets are separate. Levels 1-3 are greedy, expressed as
/// `max_lazy = 0`. Level 0 (stored only) is special-cased in the block
/// planner and never searches.
#valtype
priv struct LevelConfig {
  good_length : Int32 // shrink the chain budget once a match this long is held
  max_lazy : Int32 // 0 = greedy (commit immediately); else defer while best < this
  nice_length : Int32 // stop searching outright at this match length
  max_chain : Int32 // candidate positions examined per search
} derive(Eq)

///|
let level_configs : FixedArray[LevelConfig] = [
  { good_length: 0, max_lazy: 0, nice_length: 0, max_chain: 0, }, // 0: stored
  { good_length: 4, max_lazy: 0, nice_length: 8, max_chain: 4, },
  { good_length: 4, max_lazy: 0, nice_length: 16, max_chain: 8, },
  { good_length: 4, max_lazy: 0, nice_length: 32, max_chain: 32, },
  { good_length: 4, max_lazy: 4, nice_length: 16, max_chain: 16, },
  { good_length: 8, max_lazy: 16, nice_length: 32, max_chain: 32, },
  { good_length: 8, max_lazy: 16, nice_length: 128, max_chain: 128, }, // 6: default
  { good_length: 8, max_lazy: 32, nice_length: 128, max_chain: 256, },
  { good_length: 32, max_lazy: 128, nice_length: 258, max_chain: 1024, },
  { good_length: 32, max_lazy: 258, nice_length: 258, max_chain: 4096, }, // 9
]

///|
fn hash3(data : BytesView, i : Int32) -> Int32 {
  let a = data[i].to_int()
  let b = data[i + 1].to_int()
  let c = data[i + 2].to_int()
  (a ^ (b << 5) ^ (c << 10)) & ((1 << HASH_BITS) - 1)
}

///|
fn hash3_window(
  data : FixedArray[Byte],
  i : Int32,
  shift~ : Int32 = 9,
) -> Int32 {
  let offset = i & STREAM_RING_MASK
  let triple = (data[offset].to_int() |
  (data[offset + 1].to_int() << 8) |
  (data[offset + 2].to_int() << 16)).reinterpret_as_uint()
  short_hash_product(triple * 0x1E35A7BDU, shift~)
}

///|
// The fourth input byte contributes only above bit 23 of the wrapping
// product. Its lower 24 bits therefore hash the three-byte prefix too.
#inline
fn short_hash_product(product : UInt32, shift~ : Int32 = 9) -> Int32 {
  ((product & 0xFFFFFF) >> shift).reinterpret_as_int()
}

///|
fn short_hash3(data : BytesView, position : Int32, shift~ : Int32 = 9) -> Int32 {
  let triple = (data[position].to_int() |
  (data[position + 1].to_int() << 8) |
  (data[position + 2].to_int() << 16)).reinterpret_as_uint()
  short_hash_product(triple * 0x1E35A7BDU, shift~)
}

///|
// Wider tables are useful for high-entropy input, where a narrow table turns
// most probes into collision walks. Keep ordinary data at 16 bits and reserve
// the larger tables for whole-buffer inputs selected by a cheap sample.
const NARROW_LONG_HASH_BITS : Int32 = 16

///|
const MID_LONG_HASH_BITS : Int32 = 17

///|
const LONG_HASH_BITS : Int32 = 18

///|
/// Decide whether a complete input benefits from the wide long-match table.
/// Sampling four separated 1 KiB regions avoids classifying a mixed buffer by
/// its prefix alone. The threshold keeps structured/textual inputs on the
/// cache-friendly narrow table while selecting the wide table for binary and
/// high-diversity source data.
fn long_hash_bits_for_input(data : BytesView) -> Int32 {
  let n = data.length()
  guard n >= 32768 else { return NARROW_LONG_HASH_BITS }
  let sample = n.min(1024)
  let span = n - sample
  let used = FixedArray::make(256, 0)
  let local_used = FixedArray::make(256, 0)
  let mut distinct = 0
  let mut high_regions = 0
  for region in 0..<4 {
    let start = match region {
      0 => 0
      1 => span / 3
      2 => span / 3 * 2
      _ => span
    }
    // A merged byte alphabet hides the shape of mixed inputs. Track each
    // region separately so a wide table is reserved for uniformly diverse
    // data rather than a stream with only one random half.
    local_used.fill(0)
    let mut local_distinct = 0
    for i in start..<(start + sample) {
      let byte = data[i].to_int()
      if used[byte] == 0 {
        used[byte] = 1
        distinct += 1
      }
      if local_used[byte] == 0 {
        local_used[byte] = 1
        local_distinct += 1
      }
    }
    if local_distinct >= 128 {
      high_regions += 1
    }
  }
  if high_regions == 4 {
    LONG_HASH_BITS
  } else if distinct >= 64 {
    MID_LONG_HASH_BITS
  } else {
    NARROW_LONG_HASH_BITS
  }
}

///|
#inline
fn long_hash_product(product : UInt32, shift~ : Int32 = 16) -> Int32 {
  (product >> shift).reinterpret_as_int()
}

///|
#inline
fn read_match_word(data : BytesView, position : Int32) -> UInt32 {
  // SAFETY: insertion proves four bytes remain. Search clamps probe below
  // limit <= n - i and only visits earlier candidates, so prefix and suffix
  // words both stay inside the input, including its final four-byte tail.
  data.data().unsafe_read_uint32_le(data.start_offset() + position)
}

///|
#cfg(not(any(target="native", target="wasm")))
#inline
fn read_window_match_word(data : FixedArray[Byte], position : Int32) -> UInt32 {
  let offset = position & STREAM_RING_MASK
  (data[offset].to_int() |
  (data[offset + 1].to_int() << 8) |
  (data[offset + 2].to_int() << 16) |
  (data[offset + 3].to_int() << 24)).reinterpret_as_uint()
}

///|
// The mirrored byte array and Bytes use the same backing layout on these
// backends. This borrowed view never escapes the immediate read below.
#cfg(any(target="native", target="wasm"))
fn match_window_as_bytes(data : FixedArray[Byte]) -> Bytes = "%identity"

///|
#cfg(any(target="native", target="wasm"))
#inline
fn read_window_match_word(data : FixedArray[Byte], position : Int32) -> UInt32 {
  // SAFETY: masking selects the first half of the mirrored ring, leaving
  // at least four bytes of storage even when the read crosses the wrap.
  match_window_as_bytes(data).unsafe_read_uint32_le(position & STREAM_RING_MASK)
}

///|
// As in libdeflate's hc_matchfinder, short matches use a single recent
// 3-byte candidate; the chain is reserved for matches of at least 4 bytes.
// Heads contain stream-stamped positions; predecessors remain stream-relative.
// The predecessor ring stores saturated 16-bit backward distances across the
// full 32 KiB window. Distances survive stream rebasing without adjustment.
priv struct MatchFinder {
  mut min_match_length : Int32
  mut position_base : Int32
  mut next_base : Int32
  mut short_shift : Int32
  mut long_shift : Int32
  mut short_head : FixedArray[Int32]
  mut head : FixedArray[Int32]
  prev : FixedArray[Byte]
}

///|
fn MatchFinder::MatchFinder(
  input_size~ : Int32 = WINDOW_SIZE,
  long_hash_bits~ : Int32 = NARROW_LONG_HASH_BITS,
) -> MatchFinder {
  let short_size = match_table_capacity(
    input_size.min(16384) * 2,
    1 << HASH_BITS,
  )
  let long_size = long_match_table_capacity(input_size, long_hash_bits)
  {
    min_match_length: 0,
    position_base: 0,
    next_base: 0,
    short_shift: 24 - short_size.ctz(),
    long_shift: 32 - long_size.ctz(),
    short_head: FixedArray::make(short_size, -1),
    head: FixedArray::make(long_size, -1),
    prev: FixedArray::make(WINDOW_SIZE * 2 + 2, b'\xFF'),
  }
}

///|
fn match_table_capacity(requested : Int32, maximum : Int32) -> Int32 {
  for capacity = 256 {
    guard capacity < requested && capacity < maximum else { break capacity }
    continue capacity * 2
  }
}

///|
// Keep compact tables for small inputs; sampled inputs use the selected width
// in full. Construction and reset must use the same logical capacity.
fn long_match_table_capacity(
  input_size : Int32,
  long_hash_bits : Int32,
) -> Int32 {
  guard input_size < 32768 else { return 1 << long_hash_bits }
  match_table_capacity(input_size.min(16384) * 4, 1 << long_hash_bits)
}

///|
// Logical size depends only on this input, even when larger backing tables
// are retained from an earlier stream. Cold and reused codecs choose the same
// candidates; allocations grow only when a larger input first needs them.
fn MatchFinder::size_for_input(
  self : MatchFinder,
  input_size : Int32,
  long_hash_bits : Int32,
) -> Unit {
  let short_size = match_table_capacity(
    input_size.min(16384) * 2,
    1 << HASH_BITS,
  )
  let long_size = long_match_table_capacity(input_size, long_hash_bits)
  if self.short_head.length() < short_size {
    self.short_head = FixedArray::make(short_size, -1)
  }
  if self.head.length() < long_size {
    self.head = FixedArray::make(long_size, -1)
  }
  self.short_shift = 24 - short_size.ctz()
  self.long_shift = 32 - long_size.ctz()
}

///|
fn MatchFinder::reset(self : MatchFinder) -> Unit {
  self.min_match_length = 0
  self.position_base = 0
  self.next_base = 0
  self.short_head.fill(-1)
  self.head.fill(-1)
  self.prev.fill(b'\xFF')
}

///|
// A streaming encoder knows the previous stream's accepted span at reset.
// Keep a half-GiB base ceiling: the encoder rebases its relative positions
// after one GiB, leaving ample Int headroom for a pending ring and lookahead.
fn MatchFinder::reset_stream(self : MatchFinder, previous_size : Int32) -> Unit {
  self.min_match_length = 0
  let next = self.position_base + previous_size
  guard next < 1 << 29 else {
    self.reset()
    return
  }
  self.position_base = next
  self.next_base = next + (1 << 30) + STREAM_RING_SIZE
}

///|
// Head positions carry a monotonically increasing stream base. Old heads
// decode to negative positions and are rejected without clearing either table.
// Predecessor distances are overwritten before their head becomes
// reachable. Reset before Int overflow; empty inputs cannot publish a head.
fn MatchFinder::reset_for_input(
  self : MatchFinder,
  input : BytesView,
  long_hash_bits~ : Int32 = -1,
) -> Unit {
  self.min_match_length = 0
  let bits = if long_hash_bits >= 0 {
    long_hash_bits
  } else {
    long_hash_bits_for_input(input)
  }
  self.size_for_input(input.length(), bits)
  if input.length() > 2147483647 - self.next_base {
    self.short_head.fill(-1)
    self.head.fill(-1)
    self.next_base = 0
  }
  self.position_base = self.next_base
  self.next_base += input.length()
}

///|
fn MatchFinder::rebase(self : MatchFinder, offset : Int32) -> Unit {
  for table in [self.short_head, self.head] {
    for i in 0..<table.length() {
      if table[i] >= 0 {
        table[i] = table[i] - offset
      }
    }
  }
}

///|
/// `Bytes` and `FixedArray[Byte]` share the same immutable backing layout in
/// the current MoonBit runtime. Keep this experimental identity bridge private
/// and confined to the native/linear-wasm SIMD loader.
#cfg(any(target="native", target="wasm"))
fn bytes_as_fixedarray(data : Bytes) -> FixedArray[Byte] = "%identity"

///|
#cfg(any(target="native", target="wasm"))
fn match_len_up_to(
  data : BytesView,
  src : Int32,
  pos : Int32,
  limit : Int32,
) -> Int32 {
  // Every wide-loop iteration proves both offsets have 16 available bytes.
  // Hoist the zero-copy representation bridge and call v128_load directly;
  // an otherwise tiny wrapper survives native optimization as two calls per
  // compared chunk.
  let bytes = bytes_as_fixedarray(data.data())
  let start = data.start_offset()
  let mut k = 0
  while k + 16 <= limit {
    let equal_lanes = @v128.i8x16_bitmask(
      @v128.i8x16_eq(
        @v128.v128_load(bytes, start + src + k),
        @v128.v128_load(bytes, start + pos + k),
      ),
    )
    if equal_lanes != 0xFFFF {
      return k + (equal_lanes ^ 0xFFFF).ctz()
    }
    k = k + 16
  }
  while k < limit && data[src + k] == data[pos + k] {
    k = k + 1
  }
  k
}

///|
#cfg(any(target="native", target="wasm"))
fn match_len_in_window(
  data : FixedArray[Byte],
  src : Int32,
  pos : Int32,
  limit : Int32,
) -> Int32 {
  let src = src & STREAM_RING_MASK
  let pos = pos & STREAM_RING_MASK
  let mut k = 0
  while k + 16 <= limit {
    let equal_lanes = @v128.i8x16_bitmask(
      @v128.i8x16_eq(
        @v128.v128_load(data, src + k),
        @v128.v128_load(data, pos + k),
      ),
    )
    if equal_lanes != 0xFFFF {
      return k + (equal_lanes ^ 0xFFFF).ctz()
    }
    k = k + 16
  }
  while k < limit && data[src + k] == data[pos + k] {
    k = k + 1
  }
  k
}

///|
/// JS and wasm-gc currently lower V128 byte comparisons to BigInt/per-lane
/// fallback code. Keep their match finder scalar until those backends provide
/// real SIMD lowering; the native and linear-wasm implementation above remains
/// the semantic reference.
#cfg(not(any(target="native", target="wasm")))
fn match_len_up_to(
  data : BytesView,
  src : Int32,
  pos : Int32,
  limit : Int32,
) -> Int32 {
  let mut k = 0
  while k < limit && data[src + k] == data[pos + k] {
    k = k + 1
  }
  k
}

///|
#cfg(not(any(target="native", target="wasm")))
fn match_len_in_window(
  data : FixedArray[Byte],
  src : Int32,
  pos : Int32,
  limit : Int32,
) -> Int32 {
  let mut k = 0
  while k < limit &&
        data[(src + k) & STREAM_RING_MASK] == data[(pos + k) & STREAM_RING_MASK] {
    k = k + 1
  }
  k
}

///|
/// Scalar candidate probe retained for the optimal parser. The regular
/// match finders cache their current-position probes across the search loop.
#inline
fn match_candidate_can_beat(
  data : BytesView,
  candidate : Int32,
  position : Int32,
  best_len : Int32,
  limit : Int32,
) -> Bool {
  guard best_len < limit else { return false }
  if best_len < 3 {
    data[candidate] == data[position] &&
    data[candidate + 1] == data[position + 1] &&
    data[candidate + 2] == data[position + 2]
  } else {
    data[candidate] == data[position] &&
    data[candidate + 1] == data[position + 1] &&
    data[candidate + best_len - 1] == data[position + best_len - 1] &&
    data[candidate + best_len] == data[position + best_len]
  }
}

///|
/// Whether `count` bytes lie in `[position, end)`, for `position <= end`.
/// Written as a difference: `position + count <= end` wraps for a position
/// within `count` of `Int`'s maximum and then admits a read past the end.
#inline
fn has_bytes_from(position : Int32, count : Int32, end : Int32) -> Bool {
  end - position >= count
}

///|
/// Find a recent length-3 match, then search the independent 4-byte chain.
/// Keep the existing per-level budget and nice/good/lazy tuning unchanged.
fn MatchFinder::find_match_hashed(
  finder : MatchFinder,
  data : BytesView,
  i : Int32,
  n : Int32,
  base : Int32,
  cfg : LevelConfig,
  prefix : UInt32,
  product : UInt32,
) -> Int32 {
  let limit = (n - i).min(258)
  guard base < limit else { return base << 16 }
  let mut budget = if base >= cfg.good_length {
    cfg.max_chain >> 2
  } else {
    cfg.max_chain
  }
  guard budget > 0 else { return base << 16 }
  let cutoff = (i - WINDOW_SIZE).max(0)
  let mut best_len = base
  let mut best_dist = 0
  if base < 3 {
    let short_hash = short_hash_product(product, shift=finder.short_shift)
    let short = finder.short_head.unsafe_get(short_hash) - finder.position_base
    // Every long-chain insertion also updates this short head. If even
    // the newest short-hash candidate expired, no four-byte match can exist.
    guard short >= cutoff else { return base << 16 }
    if (read_match_word(data, short) & 0xFFFFFF) == (prefix & 0xFFFFFF) {
      best_len = 3
      best_dist = i - short
    }
  }
  let mut cand = finder.head.unsafe_get(
      long_hash_product(product, shift=finder.long_shift),
    ) -
    finder.position_base
  guard cand >= cutoff else { return (best_len << 16) | best_dist }
  let prev = finder.prev
  let mut probe = best_len.max(3)
  let mut suffix = read_match_word(data, i + probe - 3)
  let nice_length = cfg.nice_length.min(limit)
  for ;; {
    for ;; {
      let candidate_suffix = read_match_word(data, cand + probe - 3)
      if candidate_suffix == suffix && read_match_word(data, cand) == prefix {
        break
      }
      budget -= 1
      cand = chain_previous(prev, cand)
      guard budget > 0 && cand >= cutoff else {
        return (best_len << 16) | best_dist
      }
    }
    let length = match_len_up_to(data, cand, i, limit)
    if length > best_len {
      best_len = length
      best_dist = i - cand
      if length >= nice_length {
        break
      }
      probe = length
      suffix = read_match_word(data, i + probe - 3)
    }
    budget -= 1
    cand = chain_previous(prev, cand)
    guard budget > 0 && cand >= cutoff else { break }
  }
  (best_len << 16) | best_dist
}

///|
fn MatchFinder::find_match(
  finder : MatchFinder,
  data : BytesView,
  i : Int32,
  n : Int32,
  base : Int32,
  cfg : LevelConfig,
) -> Int32 {
  let limit = (n - i).min(258)
  if limit < 4 {
    let budget = if base >= cfg.good_length {
      cfg.max_chain >> 2
    } else {
      cfg.max_chain
    }
    guard base < limit && budget > 0 else { return base << 16 }
    let cutoff = (i - WINDOW_SIZE).max(0)
    let short = finder.short_head.unsafe_get(
        short_hash3(data, i, shift=finder.short_shift),
      ) -
      finder.position_base
    if base < 3 && short >= cutoff {
      if data[short] == data[i] &&
        data[short + 1] == data[i + 1] &&
        data[short + 2] == data[i + 2] {
        return (3 << 16) | (i - short)
      }
    }
    return base << 16
  }
  let prefix = read_match_word(data, i)
  let product = prefix * 0x1E35A7BDU
  finder.find_match_hashed(data, i, n, base, cfg, prefix, product)
}

///|
/// Find a recent length-3 match, then search the independent 4-byte chain.
/// Keep the existing per-level budget and nice/good/lazy tuning unchanged.
fn MatchFinder::find_window_match_hashed(
  finder : MatchFinder,
  data : FixedArray[Byte],
  i : Int32,
  end : Int32,
  base : Int32,
  cfg : LevelConfig,
  prefix : UInt32,
  product : UInt32,
) -> Int32 {
  let limit = (end - i).min(258)
  guard base < limit else { return base << 16 }
  let mut budget = if base >= cfg.good_length {
    cfg.max_chain >> 2
  } else {
    cfg.max_chain
  }
  guard budget > 0 else { return base << 16 }
  let cutoff = (i - WINDOW_SIZE).max(0)
  let mut best_len = base
  let mut best_dist = 0
  if base < 3 {
    let short_hash = short_hash_product(product, shift=finder.short_shift)
    let short = finder.short_head.unsafe_get(short_hash) - finder.position_base
    // Every long-chain insertion also updates this short head. If even
    // the newest short-hash candidate expired, no four-byte match can exist.
    guard short >= cutoff else { return base << 16 }
    if (read_window_match_word(data, short) & 0xFFFFFF) == (prefix & 0xFFFFFF) {
      best_len = 3
      best_dist = i - short
    }
  }
  let mut cand = finder.head.unsafe_get(
      long_hash_product(product, shift=finder.long_shift),
    ) -
    finder.position_base
  guard cand >= cutoff else { return (best_len << 16) | best_dist }
  let prev = finder.prev
  let mut probe = best_len.max(3)
  let mut suffix = read_window_match_word(data, i + probe - 3)
  let nice_length = cfg.nice_length.min(limit)
  for ;; {
    for ;; {
      let candidate_suffix = read_window_match_word(data, cand + probe - 3)
      if candidate_suffix == suffix &&
        read_window_match_word(data, cand) == prefix {
        break
      }
      budget -= 1
      cand = chain_previous(prev, cand)
      guard budget > 0 && cand >= cutoff else {
        return (best_len << 16) | best_dist
      }
    }
    let length = match_len_in_window(data, cand, i, limit)
    if length > best_len {
      best_len = length
      best_dist = i - cand
      if length >= nice_length {
        break
      }
      probe = length
      suffix = read_window_match_word(data, i + probe - 3)
    }
    budget -= 1
    cand = chain_previous(prev, cand)
    guard budget > 0 && cand >= cutoff else { break }
  }
  (best_len << 16) | best_dist
}

///|
fn MatchFinder::find_window_match(
  finder : MatchFinder,
  data : FixedArray[Byte],
  i : Int32,
  end : Int32,
  base : Int32,
  cfg : LevelConfig,
) -> Int32 {
  let limit = (end - i).min(258)
  if limit < 4 {
    let budget = if base >= cfg.good_length {
      cfg.max_chain >> 2
    } else {
      cfg.max_chain
    }
    guard base < limit && budget > 0 else { return base << 16 }
    let cutoff = (i - WINDOW_SIZE).max(0)
    let short = finder.short_head.unsafe_get(
        hash3_window(data, i, shift=finder.short_shift),
      ) -
      finder.position_base
    if base < 3 && short >= cutoff {
      let candidate = short & STREAM_RING_MASK
      let position = i & STREAM_RING_MASK
      if data[candidate] == data[position] &&
        data[candidate + 1] == data[position + 1] &&
        data[candidate + 2] == data[position + 2] {
        return (3 << 16) | (i - short)
      }
    }
    return base << 16
  }
  let prefix = read_window_match_word(data, i)
  let product = prefix * 0x1E35A7BDU
  finder.find_window_match_hashed(data, i, end, base, cfg, prefix, product)
}

///|
fn MatchFinder::insert_pos_hashed(
  finder : MatchFinder,
  i : Int32,
  product : UInt32,
) -> Unit {
  let h = long_hash_product(product, shift=finder.long_shift)
  let stamped = i + finder.position_base
  finder.short_head.unsafe_set(
    short_hash_product(product, shift=finder.short_shift),
    stamped,
  )
  set_chain_previous(
    finder.prev,
    i,
    finder.head.unsafe_get(h) - finder.position_base,
  )
  finder.head.unsafe_set(h, stamped)
}

///|
fn MatchFinder::insert_pos(
  finder : MatchFinder,
  data : BytesView,
  i : Int32,
  n : Int32,
) -> Unit {
  if n - i >= 4 {
    finder.insert_pos_hashed(i, read_match_word(data, i) * 0x1E35A7BDU)
  } else if n - i >= 3 {
    finder.short_head.unsafe_set(
      short_hash3(data, i, shift=finder.short_shift),
      i + finder.position_base,
    )
  }
}

///|
// One packed load and multiplication feed both hash tables. The loop proves
// four available bytes. Masked indices address the private fixed-size tables.
fn MatchFinder::insert_positions(
  finder : MatchFinder,
  data : BytesView,
  start : Int32,
  end : Int32,
  available_end : Int32,
) -> Unit {
  let end = end.min(available_end - 2)
  guard start < end else { return }
  let long_end = end.min(available_end - 3)
  let head = finder.head
  let short_head = finder.short_head
  let prev = finder.prev
  let base = finder.position_base
  let short_shift = finder.short_shift
  let long_shift = finder.long_shift
  for position in start..<long_end {
    let product = read_match_word(data, position) * 0x1E35A7BDU
    let h = long_hash_product(product, shift=long_shift)
    let stamped = position + base
    short_head.unsafe_set(
      short_hash_product(product, shift=short_shift),
      stamped,
    )
    set_chain_previous(prev, position, head.unsafe_get(h) - base)
    head.unsafe_set(h, stamped)
  }
  if long_end < end {
    finder.insert_pos(data, long_end, available_end)
  }
}

///|
fn MatchFinder::insert_window_pos_hashed(
  finder : MatchFinder,
  i : Int32,
  product : UInt32,
) -> Unit {
  let h = long_hash_product(product, shift=finder.long_shift)
  let stamped = i + finder.position_base
  finder.short_head.unsafe_set(
    short_hash_product(product, shift=finder.short_shift),
    stamped,
  )
  set_chain_previous(
    finder.prev,
    i,
    finder.head.unsafe_get(h) - finder.position_base,
  )
  finder.head.unsafe_set(h, stamped)
}

///|
fn MatchFinder::insert_window_pos(
  finder : MatchFinder,
  data : FixedArray[Byte],
  i : Int32,
  n : Int32,
) -> Unit {
  if n - i >= 4 {
    finder.insert_window_pos_hashed(
      i,
      read_window_match_word(data, i) * 0x1E35A7BDU,
    )
  } else if n - i >= 3 {
    finder.short_head.unsafe_set(
      hash3_window(data, i, shift=finder.short_shift),
      i + finder.position_base,
    )
  }
}

///|
// One packed load and multiplication feed both hash tables. The loop proves
// four available bytes. Masked indices address the private fixed-size tables.
fn MatchFinder::insert_window_positions(
  finder : MatchFinder,
  data : FixedArray[Byte],
  start : Int32,
  end : Int32,
  available_end : Int32,
) -> Unit {
  let end = end.min(available_end - 2)
  guard start < end else { return }
  let long_end = end.min(available_end - 3)
  let head = finder.head
  let short_head = finder.short_head
  let prev = finder.prev
  let base = finder.position_base
  let short_shift = finder.short_shift
  let long_shift = finder.long_shift
  for position in start..<long_end {
    let product = read_window_match_word(data, position) * 0x1E35A7BDU
    let h = long_hash_product(product, shift=long_shift)
    let stamped = position + base
    short_head.unsafe_set(
      short_hash_product(product, shift=short_shift),
      stamped,
    )
    set_chain_previous(prev, position, head.unsafe_get(h) - base)
    head.unsafe_set(h, stamped)
  }
  if long_end < end {
    finder.insert_window_pos(data, long_end, available_end)
  }
}

///|
/// Packed private token representation. Literals are their byte value 0..255.
/// A match is `(length << 16) | distance`, the same layout returned by
/// `find_match`. With length <= 258 and distance <= 32768, every token is a
/// non-negative Int below 2^25 on every backend. Unlike enum payloads, this
/// scalar representation does not allocate once per input token.
#inline
fn pack_match_token(length : Int32, distance : Int32) -> Int32 {
  (length << 16) | distance
}

///|
/// Record one match token starting at byte `start` with the given `length` and
/// `distance`: push the packed token, tally its literal/length and distance
/// symbols, and fill the hash chain over the match's interior bytes so later
/// positions may match inside it. Returns the position one past the match.
#inline
fn commit_match(
  data : BytesView,
  finder : MatchFinder,
  n : Int32,
  start : Int32,
  length : Int32,
  dist : Int32,
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  tokens.push(pack_match_token(length, dist))
  ll_freq[257 + len_to_idx[length]] += 1
  d_freq[dist_index(dist)] += 1
  let match_end = start + length
  if length >= 32 {
    finder.insert_matched_positions(data, start + 1, match_end, n)
  } else {
    finder.insert_positions(data, start + 1, match_end, n)
  }
  match_end
}

///|
#inline
fn commit_window_match(
  data : FixedArray[Byte],
  finder : MatchFinder,
  end : Int32,
  start : Int32,
  length : Int32,
  dist : Int32,
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  tokens.push(pack_match_token(length, dist))
  ll_freq[257 + len_to_idx[length]] += 1
  d_freq[dist_index(dist)] += 1
  let match_end = start + length
  if length >= 32 {
    finder.insert_matched_window_positions(data, start + 1, match_end, end)
  } else {
    finder.insert_window_positions(data, start + 1, match_end, end)
  }
  match_end
}

///|
/// Record one literal token: push its byte value and tally its symbol.
#inline
fn emit_literal(
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  b : Int32,
) -> Unit {
  tokens.push(b)
  ll_freq[b] += 1
}

///|
/// LZ77 over `data[start:end)` with the given level's search tuning. Appends to
/// the caller-owned `tokens`, increments the caller-owned literal/length and
/// distance frequency tables (sized 286 / 30, end-of-block not yet counted),
/// and returns the absolute position one past the last byte consumed (≥ `end`
/// when a match straddled the boundary). Callers pass fresh, zeroed outputs.
///
/// `finder` persists for the whole compression session, so prior blocks are
/// already chained when this call begins. Matches may extend past `end` into
/// any lookahead present in `data`.
fn tokenize(
  data : BytesView,
  finder : MatchFinder,
  start : Int32,
  end : Int32,
  cfg : LevelConfig,
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  let n = data.length()
  // The default level uses a distance-aware lazy decision. Other levels
  // retain their existing search policy and budgets.
  // Tiny blocks have too little evidence for the sampled literal-cost model.
  let cost_model = cfg == level_configs[6] &&
    (finder.min_match_length > 0 || n - start >= 1024)
  if cost_model && finder.min_match_length == 0 && n - start >= 512 {
    let used = FixedArray::make(256, 0)
    for j in start..<(start + 4096).min(n) {
      used[data[j].to_int()] = 1
    }
    let mut distinct = 0
    for j in 0..<256 {
      distinct += used[j]
    }
    finder.min_match_length = minimum_match_length(distinct)
  }
  let min_length = if cost_model { finder.min_match_length.max(3) } else { 3 }
  let max_lazy = if cost_model { 65 } else { cfg.max_lazy }
  // A broad byte alphabet makes long hash chains mostly collision probes;
  // cap their work aggressively while retaining a larger budget for text.
  let chain_budget = if min_length >= 5 {
    17
  } else if min_length >= 4 {
    24
  } else {
    8
  }
  let chain_budget_after_prev = if min_length >= 5 {
    8
  } else if min_length >= 4 {
    12
  } else {
    4
  }
  let cost_cfg = {
    good_length: 259,
    max_lazy: 65,
    nice_length: 65,
    max_chain: chain_budget,
  }
  let cost_cfg_after_prev = {
    good_length: 259,
    max_lazy: 65,
    nice_length: 65,
    max_chain: chain_budget_after_prev,
  }
  // LZ77 with hash chains: head[hash] is the most recent position with a
  // given 4-byte hash, prev[pos] the next-older. "Lazy" means a match found
  // at i is held back to see if i+1 starts a longer one.
  let mut i = start
  let mut prev_len = 0
  let mut prev_dist = 0
  let mut have_prev = false // a match found at i-1 is pending a decision
  while i < end {
    // The current position is searched and inserted in the same iteration.
    // Carry its packed word/hash across both operations so incompressible
    // input pays for one load and multiply instead of two.
    let has_word = has_bytes_from(i, 4, n)
    let mut prefix = 0U
    let mut product = 0U
    if has_word {
      prefix = read_match_word(data, i)
      product = prefix * 0x1E35A7BDU
    }
    // Skip the search when the deferred match is already >= max_lazy: it is
    // good enough to commit without looking for a longer one (zlib).
    let searching = has_bytes_from(i, 3, n) &&
      !(have_prev && prev_len >= max_lazy)
    let base = if have_prev {
      prev_len - (if cost_model { 1 } else { 0 })
    } else {
      min_length - 1
    }
    let search_cfg = if cost_model {
      if have_prev {
        cost_cfg_after_prev
      } else {
        cost_cfg
      }
    } else {
      cfg
    }
    let match_info = if searching {
      if has_word {
        finder.find_match_hashed(data, i, n, base, search_cfg, prefix, product)
      } else {
        finder.find_match(data, i, n, base, search_cfg)
      }
    } else {
      0
    }
    let cur_len = match_info >> 16
    let cur_dist = match_info & 0xFFFF
    // The deferred match (starting at i-1) wins: emit it.
    let prefer_current = cur_dist > 0 &&
      (
        !cost_model ||
        (
          cur_len >= prev_len &&
          4 * (cur_len - prev_len) + cur_dist.clz() - prev_dist.clz() > 2
        )
      )
    guard !have_prev || prefer_current else {
      i = commit_match(
        data,
        finder,
        n,
        i - 1,
        prev_len,
        prev_dist,
        tokens,
        ll_freq,
        d_freq,
      )
      have_prev = false
      continue
    }
    // A deferred commit inserts i as an interior position. Insert it here
    // only when that commit did not happen, so prev never links to itself.
    if has_word {
      finder.insert_pos_hashed(i, product)
    } else {
      finder.insert_pos(data, i, n)
    }
    // A longer match starts at i: emit a literal for i-1, keep deferring.
    guard !have_prev else {
      emit_literal(tokens, ll_freq, data[i - 1].to_int())
      prev_len = cur_len
      prev_dist = cur_dist
      i = i + 1
      continue
    }
    // No match at i: literal.
    guard cur_dist > 0 &&
      cur_len >= min_length &&
      !(cost_model && cur_len == 3 && cur_dist > 8192) else {
      emit_literal(tokens, ll_freq, data[i].to_int())
      i = i + 1
      continue
    }
    // Greedy levels (1-3): commit the match immediately.
    guard cfg.max_lazy > 0 else {
      i = commit_match(
        data, finder, n, i, cur_len, cur_dist, tokens, ll_freq, d_freq,
      )
      continue
    }
    // Lazy levels: hold this match back to see if i+1 starts a longer one.
    prev_len = cur_len
    prev_dist = cur_dist
    have_prev = true
    i = i + 1
  }
  if have_prev {
    // A still-pending match at the boundary commits here.
    i = commit_match(
      data,
      finder,
      n,
      i - 1,
      prev_len,
      prev_dist,
      tokens,
      ll_freq,
      d_freq,
    )
  }
  i
}

///|
// Streaming counterpart of `tokenize`: positions are absolute within the
// mirrored input ring, but the parse policy and token accounting are exactly
// the same as the one-shot path above.
fn tokenize_window(
  data : FixedArray[Byte],
  finder : MatchFinder,
  start : Int32,
  token_end : Int32,
  available_end : Int32,
  cfg : LevelConfig,
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> Int32 {
  // The default level uses a distance-aware lazy decision. Other levels
  // retain their existing search policy and budgets.
  let cost_model = cfg == level_configs[6] &&
    (finder.min_match_length > 0 || available_end - start >= 1024)
  if cost_model && finder.min_match_length == 0 && available_end - start >= 512 {
    let used = FixedArray::make(256, 0)
    for j in start..<(start + 4096).min(available_end) {
      used[data[j & STREAM_RING_MASK].to_int()] = 1
    }
    let mut distinct = 0
    for j in 0..<256 {
      distinct += used[j]
    }
    finder.min_match_length = minimum_match_length(distinct)
  }
  let min_length = if cost_model { finder.min_match_length.max(3) } else { 3 }
  let max_lazy = if cost_model { 65 } else { cfg.max_lazy }
  // Match the whole-buffer parser's collision budget in the ring path.
  let chain_budget = if min_length >= 5 {
    17
  } else if min_length >= 4 {
    24
  } else {
    8
  }
  let chain_budget_after_prev = if min_length >= 5 {
    8
  } else if min_length >= 4 {
    12
  } else {
    4
  }
  let cost_cfg = {
    good_length: 259,
    max_lazy: 65,
    nice_length: 65,
    max_chain: chain_budget,
  }
  let cost_cfg_after_prev = {
    good_length: 259,
    max_lazy: 65,
    nice_length: 65,
    max_chain: chain_budget_after_prev,
  }
  let mut i = start
  let mut prev_len = 0
  let mut prev_dist = 0
  let mut have_prev = false
  while i < token_end {
    // Reuse the current four-byte hash between the match probe and insertion.
    let has_word = i + 4 <= available_end
    let mut prefix = 0U
    let mut product = 0U
    if has_word {
      prefix = read_window_match_word(data, i)
      product = prefix * 0x1E35A7BDU
    }
    let searching = i + 3 <= available_end &&
      !(have_prev && prev_len >= max_lazy)
    let base = if have_prev {
      prev_len - (if cost_model { 1 } else { 0 })
    } else {
      min_length - 1
    }
    let search_cfg = if cost_model {
      if have_prev {
        cost_cfg_after_prev
      } else {
        cost_cfg
      }
    } else {
      cfg
    }
    let match_info = if searching {
      if has_word {
        finder.find_window_match_hashed(
          data, i, available_end, base, search_cfg, prefix, product,
        )
      } else {
        finder.find_window_match(data, i, available_end, base, search_cfg)
      }
    } else {
      0
    }
    let cur_len = match_info >> 16
    let cur_dist = match_info & 0xFFFF
    let prefer_current = cur_dist > 0 &&
      (
        !cost_model ||
        (
          cur_len >= prev_len &&
          4 * (cur_len - prev_len) + cur_dist.clz() - prev_dist.clz() > 2
        )
      )
    guard !have_prev || prefer_current else {
      i = commit_window_match(
        data,
        finder,
        available_end,
        i - 1,
        prev_len,
        prev_dist,
        tokens,
        ll_freq,
        d_freq,
      )
      have_prev = false
      continue
    }
    // The deferred commit above already inserts its interior positions.
    if has_word {
      finder.insert_window_pos_hashed(i, product)
    } else {
      finder.insert_window_pos(data, i, available_end)
    }
    guard !have_prev else {
      emit_literal(tokens, ll_freq, data[(i - 1) & STREAM_RING_MASK].to_int())
      prev_len = cur_len
      prev_dist = cur_dist
      i = i + 1
      continue
    }
    guard cur_dist > 0 &&
      cur_len >= min_length &&
      !(cost_model && cur_len == 3 && cur_dist > 8192) else {
      emit_literal(tokens, ll_freq, data[i & STREAM_RING_MASK].to_int())
      i = i + 1
      continue
    }
    guard cfg.max_lazy > 0 else {
      i = commit_window_match(
        data, finder, available_end, i, cur_len, cur_dist, tokens, ll_freq, d_freq,
      )
      continue
    }
    prev_len = cur_len
    prev_dist = cur_dist
    have_prev = true
    i = i + 1
  }
  if have_prev {
    i = commit_window_match(
      data,
      finder,
      available_end,
      i - 1,
      prev_len,
      prev_dist,
      tokens,
      ll_freq,
      d_freq,
    )
  }
  i
}

///|
#inline
fn set_chain_previous(
  chain : FixedArray[Byte],
  position : Int32,
  previous : Int32,
) -> Unit {
  // Every reachable predecessor is older. Saturate expired links to a
  // distance beyond the window, which also fits in an unsigned 16-bit slot.
  // An expired head can lie more than `Int`'s range below `position` (a head
  // of an earlier stream, moved further down by a rebase), so compare before
  // subtracting: `position` is not negative.
  let delta = if previous < position - WINDOW_SIZE {
    WINDOW_SIZE + 1
  } else {
    position - previous
  }
  let index = (position & WINDOW_MASK) * 2
  chain.unsafe_set(index, delta.to_byte())
  chain.unsafe_set(index + 1, (delta >> 8).to_byte())
}

///|
#cfg(any(target="native", target="wasm"))
#inline
fn chain_previous(chain : FixedArray[Byte], position : Int32) -> Int32 {
  let index = (position & WINDOW_MASK) * 2
  // The ring has two padding bytes for the final unaligned four-byte load;
  // only the low halfword belongs to this link.
  let delta = match_window_as_bytes(chain).unsafe_read_uint32_le(index) & 0xFFFF
  position - delta.reinterpret_as_int()
}

///|
#cfg(not(any(target="native", target="wasm")))
#inline
fn chain_previous(chain : FixedArray[Byte], position : Int32) -> Int32 {
  let index = (position & WINDOW_MASK) * 2
  let delta = chain.unsafe_get(index).to_int() |
    (chain.unsafe_get(index + 1).to_int() << 8)
  position - delta
}

///|
// Each complete four-byte word inside the match already occurs within the
// live window, so its predecessor distance needs no saturation. The final
// three positions may cross the match boundary and use general insertion.
// Callers have already proved a match length of at least 32 bytes.
fn MatchFinder::insert_matched_positions(
  finder : MatchFinder,
  data : BytesView,
  start : Int32,
  end : Int32,
  available_end : Int32,
) -> Unit {
  let end = end.min(available_end - 2)
  let long_end = (end - 3).min(available_end - 3)
  let head = finder.head
  let short_head = finder.short_head
  let prev = finder.prev
  let base = finder.position_base
  let short_shift = finder.short_shift
  let long_shift = finder.long_shift
  // Whole groups of four positions are hashed in vector lanes where those
  // are real; the loop below inserts what is left.
  let start = finder.insert_matched_quads(data, start, long_end)
  for position in start..<long_end {
    let product = read_match_word(data, position) * 0x1E35A7BDU
    let h = long_hash_product(product, shift=long_shift)
    let stamped = position + base
    short_head.unsafe_set(
      short_hash_product(product, shift=short_shift),
      stamped,
    )
    let delta = stamped - head.unsafe_get(h)
    let index = (position & WINDOW_MASK) * 2
    prev.unsafe_set(index, delta.to_byte())
    prev.unsafe_set(index + 1, (delta >> 8).to_byte())
    head.unsafe_set(h, stamped)
  }
  finder.insert_positions(data, long_end, end, available_end)
}

///|
fn MatchFinder::insert_matched_window_positions(
  finder : MatchFinder,
  data : FixedArray[Byte],
  start : Int32,
  end : Int32,
  available_end : Int32,
) -> Unit {
  let end = end.min(available_end - 2)
  let long_end = (end - 3).min(available_end - 3)
  let head = finder.head
  let short_head = finder.short_head
  let prev = finder.prev
  let base = finder.position_base
  let short_shift = finder.short_shift
  let long_shift = finder.long_shift
  let start = finder.insert_matched_window_quads(data, start, long_end)
  for position in start..<long_end {
    let product = read_window_match_word(data, position) * 0x1E35A7BDU
    let h = long_hash_product(product, shift=long_shift)
    let stamped = position + base
    short_head.unsafe_set(
      short_hash_product(product, shift=short_shift),
      stamped,
    )
    let delta = stamped - head.unsafe_get(h)
    let index = (position & WINDOW_MASK) * 2
    prev.unsafe_set(index, delta.to_byte())
    prev.unsafe_set(index + 1, (delta >> 8).to_byte())
    head.unsafe_set(h, stamped)
  }
  finder.insert_window_positions(data, long_end, end, available_end)
}

///|
/// The two hashes of the four overlapping four-byte words at the start of
/// `bytes`, in lanes: `long_hash_product` (`shorts` false) or
/// `short_hash_product` of `word * 0x1E35A7BD` for the words at byte 0, 1, 2
/// and 3. Lane arithmetic is 32-bit and wraps like `UInt`.
#cfg(any(target="native", target="wasm"))
#inline
fn matched_quad_hashes(bytes : V128, shift : Int32, shorts : Bool) -> V128 {
  let words = @v128.i8x16_shuffle(
    bytes, bytes, 0, 1, 2, 3, 1, 2, 3, 4, 2, 3, 4, 5, 3, 4, 5, 6,
  )
  let products = @v128.i32x4_mul(words, @v128.i32x4_splat(0x1E35A7BDU))
  if shorts {
    @v128.i32x4_shr_u(
      @v128.v128_and_(products, @v128.i32x4_splat(0xFFFFFFU)),
      shift,
    )
  } else {
    @v128.i32x4_shr_u(products, shift)
  }
}

///|
/// One position of `insert_matched_positions`, its hashes already computed:
/// the same three stores in the same order. The tables are passed in so the
/// callers' loops keep them in locals.
#cfg(any(target="native", target="wasm"))
#inline
fn link_matched_position(
  short_head : FixedArray[Int32],
  head : FixedArray[Int32],
  prev : FixedArray[Byte],
  base : Int32,
  position : Int32,
  long_hash : UInt32,
  short_hash : UInt32,
) -> Unit {
  // The hashes are those of the scalar loop, which indexes the same tables
  // unchecked: the shifts keep them below the tables' logical sizes.
  let h = long_hash.reinterpret_as_int()
  let stamped = position + base
  short_head.unsafe_set(short_hash.reinterpret_as_int(), stamped)
  let delta = stamped - head.unsafe_get(h)
  let index = (position & WINDOW_MASK) * 2
  prev.unsafe_set(index, delta.to_byte())
  prev.unsafe_set(index + 1, (delta >> 8).to_byte())
  head.unsafe_set(h, stamped)
}

///|
/// Insert the positions of `[start, long_end)` four at a time while a
/// 16-byte load at the position stays inside `data`, and return the first
/// position not inserted. Positions are linked in ascending order, one after
/// the other, so a later position of a group sees the heads an earlier one
/// wrote, exactly as in the scalar loop of `insert_matched_positions`.
#cfg(any(target="native", target="wasm"))
fn MatchFinder::insert_matched_quads(
  finder : MatchFinder,
  data : BytesView,
  start : Int32,
  long_end : Int32,
) -> Int32 {
  let bytes = bytes_as_fixedarray(data.data())
  let offset = data.start_offset()
  let length = data.length()
  let head = finder.head
  let short_head = finder.short_head
  let prev = finder.prev
  let base = finder.position_base
  let short_shift = finder.short_shift
  let long_shift = finder.long_shift
  let mut position = start
  // SAFETY: `position >= start >= 0` and `position <= length - 16`: the
  // sixteen bytes lie inside the view. Only bytes 0..6 are used, the words
  // of `position..position + 3`, all below `long_end`.
  while position <= long_end - 4 && position <= length - 16 {
    let block = @v128.v128_load(bytes, offset + position)
    let longs = matched_quad_hashes(block, long_shift, false)
    let shorts = matched_quad_hashes(block, short_shift, true)
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position,
      @v128.i32x4_extract_lane(longs, 0),
      @v128.i32x4_extract_lane(shorts, 0),
    )
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position + 1,
      @v128.i32x4_extract_lane(longs, 1),
      @v128.i32x4_extract_lane(shorts, 1),
    )
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position + 2,
      @v128.i32x4_extract_lane(longs, 2),
      @v128.i32x4_extract_lane(shorts, 2),
    )
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position + 3,
      @v128.i32x4_extract_lane(longs, 3),
      @v128.i32x4_extract_lane(shorts, 3),
    )
    position = position + 4
  }
  position
}

///|
/// `insert_matched_quads` for the mirrored ring: a load at a masked position
/// may run into the mirror half, which holds the same bytes.
#cfg(any(target="native", target="wasm"))
fn MatchFinder::insert_matched_window_quads(
  finder : MatchFinder,
  data : FixedArray[Byte],
  start : Int32,
  long_end : Int32,
) -> Int32 {
  let head = finder.head
  let short_head = finder.short_head
  let prev = finder.prev
  let base = finder.position_base
  let short_shift = finder.short_shift
  let long_shift = finder.long_shift
  let mut position = start
  while position <= long_end - 4 {
    // SAFETY: the masked offset is below `STREAM_RING_SIZE` and the storage
    // is twice that, so sixteen bytes are there. Only bytes 0..6 are used,
    // the words of `position..position + 3`, which the mirror keeps equal.
    let block = @v128.v128_load(data, position & STREAM_RING_MASK)
    let longs = matched_quad_hashes(block, long_shift, false)
    let shorts = matched_quad_hashes(block, short_shift, true)
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position,
      @v128.i32x4_extract_lane(longs, 0),
      @v128.i32x4_extract_lane(shorts, 0),
    )
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position + 1,
      @v128.i32x4_extract_lane(longs, 1),
      @v128.i32x4_extract_lane(shorts, 1),
    )
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position + 2,
      @v128.i32x4_extract_lane(longs, 2),
      @v128.i32x4_extract_lane(shorts, 2),
    )
    link_matched_position(
      short_head,
      head,
      prev,
      base,
      position + 3,
      @v128.i32x4_extract_lane(longs, 3),
      @v128.i32x4_extract_lane(shorts, 3),
    )
    position = position + 4
  }
  position
}

///|
/// Without vector lanes the scalar loops insert every position.
#cfg(not(any(target="native", target="wasm")))
#inline
fn MatchFinder::insert_matched_quads(
  _finder : MatchFinder,
  _data : BytesView,
  start : Int32,
  _long_end : Int32,
) -> Int32 {
  start
}

///|
#cfg(not(any(target="native", target="wasm")))
#inline
fn MatchFinder::insert_matched_window_quads(
  _finder : MatchFinder,
  _data : FixedArray[Byte],
  start : Int32,
  _long_end : Int32,
) -> Int32 {
  start
}

///|
// Fewer distinct literals mean cheaper literal codes, making short matches
// less attractive. Sample once after at least 512 input bytes are available.
fn minimum_match_length(distinct : Int32) -> Int32 {
  match () {
    _ if distinct >= 80 => 3
    _ if distinct >= 45 => 4
    _ if distinct >= 16 => 5
    _ if distinct >= 10 => 6
    _ if distinct >= 8 => 7
    _ if distinct >= 6 => 8
    _ => 9
  }
}
