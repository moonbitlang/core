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
test "decoded output sizes reject overflow before allocation or mutation" {
  let maximum = MAX_DECODE_OUTPUT_SIZE
  for entry in [(0, 0), (0, maximum), (maximum, 0), (maximum - 1, 1)] {
    let (length, additional) = entry
    @test.assert_eq(
      checked_decode_output_length(length, additional),
      length + additional,
    )
  }
  for
    (length, additional, ceiling) in [
      (0, 1, 0),
      (maximum - 10, 20, maximum - 5),
      (maximum, 1, maximum),
      (1, maximum, maximum),
      (maximum - 1, 2, maximum),
    ] {
    let InflateError(kind, _) = @test.expect_error(() => {
      checked_decode_output_length(length, additional, limit=ceiling)
    })
    @test.assert_eq(
      kind,
      OutputLimitExceeded(
        limit=ceiling.to_uint64(),
        observed=length.to_uint64() + additional.to_uint64(),
      ),
    )
  }
  for
    (out, limit) in [
      (DecodeOutput(1), maximum),
      (DecodeOutput::into([b'\x00'].mut_view()), 1),
    ] {
    out.append_byte(b'a')
    let err = @test.expect_error(() => out.ensure_capacity(maximum))
    guard err is InflateError(kind, _)
    @test.assert_eq(
      kind,
      OutputLimitExceeded(
        limit=limit.to_uint64(),
        observed=maximum.to_uint64() + 1UL,
      ),
    )
    @test.assert_eq(out.length, 1)
    @test.assert_eq(out.storage.length(), 1)
    @test.assert_eq(out.to_bytes(), b"a")
  }
}

///|
test "decoded output growth stays representable at the doubling boundary" {
  @test.assert_eq(grown_decode_output_capacity(4, 5), 8)
  @test.assert_eq(grown_decode_output_capacity(4, 9), 9)
  let half = MAX_DECODE_OUTPUT_SIZE / 2
  @test.assert_eq(
    grown_decode_output_capacity(half, half + 1),
    MAX_DECODE_OUTPUT_SIZE - 1,
  )
  @test.assert_eq(
    grown_decode_output_capacity(half, MAX_DECODE_OUTPUT_SIZE),
    MAX_DECODE_OUTPUT_SIZE,
  )
  // Past the doubling boundary, growth is by half the current capacity.
  @test.assert_eq(grown_decode_output_capacity(half + 1, half + 2), 0x6000_0000)
  @test.assert_eq(
    grown_decode_output_capacity(half + 1, 0x7000_0000),
    0x7000_0000,
  )
  // Near the limit the step saturates instead of overflowing.
  @test.assert_eq(
    grown_decode_output_capacity(0x6000_0000, 0x6000_0001),
    MAX_DECODE_OUTPUT_SIZE,
  )
  @test.assert_eq(
    grown_decode_output_capacity(
      MAX_DECODE_OUTPUT_SIZE - 1,
      MAX_DECODE_OUTPUT_SIZE,
    ),
    MAX_DECODE_OUTPUT_SIZE,
  )
  @test.assert_eq(
    grown_decode_output_capacity(MAX_DECODE_OUTPUT_SIZE, MAX_DECODE_OUTPUT_SIZE),
    MAX_DECODE_OUTPUT_SIZE,
  )
}

///|
/// Replay the growth `DecodeOutput::ensure_capacity` performs for a stream of
/// 258-byte matches, without allocating, and report how many reallocations it
/// takes and how many bytes they copy.
fn decode_output_growth_cost(
  start : Int32,
  capacity : Int32,
  limit : Int32,
) -> (Int32, Int64) {
  let mut length = start
  let mut capacity = capacity
  let mut steps = 0
  let mut copied = 0L
  while length < limit {
    let required = length + (limit - length).min(258)
    if required > capacity {
      capacity = grown_decode_output_capacity(capacity, required).min(limit)
      steps += 1
      copied += length.to_int64()
    }
    length = required
  }
  (steps, copied)
}

///|
test "decoded output growth past 1 GiB takes a constant number of steps" {
  let half = MAX_DECODE_OUTPUT_SIZE / 2
  // A full output just over 1 GiB, filled one token at a time up to the limit.
  let (steps, copied) = decode_output_growth_cost(
    half + 1,
    half + 1,
    MAX_DECODE_OUTPUT_SIZE,
  )
  inspect(steps, content="2")
  assert_true(copied < 2L * MAX_DECODE_OUTPUT_SIZE.to_int64())
  // At the doubling boundary: doubling reaches the limit minus one, then one
  // more step reaches the limit.
  let (steps, copied) = decode_output_growth_cost(
    half,
    half,
    MAX_DECODE_OUTPUT_SIZE,
  )
  inspect(steps, content="2")
  assert_true(copied < 2L * MAX_DECODE_OUTPUT_SIZE.to_int64())
  // The whole range from an empty one-byte output: the first token sets the
  // capacity to 258, 22 doublings pass 1 GiB, then two linear steps.
  let (steps, copied) = decode_output_growth_cost(0, 1, MAX_DECODE_OUTPUT_SIZE)
  inspect(steps, content="25")
  assert_true(copied < 2L * MAX_DECODE_OUTPUT_SIZE.to_int64())
  // A lower caller limit just over 1 GiB.
  let (steps, _) = decode_output_growth_cost(
    half + 1,
    half + 1,
    half + 0x10_0000,
  )
  inspect(steps, content="1")
}

///|
test "rebasing preserves live match distances and pending ring bytes" {
  let d = IncrementalEncoder()
  let position = (1 << 30) + 17
  let offset = (position / STREAM_RING_SIZE - 1) * STREAM_RING_SIZE
  d.parse_pos = position
  d.pending_end = position
  d.hashed_through = position - 2
  d.finder.short_head[0] = position - 3
  d.finder.short_head[1] = 0
  d.finder.head[0] = position - 3
  set_chain_previous(d.finder.prev, position - 3, position - 9)
  d.finder.head[1] = 0 // stale history becomes a negative sentinel
  d.push_pending(Bytes::make(1, b'a'))
  d.push_pending(Bytes::make(1, b'b'))
  d.push_pending(Bytes::make(1, b'c'))
  d.maybe_rebase()
  @test.assert_eq(d.parse_pos, position - offset)
  @test.assert_eq(d.pending_bytes(), 3)
  @test.assert_eq(d.hashed_through, position - 2 - offset)
  @test.assert_eq(d.finder.short_head[0], d.parse_pos - 3)
  @test.assert_eq(d.finder.short_head[1], -offset)
  @test.assert_eq(d.finder.short_head[2], -1)
  @test.assert_eq(d.finder.head[0], d.parse_pos - 3)
  @test.assert_eq(
    chain_previous(d.finder.prev, position - 3 - offset),
    d.parse_pos - 9,
  )
  @test.assert_eq(d.finder.head[1], -offset)
  @test.assert_eq(d.finder.head[2], -1)
  d.maybe_rebase()
  @test.assert_eq(d.parse_pos, position - offset)
  d.record_chained_positions(d.parse_pos - 3)
  @test.assert_eq(d.hashed_through, d.parse_pos - 2)
  d.write_stored_pending(is_final=true)
  @test.assert_eq(inflate_prefix(Bytes::from_array(d.w.out)).data, b"abc")
}

///|
test "stored ring blocks split at LEN limit and preserve wrapped bytes" {
  let ring = FixedArray::make(STREAM_RING_STORAGE_SIZE, b'\x00')
  for i in 0..<STREAM_RING_SIZE {
    let byte = ((i * 73 + i / 17) & 255).to_byte()
    ring[i] = byte
    ring[i + STREAM_RING_SIZE] = byte
  }
  let start = STREAM_RING_SIZE - 7
  for length in [0, 65535, 65536] {
    let w = BitWriter()
    w.write_stored_window(ring, start, start + length, is_final=true)
    let expected = Bytes::makei(length, i => {
      ring[(start + i) & STREAM_RING_MASK]
    })
    @test.assert_eq(inflate_prefix(Bytes::from_array(w.out)).data, expected)
    @test.assert_eq(w.out.length(), length + 5 * stored_block_count(length))
  }
}

///|
test "streaming lazy match commits lookahead beyond a one-byte token range" {
  let data = b"abcabcabc"
  let ring = FixedArray::make(STREAM_RING_STORAGE_SIZE, b'\x00')
  for i in 0..<data.length() {
    ring[i] = data[i]
    ring[i + STREAM_RING_SIZE] = data[i]
  }
  let finder = MatchFinder()
  for i in 0..<3 {
    finder.insert_window_pos(ring, i, data.length())
  }
  let tokens : Array[Int32] = []
  let ll = FixedArray::make(286, 0)
  let dd = FixedArray::make(30, 0)
  let end = tokenize_window(
    ring,
    finder,
    3,
    4,
    data.length(),
    level_configs[6],
    tokens,
    ll,
    dd,
  )
  @test.assert_eq(end, 9)
  @test.assert_eq(tokens, [pack_match_token(6, 3)])
  @test.assert_eq(ll[257 + len_to_idx[6]], 1)
  @test.assert_eq(dd[dist_index(3)], 1)
}

///|
test "stored decoder drains prefetched bytes before staged and external input" {
  let d = IncrementalDecoder()
  let output = FixedArray::make(3, b'\x00')
  d.mode = InStored
  d.final_block = true
  d.stored_remaining = 3
  d.wpos = WINDOW_SIZE - 1
  d.bitbuf = 97
  d.bit_count = 8
  d.staged_input = [b'b']
  d.view = b"c"
  d.out = output.mut_view()
  d.out_end = 3
  @test.assert_eq(d.run_step(), Done)
  @test.assert_eq(Bytes::from_array(output), b"abc")
  @test.assert_eq(d.wpos, WINDOW_SIZE + 2)
  @test.assert_eq(d.filled, true)
  @test.assert_eq(d.window[WINDOW_SIZE - 1], b'a')
  @test.assert_eq(d.window[0], b'b')
  @test.assert_eq(d.window[1], b'c')
  @test.assert_eq(d.stored_remaining, 0)
  @test.assert_eq(d.next_stored_byte(), None)
  d.copy_remaining = 2
  d.copy_dist = 1
  d.drain_match() // no output room: retain the suspended match
  @test.assert_eq(d.copy_remaining, 2)
  @test.assert_eq(d.wpos, WINDOW_SIZE + 2)
}

///|
test "fast Huffman lookup handles linked symbols invalid codes and short input" {
  let h = HuffmanDecoder()
  @test.assert_eq(h.initialize([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10]), true)
  for entry in [(b"\xFF\x01\x00", 9), (b"\xFF\x03\x00", 10)] {
    let (input, expected) = entry
    let d = MemDecoder(input, () => false)
    @test.assert_eq(d.huff_sym_data(h), expected)
    @test.assert_eq(d.bit_count, 14)
  }
  let truncated = MemDecoder(b"\xFF", () => false)
  let err = @test.expect_error(() => truncated.huff_sym_data(h))
  guard err is InflateError(kind, _)
  @test.assert_eq(kind, Truncated)
  let invalid = MemDecoder(b"\x00\x00\x00", () => false)
  let err = @test.expect_error(() => invalid.huff_sym_data(HuffmanDecoder()))
  guard err is InflateError(kind, _)
  @test.assert_eq(kind, Corrupt)
}

///|
test "growable bit writer preserves prefix when byte payload grows storage" {
  let writer = BitWriter::growing(FixedArray::make(1, b'\x00'))
  writer.write_byte(b'\xaa')
  writer.write_bytes(b"012345", 1, 4)
  @test.assert_eq(writer.direct_pos, 5)
  assert_false(writer.overflowed)
  @test.assert_eq(
    Bytes::from_array(writer.direct_output.unwrap()[:5]),
    b"\xaa1234",
  )
}

///|
test "bit writer capacity arithmetic stays within Int at the doubling boundary" {
  @test.assert_eq(
    bitwriter_growth_capacity(0x3fff_ffff, 0x4000_0000),
    0x7fff_fffe,
  )
  @test.assert_eq(
    bitwriter_growth_capacity(0x4000_0000, 0x4000_0001),
    0x4000_0001,
  )
  @test.assert_eq(
    bitwriter_growth_capacity(0x7fff_fffe, 0x7fff_ffff),
    0x7fff_ffff,
  )
}

///|
test "a full growing output becomes the result without a copy" {
  let out = DecodeOutput(4, limit=4)
  out.append_bytes(b"abcd", 0, 4)
  let bytes = out.into_owned_bytes()
  // Shared storage: a write through the output shows in the result.
  out.storage[0] = b'z'
  inspect(bytes[0] == b'z', content="true")
  inspect(bytes.length(), content="4")
}

///|
test "a partly filled growing output is copied into its result" {
  let out = DecodeOutput(8, limit=8)
  out.append_bytes(b"abc", 0, 3)
  let bytes = out.into_owned_bytes()
  out.storage[0] = b'z'
  @test.assert_eq(bytes, b"abc")
}

///|
test "decompress returns exact-limit output intact across reuse" {
  let decompressor = Decompressor()
  let first = Bytes::makei(100_000, i => (i % 251).to_byte())
  let second = Bytes::makei(70_000, i => (i % 13).to_byte())
  let a = decompressor.decompress(
      deflate_all(first),
      max_output_bytes=first.length(),
    ).data
  let b = decompressor.decompress(
      deflate_all(second),
      max_output_bytes=second.length(),
    ).data
  @test.assert_eq(a, first)
  @test.assert_eq(b, second)
}
