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
// Only whole bytes from the current header field, token, or EOB can spill.
// A match emits at most floor((7 pending + 48 token bits) / 8) = 6 bytes;
// a byte-aligned stored header including LEN/NLEN also emits at most six.
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
        // A batch fitting even the longest matches needs no capacity checks at
        // token boundaries. With less room finish just one bounded token.
        let count = (self.tokens.length() - self.cursor).min(
          ((output.length() - w.direct_pos) / 6).max(1),
        )
        if count > 0 {
          let batch = self.tokens[self.cursor:self.cursor + count]
          if codes is Some(c) {
            w.write_tokens(
              batch,
              c.dll_val,
              c.lengths.dll_len,
              c.dd_val,
              c.lengths.dd_len,
            )
          } else {
            w.write_tokens(
              batch, fixed_ll_val, fixed_ll_len, fixed_dist_val, fixed_dist_len,
            )
          }
          self.cursor += count
        }
        if self.cursor == self.tokens.length() {
          self.phase = EndBlock(codes)
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
