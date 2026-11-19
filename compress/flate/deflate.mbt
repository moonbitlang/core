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
const DEFLATE_BLOCK_SIZE : Int32 = 16384

// Streaming DEFLATE compressor (RFC 1951), the push-based counterpart to
// `IncrementalDecoder`. Unlike a one-shot `deflate_all`, it emits the stream as a
// sequence of blocks while input arrives, so memory is bounded and output is
// produced incrementally.
//
// Model:
//  - Input accumulates in a fixed mirrored 64 KiB ring. `parse_pos` is the
//    first un-emitted absolute position and `pending_end` is one past input.
//  - A persistent 32 KiB hash-chain matchfinder spans every block boundary;
//    no block rebuilds it or copies a carried history window.
//  - When enough tokenizable input has accrued (a block's worth, with a
//    lookahead margin reserved so matches near the boundary aren't truncated),
//    one non-final block is emitted via the shared parse policy and the bytes
//    flow on.
//  - `Finish` tokenizes whatever remains into a final block and flushes.
//  - A persistent `BitWriter` carries the sub-byte bit remainder across blocks
//    (the bit stream is continuous; only the final block pads to a byte). Its
//    whole bytes go to the caller's current view, suspending block emission
//    at a stored payload, header field, or token boundary.

///|
/// Clamp a compression level to 0-9.
fn clamp_level(level : Int32) -> Int32 {
  level.clamp(min=0, max=9)
}

///|
/// Streaming DEFLATE compressor : a push-based, suspendable state
/// machine. It emits the stream block-by-block as input arrives, and chooses fixed- or dynamic-Huffman per block.
struct IncrementalEncoder {
  pending : FixedArray[Byte] // mirrored 64 KiB input ring
  mut parse_pos : Int32 // first un-emitted absolute byte position
  mut pending_end : Int32 // one past the last accepted absolute position
  mut hashed_through : Int32 // first historical position not yet chained
  finder : MatchFinder // persistent 32 KiB hash-chain matchfinder
  w : BitWriter // persistent bit sink spanning all blocks
  mut phase : EmissionPhase
  mut cursor : Int32 // next payload byte, header symbol, or token in `phase`
  mut token_high : UInt32 // upper word of the suspended Huffman bit accumulator
  mut out_pos : Int32 // next byte of the bounded spill
  mut flushing : Bool // an accepted flush has started emitting its blocks
  mut emitted_final : Bool // the current or just-completed block has BFINAL
  mut done : Bool // the final block has been fully drained
  mut flush_done : Bool // the current buffered content has been sync-flushed
  mut flush_requested : Bool // sticky until the requested flush is emitted
  mut end_requested : Bool // sticky until reset; no later input is accepted
  fast_store : Bool
  level : Int32 // compression level 0-9 (0 = stored only)
  cfg : LevelConfig // match-search tuning for `level`
  tokens : Array[Int32]
  ll_freq : FixedArray[Int32]
  d_freq : FixedArray[Int32]
}

///|
/// Create a fresh compressor. `level` 0-9 (clamped) trades speed for ratio
/// with level-specific tuning; 0 emits stored blocks only, 6 is the default.
/// `dictionary`, when supplied, preloads the match window with its last 32 KB;
/// the decoder must use the same preset dictionary. Optional `fast_store`
/// samples each block and may skip compression; it is off by default and
/// may increase output size, including when a dictionary could help.
pub fn IncrementalEncoder::IncrementalEncoder(
  level~ : Int32 = 6,
  dictionary? : BytesView,
  fast_store~ : Bool = false,
) -> IncrementalEncoder {
  let lv = clamp_level(level)
  let deflater = {
    pending: FixedArray::make(STREAM_RING_STORAGE_SIZE, b'\x00'),
    parse_pos: 0,
    pending_end: 0,
    hashed_through: 0,
    finder: MatchFinder(),
    w: BitWriter(spill_on_full=true),
    phase: Idle,
    cursor: 0,
    token_high: 0U,
    flushing: false,
    out_pos: 0,
    emitted_final: false,
    done: false,
    flush_done: false,
    flush_requested: false,
    end_requested: false,
    level: lv,
    fast_store,
    cfg: level_configs[lv],
    tokens: [],
    ll_freq: FixedArray::make(MAX_NUM_LIT, 0),
    d_freq: FixedArray::make(MAX_NUM_DIST, 0),
  }
  if dictionary is Some(dict) {
    deflater.preload_dictionary(dict)
  }
  deflater
}

///|
/// Preload the match window from a constructor or reset dictionary. The
/// persistent matchfinder receives the final 32 KiB once, as history only.
fn IncrementalEncoder::preload_dictionary(
  self : IncrementalEncoder,
  dictionary : BytesView,
) -> Unit {
  let start = (dictionary.length() - WINDOW_SIZE).max(0)
  self.push_pending(dictionary[start:])
  for i in 0..<self.pending_end {
    self.finder.insert_window_pos(self.pending, i, self.pending_end)
  }
  self.hashed_through = (self.pending_end - 3).max(0)
  self.parse_pos = self.pending_end
}

///|
/// Reset to the start of a fresh DEFLATE stream, keeping the compression
/// level and `fast_store` policy, reusing allocations across streams (e.g. ZIP entries).
/// With no `dictionary`, the history is cleared. Supplying one immediately
/// preloads its last 32 KB for the new stream; the decoder must use the same
/// preset dictionary.
pub fn IncrementalEncoder::reset(
  self : IncrementalEncoder,
  dictionary? : BytesView,
) -> Unit {
  self.finder.reset_stream(self.pending_end)
  self.parse_pos = 0
  self.pending_end = 0
  self.hashed_through = 0
  self.phase = Idle
  self.flushing = false
  self.cursor = 0
  self.token_high = 0U
  self.w.out.clear()
  self.w.bitbuf = 0
  self.w.bit_count = 0
  self.out_pos = 0
  self.emitted_final = false
  self.done = false
  self.flush_done = false
  self.flush_requested = false
  self.end_requested = false
  if dictionary is Some(dict) {
    self.preload_dictionary(dict)
  }
}

///|
/// Whether the final compressed stream has been fully emitted.
pub fn IncrementalEncoder::is_finished(self : IncrementalEncoder) -> Bool {
  self.done
}

///|
/// Latch a caller-supplied control action once its input view has been fully
/// accepted. `Finish` is sticky until the final block is emitted; `SyncFlush`
/// is sticky until the flush is produced. Later input is left unconsumed.
fn IncrementalEncoder::latch_action(
  self : IncrementalEncoder,
  action : DeflateAction,
) -> Unit {
  match action {
    Finish => {
      self.end_requested = true
      self.flush_requested = false
    }
    SyncFlush if !self.flush_done => self.flush_requested = true
    Continue | SyncFlush => ()
  }
}

///|
/// Accept up to `capacity` bytes of `input` into `pending` and latch `action`
/// the instant its complete view is accepted — before emitting that block can
/// return through output backpressure — returning the new consumed count.
fn IncrementalEncoder::accept_input(
  self : IncrementalEncoder,
  input : BytesView,
  consumed : Int32,
  input_end : Int32,
  capacity : Int32,
  action : DeflateAction,
) -> Int32 {
  let take = (input_end - consumed).min(capacity)
  self.push_pending(input[consumed:consumed + take])
  let consumed = consumed + take
  if take > 0 {
    self.flush_done = false
  }
  if consumed == input_end {
    self.latch_action(action)
  }
  consumed
}

///|
/// Run one compression step. Accepts as much of `input` as fits in one bounded
/// block window, emits blocks, and drains compressed bytes into `output`.
/// Returns `StepResult` with the status and this call's consumed/produced
/// counts. Drop only `input[:result.consumed]` and
/// re-present the suffix. With a small output buffer a large input may be
/// consumed only partially, which propagates output backpressure instead of
/// growing internal memory with the caller's input size. Once a final block has
/// been emitted, calls only drain that block and consume no new input; after
/// completion they idempotently return `Done` with both counts zero.
///
/// Use `action=Finish` with the final input view. The action is accepted after
/// that entire view has been consumed, then remains latched across
/// `NeedMoreOutput`; if a call reports partial consumption, re-present the
/// suffix with `action=Finish`. Later input is left unconsumed.
///
/// `action=SyncFlush` similarly requests zlib-style `Z_SYNC_FLUSH`: everything
/// buffered is compressed and the bit stream is padded to a byte boundary with
/// an empty stored block, so all produced bytes are final and transmittable
/// while the stream continues. A sync-flush is sticky across output
/// backpressure once accepted. `Continue` only accepts input. An empty `output`
/// may accept at most one bounded block window before returning
/// `NeedMoreOutput`.
pub fn IncrementalEncoder::step(
  self : IncrementalEncoder,
  input : BytesView,
  output : MutArrayView[Byte],
  action~ : DeflateAction = Continue,
) -> StepResult {
  // Completion is a stable terminal state. In particular, input presented by
  // a generic driver after it observes EOF remains unconsumed instead of
  // disappearing into a stream that can no longer encode it.
  guard !self.done else { return { status: Done, consumed: 0, produced: 0, } }
  // An empty view is already fully accepted, so its control request can be
  // latched even while older compressed output is still backpressured.
  if input.length() == 0 && !self.end_requested && !self.emitted_final {
    self.latch_action(action)
  }
  if self.phase is StoredPayload(end) &&
    self.w.out.is_empty() &&
    output.length() < end - self.cursor {
    if output.length() == 1 {
      // SAFETY: a nonempty mirrored payload and one output slot remain.
      output.unsafe_set(0, self.pending.unsafe_get(self.cursor))
      self.cursor += 1
    } else {
      self.copy_stored(output, 0, output.length())
    }
    return { status: NeedMoreOutput, consumed: 0, produced: output.length(), }
  }
  self.step_emission(input, output, action)
}

///|
fn IncrementalEncoder::step_emission(
  self : IncrementalEncoder,
  input : BytesView,
  output : MutArrayView[Byte],
  action : DeflateAction,
) -> StepResult {
  let mut pos = 0
  if self.phase is Tokens(codes) && self.w.out.is_empty() {
    if output.length() == 1 && self.w.bit_count >= 16 {
      // A second whole byte guarantees backpressure, even at the last token.
      output.unsafe_set(0, self.w.bitbuf.to_byte())
      self.w.bitbuf = ((self.w.bitbuf.reinterpret_as_uint() >> 8) |
      (self.token_high << 24)).reinterpret_as_int()
      self.token_high = self.token_high >> 8
      self.w.bit_count -= 8
      return { status: NeedMoreOutput, consumed: 0, produced: 1, }
    }
    pos = self.resume_token_prefix(codes, output, 0)
    if self.phase is Tokens(_) {
      return { status: NeedMoreOutput, consumed: 0, produced: pos, }
    }
  }
  self.w.direct_output = Some(output_storage(output))
  self.w.direct_start = output.start_offset()
  self.w.direct_capacity = output.length()
  self.w.direct_pos = pos
  let result = self.step_blocks(input, output, action)
  self.w.direct_output = None // do not retain caller-owned output between steps
  result
}

///|
fn IncrementalEncoder::step_blocks(
  self : IncrementalEncoder,
  input : BytesView,
  output : MutArrayView[Byte],
  action : DeflateAction,
) -> StepResult {
  let input_end = input.length()
  let input_limit = DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD
  let mut consumed = 0
  for ;; {
    guard self.resume_block(output) else {
      return { status: NeedMoreOutput, consumed, produced: self.w.direct_pos, }
    }
    guard !self.emitted_final else {
      self.done = true
      return { status: Done, consumed, produced: self.w.direct_pos, }
    }
    // A flush already underway owns its empty stored marker, even if Finish
    // arrives while a preceding block is backpressured.
    if self.flushing || self.flush_requested {
      self.flush_requested = false
      if self.pending_bytes() > 0 {
        self.flushing = true
        self.plan_block(finish=false)
      } else {
        self.start_stored(0, 0, is_final=false)
        self.flushing = false
        self.flush_done = true
      }
      continue
    }
    if self.end_requested {
      self.plan_block(finish=true)
      continue
    }
    // A full token window becomes one bounded non-final block before more
    // input is accepted. This is the high-water mark that propagates output
    // backpressure through `consumed`.
    let buffered = self.pending_bytes()
    guard buffered < input_limit else {
      self.plan_block(finish=false)
      continue
    }
    guard consumed < input_end else {
      return { status: NeedMoreInput, consumed, produced: self.w.direct_pos, }
    }
    consumed = self.accept_input(
      input,
      consumed,
      input_end,
      input_limit - buffered,
      action,
    )
  }
}
