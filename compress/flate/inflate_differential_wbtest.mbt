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
priv enum InflateDifferentialOutcome {
  InflateDifferentialOk(Bytes)
  InflateDifferentialErr(InflateErrorKind)
} derive(Eq, @debug.Debug)

///|
priv struct InflateDifferentialRng {
  mut state : UInt32
}

///|
fn InflateDifferentialRng::InflateDifferentialRng(
  seed : UInt32,
) -> InflateDifferentialRng {
  { state: seed, }
}

///|
fn InflateDifferentialRng::next(self : InflateDifferentialRng) -> UInt32 {
  self.state = self.state * 1664525 + 1013904223
  self.state
}

///|
fn InflateDifferentialRng::size(
  self : InflateDifferentialRng,
  maximum : Int32,
) -> Int32 {
  (self.next() >> 1).reinterpret_as_int() % maximum + 1
}

///|
fn inflate_differential_random_bytes(
  seed : UInt32,
  length : Int32,
  alphabet : Int32,
) -> Bytes {
  let rng = InflateDifferentialRng(seed)
  let bytes = Array::make(length, b'\x00')
  for i in 0..<length {
    bytes[i] = (rng.size(alphabet) - 1).to_byte()
  }
  Bytes::from_array(bytes)
}

///|
fn inflate_differential_pattern(pattern : Bytes, length : Int32) -> Bytes {
  let bytes = Array::make(length, b'\x00')
  for i in 0..<length {
    bytes[i] = pattern[i % pattern.length()]
  }
  Bytes::from_array(bytes)
}

///|
fn inflate_differential_sources() -> Array[Bytes] {
  [
    b"",
    b"a",
    Bytes::from_array(Array::make(258, b'a')),
    inflate_differential_pattern(b"moonbit-flate-", 777),
    inflate_differential_random_bytes(0xA11CE001U, 257, 2),
    inflate_differential_random_bytes(0xA11CE002U, 513, 17),
    inflate_differential_random_bytes(0xA11CE003U, 1025, 4),
    inflate_differential_random_bytes(0xA11CE004U, 1536, 256),
  ]
}

///|
fn inflate_differential_one_shot(input : Bytes) -> InflateDifferentialOutcome {
  try inflate_all(input) catch {
    InflateError(kind, _) => InflateDifferentialErr(kind)
  } noraise {
    decoded => InflateDifferentialOk(decoded)
  }
}

///|
fn inflate_differential_stream_bytes(
  input : Bytes,
  schedule_seed : UInt32,
  one_byte_only : Bool,
) -> Bytes raise {
  let inflater = Inflater()
  let rng = InflateDifferentialRng(schedule_seed)
  let output = FixedArray::make(23, b'\x00')
  let decoded = @buffer.Buffer()
  let mut input_pos = 0
  let mut available = 0
  let mut steps = 0
  for ;; {
    if available == input_pos && available < input.length() {
      let chunk_size = if one_byte_only || steps % 7 == 0 {
        1
      } else {
        rng.size(17)
      }
      available = if available + chunk_size < input.length() {
        available + chunk_size
      } else {
        input.length()
      }
    }
    let output_size = if one_byte_only || steps % 5 == 0 {
      1
    } else {
      rng.size(23)
    }
    let status_result = inflater.step(
      input[input_pos:available],
      output.mut_view(end=output_size),
    )
    let status = status_result.status
    if status is NeedMoreInput && available == input.length() {
      raise InflateError(Truncated, "unexpected end of input")
    }
    let consumed = status_result.consumed
    let produced = status_result.produced
    input_pos = input_pos + consumed
    for i in 0..<produced {
      decoded.write_byte(output[i])
    }
    steps = steps + 1
    if steps > 1000000 {
      @test.fail(
        "streaming differential driver stalled: schedule_seed=\{@debug.Repr(schedule_seed)}, input_length=\{input.length()}",
      )
    }
    match status {
      Done => return decoded.to_bytes()
      NeedMoreInput => ()
      NeedMoreOutput => ()
    }
  }
}

///|
fn inflate_differential_streaming(
  input : Bytes,
  schedule_seed : UInt32,
  one_byte_only : Bool,
) -> InflateDifferentialOutcome raise {
  try
    inflate_differential_stream_bytes(input, schedule_seed, one_byte_only)
  catch {
    InflateError(kind, _) => InflateDifferentialErr(kind)
    error => raise error
  } noraise {
    decoded => InflateDifferentialOk(decoded)
  }
}

///|
fn inflate_differential_compare(
  input : Bytes,
  schedule_seed : UInt32,
  corpus : String,
  one_byte_only : Bool,
) -> Unit raise {
  let one_shot = inflate_differential_one_shot(input)
  let streaming = inflate_differential_streaming(
    input, schedule_seed, one_byte_only,
  )
  if one_shot != streaming {
    @test.fail(
      "inflate differential mismatch: corpus=\{corpus}, schedule_seed=\{@debug.Repr(schedule_seed)}, input_length=\{input.length()}, one_shot=\{@debug.Repr(one_shot)}, streaming=\{@debug.Repr(streaming)}",
    )
  }
}

///|
fn inflate_differential_flip(
  input : Bytes,
  index : Int32,
  mask : Int32,
) -> Bytes {
  let mutated = input.to_array()
  mutated[index] = (mutated[index].to_int() ^ mask).to_byte()
  Bytes::from_array(mutated)
}

///|
test "inflate_all and streaming Inflater agree under deterministic fuzz" {
  let sources = inflate_differential_sources()
  let levels : ReadOnlyArray[_] = [0, 1, 6, 9]
  let mut schedule_seed = 0xD1FF2026U
  for source_index in 0..<sources.length() {
    let source = sources[source_index]
    for level_index in 0..<levels.length() {
      let level = levels[level_index]
      let compressed = deflate_all(source, level~)
      let corpus = "source-\{source_index}/level-\{level}"
      let expected = InflateDifferentialOk(source)
      let one_shot = inflate_differential_one_shot(compressed)
      if one_shot != expected {
        @test.fail(
          "valid differential corpus failed: corpus=\{corpus}, expected=\{@debug.Repr(expected)}, one_shot=\{@debug.Repr(one_shot)}",
        )
      }

      schedule_seed = schedule_seed * 1664525 + 1013904223
      inflate_differential_compare(
        compressed,
        schedule_seed,
        "\{corpus}/valid-random-chunks",
        false,
      )
      // Keep a small explicit 1-byte-only matrix in addition to the 1-byte
      // chunks periodically injected into every randomized schedule.
      if source_index == level_index {
        schedule_seed = schedule_seed * 1664525 + 1013904223
        inflate_differential_compare(
          compressed,
          schedule_seed,
          "\{corpus}/valid-1-byte-only",
          true,
        )
      }

      let truncation_points : ReadOnlyArray[_] = [
        0,
        compressed.length() / 2,
        compressed.length() - 1,
      ]
      for mutation_index in 0..<truncation_points.length() {
        let end = truncation_points[mutation_index]
        let truncated = compressed[:end].to_owned()
        schedule_seed = schedule_seed * 1664525 + 1013904223
        inflate_differential_compare(
          truncated,
          schedule_seed,
          "\{corpus}/truncate-\{mutation_index}-at-\{end}",
          false,
        )
      }

      let flip_positions : ReadOnlyArray[_] = [
        0,
        compressed.length() / 3,
        compressed.length() * 2 / 3,
        compressed.length() - 1,
      ]
      for mutation_index in 0..<flip_positions.length() {
        let position = flip_positions[mutation_index]
        let bit = (mutation_index * 3 + source_index + level_index) % 8
        let mask = 1 << bit
        let mutated = inflate_differential_flip(compressed, position, mask)
        schedule_seed = schedule_seed * 1664525 + 1013904223
        inflate_differential_compare(
          mutated,
          schedule_seed,
          "\{corpus}/flip-\{mutation_index}-byte-\{position}-bit-\{bit}",
          false,
        )
      }
    }
  }
}

///|
/// Arbitrary raw bytes exercise malformed states that mutations around streams
/// produced by our own compressor may never reach. The seed is part of every
/// corpus label so a failing case is exactly reproducible.
test "inflate_all and streaming Inflater agree on deterministic raw noise" {
  let corpus_rng = InflateDifferentialRng(0xBAD5EEDU)
  let mut schedule_seed = 0x51A7E202U
  for case_index in 0..<128 {
    let corpus_seed = corpus_rng.next()
    let length = corpus_rng.size(96)
    let input = inflate_differential_random_bytes(corpus_seed, length, 256)
    schedule_seed = schedule_seed * 1664525 + 1013904223
    inflate_differential_compare(
      input,
      schedule_seed,
      "raw-noise-\{case_index}/seed-\{@debug.Repr(corpus_seed)}",
      false,
    )
  }
}

///|
fn inflate_differential_exact_kind(
  input : Bytes,
  preallocated : Bool,
) -> InflateErrorKind? {
  try ignore(inflate_exact(input, preallocated~)) catch {
    InflateError(kind, _) => Some(kind)
  } noraise {
    _ => None
  }
}

///|
/// The preallocated path replays the same deterministic decode, so it must
/// agree byte-for-byte on valid streams and report the same error kind on
/// truncated, trailing, and bit-flipped input.
test "preallocated inflate_exact matches the grow path" {
  let sources = inflate_differential_sources()
  for level_index in 0..<4 {
    let level = [0, 1, 6, 9][level_index]
    for source_index in 0..<sources.length() {
      let source = sources[source_index]
      let compressed = deflate_all(source, level~)
      let corpus = "source-\{source_index}/level-\{level}"
      @test.assert_eq(inflate_exact(compressed, preallocated=true), source)
      let framed = compressed + b"TAIL"
      let default_outcome = inflate_differential_exact_kind(framed, false)
      let preallocated_outcome = inflate_differential_exact_kind(framed, true)
      if default_outcome != Some(TrailingData) ||
        preallocated_outcome != Some(TrailingData) {
        @test.fail(
          "preallocated vs grow mismatch on trailing corpus: \{corpus}, default=\{@debug.Repr(default_outcome)}, preallocated=\{@debug.Repr(preallocated_outcome)}",
        )
      }
      let truncation_points : ReadOnlyArray[_] = [
        0,
        compressed.length() / 2,
        compressed.length() - 1,
      ]
      for mutation_index in 0..<truncation_points.length() {
        let end = truncation_points[mutation_index]
        let truncated = compressed[:end].to_owned()
        let default_outcome = inflate_differential_exact_kind(truncated, false)
        let preallocated_outcome = inflate_differential_exact_kind(
          truncated, true,
        )
        if default_outcome != preallocated_outcome {
          @test.fail(
            "preallocated vs grow mismatch on truncate-\{mutation_index}-at-\{end}: corpus=\{corpus}, default=\{@debug.Repr(default_outcome)}, preallocated=\{@debug.Repr(preallocated_outcome)}",
          )
        }
      }
      let flip_positions : ReadOnlyArray[_] = [
        0,
        compressed.length() / 3,
        compressed.length() * 2 / 3,
        compressed.length() - 1,
      ]
      for mutation_index in 0..<flip_positions.length() {
        let position = flip_positions[mutation_index]
        let bit = (mutation_index * 3 + source_index + level_index) % 8
        let mask = 1 << bit
        let mutated = inflate_differential_flip(compressed, position, mask)
        let default_outcome = inflate_differential_exact_kind(mutated, false)
        let preallocated_outcome = inflate_differential_exact_kind(
          mutated, true,
        )
        if default_outcome != preallocated_outcome {
          @test.fail(
            "preallocated vs grow mismatch on flip-\{mutation_index}-byte-\{position}-bit-\{bit}: corpus=\{corpus}, default=\{@debug.Repr(default_outcome)}, preallocated=\{@debug.Repr(preallocated_outcome)}",
          )
        }
      }
    }
  }
}
