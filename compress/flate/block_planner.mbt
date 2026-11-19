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
const MIN_LOOKAHEAD : Int32 = 258

///|
fn IncrementalEncoder::pending_bytes(deflater : IncrementalEncoder) -> Int32 {
  deflater.pending_end - deflater.parse_pos
}

///|
/// Append `input` to both mirrored halves, split at the ring wrap.
fn IncrementalEncoder::push_pending(
  deflater : IncrementalEncoder,
  input : BytesView,
) -> Unit {
  let mut rest = input
  while rest.length() > 0 {
    let offset = deflater.pending_end & STREAM_RING_MASK
    let count = rest.length().min(STREAM_RING_SIZE - offset)
    let chunk = rest[:count]
    deflater.pending.blit_from_bytesview(offset, chunk)
    deflater.pending.blit_from_bytesview(offset + STREAM_RING_SIZE, chunk)
    deflater.pending_end = deflater.pending_end + count
    rest = rest[count:]
  }
}

///|
// The final three bytes of an earlier accepted chunk could not yet form a
// 4-byte hash. Insert them once new lookahead makes them hashable.
fn IncrementalEncoder::chain_ready_history(
  deflater : IncrementalEncoder,
) -> Unit {
  let ready_end = deflater.parse_pos.min((deflater.pending_end - 3).max(0))
  while deflater.hashed_through < ready_end {
    deflater.finder.insert_window_pos(
      deflater.pending,
      deflater.hashed_through,
      deflater.pending_end,
    )
    deflater.hashed_through += 1
  }
}

///|
fn IncrementalEncoder::record_chained_positions(
  deflater : IncrementalEncoder,
  processed : Int32,
) -> Unit {
  let chained_end = processed.min((deflater.pending_end - 3).max(0))
  if chained_end > deflater.hashed_through {
    deflater.hashed_through = chained_end
  }
}

///|
// A heuristically stored block remains history if the next block resumes matching.
fn IncrementalEncoder::try_fast_store(
  deflater : IncrementalEncoder,
  end : Int32,
  is_final~ : Bool,
) -> Bool {
  guard deflater.fast_store &&
    should_fast_store_window(deflater.pending, deflater.parse_pos, end) else {
    return false
  }
  deflater.chain_ready_history()
  deflater.start_stored(deflater.parse_pos, end, is_final~)
  deflater.finder.insert_window_positions(
    deflater.pending,
    deflater.parse_pos,
    end,
    deflater.pending_end,
  )
  deflater.parse_pos = end
  deflater.record_chained_positions(end)
  deflater.maybe_rebase()
  true
}

///|
// Plan exactly one block. The driver resumes its emission to completion before
// it can reuse either the token array or the mirrored payload range.
fn IncrementalEncoder::plan_block(
  self : IncrementalEncoder,
  finish~ : Bool,
) -> Unit {
  let start = self.parse_pos
  if self.level == 0 {
    self.start_stored(start, self.pending_end, is_final=finish)
    self.parse_pos = 0
    self.pending_end = 0
    return
  }
  let target = start + self.pending_bytes().min(DEFLATE_BLOCK_SIZE)
  let is_final = finish && target == self.pending_end
  if self.try_fast_store(target, is_final~) {
    return
  }
  self.tokens.clear()
  self.ll_freq.fill(0)
  self.d_freq.fill(0)
  self.chain_ready_history()
  let end = tokenize_window(
    self.pending,
    self.finder,
    start,
    target,
    self.pending_end,
    self.cfg,
    self.tokens,
    self.ll_freq,
    self.d_freq,
  )
  match choose_block_encoding(end - start, self.ll_freq, self.d_freq) {
    Stored => self.start_stored(start, end, is_final~)
    Fixed => self.phase = FixedHeader
    Dynamic(codes) => self.phase = DynamicHeader(codes)
  }
  self.emitted_final = is_final
  self.parse_pos = end
  self.record_chained_positions(end)
  self.maybe_rebase()
}

///|
/// Keep absolute positions comfortably below backend integer limits. This is
/// amortized over 1 GiB of source and preserves every live 32 KiB chain link.
fn IncrementalEncoder::maybe_rebase(deflater : IncrementalEncoder) -> Unit {
  let rebase_at = 1 << 30
  guard deflater.parse_pos >= rebase_at else { return }
  let offset = (deflater.parse_pos / STREAM_RING_SIZE - 1) * STREAM_RING_SIZE
  deflater.finder.rebase(offset)
  deflater.parse_pos = deflater.parse_pos - offset
  deflater.pending_end = deflater.pending_end - offset
  deflater.hashed_through = deflater.hashed_through - offset
}
