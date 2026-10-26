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

// Block planning for the streaming encoder. Input lives in a fixed mirrored
// ring: the first half is indexed by absolute position modulo 64 KiB and the
// second half mirrors it for branch-free SIMD comparisons across the wrap.
// The parser and its 32 KiB matchfinder survive every block boundary.

///|
fn IncrementalEncoder::pending_bytes(deflater : IncrementalEncoder) -> Int32 {
  deflater.pending_end - deflater.parse_pos
}

///|
/// Append `input` to the ring with bulk copies into both mirrored halves,
/// split at the ring wrap.
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
fn IncrementalEncoder::write_stored_pending(
  deflater : IncrementalEncoder,
  is_final~ : Bool,
) -> Unit {
  deflater.w.write_stored_window(
    deflater.pending,
    deflater.parse_pos,
    deflater.pending_end,
    is_final~,
  )
  deflater.parse_pos = deflater.pending_end
}

///|
// The final three bytes of an earlier accepted chunk could not yet form a
// 4-byte hash. Insert them once new lookahead makes them hashable; all older
// history is already present in the persistent chain.
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
    deflater.hashed_through = deflater.hashed_through + 1
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
// Unlike level 0, a heuristically stored block must remain available as
// history if a later block resumes normal matching. Keep both hash tables
// current without spending time on token search or Huffman construction.
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
  deflater.w.write_stored_window(
    deflater.pending,
    deflater.parse_pos,
    end,
    is_final~,
  )
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
/// Emit one non-final parsed block. `pending` already includes the lookahead
/// tail, and `tokenize_window` only commits `DEFLATE_BLOCK_SIZE` bytes except
/// for an ordinary 258-byte match overhang.
fn IncrementalEncoder::emit_capped(deflater : IncrementalEncoder) -> Unit {
  let target = (deflater.parse_pos + DEFLATE_BLOCK_SIZE).min(
    deflater.pending_end,
  )
  if deflater.try_fast_store(target, is_final=false) {
    return
  }
  deflater.tokens.clear()
  deflater.ll_freq.fill(0)
  deflater.d_freq.fill(0)
  deflater.chain_ready_history()
  let processed = tokenize_window(
    deflater.pending,
    deflater.finder,
    deflater.parse_pos,
    target,
    deflater.pending_end,
    deflater.cfg,
    deflater.tokens,
    deflater.ll_freq,
    deflater.d_freq,
  )
  deflater.w.emit_window_block(
    deflater.pending,
    deflater.parse_pos,
    processed,
    deflater.tokens,
    deflater.ll_freq,
    deflater.d_freq,
    is_final=false,
  )
  deflater.parse_pos = processed
  deflater.record_chained_positions(processed)
  deflater.maybe_rebase()
}

///|
/// Level 0 bypasses parsing entirely and writes buffered bytes straight out of
/// the ring. With no matches, neither matchfinder nor history needs updates.
fn IncrementalEncoder::emit_stored_all(
  deflater : IncrementalEncoder,
  is_final~ : Bool,
) -> Unit {
  deflater.write_stored_pending(is_final~)
  deflater.parse_pos = 0
  deflater.pending_end = 0
}

///|
fn IncrementalEncoder::emit_one(deflater : IncrementalEncoder) -> Unit {
  guard deflater.level != 0 else {
    deflater.emit_stored_all(is_final=false)
    return
  }
  deflater.emit_capped()
}

///|
/// Tokenize all remaining input into one trailing block. The end bound removes
/// the non-final lookahead restriction while preserving the same parse policy.
fn IncrementalEncoder::emit_trailing_block(
  deflater : IncrementalEncoder,
  is_final~ : Bool,
) -> Int32 {
  let end = deflater.pending_end
  if deflater.try_fast_store(end, is_final~) {
    return end
  }
  deflater.tokens.clear()
  deflater.ll_freq.fill(0)
  deflater.d_freq.fill(0)
  deflater.chain_ready_history()
  let processed = tokenize_window(
    deflater.pending,
    deflater.finder,
    deflater.parse_pos,
    deflater.pending_end,
    deflater.pending_end,
    deflater.cfg,
    deflater.tokens,
    deflater.ll_freq,
    deflater.d_freq,
  )
  deflater.w.emit_window_block(
    deflater.pending,
    deflater.parse_pos,
    processed,
    deflater.tokens,
    deflater.ll_freq,
    deflater.d_freq,
    is_final~,
  )
  deflater.parse_pos = processed
  deflater.record_chained_positions(processed)
  deflater.maybe_rebase()
  processed
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

///|
fn IncrementalEncoder::emit_final(deflater : IncrementalEncoder) -> Unit {
  if deflater.level == 0 {
    deflater.emit_stored_all(is_final=true)
  } else {
    while deflater.pending_bytes() > DEFLATE_BLOCK_SIZE {
      deflater.emit_capped()
    }
    ignore(deflater.emit_trailing_block(is_final=true))
  }
  deflater.w.flush()
  deflater.emitted_final = true
}

///|
fn IncrementalEncoder::flush_stored(deflater : IncrementalEncoder) -> Unit {
  if deflater.pending_bytes() > 0 {
    deflater.emit_stored_all(is_final=false)
  }
}

///|
fn IncrementalEncoder::flush_capped(deflater : IncrementalEncoder) -> Unit {
  while deflater.pending_bytes() > DEFLATE_BLOCK_SIZE {
    deflater.emit_capped()
  }
  if deflater.pending_bytes() > 0 {
    ignore(deflater.emit_trailing_block(is_final=false))
  }
}

///|
/// Sync flush (zlib `Z_SYNC_FLUSH`): drain all buffered bytes, then append an
/// empty byte-aligned stored block. The persistent matchfinder retains the
/// preceding window for the stream's next input.
fn IncrementalEncoder::emit_flush(deflater : IncrementalEncoder) -> Unit {
  if deflater.level == 0 {
    deflater.flush_stored()
  } else {
    deflater.flush_capped()
  }
  deflater.w.write_stored(b"", 0, 0, is_final=false)
}
