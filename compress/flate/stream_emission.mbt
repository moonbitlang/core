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
priv enum EmissionPhase {
  Idle
  StoredHeader(Int32)
  StoredPayload(Int32)
  FixedHeader
  DynamicHeader(DynamicCodes)
  CodeLengths(DynamicCodes)
  CodeSymbols(DynamicCodes)
  Tokens(DynamicCodes?)
  EndBlock(DynamicCodes?)
}

///|
fn IncrementalEncoder::start_stored(
  self : IncrementalEncoder,
  start : Int32,
  end : Int32,
  is_final~ : Bool,
) -> Unit {
  // Save physical offsets before the planner rebases its absolute positions.
  // A stream block fits in one LEN field and is contiguous in the mirrored ring.
  self.cursor = start & STREAM_RING_MASK
  self.phase = StoredHeader(self.cursor + (end - start))
  self.emitted_final = is_final
}

///|
fn IncrementalEncoder::copy_stored(
  self : IncrementalEncoder,
  output : MutArrayView[Byte],
  pos : Int32,
  count : Int32,
) -> Unit {
  if count == 1 {
    output[pos] = self.pending[self.cursor]
  } else if count > 1 {
    self.pending.blit_to(
      output_storage(output),
      src_offset=self.cursor,
      dst_offset=output.start_offset() + pos,
      len=count,
    )
  }
  self.cursor += count
}

///|
#cfg(any(target="native", target="wasm"))
const STREAM_WIDE_TOKENS : Bool = true

///|
#cfg(not(any(target="native", target="wasm")))
const STREAM_WIDE_TOKENS : Bool = false

///|
fn IncrementalEncoder::resume_token_prefix(
  self : IncrementalEncoder,
  codes : DynamicCodes?,
  output : MutArrayView[Byte],
  pos : Int32,
) -> Int32 {
  let pos = if codes is Some(c) {
    self.write_token_prefix(
      output,
      pos,
      c.dll_val,
      c.lengths.dll_len,
      c.dd_val,
      c.lengths.dd_len,
    )
  } else {
    self.write_token_prefix(
      output, pos, fixed_ll_val, fixed_ll_len, fixed_dist_val, fixed_dist_len,
    )
  }
  if self.cursor == self.tokens.length() && self.w.bit_count < 8 {
    self.phase = EndBlock(codes)
  }
  pos
}

///|
// Refill a word before draining it. With output room we can assemble up to
// 63 bits: draining at least one byte leaves at most 55 (six whole bytes).
// With no room, append to at most seven bits, stopping after the first whole
// byte becomes available. Other phases always see the normal 0..7 bits.
fn IncrementalEncoder::write_token_prefix(
  self : IncrementalEncoder,
  output : MutArrayView[Byte],
  start : Int32,
  ll_val : FixedArray[UInt32],
  ll_len : FixedArray[Int32],
  dd_val : FixedArray[UInt32],
  dd_len : FixedArray[Int32],
) -> Int32 {
  let mut pos = start
  let mut cursor = self.cursor
  let end = self.tokens.length()
  let mut lo = self.w.bitbuf.reinterpret_as_uint()
  let mut hi = self.token_high
  let mut bits = self.w.bit_count
  for ;; {
    while bits >= 8 && pos < output.length() {
      output.unsafe_set(pos, lo.to_byte())
      pos += 1
      lo = (lo >> 8) | (hi << 24)
      hi = hi >> 8
      bits -= 8
    }
    let room = output.length() - pos
    // Eight more tokens guarantee another byte. Near EOB resolve whether
    // this exact fit actually stalls or leaves only a sub-byte remainder.
    if bits >= 8 || cursor == end || (room == 0 && end - cursor >= 8) {
      break
    }
    if STREAM_WIDE_TOKENS && room >= 8 && end - cursor > 64 {
      // Each token advances at most six bytes. Leave eight bytes for the last
      // speculative store and 64 tokens (at least eight bytes) to cover it.
      let count = (end - cursor - 64).min(1 + (room - 8) / 6)
      self.w.bitbuf = lo.reinterpret_as_int()
      self.w.bit_count = bits
      pos += self.w.write_wide_run(
        self.tokens[cursor:cursor + count],
        ll_val,
        ll_len,
        dd_val,
        dd_len,
        output_storage(output),
        output.start_offset() + pos,
      )
      lo = self.w.bitbuf.reinterpret_as_uint()
      bits = self.w.bit_count
      cursor += count
      continue
    }
    // Below 48 bits even the longest literal fits. Check a whole match's
    // width before committing it so that neither half of the word overflows.
    let goal = if room == 0 { 8 } else { 48 }
    while cursor < end && bits < goal {
      let tok = self.tokens.unsafe_get(cursor)
      let (low, high, width) = if tok < 256 {
        (ll_val[tok], 0U, ll_len[tok])
      } else {
        let length = tok >> 16
        let dist = tok & 0xFFFF
        let lidx = len_to_idx[length]
        let lsym = 257 + lidx
        let didx = dist_index(dist)
        let lbits = ll_len[lsym] + len_extra[lidx]
        let l = ll_val[lsym] |
          ((length - len_base[lidx]).reinterpret_as_uint() << ll_len[lsym])
        let d = dd_val[didx] |
          ((dist - dist_base[didx]).reinterpret_as_uint() << dd_len[didx])
        (
          l | (d << lbits),
          d >> (32 - lbits),
          lbits + dd_len[didx] + dist_extra[didx],
        )
      }
      if bits + width > 63 {
        break
      }
      if bits >= 32 {
        hi = hi | (low << (bits - 32))
      } else {
        hi = if bits == 0 {
          high
        } else {
          (high << bits) | (low >> (32 - bits))
        }
        lo = lo | (low << bits)
      }
      bits += width
      cursor += 1
    }
  }
  self.cursor = cursor
  self.w.bitbuf = lo.reinterpret_as_int()
  self.token_high = hi
  self.w.bit_count = bits
  pos
}

///|
// Headers and EOB can spill at most six bytes (a stored header after seven
// pending bits). Drain them before entering the token writer or stored data.
fn IncrementalEncoder::resume_block(
  self : IncrementalEncoder,
  output : MutArrayView[Byte],
) -> Bool {
  let w = self.w
  for ;; {
    if w.out.length() > 0 {
      let remaining = w.out.length() - self.out_pos
      let count = remaining.min(output.length() - w.direct_pos)
      for i in 0..<count {
        output[w.direct_pos + i] = w.out[self.out_pos + i]
      }
      w.direct_pos += count
      if count < remaining {
        self.out_pos += count
        return false
      }
      w.out.clear()
      self.out_pos = 0
    }
    match self.phase {
      Idle => return true
      StoredHeader(end) => {
        let n = end - self.cursor
        w.write_bits(self.emitted_final.to_int(), 3)
        w.flush()
        w.write_byte(n.to_byte())
        w.write_byte((n >> 8).to_byte())
        w.write_byte((n ^ 0xFFFF).to_byte())
        w.write_byte(((n ^ 0xFFFF) >> 8).to_byte())
        self.phase = StoredPayload(end)
      }
      StoredPayload(end) => {
        let count = (end - self.cursor).min(output.length() - w.direct_pos)
        self.copy_stored(output, w.direct_pos, count)
        w.direct_pos += count
        if self.cursor < end {
          return false
        }
        self.phase = Idle
      }
      FixedHeader => {
        w.write_bits(2 | self.emitted_final.to_int(), 3)
        self.cursor = 0
        self.phase = Tokens(None)
      }
      DynamicHeader(codes) => {
        w.write_bits(4 | self.emitted_final.to_int(), 3)
        w.write_bits(codes.lengths.hlit - 257, 5)
        w.write_bits(codes.lengths.hdist - 1, 5)
        w.write_bits(codes.lengths.hclen - 4, 4)
        self.cursor = 0
        self.phase = CodeLengths(codes)
      }
      CodeLengths(codes) => {
        w.write_bits(codes.lengths.codelen_code_len[code_order[self.cursor]], 3)
        self.cursor += 1
        if self.cursor == codes.lengths.hclen {
          self.cursor = 0
          self.phase = CodeSymbols(codes)
        }
      }
      CodeSymbols(codes) => {
        let it = codes.lengths.codelen_syms[self.cursor]
        w.write_rcode(
          codes.codelen_code_val[it.sym],
          codes.lengths.codelen_code_len[it.sym],
        )
        w.write_bits(it.extra, it.nextra)
        self.cursor += 1
        if self.cursor == codes.lengths.codelen_syms.length() {
          self.cursor = 0
          self.phase = Tokens(Some(codes))
        }
      }
      Tokens(codes) => {
        w.direct_pos = self.resume_token_prefix(codes, output, w.direct_pos)
        if self.phase is Tokens(_) {
          return false
        }
      }
      EndBlock(codes) => {
        if codes is Some(c) {
          w.write_rcode(c.dll_val[256], c.lengths.dll_len[256])
        } else {
          w.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
        }
        if self.emitted_final {
          w.flush()
        }
        self.phase = Idle
      }
    }
  }
}
