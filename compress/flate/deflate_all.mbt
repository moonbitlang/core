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

// One-shot DEFLATE compression: the whole input in, a complete raw DEFLATE
// stream out. The counterpart to the streaming `Deflater` (deflate.mbt) for
// when all input is already in hand.

///|
/// A reusable, whole-buffer raw DEFLATE compressor. Unlike the suspendable
/// `Deflater`, it reads the input directly and writes one complete stream into
/// either a caller-provided buffer or reusable growable output storage.
struct Compressor {
  level : Int32
  fast_store : Bool
  cfg : LevelConfig
  finder : MatchFinder
  tokens : Array[Int32]
  mut output : FixedArray[Byte]
  ll_freq : FixedArray[Int32]
  d_freq : FixedArray[Int32]
}

///|
/// Create a reusable whole-buffer compressor. `level` 0-9 is clamped, with
/// level 0 selecting stored blocks only. `fast_store` defaults to false; when
/// enabled, sampled high-diversity inputs may bypass compression and use stored
/// blocks. It trades compression ratio for speed without changing the data.
pub fn Compressor::Compressor(
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Compressor {
  let level = clamp_level(level)
  {
    level,
    fast_store,
    cfg: level_configs[level],
    finder: MatchFinder(input_size=0),
    tokens: [],
    output: [],
    ll_freq: FixedArray::make(MAX_NUM_LIT, 0),
    d_freq: FixedArray::make(MAX_NUM_DIST, 0),
  }
}

///|
/// A conservative output capacity for `deflate_into` or
/// `Compressor::compress_into`. The returned value covers the fixed 16 KiB
/// minimum block cadence and final bit padding for a non-negative input length.
/// Panics if the input length is negative or the bound cannot fit in `Int`.
pub fn deflate_bound(input_size : Int32) -> Int32 {
  guard input_size >= 0 else { abort("negative DEFLATE input size") }
  let block_count = if input_size == 0 {
    1
  } else {
    (input_size - 1) / DEFLATE_BLOCK_SIZE + 1
  }
  let overhead = 5 * block_count + 1
  guard input_size <= 0x7fffffff - overhead else {
    abort("DEFLATE output capacity overflow")
  }
  input_size + overhead
}

///|
/// Compress `input` directly into `output`, returning its byte length. `None`
/// means that `output` was too small; any prefix written before exhaustion is
/// unspecified. Reuse one `Compressor` and one caller-owned output buffer to
/// avoid per-stream workspace and result-buffer allocation.
pub fn Compressor::compress_into(
  self : Compressor,
  input : BytesView,
  output : FixedArray[Byte],
) -> Int32? {
  self.encode(input, BitWriter::into(output))
}

///|
/// Compress a complete stream, reusing the parsing and output workspace.
/// The returned bytes are independent of subsequent calls to this compressor.
pub fn Compressor::compress(self : Compressor, input : BytesView) -> Bytes {
  let writer = BitWriter::growing(self.output)
  ignore(self.encode(input, writer))
  if writer.direct_output is Some(output) {
    self.output = output
  }
  Bytes::from_array(self.output[:writer.direct_pos])
}

///|
fn Compressor::encode(
  self : Compressor,
  input : BytesView,
  w : BitWriter,
) -> Int32? {
  let n = input.length()
  // Level 0 or an explicit heuristic decision bypasses parsing entirely.
  guard self.level != 0 && !(self.fast_store && should_fast_store(input)) else {
    w.write_stored(input, 0, n, is_final=true)
    w.flush()
    if w.overflowed {
      None
    } else {
      Some(w.direct_pos)
    }
  }
  self.finder.reset_for_input(input)
  encode_blocks(
    input,
    self.finder,
    self.cfg,
    self.tokens,
    self.ll_freq,
    self.d_freq,
    w,
  )
  w.flush()
  if w.overflowed {
    None
  } else {
    Some(w.direct_pos)
  }
}

///|
/// Compress bytes into a complete raw DEFLATE stream held entirely in memory.
/// The whole input is tokenized directly, advancing a single offset and a
/// session-owned fixed matchfinder; unlike `Deflater`, no input staging ring
/// is needed. Opt-in `fast_store` may emit stored blocks after a heuristic
/// check; false (the default) preserves normal compression behavior.
pub fn deflate_all(
  input : BytesView,
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Bytes {
  let lv = clamp_level(level)
  let w = BitWriter()
  let n = input.length()
  // Level 0 or an explicit heuristic decision bypasses parsing entirely.
  guard lv != 0 && !(fast_store && should_fast_store(input)) else {
    w.write_stored(input, 0, n, is_final=true)
    w.flush()
    return Bytes::from_array(w.out)
  }
  let cfg = level_configs[lv]
  let long_hash_bits = long_hash_bits_for_input(input)
  let finder = MatchFinder(input_size=n, long_hash_bits~)
  // Reuse token and frequency storage across blocks. A whole-buffer stream
  // can span several legal blocks; reallocating these fixed workspaces for
  // every block only adds GC pressure and does not improve the parse.
  let tokens : Array[Int32] = []
  let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
  let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
  finder.reset_for_input(input, long_hash_bits~)
  encode_blocks(input, finder, cfg, tokens, ll_freq, d_freq, w)
  w.flush()
  Bytes::from_array(w.out)
}

///|
/// One-shot convenience form of `Compressor::compress_into`. It creates a
/// compressor for this call; use `Compressor` when encoding many streams.
/// Optional `fast_store` has the same opt-in speed/ratio trade-off as `deflate_all`.
pub fn deflate_into(
  input : BytesView,
  output : FixedArray[Byte],
  level~ : Int32 = 6,
  fast_store~ : Bool = false,
) -> Int32? {
  Compressor(level~, fast_store~).compress_into(input, output)
}

///|
/// Cap the span before adding it to an absolute input position. Callers supply
/// `0 <= pos <= end` and a positive block size, including near the Int32 limit.
#inline
fn next_block_target(pos : Int32, end : Int32, block_size : Int32) -> Int32 {
  pos + (end - pos).min(block_size)
}

///|
/// Whole-buffer encoders share one block cadence and encoding decision. The
/// caller owns the match finder and workspaces, so reuse introduces no copies.
fn encode_blocks(
  input : BytesView,
  finder : MatchFinder,
  cfg : LevelConfig,
  tokens : Array[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
  w : BitWriter,
) -> Unit {
  let n = input.length()
  let block_size = 65535
  let mut pos = 0
  for ;; {
    let target = next_block_target(pos, n, block_size)
    tokens.clear()
    ll_freq.fill(0)
    d_freq.fill(0)
    let processed = tokenize(
      input, finder, pos, target, cfg, tokens, ll_freq, d_freq,
    )
    w.emit_block(
      input,
      pos,
      processed,
      tokens,
      ll_freq,
      d_freq,
      is_final=processed >= n,
    )
    pos = processed
    guard pos < n else { break }
  }
}
