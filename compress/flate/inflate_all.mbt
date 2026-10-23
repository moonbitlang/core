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
/// Output storage for the one-shot decoder. Unlike the general-purpose core
/// `@buffer.Buffer`, this exposes the fixed backing array needed for DEFLATE's
/// overlapping back-reference copies.
priv struct DecodeOutput {
  mut storage : FixedArray[Byte]
  mut length : Int32
  fixed_capacity : Bool
}

///|
fn DecodeOutput::DecodeOutput(size_hint : Int32) -> DecodeOutput {
  {
    storage: FixedArray::make(size_hint.max(1), b'\x00'),
    length: 0,
    fixed_capacity: false,
  }
}

///|
/// Use caller-owned storage for a one-shot decode. Capacity exhaustion becomes
/// the existing public `OutputLimitExceeded` failure instead of reallocating.
fn DecodeOutput::into(storage : FixedArray[Byte]) -> DecodeOutput {
  { storage, length: 0, fixed_capacity: true, }
}

///|
/// Byte counts use signed 32-bit Int on every backend.
const MAX_DECODE_OUTPUT_SIZE : Int32 = 0x7FFFFFFF

///|
/// Both counts are non-negative. Check the remaining range before adding so
/// overflow cannot bypass the capacity check or reach an array write.
fn checked_decode_output_length(
  length : Int32,
  additional : Int32,
) -> Int32 raise InflateError {
  guard additional <= MAX_DECODE_OUTPUT_SIZE - length else {
    raise InflateError(OutputLimitExceeded, "DEFLATE output size overflow")
  }
  length + additional
}

///|
/// Retain geometric growth when doubling fits; otherwise allocate only the
/// required size. Keeping this arithmetic separate permits allocation-free
/// tests at the integer limit.
fn grown_decode_output_capacity(current : Int32, required : Int32) -> Int32 {
  if current <= MAX_DECODE_OUTPUT_SIZE / 2 {
    (current * 2).max(required)
  } else {
    required
  }
}

///|
fn DecodeOutput::ensure_capacity(
  self : DecodeOutput,
  additional : Int32,
) -> Unit raise InflateError {
  let required = checked_decode_output_length(self.length, additional)
  guard required > self.storage.length() else { return }
  guard !self.fixed_capacity else {
    raise InflateError(
      OutputLimitExceeded,
      "decoded output exceeds output buffer",
    )
  }
  let capacity = grown_decode_output_capacity(self.storage.length(), required)
  self.storage = FixedArray::make_and_blit(
    self.storage,
    allocate_len=capacity,
    init=b'\x00',
    len=self.length,
  )
}

///|
fn DecodeOutput::append_byte(
  self : DecodeOutput,
  byte : Byte,
) -> Unit raise InflateError {
  self.ensure_capacity(1)
  self.storage[self.length] = byte
  self.length = self.length + 1
}

///|
fn DecodeOutput::append_bytes(
  self : DecodeOutput,
  source : BytesView,
  source_offset : Int32,
  length : Int32,
) -> Unit raise InflateError {
  guard length > 0 else { return }
  self.ensure_capacity(length)
  self.storage.blit_from_bytes(
    self.length,
    source.data(),
    source.start_offset() + source_offset,
    length,
  )
  self.length = self.length + length
}

///|
/// Check capacity, then append a match without writing beyond its exact length.
/// The one-shot driver splits matches at cancellation boundaries.
fn DecodeOutput::append_repeated_suffix(
  self : DecodeOutput,
  distance : Int32,
  length : Int32,
) -> Unit raise InflateError {
  guard length > 0 else { return }
  self.ensure_capacity(length)
  let start = self.length
  let storage = self.storage
  if length <= 8 {
    // Keep the common short-text match in the caller to avoid an extra
    // helper call. Forward byte copies also handle overlapping history.
    for i in 0..<length {
      storage[start + i] = storage[start + i - distance]
    }
  } else if distance == 1 {
    storage.fill(storage[start - 1], start~, end=start + length)
  } else {
    copy_match_bytes(storage, start, distance, length)
  }
  self.length = start + length
}

///|
/// Each vector load precedes its store and distance >= 16 keeps them disjoint.
/// The final vector may rewrite the preceding output bytes, but ends exactly
/// at the match boundary and only reads history that has already been produced.
#cfg(any(target="native", target="wasm"))
fn copy_match_bytes(
  storage : FixedArray[Byte],
  start : Int32,
  distance : Int32,
  length : Int32,
) -> Unit {
  if distance >= 16 && length >= 16 {
    for offset = 0; offset + 16 <= length; offset = offset + 16 {
      @v128.v128_store(
        storage,
        start + offset,
        @v128.v128_load(storage, start + offset - distance),
      )
    }
    if (length & 15) != 0 {
      let offset = length - 16
      @v128.v128_store(
        storage,
        start + offset,
        @v128.v128_load(storage, start + offset - distance),
      )
    }
  } else {
    copy_match_bytes_scalar(storage, start, distance, length)
  }
}

///|
#cfg(not(any(target="native", target="wasm")))
fn copy_match_bytes(
  storage : FixedArray[Byte],
  start : Int32,
  distance : Int32,
  length : Int32,
) -> Unit {
  copy_match_bytes_scalar(storage, start, distance, length)
}

///|
/// Longer overlapping matches double their generated prefix. This is also
/// the fallback on targets without native SIMD; the caller handles short matches.
fn copy_match_bytes_scalar(
  storage : FixedArray[Byte],
  start : Int32,
  distance : Int32,
  length : Int32,
) -> Unit {
  let first = distance.min(length)
  FixedArray::unsafe_blit(storage, start, storage, start - distance, first)
  let mut copied = first
  while copied < length {
    let chunk = copied.min(length - copied)
    FixedArray::unsafe_blit(storage, start + copied, storage, start, chunk)
    copied = copied + chunk
  }
}

///|
/// Whether a growing output of `capacity` bytes that holds `length` makes room
/// for one whole token, 258 bytes, before the native batch looks at it: it has
/// less than that left, and it can still double. Beyond half the size limit
/// growth is by the byte, so there the checked decoder ends the output as it
/// always has, growing only for what is decoded.
#cfg(target="native")
#inline
fn reserves_token(capacity : Int32, length : Int32) -> Bool {
  capacity - length < 258 && capacity <= MAX_DECODE_OUTPUT_SIZE / 2
}

///|
/// Make room for one whole token in an output that grows. The native batch
/// decodes only with that much room, so without this the last 258 bytes before
/// every growth, and all of an output shorter than its first capacity plus
/// 258, were left to the checked decoder. The caller's fixed storage is never
/// replaced.
#cfg(target="native")
fn DecodeOutput::reserve_token(self : DecodeOutput) -> Unit {
  guard !self.fixed_capacity &&
    reserves_token(self.storage.length(), self.length) else {
    return
  }
  self.storage = FixedArray::make_and_blit(
    self.storage,
    allocate_len=grown_decode_output_capacity(
      self.storage.length(),
      self.length + 258,
    ),
    init=b'\x00',
    len=self.length,
  )
}

///|
fn DecodeOutput::to_bytes(self : DecodeOutput) -> Bytes {
  Bytes::from_array(self.storage[:self.length])
}

///|
/// In-memory DEFLATE decoder. Reads from a `Bytes` and appends to `out`.
priv struct MemDecoder {
  mut input : BytesView
  mut pos : Int32 // next input byte
  mut bitbuf : UInt32 // LSB-first bit accumulator
  mut bit_count : Int32 // valid bits in `bitbuf`
  mut out : DecodeOutput
  mut cancelled : () -> Bool // polled every `CANCEL_GRANULARITY` produced bytes
  mut poll_cancel : Bool
  mut next_cancel : Int32 // poll `cancelled` once `out` reaches this length
  dyn_litlen : HuffmanDecoder // literal/length (also reused for the code-length tree)
  dyn_dist : HuffmanDecoder // distance
  clbits : FixedArray[Int32] // decoded literal+distance code lengths
  codebits : FixedArray[Int32] // code-length code lengths
}

///|
const CANCEL_GRANULARITY : Int32 = 4096

///|
fn no_cancellation() -> Bool {
  false
}

///|
/// A DEFLATE Huffman code is at most 15 bits. The one-shot decoder can keep a
/// 24-bit reservoir because it is allowed to consume trailing bytes after the
/// final block, as documented by `inflate_all`'s prefix semantics.
const HUFFMAN_FAST_BITS : Int32 = 15

///|
const HUFFMAN_FAST_REFILL_BITS : Int32 = 24

///|
/// Output chunk size for the streaming one-shot drivers: each `step` call
/// writes into this scratch, so cancellation is polled at this granularity.
const INFLATE_SCRATCH_SIZE : Int32 = 8192

///|
fn MemDecoder::MemDecoder(
  input : BytesView,
  cancelled : () -> Bool,
) -> MemDecoder {
  {
    input,
    pos: 0,
    bitbuf: 0,
    bit_count: 0,
    out: DecodeOutput(input.length()),
    cancelled,
    poll_cancel: true,
    next_cancel: 0,
    dyn_litlen: HuffmanDecoder(),
    dyn_dist: HuffmanDecoder(),
    clbits: FixedArray::make(MAX_NUM_LIT + MAX_NUM_DIST, 0),
    codebits: FixedArray::make(NUM_CODES, 0),
  }
}

///|
/// Reinitialize an in-memory decoder over a new stream while retaining its
/// Huffman and dynamic-header workspace. `output` becomes the complete
/// back-reference history, so no secondary output allocation is needed.
fn MemDecoder::reset_into(
  self : MemDecoder,
  input : BytesView,
  output : FixedArray[Byte],
  cancelled : (() -> Bool)?,
) -> Unit {
  self.input = input
  self.pos = 0
  self.bitbuf = 0
  self.bit_count = 0
  self.out = DecodeOutput::into(output)
  self.set_cancellation(cancelled)
}

///|
/// Release caller-owned storage while keeping only reusable decoding workspace.
fn MemDecoder::release_buffers(self : MemDecoder) -> Unit {
  self.input = b""
  self.out.storage = []
  self.out.length = 0
  self.cancelled = no_cancellation
}

///|
fn MemDecoder::set_cancellation(
  self : MemDecoder,
  cancelled : (() -> Bool)?,
) -> Unit {
  self.cancelled = cancelled.unwrap_or(() => false)
  self.poll_cancel = cancelled is Some(_)
  // Without a callback, capacity/EOF alone delimit the batch. Explicit
  // callbacks still run at entry and every 4096 produced bytes.
  self.next_cancel = if self.poll_cancel { 0 } else { 0x7FFF_FFFF }
}

///|
fn MemDecoder::check_cancel(self : MemDecoder) -> Unit raise InflateError {
  guard self.poll_cancel && self.out.length >= self.next_cancel else { return }
  if (self.cancelled)() {
    raise InflateError(Cancelled, "cancelled by caller")
  }
  self.next_cancel = self.out.length + CANCEL_GRANULARITY
}

///|
#inline
fn MemDecoder::push(self : MemDecoder, b : Byte) -> Unit raise InflateError {
  let out = self.out
  let start = out.length
  // The capacity check also proves start + 1 cannot overflow. Keep growth,
  // output-limit errors and the exact cancellation boundary on the slow path.
  if start < out.storage.length() && start + 1 < self.next_cancel {
    out.storage[start] = b
    out.length = start + 1
  } else {
    out.append_byte(b)
    self.check_cancel()
  }
}

///|
fn MemDecoder::pull_byte(self : MemDecoder) -> Bool {
  if self.pos >= self.input.length() {
    return false
  }
  self.bitbuf = self.bitbuf | (self.input[self.pos].to_uint() << self.bit_count)
  self.bit_count = self.bit_count + 8
  self.pos = self.pos + 1
  true
}

///|
fn MemDecoder::need(self : MemDecoder, n : Int32) -> Unit raise InflateError {
  while self.bit_count < n {
    if !self.pull_byte() {
      raise InflateError(Truncated, "unexpected end of input")
    }
  }
}

///|
fn MemDecoder::read_bits(
  self : MemDecoder,
  n : Int32,
) -> Int32 raise InflateError {
  self.need(n)
  let v = (self.bitbuf & ((1U << n) - 1)).reinterpret_as_int()
  self.bitbuf = self.bitbuf >> n
  self.bit_count = self.bit_count - n
  v
}

///|
fn MemDecoder::huff_sym(
  self : MemDecoder,
  h : HuffmanDecoder,
) -> Int32 raise InflateError {
  let mut n = h.min
  for ;; {
    while self.bit_count < n {
      if !self.pull_byte() {
        raise InflateError(Truncated, "unexpected end of input")
      }
    }
    let mut chunk = h.chunks[(self.bitbuf & 0x1FF).reinterpret_as_int()]
    n = (chunk & 0xF).reinterpret_as_int()
    if n > HUFFMAN_CHUNK_BITS {
      let link = ((self.bitbuf >> HUFFMAN_CHUNK_BITS) & h.link_mask).reinterpret_as_int()
      chunk = h.links[(chunk >> HUFFMAN_VALUE_SHIFT).reinterpret_as_int() + link]
      n = (chunk & 0xF).reinterpret_as_int()
    }
    if n <= self.bit_count {
      if n == 0 {
        raise InflateError(Corrupt, "corrupt: bad Huffman code")
      }
      self.bitbuf = self.bitbuf >> n
      self.bit_count = self.bit_count - n
      return ((chunk >> HUFFMAN_VALUE_SHIFT) & 0x1FF).reinterpret_as_int()
    }
  }
}

///|
/// Refill the one-shot bit reservoir in two-byte groups when possible. This is
/// intentionally private to `MemDecoder`: a streaming inflater must not read
/// past the current symbol because those bytes can be a container trailer.
#inline
fn MemDecoder::refill_huffman_fast(self : MemDecoder) -> Unit {
  while self.bit_count < HUFFMAN_FAST_REFILL_BITS &&
        self.pos < self.input.length() {
    if self.bit_count <= HUFFMAN_FAST_BITS && self.pos + 1 < self.input.length() {
      let pair = self.input[self.pos].to_uint() |
        (self.input[self.pos + 1].to_uint() << 8)
      self.bitbuf = self.bitbuf | (pair << self.bit_count)
      self.bit_count = self.bit_count + 16
      self.pos = self.pos + 2
    } else {
      self.bitbuf = self.bitbuf |
        (self.input[self.pos].to_uint() << self.bit_count)
      self.bit_count = self.bit_count + 8
      self.pos = self.pos + 1
    }
  }
}

///|
/// Decode a data-block symbol using the prefilled fast reservoir when possible.
/// Unlike the dynamic-header path, this loop is the dominant one-shot decode
/// cost, so it keeps a wide reservoir and only falls back near physical EOF.
#inline
fn MemDecoder::huff_sym_data(
  self : MemDecoder,
  h : HuffmanDecoder,
) -> Int32 raise InflateError {
  // Fifteen buffered bits cover any DEFLATE code. Avoid topping up the
  // reservoir on every symbol when the next lookup can already complete.
  if self.bit_count < HUFFMAN_FAST_BITS {
    self.refill_huffman_fast()
  }
  if self.bit_count < HUFFMAN_FAST_BITS {
    return self.huff_sym(h)
  }
  let mut chunk = h.chunks[(self.bitbuf & 0x1FF).reinterpret_as_int()]
  let mut n = (chunk & 0xF).reinterpret_as_int()
  if n > HUFFMAN_CHUNK_BITS {
    let link = ((self.bitbuf >> HUFFMAN_CHUNK_BITS) & h.link_mask).reinterpret_as_int()
    chunk = h.links[(chunk >> HUFFMAN_VALUE_SHIFT).reinterpret_as_int() + link]
    n = (chunk & 0xF).reinterpret_as_int()
  }
  guard n != 0 else { raise InflateError(Corrupt, "corrupt: bad Huffman code") }
  self.bitbuf = self.bitbuf >> n
  self.bit_count = self.bit_count - n
  ((chunk >> HUFFMAN_VALUE_SHIFT) & 0x1FF).reinterpret_as_int()
}

///|
/// Decode and copy one length/distance pair. Keeping the uncommon match path
/// separate lets `decode_block` keep its literal fast loop branch-predictable.
#inline
fn MemDecoder::decode_match(
  self : MemDecoder,
  code : Int32,
  hd : HuffmanDecoder?,
) -> Unit raise InflateError {
  guard code < 286 else {
    raise InflateError(Corrupt, "corrupt: invalid literal/length code")
  }
  let length_info = length_code_info_table[code - 257]
  let length = (length_info >> 3) + self.read_bits(length_info & 0x7)
  let dsym = if hd is Some(h) {
    self.huff_sym_data(h)
  } else {
    fixed_distance_symbol(self.read_bits(5))
  }
  guard dsym.reinterpret_as_uint() < MAX_NUM_DIST.reinterpret_as_uint() else {
    raise InflateError(Corrupt, "corrupt: invalid distance code")
  }
  let distance_info = distance_code_info_table[dsym]
  // `read_bits(0)` reads nothing and returns 0, so the base serves as the
  // distance when the code carries no extra bits.
  let dist = (distance_info >> 4) + self.read_bits(distance_info & 0xF)
  let available_history = self.out.length
  guard available_history >= WINDOW_SIZE ||
    back_reference_distance_is_valid(dist, available_history) else {
    raise InflateError(Corrupt, "corrupt: distance too far back")
  }
  // Copy a complete match here when capacity and the cancellation interval
  // permit it. Subtract before comparing so the output bound cannot overflow.
  // Short text matches use forward byte copies, including overlapping history.
  let out = self.out
  let start = out.length
  if length <= out.storage.length() - start && length < self.next_cancel - start {
    let storage = out.storage
    if length <= 16 {
      // A decoded match is at least three bytes. Keep the mandatory prefix
      // outside the loop; sequential stores preserve distances one and two.
      storage[start] = storage[start - dist]
      storage[start + 1] = storage[start + 1 - dist]
      storage[start + 2] = storage[start + 2 - dist]
      for i in 3..<length {
        storage[start + i] = storage[start + i - dist]
      }
    } else if dist == 1 {
      storage.fill(storage[start - 1], start~, end=start + length)
    } else {
      copy_match_bytes(storage, start, dist, length)
    }
    out.length = start + length
  } else {
    self.copy_match(dist, length)
  }
}

///|
// Lookup only: the batch caller has at least 15 bits and checks invalid entries.
#cfg(target="native")
#inline
fn batch_huffman_entry(h : HuffmanDecoder, bits : UInt64) -> UInt32 {
  // HuffmanDecoder always owns 512 primary entries, including empty trees.
  // Masking to nine bits proves this load's range independently of input.
  let chunk = h.chunks.unsafe_get((bits & 0x1FFUL).to_int())
  if (chunk & 15) > HUFFMAN_CHUNK_BITS.reinterpret_as_uint() {
    let link = ((bits >> HUFFMAN_CHUNK_BITS).to_uint() & h.link_mask).reinterpret_as_int()
    h.links[(chunk >> HUFFMAN_VALUE_SHIFT).reinterpret_as_int() + link]
  } else {
    chunk
  }
}

///|
// Low input lanes contain eight history bytes; high lanes hold old output.
// Repeating only the available history handles overlap, while selecting old
// output beyond the match preserves every caller-owned tail byte.
#cfg(target="native")
let short_copy_shuffle : FixedArray[Byte] = FixedArray::makei(1024, index => {
  let lane = index & 15
  let length = index >> 7
  let distance = ((index >> 4) & 7).max(1)
  if lane < length {
    (lane % distance).to_byte()
  } else {
    (8 + (lane & 7)).to_byte()
  }
})

///|
/// Process complete tokens with local state. A token needs at most 48 bits
/// (15 + 5 + 15 + 13) and emits at most 258 bytes. Uncommitted tokens are
/// retried by the checked decoder, including malformed codes and EOF tails.
#cfg(target="native")
fn MemDecoder::decode_batch(
  self : MemDecoder,
  hl : HuffmanDecoder,
  hd : HuffmanDecoder?,
) -> Bool {
  guard hd is Some(distance_tree) else { return false }
  let input = self.input
  let out = self.out
  // The poll counter is ahead of the output, except after a poll within 4096
  // bytes of the size limit: there it has wrapped below zero, the bound below
  // would wrap with it, and the checked decoder polls as it always has.
  guard input.length() - self.pos >= 8 && self.next_cancel > 0 else {
    return false
  }
  out.reserve_token()
  let storage = out.storage
  let output_end = storage.length().min(self.next_cancel - 1)
  guard output_end - out.length >= 258 else { return false }
  let mut bits = UInt64::extend_uint(self.bitbuf)
  let mut count = self.bit_count
  let mut pos = self.pos
  let mut written = out.length
  let mut next_primary = 0U
  let ended = for ;; {
    let input_length = input.length()
    let output_length = storage.length()
    // Explicit nonnegative ranges enable native bounds-check elimination for
    // the constant-offset loads and stores below.
    let can_decode_token = input_length >= 8 &&
      pos >= 0 &&
      pos <= input_length - 8 &&
      output_length >= 258 &&
      written >= 0 &&
      written <= output_length - 258 &&
      output_end - written >= 258
    guard can_decode_token else { break false }
    let mut word = bits
    let mut remaining = count
    let mut cursor = pos
    if remaining < 48 {
      // The iteration proves eight readable bytes. Advance only by complete
      // bytes fitting below bit 63; afterwards 56..63 bits are available.
      // Higher loaded bits are lookahead from the same unconsumed input. They
      // agree with the next refill's OR and are discarded on batch exit.
      // SAFETY: `can_decode_token` holds `0 <= pos <= input_length - 8`
      // and `cursor` is `pos`: the eight bytes lie inside the view.
      let loaded = input.unsafe_read_uint64_le(cursor)
      let bytes = (63 - remaining) >> 3
      word = word | (loaded << remaining)
      remaining += bytes << 3
      cursor += bytes
    }
    let mut entry = if next_primary != 0U {
      next_primary
    } else {
      hl.chunks.unsafe_get((word & 511UL).to_int())
    }
    if (entry & 15U) > 9U {
      entry = batch_huffman_entry(hl, word)
    }
    let mut used = (entry & 15).reinterpret_as_int()
    guard used != 0 else { break false }
    let mut symbol = ((entry >> HUFFMAN_VALUE_SHIFT) & 0x1FF).reinterpret_as_int()
    if symbol < 256 {
      word = word >> used
      remaining -= used
      // The loop entered with at least 48 bits and a literal uses at most 15,
      // so a complete nine-bit primary prefix remains available.
      next_primary = hl.chunks.unsafe_get((word & 511UL).to_int())
      storage[written] = symbol.to_byte()
      written += 1
      // Preserve this literal even if the following token needs checked
      // fallback. Continue directly only with a full token's reservation.
      bits = word
      count = remaining
      pos = cursor
      guard remaining >= 48 && output_end - written >= 258 else { continue }
      entry = next_primary
      if (entry & 15U) > 9U {
        entry = batch_huffman_entry(hl, word)
      }
      used = (entry & 15).reinterpret_as_int()
      guard used != 0 else { break false }
      symbol = ((entry >> HUFFMAN_VALUE_SHIFT) & 0x1FF).reinterpret_as_int()
    }
    if symbol < 256 {
      word = word >> used
      remaining -= used
      // The paired literal starts only with at least 48 remaining bits.
      next_primary = hl.chunks.unsafe_get((word & 511UL).to_int())
      storage[written] = symbol.to_byte()
      written += 1
    } else if symbol == 256 {
      bits = word >> used
      count = remaining - used
      pos = cursor
      break true
    } else {
      guard symbol < 286 else { break false }
      let info = ((entry >> 13) & 0xFFF).reinterpret_as_int()
      let extra = info & 7
      let length = (info >> 3) +
        ((word >> used) & ((1UL << extra) - 1)).to_int()
      let total = (entry >> 25).reinterpret_as_int()
      word = word >> total
      remaining -= total
      let distance_entry = batch_huffman_entry(distance_tree, word)
      let distance_used = (distance_entry & 15).reinterpret_as_int()
      let distance_info = (distance_entry >> 13).reinterpret_as_int()
      // Native data tables give every valid distance nonzero metadata and
      // leave reserved symbols 30/31 at zero. No separate symbol extraction
      // is needed to reject them before committing the token.
      guard distance_used != 0 && distance_info != 0 else { break false }
      word = word >> distance_used
      remaining -= distance_used
      let distance_extra = distance_info & 15
      let distance = (distance_info >> 4) +
        (word & ((1UL << distance_extra) - 1)).to_int()
      guard distance > 0 && distance <= written else { break false }
      word = word >> distance_extra
      remaining -= distance_extra
      // Only the bounded primary read is speculative. Secondary resolution
      // and invalid-code handling stay after refill on the next iteration.
      next_primary = if remaining >= 9 {
        hl.chunks.unsafe_get((word & 511UL).to_int())
      } else {
        0U
      }
      if length <= 7 {
        // The batch reserves 258 bytes, so these eight-byte reads/writes stay
        // in bounds even for a three-byte match. The shuffle retains the tail.
        let history = @v128.v128_load64_zero(storage, written - distance)
        let combined = @v128.v128_load64_lane(storage, written, history, 1)
        let control = @v128.v128_load(
          short_copy_shuffle,
          (length * 8 + distance.min(7)) * 16,
        )
        @v128.v128_store64_lane(
          storage,
          written,
          @v128.i8x16_swizzle(combined, control),
          0,
        )
      } else if length <= 16 && distance >= 8 {
        @v128.v128_store64_lane(
          storage,
          written,
          @v128.v128_load64_zero(storage, written - distance),
          0,
        )
        if length > 8 {
          let tail = written + length - 8
          @v128.v128_store64_lane(
            storage,
            tail,
            @v128.v128_load64_zero(storage, tail - distance),
            0,
          )
        }
      } else if length <= 16 {
        // Constant offsets reuse the batch's range proof. Each load precedes
        // its store for overlapping history; stop at the exact match length.
        storage[written] = storage[written - distance]
        storage[written + 1] = storage[written + 1 - distance]
        storage[written + 2] = storage[written + 2 - distance]
        if length > 3 {
          storage[written + 3] = storage[written + 3 - distance]
        }
        if length > 4 {
          storage[written + 4] = storage[written + 4 - distance]
        }
        if length > 5 {
          storage[written + 5] = storage[written + 5 - distance]
        }
        if length > 6 {
          storage[written + 6] = storage[written + 6 - distance]
        }
        if length > 7 {
          storage[written + 7] = storage[written + 7 - distance]
        }
        if length > 8 {
          storage[written + 8] = storage[written + 8 - distance]
        }
        if length > 9 {
          storage[written + 9] = storage[written + 9 - distance]
        }
        if length > 10 {
          storage[written + 10] = storage[written + 10 - distance]
        }
        if length > 11 {
          storage[written + 11] = storage[written + 11 - distance]
        }
        if length > 12 {
          storage[written + 12] = storage[written + 12 - distance]
        }
        if length > 13 {
          storage[written + 13] = storage[written + 13 - distance]
        }
        if length > 14 {
          storage[written + 14] = storage[written + 14 - distance]
        }
        if length > 15 {
          storage[written + 15] = storage[written + 15 - distance]
        }
      } else if length <= 48 && distance >= 16 {
        // Length is now 17..48. Two or three forward vectors cover the
        // match without a helper call, and the last store ends exactly.
        @v128.v128_store(
          storage,
          written,
          @v128.v128_load(storage, written - distance),
        )
        if length > 32 {
          @v128.v128_store(
            storage,
            written + 16,
            @v128.v128_load(storage, written + 16 - distance),
          )
        }
        let tail = written + length - 16
        @v128.v128_store(
          storage,
          tail,
          @v128.v128_load(storage, tail - distance),
        )
      } else if distance == 1 {
        storage.fill(storage[written - 1], start=written, end=written + length)
      } else {
        copy_match_bytes(storage, written, distance, length)
      }
      written += length
    }
    bits = word
    count = remaining
    pos = cursor
  }
  // Put unread whole bytes back before narrowing to the original reservoir.
  self.pos = pos - (count >> 3)
  self.bit_count = count & 7
  self.bitbuf = bits.to_uint() & ((1U << self.bit_count) - 1)
  out.length = written
  ended
}

///|
// The wide-reservoir fast path is measured on native. Keep the established
// production loop on other backends.
#cfg(not(target="native"))
#inline
fn MemDecoder::decode_batch(
  _self : MemDecoder,
  _hl : HuffmanDecoder,
  _hd : HuffmanDecoder?,
) -> Bool {
  false
}

///|
fn MemDecoder::decode_block(
  self : MemDecoder,
  hl : HuffmanDecoder,
  hd : HuffmanDecoder?,
) -> Unit raise InflateError {
  for ;; {
    if self.decode_batch(hl, hd) {
      return
    }
    let v = self.huff_sym_data(hl)
    guard v >= 256 else {
      self.push(v.to_byte())
      // Most DEFLATE streams contain literal runs. Decode one extra symbol
      // before returning to the match/EOB dispatch to amortize that branch.
      let next = self.huff_sym_data(hl)
      guard next >= 256 else {
        self.push(next.to_byte())
        continue
      }
      guard next != 256 else { return }
      self.decode_match(next, hd)
      continue
    }
    guard v != 256 else { return }
    self.decode_match(v, hd)
  }
}

///|
/// The fixed literal/length and distance codes (RFC 1951 §3.2.6) as native
/// data tables: the distance code as a table of thirty-two five-bit codes, of
/// which the reserved 30 and 31 carry no metadata.
#cfg(target="native")
let fixed_data_decoders : (HuffmanDecoder, HuffmanDecoder) = {
  let litlen = HuffmanDecoder()
  let distance = HuffmanDecoder()
  ignore(litlen.initialize_litlen(fixed_ll_len))
  ignore(distance.initialize_distance(FixedArray::make(32, 5)))
  (litlen, distance)
}

///|
// On native a fixed block is decoded like a dynamic one, by the batch and its
// checked tail, with the fixed codes as tables. Reading a distance through
// the table is reading its five bits: both need five bits or the input ends,
// and both leave the reserved codes to the same check.
#cfg(target="native")
fn MemDecoder::decode_fixed_block(self : MemDecoder) -> Unit raise InflateError {
  let (litlen, distance) = fixed_data_decoders
  self.decode_block(litlen, Some(distance))
}

///|
// Without the batch, dispatch once per block instead of paying for a failed
// batch probe on every token.
#cfg(not(target="native"))
fn MemDecoder::decode_fixed_block(self : MemDecoder) -> Unit raise InflateError {
  for ;; {
    let symbol = self.huff_sym_data(fixed_huffman_decoder)
    guard symbol >= 256 else {
      self.push(symbol.to_byte())
      let next = self.huff_sym_data(fixed_huffman_decoder)
      guard next >= 256 else {
        self.push(next.to_byte())
        continue
      }
      guard next != 256 else { return }
      self.decode_match(next, None)
      continue
    }
    guard symbol != 256 else { return }
    self.decode_match(symbol, None)
  }
}

///|
fn MemDecoder::copy_match(
  self : MemDecoder,
  distance : Int32,
  length : Int32,
) -> Unit raise InflateError {
  let mut remaining = length
  while remaining > 0 {
    // Keep the public cancellation cadence while copying in large chunks.
    let until_cancel = if self.poll_cancel {
      self.next_cancel - self.out.length
    } else {
      remaining
    }
    let chunk = remaining.min(until_cancel)
    self.out.append_repeated_suffix(distance, chunk)
    remaining = remaining - chunk
    self.check_cancel()
  }
}

///|
fn MemDecoder::copy_stored(
  self : MemDecoder,
  length : Int32,
) -> Unit raise InflateError {
  let mut remaining = length
  while remaining > 0 {
    // Preserve `inflate_all`'s cancellation cadence while copying each chunk
    // through the core bulk-copy primitive.
    let until_cancel = if self.poll_cancel {
      self.next_cancel - self.out.length
    } else {
      remaining
    }
    let chunk = remaining.min(until_cancel)
    self.out.append_bytes(self.input, self.pos, chunk)
    self.pos = self.pos + chunk
    remaining = remaining - chunk
    self.check_cancel()
  }
}

///|
fn MemDecoder::stored_block(self : MemDecoder) -> Unit raise InflateError {
  // The fast Huffman reader can have prefetched whole bytes beyond the current
  // block header. Byte alignment discards only the remaining partial byte; put
  // those unread whole bytes back so LEN/NLEN starts at the correct input byte.
  self.pos = self.pos - (self.bit_count >> 3)
  self.bitbuf = 0
  self.bit_count = 0
  if !has_bytes_from(self.pos, 4, self.input.length()) {
    raise InflateError(Truncated, "unexpected end of input")
  }
  let len = self.input[self.pos].to_int() |
    (self.input[self.pos + 1].to_int() << 8)
  let nlen = self.input[self.pos + 2].to_int() |
    (self.input[self.pos + 3].to_int() << 8)
  self.pos = self.pos + 4
  validate_stored_length(len, nlen)
  if !has_bytes_from(self.pos, len, self.input.length()) {
    raise InflateError(Truncated, "unexpected end of input")
  }
  self.copy_stored(len)
}

///|
fn MemDecoder::read_dynamic(self : MemDecoder) -> Unit raise InflateError {
  let (nlit, ndist) = decode_dynamic_header(
    n => self.read_bits(n),
    () => self.huff_sym(self.dyn_litlen),
    self.dyn_litlen,
    self.codebits,
    self.clbits,
  )
  guard self.dyn_litlen.initialize_litlen(self.clbits[0:nlit]) else {
    raise InflateError(Corrupt, "corrupt: bad literal/length tree")
  }
  guard self.dyn_dist.initialize_distance(self.clbits[nlit:nlit + ndist]) else {
    raise InflateError(Corrupt, "corrupt: bad distance tree")
  }
}

///|
fn MemDecoder::run(self : MemDecoder) -> Unit raise InflateError {
  self.check_cancel()
  for ;; {
    self.need(3)
    let bfinal = (self.bitbuf & 1) == 1
    let btype = ((self.bitbuf >> 1) & 3).reinterpret_as_int()
    self.bitbuf = self.bitbuf >> 3
    self.bit_count = self.bit_count - 3
    match btype {
      0 => self.stored_block()
      1 => self.decode_fixed_block()
      2 => {
        self.read_dynamic()
        self.decode_block(self.dyn_litlen, Some(self.dyn_dist))
      }
      _ => raise InflateError(Corrupt, "corrupt: reserved block type")
    }
    if bfinal {
      break
    }
  }
}

///|
/// After `run` has returned: how many bytes of the input the stream took, up
/// to and including the byte that holds the last bit of its final block.
/// `pos` counts every byte that was read into the reservoir, and the reservoir
/// is filled ahead of the decoder in whole bytes: those still unread in it
/// are behind the stream. The bits of a started byte belong to it.
fn MemDecoder::consumed(self : MemDecoder) -> Int32 {
  self.pos - (self.bit_count >> 3)
}

///|
/// Decompress a raw DEFLATE stream held entirely in memory. Bytes after the
/// final block are ignored; use `inflate_exact` when an exact framing boundary
/// is required. Omit `max_output` for unbounded output, or supply a non-negative
/// ceiling to raise `OutputLimitExceeded` before returning an oversized result;
/// a negative ceiling raises `InvalidArgument`.
/// If supplied, `cancelled` is polled at entry and every 4096 produced bytes
/// (8192 with `max_output`); returning `true` raises `InflateError(Cancelled, _)`.
pub fn inflate_all(
  input : BytesView,
  max_output? : Int32,
  cancelled? : () -> Bool,
) -> Bytes raise InflateError {
  if max_output is Some(limit) {
    guard limit >= 0 else {
      raise InflateError(InvalidArgument, "max_output must be non-negative")
    }
    return inflate_streaming_all(
      input,
      Some(limit),
      false,
      cancelled.map_or(no_cancellation, callback => callback),
    )
  }
  let d = MemDecoder(input, no_cancellation)
  d.set_cancellation(cancelled)
  d.run()
  d.out.to_bytes()
}

///|
/// A reusable, whole-buffer raw DEFLATE decompressor. It decodes the stream at
/// the front of its input, into caller-owned storage (`decompress_into`) or
/// into new `Bytes` (`decompress`). `decompress_into` returns both byte counts;
/// `last_consumed` also reports the input consumed by either method. Huffman
/// and dynamic-header workspace is retained across streams.
struct Decompressor {
  decoder : MemDecoder
  mut consumed : Int32 // input the latest successful call took
}

///|
/// Create a reusable whole-buffer decompressor.
pub fn Decompressor::Decompressor() -> Decompressor {
  { decoder: MemDecoder(b"", () => false), consumed: 0, }
}

///|
/// Number of input bytes the latest `decompress_into` or `decompress` took:
/// the DEFLATE stream up to and including the byte that holds the last bit of
/// its final block. `input[last_consumed():]` is what the call ignored, a
/// container's trailer for one. Zero initially and after a call raises.
pub fn Decompressor::last_consumed(self : Decompressor) -> Int32 {
  self.consumed
}

///|
/// Decompress `input` into `output`, returning consumed and produced byte counts.
/// The complete output must fit in `output`; otherwise this raises
/// `InflateError(OutputLimitExceeded, _)`. As with `inflate_all`, bytes after
/// the final DEFLATE block are ignored; the returned `consumed` tells where they
/// start. Reuse one `Decompressor` and output buffer to avoid per-stream
/// decoder and result-buffer allocation.
pub fn Decompressor::decompress_into(
  self : Decompressor,
  input : BytesView,
  output : FixedArray[Byte],
  cancelled? : () -> Bool,
) -> DecompressResult raise InflateError {
  self.consumed = 0
  self.decoder.reset_into(input, output, cancelled)
  errdefer self.decoder.release_buffers()
  self.decoder.run()
  self.consumed = self.decoder.consumed()
  let length = self.decoder.out.length
  self.decoder.release_buffers()
  { consumed: self.consumed, produced: length, }
}

///|
/// First output capacity of `Decompressor::decompress`. Its input may reach
/// far beyond the stream it decodes, one member of a file of thousands, so the
/// length of the input is no measure of the output as it is in `inflate_all`:
/// a call starts with at most this much, and growth does the rest. Allocating
/// and clearing it is what a call costs before it decodes anything, which
/// shows on members of a few hundred bytes; doubling from here costs a large
/// stream nothing that can be measured.
const PREFIX_OUTPUT_CAPACITY : Int32 = 16384

///|
/// Decompress `input` into new `Bytes` that grow with the output, as
/// `inflate_all` does, while retaining the Huffman and dynamic-header workspace
/// across streams. Bytes after the final DEFLATE block are ignored;
/// `last_consumed` tells where they start, which is how a container finds the
/// trailer of a member whose length it does not know.
///
/// The output is unbounded and the call cannot be cancelled: a convenience for
/// trusted input. To reject bytes after the stream, use `inflate_exact`. For a
/// prefix decode with a bound, use `decompress_into` (an output of the size
/// allowed, and a `cancelled` callback) or the streaming `Inflater`; both
/// report the input they consumed.
///
/// After an error the decompressor is ready for the next stream as it is, and
/// `last_consumed()` is zero.
pub fn Decompressor::decompress(
  self : Decompressor,
  input : BytesView,
) -> Bytes raise InflateError {
  self.consumed = 0
  let decoder = self.decoder
  decoder.reset_into(input, [], None)
  // Not the caller's storage: an output of its own, which grows.
  decoder.out = DecodeOutput(input.length().min(PREFIX_OUTPUT_CAPACITY))
  errdefer decoder.release_buffers()
  decoder.run()
  self.consumed = decoder.consumed()
  let decoded = decoder.out.to_bytes()
  decoder.release_buffers()
  decoded
}

///|
/// One-shot convenience form of `Decompressor::decompress_into`. It creates a
/// decompressor for this call and returns only the produced count. Use
/// `Decompressor::decompress_into` to obtain both counts and reuse workspace.
pub fn inflate_into(
  input : BytesView,
  output : FixedArray[Byte],
  cancelled? : () -> Bool,
) -> Int32 raise InflateError {
  let decoder = Decompressor()
  if cancelled is Some(callback) {
    decoder.decompress_into(input, output, cancelled=callback).produced
  } else {
    decoder.decompress_into(input, output).produced
  }
}

///|
/// Drive the streaming inflater over an in-memory input. If `exact` is true,
/// reject bytes after the final DEFLATE block. If `max_output` is present, one
/// fixed scratch buffer may be filled past that boundary internally, but no
/// oversized result is returned. `cancelled` is polled at entry and once per
/// step (every 8192 produced bytes); returning `true` raises
/// `InflateError(Cancelled, _)`.
fn inflate_streaming_all(
  input : BytesView,
  max_output : Int32?,
  exact : Bool,
  cancelled : () -> Bool,
) -> Bytes raise InflateError {
  guard !cancelled() else {
    raise InflateError(Cancelled, "cancelled by caller")
  }
  let inflater = Inflater()
  let scratch = FixedArray::make(INFLATE_SCRATCH_SIZE, b'\x00')
  let decoded : Array[Byte] = []
  let mut input_pos = 0
  for ;; {
    let status_result = inflater.step(input[input_pos:], scratch.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    input_pos = input_pos + consumed
    guard !cancelled() else {
      raise InflateError(Cancelled, "cancelled by caller")
    }
    guard max_output.map_or(true, limit => produced <= limit - decoded.length()) else {
      raise InflateError(
        OutputLimitExceeded,
        "decoded output exceeds max_output",
      )
    }
    decoded.append(scratch[:produced])
    match status {
      Done => {
        if exact && input_pos != input.length() {
          raise InflateError(TrailingData, "trailing data after DEFLATE stream")
        }
        return Bytes::from_array(decoded)
      }
      NeedMoreOutput => ()
      NeedMoreInput => raise InflateError(Truncated, "unexpected end of input")
    }
  }
}

///|
/// Decompress exactly one raw DEFLATE stream. Unlike `inflate_all`, this rejects
/// any bytes after the final block.
///
/// Optional controls:
///  - `max_output`: decoded output beyond this size raises
///    `InflateError(OutputLimitExceeded, _)`. A negative value raises
///    `InflateError(InvalidArgument, _)`.
///  - `cancelled`: polled at entry and then once per internal step (every 8192
///    produced bytes); returning `true` raises `InflateError(Cancelled, _)`.
///  - `preallocated`: when `true`, decode runs twice — a counting pass that
///    validates the whole stream, then a second pass filling one exactly sized
///    allocation. Peak memory stays at roughly one decoded output, at the cost
///    of roughly double the decode work; the default `false` grows one buffer
///    in a single pass, trading transient memory for one decode pass.
///
/// With none of the three there is nothing to poll, to bound or to count, and
/// the stream is decoded by the in-memory decoder of `inflate_all` instead of
/// in steps; the input it consumed tells whether anything follows the final
/// block. The result and the errors of a malformed, truncated or extended
/// stream are those of the stepping decoder. An output beyond the 2 GiB that
/// `Bytes` can hold raises `InflateError(OutputLimitExceeded, _)` on this path,
/// as it does with `preallocated`.
pub fn inflate_exact(
  input : BytesView,
  max_output? : Int32,
  cancelled? : () -> Bool,
  preallocated~ : Bool = false,
) -> Bytes raise InflateError {
  if max_output is Some(limit) {
    guard limit >= 0 else {
      raise InflateError(InvalidArgument, "max_output must be non-negative")
    }
  }
  guard max_output is Some(_) || cancelled is Some(_) || preallocated else {
    let decoder = MemDecoder(input, no_cancellation)
    decoder.set_cancellation(None)
    decoder.run()
    guard decoder.consumed() == input.length() else {
      raise InflateError(TrailingData, "trailing data after DEFLATE stream")
    }
    return decoder.out.to_bytes()
  }
  let cancelled = cancelled.unwrap_or(no_cancellation)
  if preallocated {
    inflate_preallocated(input, max_output, cancelled)
  } else {
    inflate_streaming_all(input, max_output, true, cancelled)
  }
}

///|
/// Drive one inflater over the whole in-memory input, delivering produced
/// chunks to `emit` (called once per step with the scratch contents). Returns
/// the total number of bytes produced. `max_output` raises once the total
/// exceeds it; `exact` rejects bytes after the final block; `cancelled` is
/// polled once per step and raises `InflateError(Cancelled, _)`.
fn inflate_drive(
  inflater : Inflater,
  input : BytesView,
  max_output : Int32?,
  exact : Bool,
  cancelled : () -> Bool,
  emit : (FixedArray[Byte], Int32) -> Unit,
) -> Int32 raise InflateError {
  let scratch = FixedArray::make(INFLATE_SCRATCH_SIZE, b'\x00')
  let mut total = 0
  let mut input_pos = 0
  for ;; {
    let status_result = inflater.step(input[input_pos:], scratch.mut_view())
    let status = status_result.status
    guard !(status is NeedMoreInput) else {
      raise InflateError(Truncated, "unexpected end of input")
    }
    let consumed = status_result.consumed
    let produced = status_result.produced
    input_pos = input_pos + consumed
    total = checked_decode_output_length(total, produced)
    guard !cancelled() else {
      raise InflateError(Cancelled, "cancelled by caller")
    }
    guard max_output.map_or(true, limit => total <= limit) else {
      raise InflateError(
        OutputLimitExceeded,
        "decoded output exceeds max_output",
      )
    }
    emit(scratch, produced)
    guard status is Done else { continue }
    if exact && input_pos != input.length() {
      raise InflateError(TrailingData, "trailing data after DEFLATE stream")
    }
    return total
  }
}

///|
/// The replay pass must produce exactly the size measured by the counting pass.
/// A mismatch indicates an internal decoder invariant failure rather than bad
/// caller input.
fn validate_preallocation_size(
  size : Int32,
  filled : Int32,
) -> Unit raise InflateError {
  guard filled == size else {
    raise InflateError(Corrupt, "corrupt: preallocation size mismatch")
  }
}

///|
/// `inflate_exact` with `preallocated=true`: validate and count in one pass
/// over an 8 KiB scratch, then replay the deterministic decode into one exact
/// allocation (the same `Inflater` is reused via `reset`).
fn inflate_preallocated(
  input : BytesView,
  max_output : Int32?,
  cancelled : () -> Bool,
) -> Bytes raise InflateError {
  guard !cancelled() else {
    raise InflateError(Cancelled, "cancelled by caller")
  }
  let inflater = Inflater()
  let size = inflate_drive(inflater, input, max_output, true, cancelled, (
    _scratch,
    _produced,
  ) => ())
  inflater.reset()
  let buf = FixedArray::make(size, b'\x00')
  let mut filled = 0
  ignore(
    inflate_drive(inflater, input, None, true, cancelled, (scratch, produced) => {
      scratch.blit_to(buf, len=produced, dst_offset=filled)
      filled = filled + produced
    }),
  )
  validate_preallocation_size(size, filled)
  owned_decode_buffer_to_bytes(buf)
}

///|
/// Transfers the completely initialized replay output. The array is local to
/// `inflate_preallocated`; neither its mutable view nor an alias escapes.
fn owned_decode_buffer_to_bytes(buffer : FixedArray[Byte]) -> Bytes = "%identity"
