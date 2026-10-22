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
// `Inflater`. Unlike a one-shot `deflate_all`, it emits the stream as a
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
//    byte buffer is drained into the caller's output and reclaimed each block,
//    suspending with `NeedMoreOutput` whenever that buffer fills.

///|
/// Clamp a compression level to 0-9.
fn clamp_level(level : Int32) -> Int32 {
  level.clamp(min=0, max=9)
}

///|
/// Streaming DEFLATE compressor : a push-based, suspendable state
/// machine. It emits the stream block-by-block as input arrives, and chooses fixed- or dynamic-Huffman per block.
struct Deflater {
  pending : FixedArray[Byte] // mirrored 64 KiB input ring
  mut parse_pos : Int32 // first un-emitted absolute byte position
  mut pending_end : Int32 // one past the last accepted absolute position
  mut hashed_through : Int32 // first historical position not yet chained
  finder : MatchFinder // persistent 32 KiB hash-chain matchfinder
  w : BitWriter // persistent bit sink spanning all blocks
  mut out_pos : Int32 // next `w.out` index to hand to the caller
  mut emitted_final : Bool // the final block has been written into `w`
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
pub fn Deflater::Deflater(
  level~ : Int32 = 6,
  dictionary? : BytesView,
  fast_store~ : Bool = false,
) -> Deflater {
  let lv = clamp_level(level)
  let deflater = {
    pending: FixedArray::make(STREAM_RING_STORAGE_SIZE, b'\x00'),
    parse_pos: 0,
    pending_end: 0,
    hashed_through: 0,
    finder: MatchFinder(),
    w: BitWriter(),
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
fn Deflater::preload_dictionary(
  self : Deflater,
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
pub fn Deflater::reset(self : Deflater, dictionary? : BytesView) -> Unit {
  self.finder.reset_stream(self.pending_end)
  self.parse_pos = 0
  self.pending_end = 0
  self.hashed_through = 0
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
pub fn Deflater::is_finished(self : Deflater) -> Bool {
  self.done
}

///|
/// Latch a caller-supplied control action once its input view has been fully
/// accepted. `Finish` is sticky until the final block is emitted; `SyncFlush`
/// is sticky until the flush is produced. Later input is left unconsumed.
fn Deflater::latch_action(self : Deflater, action : DeflateAction) -> Unit {
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
/// Copy compressed bytes already produced into the caller's buffer, returning
/// the new write position.
fn Deflater::drain_output(
  self : Deflater,
  output : MutArrayView[Byte],
  write_pos : Int32,
  out_end : Int32,
) -> Int32 {
  let pending = self.w.out
  let from = self.out_pos
  let count = (pending.length() - from).min(out_end - write_pos)
  guard count > 0 else { return write_pos }
  // SAFETY: `count` is positive and at most both `pending.length() - from`
  // and `out_end - write_pos`; `from` and `write_pos` are non-negative and
  // `out_end` is `output.length()`. Every index below is in bounds.
  for k in 0..<count {
    output.unsafe_set(write_pos + k, pending.unsafe_get(from + k))
  }
  self.out_pos = from + count
  write_pos + count
}

///|
/// Accept up to `capacity` bytes of `input` into `pending` and latch `action`
/// the instant its complete view is accepted — before emitting that block can
/// return through output backpressure — returning the new consumed count.
fn Deflater::accept_input(
  self : Deflater,
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
pub fn Deflater::step(
  self : Deflater,
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
  let out_end = output.length()
  let input_end = input.length()
  let input_limit = DEFLATE_BLOCK_SIZE + MIN_LOOKAHEAD
  let mut consumed = 0
  let mut write_pos = 0
  for ;; {
    // Drain compressed bytes already produced into the caller's buffer.
    write_pos = self.drain_output(output, write_pos, out_end)
    guard self.out_pos >= self.w.out.length() else {
      return { status: NeedMoreOutput, consumed, produced: write_pos, }
    }
    // The current block buffer is fully drained; reclaim it.
    if self.w.out.length() > 0 {
      self.w.out.clear()
      self.out_pos = 0
    }
    guard !self.emitted_final else {
      self.done = true
      return { status: Done, consumed, produced: write_pos, }
    }
    // Produce already-requested control blocks before accepting later input.
    guard !self.end_requested else {
      self.flush_requested = false
      self.emit_final()
      continue
    }
    guard !self.flush_requested else {
      self.emit_flush()
      self.flush_done = true
      self.flush_requested = false
      continue
    }
    // A full token window becomes one bounded non-final block before more
    // input is accepted. This is the high-water mark that propagates output
    // backpressure through `consumed`.
    let buffered = self.pending_bytes()
    guard buffered < input_limit else {
      self.emit_one()
      continue
    }
    guard consumed < input_end else {
      return { status: NeedMoreInput, consumed, produced: write_pos, }
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
