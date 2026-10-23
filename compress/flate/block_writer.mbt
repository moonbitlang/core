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

// Block emission stage of the encode pipeline: one batch of tokens plus its
// frequency tables in, one DEFLATE block out. Chooses fixed- or
// dynamic-Huffman by exact estimated size, and run-length-encodes the dynamic
// table's code lengths (RFC 1951 §3.2.7).

///|
#valtype
priv struct CodeLenSym {
  sym : Int32
  extra : Int32
  nextra : Int32
}

///|
/// Number of stored blocks required for `byte_len` bytes. An empty range still
/// needs one block, while every non-empty exact 65535-byte multiple ends in its
/// last full block rather than requiring a second empty block.
fn stored_block_count(byte_len : Int32) -> Int32 {
  if byte_len == 0 {
    1
  } else {
    (byte_len - 1) / 65535 + 1
  }
}

///|
/// Run-length-encode the concatenated literal/length and distance code lengths
/// into code-length symbols (RFC 1951 §3.2.7), using 16/17/18.
fn build_codelen_syms(
  ll_len : FixedArray[Int32],
  hlit : Int32,
  dd_len : FixedArray[Int32],
  hdist : Int32,
) -> Array[CodeLenSym] {
  let comb = FixedArray::make(hlit + hdist, 0)
  ll_len.blit_to(comb, len=hlit)
  dd_len.blit_to(comb, len=hdist, dst_offset=hlit)
  let out : Array[CodeLenSym] = []
  let m = comb.length()
  let mut i = 0
  while i < m {
    let cur = comb[i]
    let mut run = 1
    while i + run < m && comb[i + run] == cur {
      run = run + 1
    }
    i = i + run
    if cur == 0 {
      while run >= 11 {
        let r = run.min(138)
        out.push({ sym: 18, extra: r - 11, nextra: 7, })
        run = run - r
      }
      while run >= 3 {
        let r = run.min(10)
        out.push({ sym: 17, extra: r - 3, nextra: 3, })
        run = run - r
      }
      while run > 0 {
        out.push({ sym: 0, extra: 0, nextra: 0, })
        run = run - 1
      }
    } else {
      out.push({ sym: cur, extra: 0, nextra: 0, })
      run = run - 1
      while run >= 3 {
        let r = run.min(6)
        out.push({ sym: 16, extra: r - 3, nextra: 2, })
        run = run - r
      }
      while run > 0 {
        out.push({ sym: cur, extra: 0, nextra: 0, })
        run = run - 1
      }
    }
  }
  out
}

///|
/// Exact bit cost of each candidate encoding for one block, 3-bit block
/// header included.
#valtype
priv struct BlockCost {
  stored : Int32
  fixed : Int32
  dynamic : Int32
}

///|
/// Code lengths and RLE header metadata for one dynamic-Huffman block. The
/// encoder builds this cheaper form before deciding whether dynamic coding
/// wins; code words are materialized only for a selected dynamic block.
priv struct DynamicCodeLengths {
  dll_len : FixedArray[Int32]
  dd_len : FixedArray[Int32]
  hlit : Int32
  hdist : Int32
  codelen_syms : Array[CodeLenSym]
  codelen_code_len : FixedArray[Int32]
  hclen : Int32
}

///|
/// Complete code tables for a dynamic-Huffman block that will be emitted.
priv struct DynamicCodes {
  lengths : DynamicCodeLengths
  dll_val : FixedArray[UInt32]
  dd_val : FixedArray[UInt32]
  codelen_code_val : FixedArray[UInt32]
}

///|
priv enum BlockEncoding {
  Stored
  Fixed
  Dynamic(DynamicCodes)
}

///|
/// Build dynamic-Huffman code lengths for one block from its symbol
/// frequencies. `ll_freq` must already include the end-of-block symbol.
fn build_dynamic_code_lengths(
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> DynamicCodeLengths {
  let dll_len = FixedArray::make(286, 0)
  gen_huffman(ll_freq, 286, 15, dll_len)
  let dd_len = FixedArray::make(30, 0)
  gen_huffman(d_freq, 30, 15, dd_len)
  if !dd_len.any(length => length > 0) {
    dd_len[0] = 1 // DEFLATE requires at least one distance code
  }
  let mut hlit = 286
  while hlit > 257 && dll_len[hlit - 1] == 0 {
    hlit = hlit - 1
  }
  let mut hdist = 30
  while hdist > 1 && dd_len[hdist - 1] == 0 {
    hdist = hdist - 1
  }
  let codelen_syms = build_codelen_syms(dll_len, hlit, dd_len, hdist)
  let codelen_freq = FixedArray::make(19, 0)
  for it in codelen_syms {
    codelen_freq[it.sym] += 1
  }
  let codelen_code_len = FixedArray::make(19, 0)
  gen_huffman(codelen_freq, 19, 7, codelen_code_len)
  let mut hclen = 19
  while hclen > 4 && codelen_code_len[code_order[hclen - 1]] == 0 {
    hclen = hclen - 1
  }
  { dll_len, dd_len, hlit, hdist, codelen_syms, codelen_code_len, hclen, }
}

///|
/// Generate bit-reversed canonical code words from already-computed lengths.
/// This is only needed after a block has won the dynamic-Huffman comparison.
fn canonical_code_values(
  code_len : FixedArray[Int32],
  max_bits : Int32,
) -> FixedArray[UInt32] {
  let counts = FixedArray::make(max_bits + 1, 0)
  for length in code_len {
    if length > 0 {
      counts[length] += 1
    }
  }
  let next_code = FixedArray::make(max_bits + 1, 0)
  for length in 1..<=max_bits {
    next_code[length] = (next_code[length - 1] + counts[length - 1]) << 1
  }
  let values = FixedArray::make(code_len.length(), 0U)
  for symbol in 0..<code_len.length() {
    let length = code_len[symbol]
    if length > 0 {
      values[symbol] = reverse_bits(
        next_code[length].reinterpret_as_uint(),
        length,
      )
      next_code[length] += 1
    }
  }
  values
}

///|
/// Materialize the code words for a dynamic block after its lengths have
/// already been used for cost estimation.
fn materialize_dynamic_codes(lengths : DynamicCodeLengths) -> DynamicCodes {
  {
    lengths,
    dll_val: canonical_code_values(lengths.dll_len, 15),
    dd_val: canonical_code_values(lengths.dd_len, 15),
    codelen_code_val: canonical_code_values(lengths.codelen_code_len, 7),
  }
}

///|
/// Estimated bit cost of each encoding for `byte_len` input bytes. Stored
/// blocks use five framing bytes per chunk, without tracking the current bit
/// alignment. `ll_freq` must already include the end-of-block symbol.
/// Shared by `emit_block`'s encoding choice and the optimal planner's split
/// decisions, so both always use the same accounting.
fn estimate_block_cost(
  codes : DynamicCodeLengths,
  byte_len : Int32,
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> BlockCost {
  // Length/distance extra bits are shared by fixed and dynamic but absent
  // from stored, so they join the comparison.
  let mut dyn_sym_bits = 0
  let mut fixed_sym_bits = 0
  for s in 0..<286 {
    if ll_freq[s] != 0 {
      dyn_sym_bits = dyn_sym_bits + ll_freq[s] * codes.dll_len[s]
      fixed_sym_bits = fixed_sym_bits + ll_freq[s] * fixed_ll_len[s]
    }
  }
  for d in 0..<30 {
    if d_freq[d] != 0 {
      dyn_sym_bits = dyn_sym_bits + d_freq[d] * codes.dd_len[d]
      fixed_sym_bits = fixed_sym_bits + d_freq[d] * 5
    }
  }
  let mut extra_bits = 0
  for i in 0..<29 {
    extra_bits = extra_bits + ll_freq[257 + i] * len_extra[i]
  }
  for d in 0..<30 {
    extra_bits = extra_bits + d_freq[d] * dist_extra[d]
  }
  let mut dyn_hdr_bits = 14 + 3 * codes.hclen
  for it in codes.codelen_syms {
    dyn_hdr_bits = dyn_hdr_bits + codes.codelen_code_len[it.sym] + it.nextra
  }
  // Stored: ~5 bytes of framing per 65535-byte chunk, data verbatim. This is
  // the fallback that caps worst-case expansion on incompressible data.
  let stored_bits = 8 * (byte_len + 5 * stored_block_count(byte_len))
  {
    stored: stored_bits,
    fixed: 3 + fixed_sym_bits + extra_bits,
    dynamic: 3 + dyn_hdr_bits + dyn_sym_bits + extra_bits,
  }
}

///|
// Decide an encoding once for both input backings. The streaming writer can
// then copy a stored payload directly out of its ring, while one-shot callers
// retain their contiguous `Bytes` fast path.
fn choose_block_encoding(
  byte_len : Int32,
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
) -> BlockEncoding {
  ll_freq[256] += 1 // end-of-block
  let lengths = build_dynamic_code_lengths(ll_freq, d_freq)
  let cost = estimate_block_cost(lengths, byte_len, ll_freq, d_freq)
  if cost.stored < cost.fixed && cost.stored < cost.dynamic {
    Stored
  } else if cost.dynamic < cost.fixed {
    Dynamic(materialize_dynamic_codes(lengths))
  } else {
    Fixed
  }
}

///|
fn BitWriter::write_huffman_block(
  writer : BitWriter,
  dynamic_codes : DynamicCodes?,
  tokens : ArrayView[Int32],
  is_final : Bool,
) -> Unit {
  writer.write_bit(if is_final { 1 } else { 0 }) // BFINAL
  guard dynamic_codes is Some(codes) else {
    writer.write_fixed_block(tokens)
    return
  }
  writer.write_dynamic_block(codes, tokens)
}

///|
/// Write a token stream (literals and length/distance matches) through the
/// given literal/length and distance tables, then the end-of-block symbol.
///
/// The bit accumulator lives in locals for the whole stream: codes are
/// already bit-reversed and below `1 << length`, and extra-bit values are
/// below `1 << extra`, so no masking is needed. At most 7 bits are pending
/// before each field and no field exceeds 15 bits, so the 31-bit positive
/// range of `Int` is never exceeded. Bytes are emitted exactly as by
/// `write_bits`, which this inlines.
///
/// This is the reference for the 64-bit `write_tokens` of native and linear
/// wasm, and the implementation on the other backends.
fn BitWriter::write_tokens_bytewise(
  writer : BitWriter,
  tokens : ArrayView[Int32],
  ll_val : FixedArray[UInt32],
  ll_len : FixedArray[Int32],
  dd_val : FixedArray[UInt32],
  dd_len : FixedArray[Int32],
) -> Unit {
  let mut bitbuf = writer.bitbuf
  let mut bit_count = writer.bit_count
  for tok in tokens {
    if tok < 256 {
      bitbuf = bitbuf | (ll_val[tok].reinterpret_as_int() << bit_count)
      bit_count = bit_count + ll_len[tok]
    } else {
      let length = tok >> 16
      let dist = tok & 0xFFFF
      let lidx = len_to_idx[length]
      let lsym = 257 + lidx
      // Length code (<= 15 bits) and its extra bits (<= 5) together stay
      // below 31 bits with 7 pending, as do the distance code (<= 15) and
      // its extra bits (<= 13) after the intermediate flush.
      bitbuf = bitbuf | (ll_val[lsym].reinterpret_as_int() << bit_count)
      bit_count = bit_count + ll_len[lsym]
      bitbuf = bitbuf | ((length - len_base[lidx]) << bit_count)
      bit_count = bit_count + len_extra[lidx]
      while bit_count >= 8 {
        writer.write_byte((bitbuf & 0xFF).to_byte())
        bitbuf = bitbuf >> 8
        bit_count = bit_count - 8
      }
      let didx = dist_index(dist)
      bitbuf = bitbuf | (dd_val[didx].reinterpret_as_int() << bit_count)
      bit_count = bit_count + dd_len[didx]
      while bit_count >= 8 {
        writer.write_byte((bitbuf & 0xFF).to_byte())
        bitbuf = bitbuf >> 8
        bit_count = bit_count - 8
      }
      bitbuf = bitbuf | ((dist - dist_base[didx]) << bit_count)
      bit_count = bit_count + dist_extra[didx]
    }
    while bit_count >= 8 {
      writer.write_byte((bitbuf & 0xFF).to_byte())
      bitbuf = bitbuf >> 8
      bit_count = bit_count - 8
    }
  }
  writer.bitbuf = bitbuf
  writer.bit_count = bit_count
}

///|
/// Tokens encoded between two hand-overs of `write_tokens`' scratch chunk.
#cfg(any(target="native", target="wasm"))
const TOKEN_CHUNK_TOKENS : Int32 = 1024

///|
/// One token is at most 48 bits (a 15-bit length code, 5 extra bits, a 15-bit
/// distance code, 13 extra bits), and at most 7 bits are pending when a chunk
/// starts: `TOKEN_CHUNK_TOKENS` tokens advance the write position by at most
/// `(7 + 48 * TOKEN_CHUNK_TOKENS) / 8 < 6 * TOKEN_CHUNK_TOKENS + 1` bytes, and
/// the last eight-byte store reaches seven bytes further.
#cfg(any(target="native", target="wasm"))
const TOKEN_CHUNK_BYTES : Int32 = 6 * TOKEN_CHUNK_TOKENS + 8

///|
/// `write_tokens_bytewise` with a 64-bit accumulator, as zlib-ng and
/// libdeflate write their tokens: every token is shifted in whole, then the
/// accumulator is stored as eight little-endian bytes and the write position
/// advances by the complete bytes only, so the incomplete byte is stored again
/// (completed) by the next token. Bytes go to a scratch chunk that is handed
/// to the writer in bulk. The emitted bytes and the bits left pending are
/// exactly those of `write_tokens_bytewise`.
#cfg(any(target="native", target="wasm"))
fn BitWriter::write_tokens_wide(
  writer : BitWriter,
  tokens : ArrayView[Int32],
  ll_val : FixedArray[UInt32],
  ll_len : FixedArray[Int32],
  dd_val : FixedArray[UInt32],
  dd_len : FixedArray[Int32],
) -> Unit {
  let chunk = FixedArray::make(TOKEN_CHUNK_BYTES, b'\x00')
  // At most 7 bits are pending between fields (see `write_bits`).
  let mut bitbuf = writer.bitbuf.reinterpret_as_uint().to_uint64()
  let mut bit_count = writer.bit_count
  let count = tokens.length()
  let mut start = 0
  while start < count {
    let end = start + (count - start).min(TOKEN_CHUNK_TOKENS)
    let mut pos = 0
    for k in start..<end {
      let tok = tokens[k]
      // With at most 7 bits pending, a literal (<= 15 bits) or a whole match
      // (<= 48 bits) keeps `bit_count` at 55 or less: nothing is shifted out
      // of the 64-bit accumulator. Codes are below `1 << length` and extra
      // values below `1 << extra`, so no field needs a mask.
      if tok < 256 {
        bitbuf = bitbuf | (ll_val[tok].to_uint64() << bit_count)
        bit_count = bit_count + ll_len[tok]
      } else {
        let length = tok >> 16
        let dist = tok & 0xFFFF
        let lidx = len_to_idx[length]
        let lsym = 257 + lidx
        bitbuf = bitbuf | (ll_val[lsym].to_uint64() << bit_count)
        bit_count = bit_count + ll_len[lsym]
        bitbuf = bitbuf |
          (
            (length - len_base[lidx]).reinterpret_as_uint().to_uint64() <<
            bit_count
          )
        bit_count = bit_count + len_extra[lidx]
        let didx = dist_index(dist)
        bitbuf = bitbuf | (dd_val[didx].to_uint64() << bit_count)
        bit_count = bit_count + dd_len[didx]
        bitbuf = bitbuf |
          (
            (dist - dist_base[didx]).reinterpret_as_uint().to_uint64() <<
            bit_count
          )
        bit_count = bit_count + dist_extra[didx]
      }
      // SAFETY: before token `k` of this chunk `pos` is at most
      // `(7 + 48 * (k - start)) / 8 <= 6 * (k - start)`, and
      // `k - start < TOKEN_CHUNK_TOKENS`, so the eight bytes at `pos` end at
      // or before `6 * TOKEN_CHUNK_TOKENS + 2 <= TOKEN_CHUNK_BYTES`.
      chunk.unsafe_write_uint64_le(pos, bitbuf)
      pos = pos + (bit_count >> 3)
      bitbuf = bitbuf >> (bit_count & 0x38)
      bit_count = bit_count & 7
    }
    writer.write_array(chunk, pos)
    start = end
  }
  writer.bitbuf = bitbuf.to_int()
  writer.bit_count = bit_count
}

///|
/// A run too short to pay for the scratch chunk is written bytewise.
#cfg(any(target="native", target="wasm"))
fn BitWriter::write_tokens(
  writer : BitWriter,
  tokens : ArrayView[Int32],
  ll_val : FixedArray[UInt32],
  ll_len : FixedArray[Int32],
  dd_val : FixedArray[UInt32],
  dd_len : FixedArray[Int32],
) -> Unit {
  if tokens.length() < 64 {
    writer.write_tokens_bytewise(tokens, ll_val, ll_len, dd_val, dd_len)
  } else {
    writer.write_tokens_wide(tokens, ll_val, ll_len, dd_val, dd_len)
  }
}

///|
#cfg(not(any(target="native", target="wasm")))
fn BitWriter::write_tokens(
  writer : BitWriter,
  tokens : ArrayView[Int32],
  ll_val : FixedArray[UInt32],
  ll_len : FixedArray[Int32],
  dd_val : FixedArray[UInt32],
  dd_len : FixedArray[Int32],
) -> Unit {
  writer.write_tokens_bytewise(tokens, ll_val, ll_len, dd_val, dd_len)
}

///|
/// Write one dynamic-Huffman block (BTYPE=10): the HLIT/HDIST/HCLEN fields, the
/// code-length code lengths, the RLE-coded code lengths, the token stream, and
/// the end-of-block symbol.
fn BitWriter::write_dynamic_block(
  writer : BitWriter,
  codes : DynamicCodes,
  tokens : ArrayView[Int32],
) -> Unit {
  writer.write_bits(2, 2) // BTYPE = 10 (dynamic)
  writer.write_bits(codes.lengths.hlit - 257, 5)
  writer.write_bits(codes.lengths.hdist - 1, 5)
  writer.write_bits(codes.lengths.hclen - 4, 4)
  for k in 0..<codes.lengths.hclen {
    writer.write_bits(codes.lengths.codelen_code_len[code_order[k]], 3)
  }
  for it in codes.lengths.codelen_syms {
    writer.write_rcode(
      codes.codelen_code_val[it.sym],
      codes.lengths.codelen_code_len[it.sym],
    )
    if it.nextra > 0 {
      writer.write_bits(it.extra, it.nextra)
    }
  }
  writer.write_tokens(
    tokens,
    codes.dll_val,
    codes.lengths.dll_len,
    codes.dd_val,
    codes.lengths.dd_len,
  )
  writer.write_rcode(codes.dll_val[256], codes.lengths.dll_len[256]) // EOB
}

///|
/// Write one fixed-Huffman block (BTYPE=01): the token stream with the fixed
/// literal/length and distance tables, then the end-of-block symbol.
fn BitWriter::write_fixed_block(
  writer : BitWriter,
  tokens : ArrayView[Int32],
) -> Unit {
  writer.write_bits(1, 2) // BTYPE = 01 (fixed)
  writer.write_tokens(
    tokens, fixed_ll_val, fixed_ll_len, fixed_dist_val, fixed_dist_len,
  )
  writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256]) // EOB
}

///|
/// Write one empty final block (no tokens) — the one-shot drivers' encoding of
/// an empty input.
fn BitWriter::emit_empty_block(writer : BitWriter, input : BytesView) -> Unit {
  let ll_freq = FixedArray::make(MAX_NUM_LIT, 0)
  let d_freq = FixedArray::make(MAX_NUM_DIST, 0)
  let none : FixedArray[Int32] = []
  writer.emit_block(input, 0, 0, none, ll_freq, d_freq, is_final=true)
}

///|
/// Write one DEFLATE block for `tokens` into `w`, choosing stored, fixed- or
/// dynamic-Huffman by estimated size. `data[start:end)` is the raw input the
/// tokens cover, copied verbatim when the stored encoding wins (incompressible
/// data). `is_final` sets the BFINAL bit. Counts the end-of-block symbol into
/// `ll_freq` itself. Does not flush `w`: the bit stream continues into the
/// next block, so the caller flushes once, after the final block.
fn BitWriter::emit_block(
  writer : BitWriter,
  data : BytesView,
  start : Int32,
  end : Int32,
  tokens : ArrayView[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
  is_final~ : Bool,
) -> Unit {
  let encoding = choose_block_encoding(end - start, ll_freq, d_freq)
  match encoding {
    Stored => writer.write_stored(data, start, end, is_final~)
    Fixed => writer.write_huffman_block(None, tokens, is_final)
    Dynamic(codes) => writer.write_huffman_block(Some(codes), tokens, is_final)
  }
}

///|
/// Write `data[start:end)` as stored (BTYPE=00) blocks: byte-aligned, raw
/// bytes, at most 65535 per block (LEN is 16-bit). `start == end` writes one
/// empty stored block — which is also the sync-flush marker (`00 00 FF FF`),
/// since the mandatory alignment pads the bit stream to a byte boundary.
fn BitWriter::write_stored(
  writer : BitWriter,
  data : BytesView,
  start : Int32,
  end : Int32,
  is_final~ : Bool,
) -> Unit {
  let mut p = start
  for ;; {
    let n = end - p
    let chunk = n.min(65535)
    let last = p + chunk == end
    if is_final && last {
      writer.write_bit(1) // BFINAL
    } else {
      writer.write_bit(0)
    }
    writer.write_bits(0, 2) // BTYPE = 00 (stored)
    writer.flush() // stored blocks are byte-aligned
    let nlen = chunk ^ 0xFFFF
    writer.write_byte((chunk & 0xFF).to_byte())
    writer.write_byte(((chunk >> 8) & 0xFF).to_byte())
    writer.write_byte((nlen & 0xFF).to_byte())
    writer.write_byte(((nlen >> 8) & 0xFF).to_byte())
    writer.write_bytes(data, p, chunk)
    p = p + chunk
    if last {
      break
    }
  }
}

///|
// Streaming equivalent of `write_stored`: absolute positions map through the
// low half of the mirrored input ring, so no temporary `Bytes` needs to be
// materialized for an incompressible block.
fn BitWriter::write_stored_window(
  writer : BitWriter,
  data : FixedArray[Byte],
  start : Int32,
  end : Int32,
  is_final~ : Bool,
) -> Unit {
  let mut p = start
  for ;; {
    let n = end - p
    let chunk = n.min(65535)
    let last = p + chunk == end
    if is_final && last {
      writer.write_bit(1)
    } else {
      writer.write_bit(0)
    }
    writer.write_bits(0, 2)
    writer.flush()
    let nlen = chunk ^ 0xFFFF
    writer.out.push((chunk & 0xFF).to_byte())
    writer.out.push(((chunk >> 8) & 0xFF).to_byte())
    writer.out.push((nlen & 0xFF).to_byte())
    writer.out.push(((nlen >> 8) & 0xFF).to_byte())
    // A stored block is smaller than the ring, so at most one wrap occurs.
    let offset = p & STREAM_RING_MASK
    let first = chunk.min(STREAM_RING_SIZE - offset)
    writer.out.append(data[offset:offset + first])
    writer.out.append(data[:chunk - first])
    p = p + chunk
    if last {
      break
    }
  }
}

///|
fn BitWriter::emit_window_block(
  writer : BitWriter,
  data : FixedArray[Byte],
  start : Int32,
  end : Int32,
  tokens : ArrayView[Int32],
  ll_freq : FixedArray[Int32],
  d_freq : FixedArray[Int32],
  is_final~ : Bool,
) -> Unit {
  let encoding = choose_block_encoding(end - start, ll_freq, d_freq)
  match encoding {
    Stored => writer.write_stored_window(data, start, end, is_final~)
    Fixed => writer.write_huffman_block(None, tokens, is_final)
    Dynamic(codes) => writer.write_huffman_block(Some(codes), tokens, is_final)
  }
}
