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
/// Finish a test-only LSB-first DEFLATE bit stream.
fn coverage_finish_bits(w : BitWriter) -> Bytes {
  w.flush()
  Bytes::from_array(w.out)
}

///|
/// Write a final dynamic-block header and its code-length alphabet.
fn coverage_dynamic_header(
  w : BitWriter,
  hlit : Int32,
  hdist : Int32,
  nclen : Int32,
  code_lengths : Array[Int32],
) -> Unit {
  w.write_bit(1) // BFINAL
  w.write_bits(2, 2) // BTYPE=10 (dynamic)
  w.write_bits(hlit, 5)
  w.write_bits(hdist, 5)
  w.write_bits(nclen - 4, 4)
  for i in 0..<nclen {
    w.write_bits(code_lengths[code_order[i]], 3)
  }
}

///|
/// Both decoder implementations must reject the same complete malformed stream.
fn expect_corrupt_stream(data : Bytes) -> Unit raise {
  let InflateError(kind, _) = @test.expect_error(() => inflate_all(data))
  @test.assert_eq(kind, Corrupt)
  let inflater = Inflater()
  let output = FixedArray::make(1, b'\x00')
  let InflateError(kind, _) = @test.expect_error(() => {
    inflater.step(data, output.mut_view())
  })
  @test.assert_eq(kind, Corrupt)
}

///|
/// Both decoders must decode the longest symbols in a complete skewed tree.
test "Huffman decoders read ten-bit canonical codes" {
  // Kraft sum: 1/2 + 1/4 + ... + 1/512 + 2/1024 = 1.
  let lengths : ReadOnlyArray[_] = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10]
  let h = HuffmanDecoder()
  assert_true(h.initialize(lengths))

  // Symbols 9 and 10 have canonical codes 1022 and 1023. Their transmitted
  // (bit-reversed) forms are respectively 0x1ff and 0x3ff.
  let code9 : Bytes = [0xFF, 0x01]
  let stream9 = Inflater()
  stream9.view = code9
  @test.assert_eq(stream9.huff_sym(h), 9)
  let memory9 = MemDecoder(code9, () => false)
  @test.assert_eq(memory9.huff_sym(h), 9)

  let code10 : Bytes = [0xFF, 0x03]
  let stream10 = Inflater()
  stream10.view = code10
  @test.assert_eq(stream10.huff_sym(h), 10)
  let memory10 = MemDecoder(code10, () => false)
  @test.assert_eq(memory10.huff_sym(h), 10)
}

///|
/// Empty decode tables are permitted while reading a malformed dynamic header,
/// but selecting from one is an invalid Huffman code, not an input suspension.
test "both inflaters reject an empty Huffman alphabet" {
  let code_lengths = Array::make(NUM_CODES, 0)
  let w = BitWriter()
  coverage_dynamic_header(w, 0, 0, 4, code_lengths)
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// HLIT and HDIST reserve values beyond the supported alphabets.
test "both inflaters reject oversized dynamic alphabets" {
  let code_lengths = Array::make(NUM_CODES, 0)
  let too_many_literals = BitWriter()
  coverage_dynamic_header(too_many_literals, 31, 0, 4, code_lengths)
  expect_corrupt_stream(coverage_finish_bits(too_many_literals))

  let too_many_distances = BitWriter()
  coverage_dynamic_header(too_many_distances, 0, 31, 4, code_lengths)
  expect_corrupt_stream(coverage_finish_bits(too_many_distances))
}

///|
/// Three one-bit symbols oversubscribe the code-length Huffman tree.
test "both inflaters reject an oversubscribed code-length tree" {
  let code_lengths = Array::make(NUM_CODES, 0)
  code_lengths[16] = 1
  code_lengths[17] = 1
  code_lengths[18] = 1
  let w = BitWriter()
  coverage_dynamic_header(w, 0, 0, 4, code_lengths)
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// Repeat symbol 16 cannot be the first decoded code length.
test "both inflaters reject repeat-without-previous" {
  let code_lengths = Array::make(NUM_CODES, 0)
  code_lengths[16] = 1 // valid degenerate one-symbol tree; code is zero
  let w = BitWriter()
  coverage_dynamic_header(w, 0, 0, 4, code_lengths)
  w.write_bits(0, 1)
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// Two maximum symbol-18 runs describe 276 lengths although only 258 are due.
test "both inflaters reject code-length repeat overflow" {
  let code_lengths = Array::make(NUM_CODES, 0)
  code_lengths[18] = 1 // valid degenerate one-symbol tree; code is zero
  let w = BitWriter()
  coverage_dynamic_header(w, 0, 0, 4, code_lengths)
  w.write_bits(0, 1)
  w.write_bits(127, 7) // 11 + 127 = 138 zeros
  w.write_bits(0, 1)
  w.write_bits(127, 7) // 138 + 138 > 258
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// The code-length alphabet is valid, but it describes one lone two-bit
/// literal code, which is neither complete nor the permitted one-bit degenerate
/// tree.
test "both inflaters reject an incomplete literal-length tree" {
  let code_lengths = Array::make(NUM_CODES, 0)
  code_lengths[0] = 1
  code_lengths[2] = 2
  code_lengths[18] = 2
  let w = BitWriter()
  coverage_dynamic_header(w, 0, 0, 16, code_lengths)
  w.write_bits(1, 2) // symbol 2: clbits[0] = 2
  w.write_bits(3, 2) // symbol 18
  w.write_bits(127, 7) // 138 zeros
  w.write_bits(3, 2) // symbol 18
  w.write_bits(108, 7) // 119 zeros; 1 + 138 + 119 = 258
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// A one-bit EOB-only literal tree is valid, while a lone two-bit distance tree
/// is incomplete and must be rejected independently.
test "both inflaters reject an incomplete distance tree" {
  let code_lengths = Array::make(NUM_CODES, 0)
  code_lengths[0] = 2
  code_lengths[1] = 2
  code_lengths[2] = 2
  code_lengths[18] = 2
  let w = BitWriter()
  coverage_dynamic_header(w, 0, 0, 18, code_lengths)
  w.write_bits(3, 2) // symbol 18
  w.write_bits(127, 7) // 138 zeros
  w.write_bits(3, 2) // symbol 18
  w.write_bits(107, 7) // 118 zeros; now at literal symbol 256
  w.write_bits(2, 2) // symbol 1: the EOB code has length one
  w.write_bits(1, 2) // symbol 2: the sole distance code has length two
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// Fixed literal/length symbols 286 and 287 are reserved by RFC 1951.
test "both inflaters reject a reserved fixed literal-length symbol" {
  let w = BitWriter()
  w.write_bit(1)
  w.write_bits(1, 2) // BTYPE=01 (fixed)
  w.write_rcode(fixed_ll_val[286], fixed_ll_len[286]) // symbol 286, 8 bits
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// Fixed distance symbols 30 and 31 are reserved by RFC 1951.
test "both inflaters reject a reserved fixed distance symbol" {
  let w = BitWriter()
  w.write_bit(1)
  w.write_bits(1, 2) // BTYPE=01 (fixed)
  w.write_rcode(fixed_ll_val[257], fixed_ll_len[257]) // length 3
  w.write_rcode(reverse_bits((30).reinterpret_as_uint(), 5), 5) // reserved code 30
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// A valid distance code is still illegal before any history byte exists.
test "both inflaters reject a back-reference before the window" {
  let w = BitWriter()
  w.write_bit(1)
  w.write_bits(1, 2) // BTYPE=01 (fixed)
  w.write_rcode(fixed_ll_val[257], fixed_ll_len[257]) // length 3
  w.write_rcode(fixed_dist_val[0], fixed_dist_len[0]) // distance 1
  expect_corrupt_stream(coverage_finish_bits(w))
}

///|
/// The in-memory decoder reports truncation, while the streaming decoder owns
/// the incomplete atomic tail so the caller may drop the supplied byte.
test "stored header truncation stages streaming input" {
  let truncated : Bytes = [0x01]
  let InflateError(kind, _) = @test.expect_error(() => inflate_all(truncated))
  @test.assert_eq(kind, Truncated)
  let inflater = Inflater()
  let output = FixedArray::make(1, b'\x00')
  let status_result = inflater.step(truncated, output.mut_view())
  let status = status_result.status
  let consumed = status_result.consumed
  let produced = status_result.produced
  assert_true(status is NeedMoreInput)
  @test.assert_eq(consumed, 1)
  @test.assert_eq(produced, 0)
  @test.assert_eq(inflater.staged_input.length(), 1)
  @test.assert_eq(inflater.view.length(), 0)
  @test.assert_eq(inflater.out.length(), 0)
}

///|
/// Stored-byte reads may resume from an owned atomic tail. Once part of that
/// tail is permanent, compaction must retain only the unread suffix.
test "stored input drains and compacts a partial staged tail" {
  let inflater = Inflater()
  inflater.staged_input = [b'\xAA', b'\xBB', b'\xCC']
  inflater.staged_pos = 0
  assert_true(inflater.next_stored_byte() == Some(b'\xAA'))
  @test.assert_eq(inflater.staged_pos, 1)
  inflater.compact_staged_input()
  @test.assert_eq(inflater.staged_pos, 0)
  @test.assert_eq(inflater.staged_input.length(), 2)
  @test.assert_eq(inflater.staged_input[0], b'\xBB')
  @test.assert_eq(inflater.staged_input[1], b'\xCC')
}

///|
/// A complete stored header with a non-complementary NLEN is malformed in both
/// decoding modes.
test "both inflaters reject a stored length mismatch" {
  expect_corrupt_stream(([0x01, 0x01, 0x00, 0x00, 0x00] : Bytes))
}

///|
/// A fixed block header alone permanently consumes that header in streaming
/// mode but leaves its first Huffman symbol incomplete.
test "fixed-symbol truncation suspends only the streaming inflater" {
  let truncated : Bytes = [0x03]
  let InflateError(kind, _) = @test.expect_error(() => inflate_all(truncated))
  @test.assert_eq(kind, Truncated)
  let inflater = Inflater()
  let output = FixedArray::make(1, b'\x00')
  let status_result = inflater.step(truncated, output.mut_view())
  let status = status_result.status
  let consumed = status_result.consumed
  let produced = status_result.produced
  assert_true(status is NeedMoreInput)
  @test.assert_eq(consumed, 1)
  @test.assert_eq(produced, 0)
}
