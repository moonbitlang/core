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
// stream out. The counterpart to the streaming `IncrementalEncoder` (deflate.mbt) for
// when all input is already in hand.

///|
/// Whole-buffer compression strategy. Levels are clamped to 0-9;
/// level 0 emits stored blocks only.
pub(all) enum Strategy {
  /// Fixed-cadence blocks with the selected compression level.
  Standard(level~ : Int32)
  /// Content-driven block splitting after a single tokenization pass.
  Split(level~ : Int32)
  /// Iterated optimal parsing and splitting; iterations are clamped to at least 1.
  Optimal(iterations~ : Int32)
} derive(Eq, @debug.Debug)

///|
/// Select content-driven splitting with compression level 6 by default.
pub fn Strategy::split(level~ : Int32 = 6) -> Strategy {
  Split(level~)
}

///|
/// Select optimal parsing and splitting with 15 iterations by default.
pub fn Strategy::optimal(iterations~ : Int32 = 15) -> Strategy {
  Optimal(iterations~)
}

///|
/// A reusable, whole-buffer raw DEFLATE compressor. Unlike the suspendable
/// `IncrementalEncoder`, it reads the input directly and writes one complete stream into
/// either a caller-provided buffer or reusable growable output storage.
struct Compressor {
  strategy : Strategy
  fast_store : Bool
  finder : MatchFinder
  tokens : Array[Int32]
  mut output : FixedArray[Byte]
  ll_freq : FixedArray[Int32]
  d_freq : FixedArray[Int32]
}

///|
/// Create a reusable whole-buffer compressor with the selected strategy.
/// `fast_store` may bypass parsing and use stored blocks for sampled inputs.
pub fn Compressor::Compressor(
  strategy~ : Strategy = Standard(level=6),
  fast_store~ : Bool = false,
) -> Compressor {
  let strategy = match strategy {
    Standard(level~) => Standard(level=clamp_level(level))
    Split(level~) => Split(level=clamp_level(level))
    Optimal(iterations~) => Optimal(iterations=iterations.max(1))
  }
  {
    strategy,
    fast_store,
    finder: MatchFinder(input_size=0),
    tokens: [],
    output: [],
    ll_freq: FixedArray::make(MAX_NUM_LIT, 0),
    d_freq: FixedArray::make(MAX_NUM_DIST, 0),
  }
}

///|
/// An output capacity sufficient for the selected strategy, with or without
/// `fast_store`. Panics for negative input sizes or an unrepresentable bound.
pub fn deflate_bound(
  input_size : Int32,
  strategy~ : Strategy = Standard(level=6),
) -> Int32 {
  guard input_size >= 0 else { abort("negative DEFLATE input size") }
  let size = input_size.to_int64()
  // Every planned block costs at most its stored encoding, plus one byte
  // for alignment. Stored segments may themselves split at 65535 bytes.
  // Split has at most seven parts per chunk (including match overhang);
  // Optimal caps each master chunk at OPTIMAL_MAX_BLOCKS parts.
  let max_blocks = match strategy {
    Standard(_) => (size + 65534L) / 65535L
    Split(_) => (size + 65534L) / 65535L * 7L
    Optimal(_) =>
      (size + OPTIMAL_MASTER_BLOCK.to_int64() - 1L) /
      OPTIMAL_MASTER_BLOCK.to_int64() *
      OPTIMAL_MAX_BLOCKS.to_int64()
  }
  let blocks = max_blocks.min(size).max(1L)
  let bound = size + 5L * (size / 65535L + blocks) + blocks + 1L
  guard bound <= 0x7fff_ffffL else { abort("DEFLATE output capacity overflow") }
  bound.to_int()
}

///|
/// Compress `input` directly into `output`, returning its byte length. `None`
/// means that `output` was too small; any prefix written before exhaustion is
/// unspecified. Reuse one `Compressor` and one caller-owned output buffer to
/// avoid per-stream workspace and result-buffer allocation.
pub fn Compressor::compress_into(
  self : Compressor,
  input : BytesView,
  output : MutArrayView[Byte],
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
  let level = match self.strategy {
    Standard(level~) | Split(level~) => level
    Optimal(_) => 9
  }
  if level == 0 || (self.fast_store && should_fast_store(input)) {
    w.write_stored(input, 0, input.length(), is_final=true)
  } else {
    self.finder.reset_for_input(input)
    match self.strategy {
      Standard(_) =>
        encode_blocks(
          input,
          self.finder,
          level_configs[level],
          self.tokens,
          self.ll_freq,
          self.d_freq,
          w,
        )
      Split(_) => self.encode_split(input, w, level_configs[level])
      Optimal(iterations~) => self.encode_optimal(input, w, iterations)
    }
  }
  w.flush()
  if w.overflowed {
    None
  } else {
    Some(w.direct_pos)
  }
}

///|
/// Compress bytes into a complete raw DEFLATE stream held entirely in memory.
/// Defaults to `Standard(level=6)`. Opt-in `fast_store` may bypass any strategy
/// and emit stored blocks after a heuristic check, trading compression ratio
/// for speed; it is disabled by default.
pub fn deflate_all(
  input : BytesView,
  strategy~ : Strategy = Standard(level=6),
  fast_store~ : Bool = false,
) -> Bytes {
  Compressor(strategy~, fast_store~).compress(input)
}

///|
/// One-shot convenience form of `Compressor::compress_into`. It creates a
/// compressor for this call; use `Compressor` when encoding many streams.
/// Optional `fast_store` has the same opt-in speed/ratio trade-off as `deflate_all`.
pub fn deflate_into(
  input : BytesView,
  output : MutArrayView[Byte],
  strategy~ : Strategy = Standard(level=6),
  fast_store~ : Bool = false,
) -> Int32? {
  Compressor(strategy~, fast_store~).compress_into(input, output)
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
