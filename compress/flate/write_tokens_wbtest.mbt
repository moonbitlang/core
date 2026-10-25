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

// The 64-bit token writer against its bytewise reference: same bytes, same
// pending bits and same overflow accounting in every kind of sink.

///|
/// Literals and matches of every length and distance code, from an LCG.
#cfg(any(target="native", target="wasm"))
fn token_fixture(count : Int32, seed : UInt32) -> Array[Int32] {
  let mut state = seed
  let next = () => {
    state = state * 1103515245U + 12345U
    ((state >> 8) & 0xFFFFFFU).reinterpret_as_int()
  }
  Array::makei(count, _ => {
    match next() % 4 {
      0 | 1 => next() % 256
      2 => pack_match_token(3 + next() % 256, 1 + next() % 32768)
      // Short distances reach the distance codes without extra bits.
      _ => pack_match_token(3 + next() % 256, 1 + next() % 40)
    }
  })
}

///|
/// Both writers start with `pending` bits already buffered, write `tokens`
/// and must leave the same state behind.
#cfg(any(target="native", target="wasm"))
fn assert_token_writers_agree(
  make : () -> BitWriter,
  pending : Int32,
  tokens : Array[Int32],
  ll_val : FixedArray[UInt32],
  ll_len : FixedArray[Int32],
  dd_val : FixedArray[UInt32],
  dd_len : FixedArray[Int32],
) -> Unit raise {
  let reference = make()
  let wide = make()
  reference.write_bits(0x55, pending)
  wide.write_bits(0x55, pending)
  reference.write_tokens_bytewise(tokens, ll_val, ll_len, dd_val, dd_len)
  wide.write_tokens_wide(tokens, ll_val, ll_len, dd_val, dd_len)
  @test.assert_eq(wide.bitbuf, reference.bitbuf)
  @test.assert_eq(wide.bit_count, reference.bit_count)
  @test.assert_eq(wide.direct_pos, reference.direct_pos)
  @test.assert_eq(wide.overflowed, reference.overflowed)
  @test.assert_eq(wide.out, reference.out)
  match (wide.direct_output, reference.direct_output) {
    (Some(a), Some(b)) => @test.assert_eq(a, b)
    (None, None) => ()
    _ => @test.fail("writers disagree on their sink")
  }
}

///|
#cfg(any(target="native", target="wasm"))
test "wide token writer matches the bytewise writer in every sink" {
  let lengths = build_dynamic_code_lengths(
    FixedArray::makei(MAX_NUM_LIT, i => 1 + i * 7 % 13),
    FixedArray::makei(MAX_NUM_DIST, i => 1 + i * 5 % 11),
  )
  let codes = materialize_dynamic_codes(lengths)
  let tables = [
    (codes.dll_val, lengths.dll_len, codes.dd_val, lengths.dd_len),
    (fixed_ll_val, fixed_ll_len, fixed_dist_val, fixed_dist_len),
  ]
  let counts = [
    0, 1, 2, 3, 7, 8, 9, 63, 64, 65, 1023, 1024, 1025, 2047, 2048, 2049, 5000,
  ]
  for table in tables {
    let (ll_val, ll_len, dd_val, dd_len) = table
    for count in counts {
      let tokens = token_fixture(count, count.reinterpret_as_uint() + 1)
      for pending in 0..<8 {
        assert_token_writers_agree(
          () => BitWriter(),
          pending,
          tokens,
          ll_val,
          ll_len,
          dd_val,
          dd_len,
        )
      }
      // A direct sink: ample (the sentinel behind the output must survive),
      // exact, one byte short, far too small, empty; then growable ones.
      let probe = BitWriter()
      probe.write_bits(0x55, 3)
      probe.write_tokens_bytewise(tokens, ll_val, ll_len, dd_val, dd_len)
      let size = probe.out.length()
      for capacity in [size + 9, size, size - 1, size / 2, 0] {
        guard capacity >= 0 else { continue }
        assert_token_writers_agree(
          () => BitWriter::into(FixedArray::make(capacity, b'\xA5')),
          3,
          tokens,
          ll_val,
          ll_len,
          dd_val,
          dd_len,
        )
      }
      for capacity in [0, 1, size / 3, size] {
        let reference = BitWriter::growing(FixedArray::make(capacity, b'\xA5'))
        let wide = BitWriter::growing(FixedArray::make(capacity, b'\xA5'))
        reference.write_tokens_bytewise(tokens, ll_val, ll_len, dd_val, dd_len)
        wide.write_tokens_wide(tokens, ll_val, ll_len, dd_val, dd_len)
        @test.assert_eq(wide.direct_pos, reference.direct_pos)
        @test.assert_eq(wide.bitbuf, reference.bitbuf)
        @test.assert_eq(wide.bit_count, reference.bit_count)
        assert_false(wide.overflowed)
        guard wide.direct_output is Some(a) &&
          reference.direct_output is Some(b) else {
          @test.fail("a growable writer lost its output")
        }
        @test.assert_eq(a[:wide.direct_pos], b[:reference.direct_pos])
      }
    }
  }
}

///|
/// Every token 48 bits long, with all bits set: the scratch chunk is filled
/// to the last byte its size is computed for.
#cfg(any(target="native", target="wasm"))
test "wide token writer holds chunks of maximal tokens" {
  let ll_val = FixedArray::make(MAX_NUM_LIT, 0x7FFFU)
  let ll_len = FixedArray::make(MAX_NUM_LIT, 15)
  let dd_val = FixedArray::make(MAX_NUM_DIST, 0x7FFFU)
  let dd_len = FixedArray::make(MAX_NUM_DIST, 15)
  // Length 257 has five extra bits (30), distance 32768 thirteen (8191).
  for
    count in [
      TOKEN_CHUNK_TOKENS - 1,
      TOKEN_CHUNK_TOKENS,
      TOKEN_CHUNK_TOKENS + 1,
      3 * TOKEN_CHUNK_TOKENS,
    ] {
    let tokens = Array::make(count, pack_match_token(257, 32768))
    for pending in 0..<8 {
      assert_token_writers_agree(
        () => BitWriter(),
        pending,
        tokens,
        ll_val,
        ll_len,
        dd_val,
        dd_len,
      )
    }
    let writer = BitWriter()
    writer.write_bits(0x7F, 7)
    writer.write_tokens_wide(tokens, ll_val, ll_len, dd_val, dd_len)
    @test.assert_eq(writer.out.length() * 8 + writer.bit_count, 7 + 48 * count)
  }
}

///|
#cfg(any(target="native", target="wasm"))
test "bulk byte writes count like single bytes in every sink" {
  let bytes = FixedArray::makei(40, i => (i * 7 + 1).to_byte())
  for length in [0, 1, 5, 40] {
    for capacity in [0, 1, 4, 5, 6, 64] {
      let bulk = BitWriter::into(FixedArray::make(capacity, b'\xA5'))
      let single = BitWriter::into(FixedArray::make(capacity, b'\xA5'))
      bulk.write_byte(b'\x11')
      single.write_byte(b'\x11')
      bulk.write_array(bytes, length)
      for i in 0..<length {
        single.write_byte(bytes[i])
      }
      @test.assert_eq(bulk.direct_pos, single.direct_pos)
      @test.assert_eq(bulk.overflowed, single.overflowed)
      @test.assert_eq(bulk.direct_output, single.direct_output)
      let grown = BitWriter::growing(FixedArray::make(capacity, b'\xA5'))
      grown.write_byte(b'\x11')
      grown.write_array(bytes, length)
      @test.assert_eq(grown.direct_pos, length + 1)
      assert_false(grown.overflowed)
      guard grown.direct_output is Some(output) else {
        @test.fail("a growable writer lost its output")
      }
      @test.assert_eq(output[1:length + 1], bytes[:length])
    }
    let plain = BitWriter()
    plain.write_array(bytes, length)
    @test.assert_eq(plain.out[:], bytes[:length])
  }
}
