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
priv enum DecodeMode {
  Header
  Blocks
  DynamicHeader(is_final~ : Bool)
  DynamicCodeLengths(
    is_final~ : Bool,
    hlit~ : Int32,
    hdist~ : Int32,
    hclen~ : Int32,
    index~ : Int32,
    code_lengths~ : FixedArray[Int32]
  )
  DynamicLengths(
    is_final~ : Bool,
    hlit~ : Int32,
    hdist~ : Int32,
    code_tree~ : HuffmanTree,
    index~ : Int32,
    previous~ : Int32,
    lengths~ : FixedArray[Int32]
  )
  StoredLengths(is_final~ : Bool)
  StoredBlock(is_final~ : Bool, remaining~ : Int32)
  HuffmanBlock(
    is_final~ : Bool,
    literal_tree~ : HuffmanTree,
    distance_tree~ : HuffmanTree
  )
  Trailer
  Finished
}

///|
struct Decoder {
  trailer_state : TrailerState
  mut mode : DecodeMode
  mut bit_buffer : UInt32
  mut bit_count : Int32
  mut copy_remaining : Int32
  mut copy_distance : Int32
  mut pending_buf : FixedArray[Byte]
  mut pending_len : Int32
  history : FixedArray[Byte]
  mut history_pos : Int32
  mut history_len : Int32
}

///|
priv struct DecodeInput {
  input : Bytes
  end : Int32
  mut index : Int32
  mut bit_buffer : UInt32
  mut bit_count : Int32
}

///|
fn DecodeInput::new(
  input : Bytes,
  start : Int32,
  end : Int32,
  decoder : Decoder,
) -> DecodeInput {
  {
    input,
    end,
    index: start,
    bit_buffer: decoder.bit_buffer,
    bit_count: decoder.bit_count,
  }
}

///|
fn DecodeInput::commit(self : DecodeInput, decoder : Decoder) -> Unit {
  decoder.bit_buffer = self.bit_buffer
  decoder.bit_count = self.bit_count
}

///|
fn DecodeInput::align_to_byte(self : DecodeInput) -> Unit {
  self.bit_buffer = 0U
  self.bit_count = 0
}

///|
fn DecodeInput::prepare_trailer(self : DecodeInput) -> Unit {
  let discard = self.bit_count & 7
  if discard > 0 {
    self.bit_buffer = self.bit_buffer >> discard
    self.bit_count -= discard
  }
}

///|
/// Create a decoder state machine.
/// The gzip header is consumed by the first successful `write` call.
#alias(new, deprecated)
pub fn Decoder::Decoder() -> Decoder {
  {
    trailer_state: TrailerState::new(),
    mode: Header,
    bit_buffer: 0U,
    bit_count: 0,
    copy_remaining: 0,
    copy_distance: 0,
    pending_buf: [],
    pending_len: 0,
    history: FixedArray::make(32768, b'\x00'),
    history_pos: 0,
    history_len: 0,
  }
}

///|
/// Check if a decoder has already completed
pub fn Decoder::is_finished(self : Decoder) -> Bool {
  self.mode is Finished
}

///|
/// Return the minimum compressed input required for
/// the next `write` call to make any progress.
/// The caller may provide more than this amount.
pub fn Decoder::minimum_input_size(self : Decoder) -> Int32 {
  @cmp.maximum(0, self.raw_minimum_input_size() - self.pending_len)
}

///|
fn Decoder::raw_minimum_input_size(self : Decoder) -> Int32 {
  match self.mode {
    Header => HEADER_SIZE
    DynamicHeader(_) => @cmp.maximum(0, (14 - self.bit_count + 7) / 8)
    DynamicCodeLengths(hclen~, index~, ..) => {
      let remaining = hclen - index
      @cmp.maximum(0, (remaining * 3 - self.bit_count + 7) / 8)
    }
    DynamicLengths(hlit~, hdist~, code_tree~, index~, ..) =>
      if index < hlit + hdist {
        @cmp.maximum(0, (code_tree.max_bits + 7 - self.bit_count + 7) / 8)
      } else {
        0
      }
    StoredLengths(_) => 4
    StoredBlock(remaining~, ..) => if remaining > 0 { 1 } else { 0 }
    HuffmanBlock(..) =>
      if self.copy_remaining != 0 {
        0
      } else {
        self.minimum_huffman_input_size()
      }
    Trailer => @cmp.maximum(0, 8 - self.bit_count / 8)
    Finished => 0
    Blocks => 1
  }
}

///|
fn Decoder::ensure_pending_capacity(self : Decoder, len : Int32) -> Unit {
  guard len > self.pending_buf.length() else { return }
  let new_buf = FixedArray::make(len, b'\x00')
  if self.pending_len > 0 {
    self.pending_buf.blit_to(new_buf, len=self.pending_len)
  }
  self.pending_buf = new_buf
}

///|
fn Decoder::drop_pending(self : Decoder, len : Int32) -> Unit {
  guard len > 0 else { return }
  self.pending_len -= len
  if self.pending_len > 0 {
    self.pending_buf.blit_to(
      self.pending_buf,
      src_offset=len,
      dst_offset=0,
      len=self.pending_len,
    )
  }
}

///|
fn Decoder::copy_to_pending(
  self : Decoder,
  input : Bytes,
  input_offset : Int32,
  len : Int32,
) -> Unit {
  guard len > 0 else { return }
  self.ensure_pending_capacity(self.pending_len + len)
  self.pending_buf.blit_from_bytes(self.pending_len, input, input_offset, len)
  self.pending_len += len
}

///|
/// Buffer compressed input that is smaller than `minimum_input_size()`.
/// `input_len` must be smaller than `minimum_input_size`.
pub fn Decoder::write_partial_data(
  self : Decoder,
  input : Bytes,
  input_offset~ : Int32 = 0,
  input_len~ : Int32 = input.length() - input_offset,
) -> Unit {
  guard! input_len < self.minimum_input_size()
  self.ensure_pending_capacity(self.raw_minimum_input_size())
  self.copy_to_pending(input, input_offset, input_len)
}

///|
fn Decoder::finish_dynamic_header(
  self : Decoder,
  input : DecodeInput,
  is_final~ : Bool,
) -> Unit raise {
  let hlit = input.read_bits(5)
  let hdist = input.read_bits(5)
  let hclen = input.read_bits(4)
  let hlit = hlit.reinterpret_as_int() + 257
  let hdist = hdist.reinterpret_as_int() + 1
  let hclen = hclen.reinterpret_as_int() + 4
  self.mode = DynamicCodeLengths(
    is_final~,
    hlit~,
    hdist~,
    hclen~,
    index=0,
    code_lengths=FixedArray::make(19, 0),
  )
  input.commit(self)
}

///|
fn Decoder::finish_dynamic_code_lengths(
  self : Decoder,
  input : DecodeInput,
  is_final~ : Bool,
  hlit~ : Int32,
  hdist~ : Int32,
  hclen~ : Int32,
  code_lengths : FixedArray[Int32],
  length_index~ : Int32,
) -> Unit raise {
  for i in length_index..<hclen {
    let bits = input.read_bits(3)
    code_lengths[code_length_order[i]] = bits.reinterpret_as_int()
  }
  self.mode = DynamicLengths(
    is_final~,
    hlit~,
    hdist~,
    code_tree=build_huffman_tree(code_lengths),
    index=0,
    previous=0,
    lengths=FixedArray::make(320, 0),
  )
  input.commit(self)
}

///|
fn Decoder::finish_dynamic_trees(
  self : Decoder,
  is_final~ : Bool,
  hlit~ : Int32,
  hdist~ : Int32,
  lengths : FixedArray[Int32],
) -> Unit raise {
  let literal_lengths = FixedArray::make(hlit, 0)
  for i in 0..<hlit {
    literal_lengths[i] = lengths[i]
  }
  guard hlit > 256 && literal_lengths[256] > 0 else {
    raise InvalidBlock("invalid code -- missing end-of-block")
  }
  let distance_lengths = FixedArray::make(hdist, 0)
  for i in 0..<hdist {
    distance_lengths[i] = lengths[hlit + i]
  }
  self.mode = HuffmanBlock(
    is_final~,
    literal_tree=build_huffman_tree(literal_lengths),
    distance_tree=build_huffman_tree(distance_lengths),
  )
}

///|
fn Decoder::decode_dynamic_length_step(
  self : Decoder,
  input : DecodeInput,
  is_final~ : Bool,
  hlit~ : Int32,
  hdist~ : Int32,
  code_tree~ : HuffmanTree,
  lengths : FixedArray[Int32],
  length_index~ : Int32,
  previous~ : Int32,
) -> Unit raise {
  let total = hlit + hdist
  guard length_index < total else {
    self.finish_dynamic_trees(is_final~, hlit~, hdist~, lengths)
    return ()
  }
  let mut length_index = length_index
  let mut previous = previous
  let symbol = input.decode_symbol(code_tree)
  match symbol {
    0..<=15 => {
      lengths[length_index] = symbol
      previous = symbol
      length_index += 1
    }
    16 => {
      guard length_index > 0 else {
        raise InvalidBlock("invalid bit length repeat")
      }
      let bits = input.read_bits(2)
      let repeat = bits.reinterpret_as_int() + 3
      guard length_index + repeat <= total else {
        raise InvalidBlock("invalid bit length repeat")
      }
      for _ in 0..<repeat {
        lengths[length_index] = previous
        length_index += 1
      }
    }
    17 => {
      let bits = input.read_bits(3)
      let repeat = bits.reinterpret_as_int() + 3
      guard length_index + repeat <= total else {
        raise InvalidBlock("invalid bit length repeat")
      }
      for _ in 0..<repeat {
        lengths[length_index] = 0
        length_index += 1
      }
      previous = 0
    }
    18 => {
      let bits = input.read_bits(7)
      let repeat = bits.reinterpret_as_int() + 11
      guard length_index + repeat <= total else {
        raise InvalidBlock("invalid bit length repeat")
      }
      for _ in 0..<repeat {
        lengths[length_index] = 0
        length_index += 1
      }
      previous = 0
    }
    _ => raise InvalidBlock("invalid code lengths set")
  }
  if length_index == total {
    self.finish_dynamic_trees(is_final~, hlit~, hdist~, lengths)
  } else {
    self.mode = DynamicLengths(
      is_final~,
      hlit~,
      hdist~,
      code_tree~,
      index=length_index,
      previous~,
      lengths~,
    )
  }
  input.commit(self)
}

///|
fn Decoder::finish_header(self : Decoder, input : DecodeInput) -> Unit raise {
  ignore(Header::from_bytes(input.input[input.index:input.index + HEADER_SIZE]))
  input.index += HEADER_SIZE
  self.mode = Blocks
}

///|
fn Decoder::available_output(
  output_capacity : Int32,
  produced : Int32,
) -> Int32 {
  output_capacity - produced
}

///|
fn Decoder::minimum_huffman_input_size(self : Decoder) -> Int32 {
  let needed_bits = 48 - self.bit_count
  if needed_bits <= 0 {
    0
  } else {
    (needed_bits + 7) / 8
  }
}

///|
fn Decoder::append_history(self : Decoder, byte : Byte) -> Unit {
  self.history.unsafe_set(self.history_pos, byte)
  self.history_pos = (self.history_pos + 1) & 0x7fff
  if self.history_len < 32768 {
    self.history_len += 1
  }
}

///|
fn Decoder::append_history_bytes(
  self : Decoder,
  src : FixedArray[Byte],
  src_offset : Int32,
  len : Int32,
) -> Unit {
  guard len > 0 else { return }
  let first_len = @cmp.minimum(len, 32768 - self.history_pos)
  // Callers provide a valid source range; `first_len` is capped at the end of
  // the history ring.
  self.history.unsafe_blit(self.history_pos, src, src_offset, first_len)
  if first_len < len {
    self.history.unsafe_blit(0, src, src_offset + first_len, len - first_len)
  }
  self.history_pos = (self.history_pos + len) & 0x7fff
  self.history_len = @cmp.minimum(32768, self.history_len + len)
}

///|
fn Decoder::history_index(self : Decoder, distance : Int32) -> Int32 raise {
  guard distance >= 1 && distance <= self.history_len else {
    raise InvalidBlock("invalid distance too far back")
  }
  let mut index = self.history_pos - distance
  if index < 0 {
    index += 32768
  }
  index
}

///|
fn Decoder::write_output_byte(
  self : Decoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  byte : Byte,
) -> Int32 {
  output.unsafe_set(output_offset + produced, byte)
  self.append_history(byte)
  produced + 1
}

///|
fn Decoder::update_trailer_output(
  self : Decoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  end : Int32,
) -> Unit {
  self.trailer_state.update(
    output.unsafe_reinterpret_as_bytes()[output_offset:output_offset + end],
  )
}

///|
fn Decoder::finish_stored_header(
  self : Decoder,
  input : DecodeInput,
  is_final~ : Bool,
) -> Unit raise {
  let start = input.index
  guard! input.input[start:] is [u16le(len), u16le(nlen), ..]
  guard (len ^ nlen) == 0xffff else {
    raise InvalidBlock("stored block length checksum mismatch")
  }
  if len == 0 {
    if is_final {
      input.prepare_trailer()
      self.mode = Trailer
    } else {
      self.mode = Blocks
    }
  } else {
    self.mode = StoredBlock(is_final~, remaining=len.reinterpret_as_int())
  }
  input.index += 4
  input.commit(self)
}

///|
fn DecodeInput::read_aligned_byte(self : DecodeInput) -> Byte {
  guard (self.bit_count & 7) == 0 else { abort("unreachable") }
  if self.bit_count >= 8 {
    let byte = (self.bit_buffer & 0xffU).to_byte()
    self.bit_buffer = self.bit_buffer >> 8
    self.bit_count -= 8
    byte
  } else {
    let byte = self.input.unsafe_get(self.index)
    self.index += 1
    byte
  }
}

///|
fn DecodeInput::read_aligned_uint32_le(self : DecodeInput) -> UInt32 {
  let b0 = self.read_aligned_byte()
  let b1 = self.read_aligned_byte()
  let b2 = self.read_aligned_byte()
  let b3 = self.read_aligned_byte()
  let value = b0.to_uint() |
    (b1.to_uint() << 8) |
    (b2.to_uint() << 16) |
    (b3.to_uint() << 24)
  value
}

///|
fn Decoder::finish_trailer(self : Decoder, input : DecodeInput) -> Unit raise {
  let crc32 = input.read_aligned_uint32_le()
  let input_size = input.read_aligned_uint32_le()
  let expected = self.trailer_state.snapshot()
  guard crc32 == expected.crc32 else {
    raise InvalidTrailer("gzip trailer CRC32 mismatch")
  }
  guard input_size == expected.input_size else {
    raise InvalidTrailer("gzip trailer input size mismatch")
  }
  self.mode = Finished
  input.commit(self)
}

///|
fn DecodeInput::ensure_bits(self : DecodeInput, count : Int32) -> Bool {
  while self.bit_count < count {
    if self.index >= self.end {
      return false
    }
    self.bit_buffer = self.bit_buffer |
      (self.input.unsafe_get(self.index).to_uint() << self.bit_count)
    self.bit_count += 8
    self.index += 1
  }
  true
}

///|
fn DecodeInput::read_bits(self : DecodeInput, count : Int32) -> UInt32 raise {
  guard self.ensure_bits(count) else {
    raise NeedMoreInput("unexpected EOF in compressed data")
  }
  let mask = if count == 32 { 0xffffffffU } else { (1U << count) - 1U }
  let bits = self.bit_buffer & mask
  self.bit_buffer = self.bit_buffer >> count
  self.bit_count -= count
  bits
}

///|
fn Decoder::start_next_block(self : Decoder, input : DecodeInput) -> Unit raise {
  let header = input.read_bits(3)
  let is_final = (header & 1U) == 1U
  let block_type = (header >> 1).reinterpret_as_int()
  match block_type {
    0 => {
      input.align_to_byte()
      self.mode = StoredLengths(is_final~)
    }
    1 =>
      self.mode = HuffmanBlock(
        is_final~,
        literal_tree=fixed_literal_tree,
        distance_tree=fixed_distance_tree,
      )
    2 => self.mode = DynamicHeader(is_final~)
    _ => raise InvalidBlock("invalid block type")
  }
  input.commit(self)
}

///|
fn Decoder::continue_copy(
  self : Decoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  output_len : Int32,
) -> Int32 raise {
  ignore(self.history_index(self.copy_distance))
  let max_len = @cmp.minimum(
    Decoder::available_output(output_len, produced),
    self.copy_remaining,
  )
  for written = 0; written < max_len && self.copy_remaining > 0; {
    let src_index = self.history_index(self.copy_distance)
    let chunk = @cmp.minimum(
      @cmp.minimum(max_len - written, self.copy_remaining),
      @cmp.minimum(self.copy_distance, 32768 - src_index),
    )
    // `src_index` and `chunk` are capped to the history ring, while the
    // destination is capped to the caller's available output.
    output.unsafe_blit(
      output_offset + produced + written,
      self.history,
      src_index,
      chunk,
    )
    self.append_history_bytes(output, output_offset + produced + written, chunk)
    self.copy_remaining -= chunk
    continue written + chunk
  } nobreak {
    if self.copy_remaining == 0 {
      self.copy_distance = 0
    }
    written
  }
}

///|
fn DecodeInput::decode_symbol(
  self : DecodeInput,
  tree : HuffmanTree,
) -> Int32 raise {
  for ;; {
    let has_more = self.ensure_bits(tree.max_bits)
    let lookup = (self.bit_buffer & ((1U << tree.max_bits) - 1U)).reinterpret_as_int()
    // `table` has exactly `1 << max_bits` entries and `lookup` is masked to
    // that range.
    let packed = tree.table.unsafe_get(lookup)
    let bit_len = packed & 0x1f
    if bit_len > 0 && bit_len <= self.bit_count {
      self.bit_buffer = self.bit_buffer >> bit_len
      self.bit_count -= bit_len
      return packed >> 5
    }
    guard self.bit_count < tree.max_bits else {
      raise InvalidBlock("invalid huffman code")
    }
    if !has_more {
      raise NeedMoreInput("unexpected EOF in huffman block")
    }
  }
}

///|
fn DecodeInput::read_length(self : DecodeInput, symbol : Int32) -> Int32 raise {
  let index = symbol - 257
  guard index >= 0 && index < length_bases.length() else {
    raise InvalidBlock("invalid literal/length code")
  }
  // The range guard above covers both parallel length tables.
  let extra_bits = length_extras.unsafe_get(index)
  if extra_bits == 0 {
    length_bases.unsafe_get(index)
  } else {
    let extra = self.read_bits(extra_bits)
    length_bases.unsafe_get(index) + extra.reinterpret_as_int()
  }
}

///|
fn DecodeInput::read_distance(
  self : DecodeInput,
  symbol : Int32,
) -> Int32 raise {
  guard symbol >= 0 && symbol < distance_bases.length() else {
    raise InvalidBlock("invalid distance code")
  }
  // The range guard above covers both parallel distance tables.
  let extra_bits = distance_extras.unsafe_get(symbol)
  if extra_bits == 0 {
    distance_bases.unsafe_get(symbol)
  } else {
    let extra = self.read_bits(extra_bits)
    distance_bases.unsafe_get(symbol) + extra.reinterpret_as_int()
  }
}

///|
fn Decoder::decode_huffman_step(
  self : Decoder,
  input : DecodeInput,
  is_final~ : Bool,
  literal_tree~ : HuffmanTree,
  distance_tree~ : HuffmanTree,
) -> Unit raise {
  let symbol = input.decode_symbol(literal_tree)
  match symbol {
    0..<=255 => {
      self.copy_remaining = -symbol - 1
      self.copy_distance = 0
      input.commit(self)
    }
    256 => {
      if is_final {
        input.prepare_trailer()
        self.mode = Trailer
      } else {
        self.mode = Blocks
      }
      input.commit(self)
    }
    _ => {
      let length = input.read_length(symbol)
      let distance_symbol = input.decode_symbol(distance_tree)
      let distance = input.read_distance(distance_symbol)
      self.copy_remaining = length
      self.copy_distance = distance
      input.commit(self)
    }
  }
}

///|
fn Decoder::read_stored_from_input(
  self : Decoder,
  input : DecodeInput,
  is_final~ : Bool,
  remaining~ : Int32,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  output_len : Int32,
) -> Int32 {
  let len = @cmp.minimum(
    @cmp.minimum(Decoder::available_output(output_len, produced), remaining),
    input.end - input.index,
  )
  guard len > 0 else { return 0 }
  output.blit_from_bytes(
    output_offset + produced,
    input.input,
    input.index,
    len,
  )
  self.append_history_bytes(output, output_offset + produced, len)
  let remaining = remaining - len
  if remaining == 0 {
    if is_final {
      input.prepare_trailer()
      self.mode = Trailer
    } else {
      self.mode = Blocks
    }
  } else {
    self.mode = StoredBlock(is_final~, remaining~)
  }
  input.index += len
  len
}

///|
/// Decode compressed input into `output`.
/// The caller must provide at least `minimum_input_size()` bytes of input and a
/// non-empty output buffer. The result is `(consumed, produced)`,
/// where `consumed` is the number of bytes consumed from the input
/// and `produced` is the number of bytes written to the output.
/// `produced == 0` is allowed: it means the call only advanced decoder state,
/// for example by reading a block header, stored lengths, or the trailer.
/// EOF should be checked explicitly via `is_finished`.
fn Decoder::write_direct(
  self : Decoder,
  input : Bytes,
  output : FixedArray[Byte],
  input_offset~ : Int32 = 0,
  input_len~ : Int32 = input.length() - input_offset,
  output_offset~ : Int32 = 0,
  output_len~ : Int32 = output.length() - output_offset,
) -> (Int32, Int32) raise {
  let input_state = DecodeInput::new(
    input,
    input_offset,
    input_offset + input_len,
    self,
  )
  let mut produced = 0
  for ;; {
    if Decoder::available_output(output_len, produced) == 0 {
      break
    }
    match self.mode {
      Header => {
        if input_state.end - input_state.index < self.raw_minimum_input_size() {
          break
        }
        self.finish_header(input_state)
        if self.mode is Header || input_state.index >= input_state.end {
          break
        }
      }
      DynamicHeader(is_final~) => {
        if input_state.end - input_state.index < self.raw_minimum_input_size() {
          break
        }
        self.finish_dynamic_header(input_state, is_final~)
        if self.mode is DynamicHeader(_) || input_state.index >= input_state.end {
          break
        }
      }
      DynamicCodeLengths(
        is_final~,
        hlit~,
        hdist~,
        hclen~,
        index=length_index,
        code_lengths~
      ) => {
        if input_state.end - input_state.index < self.raw_minimum_input_size() {
          break
        }
        self.finish_dynamic_code_lengths(
          input_state,
          is_final~,
          hlit~,
          hdist~,
          hclen~,
          code_lengths,
          length_index~,
        )
        if self.mode is DynamicCodeLengths(..) ||
          input_state.index >= input_state.end {
          break
        }
      }
      DynamicLengths(
        is_final~,
        hlit~,
        hdist~,
        code_tree~,
        index=length_index,
        previous~,
        lengths~
      ) => {
        let index = input_state.index
        self.decode_dynamic_length_step(
          input_state,
          is_final~,
          hlit~,
          hdist~,
          code_tree~,
          lengths,
          length_index~,
          previous~,
        ) catch {
          NeedMoreInput(_) => {
            input_state.index = index
            break
          }
          err => raise err
        }
        if self.mode is DynamicLengths(..) ||
          input_state.index >= input_state.end {
          break
        }
      }
      StoredLengths(is_final~) => {
        if input_state.end - input_state.index < self.raw_minimum_input_size() {
          break
        }
        self.finish_stored_header(input_state, is_final~)
        if self.mode is StoredLengths(_) || input_state.index >= input_state.end {
          break
        }
      }
      StoredBlock(is_final~, remaining~) => {
        let index = input_state.index
        let written = self.read_stored_from_input(
          input_state,
          is_final~,
          remaining~,
          output,
          output_offset,
          produced,
          output_len,
        )
        if written == 0 && input_state.index == index {
          break
        }
        produced += written
        continue
      }
      HuffmanBlock(is_final~, literal_tree~, distance_tree~) => {
        if self.copy_remaining > 0 {
          let written = self.continue_copy(
            output, output_offset, produced, output_len,
          )
          if written == 0 {
            break
          }
          produced += written
          continue
        }
        if self.copy_remaining < 0 {
          produced = self.write_output_byte(
            output,
            output_offset,
            produced,
            (-self.copy_remaining - 1).to_byte(),
          )
          self.copy_remaining = 0
          continue
        }
        let index = input_state.index
        self.decode_huffman_step(
          input_state,
          is_final~,
          literal_tree~,
          distance_tree~,
        ) catch {
          NeedMoreInput(_) => {
            input_state.index = index
            break
          }
          err => raise err
        }
      }
      Trailer => {
        if input_state.end - input_state.index < self.raw_minimum_input_size() {
          break
        }
        if produced > 0 {
          self.update_trailer_output(output, output_offset, produced)
        }
        self.finish_trailer(input_state)
        return (input_state.index - input_offset, produced)
      }
      Finished => break
      Blocks => {
        if input_state.index >= input_state.end {
          break
        }
        self.start_next_block(input_state)
      }
    }
  }
  if produced > 0 {
    self.update_trailer_output(output, output_offset, produced)
  }
  (input_state.index - input_offset, produced)
}

///|
/// Decode compressed input into `output`.
/// The caller must provide at least `minimum_input_size()` bytes of input and a
/// non-empty output buffer. The result is `(consumed, produced)`,
/// where `consumed` is the number of bytes consumed from the input
/// and `produced` is the number of bytes written to the output.
/// `produced == 0` is allowed: it means the call only advanced decoder state,
/// for example by reading a block header, stored lengths, or the trailer.
/// EOF should be checked explicitly via `is_finished`.
pub fn Decoder::write(
  self : Decoder,
  input : Bytes,
  output : FixedArray[Byte],
  input_offset~ : Int32 = 0,
  input_len~ : Int32 = input.length() - input_offset,
  output_offset~ : Int32 = 0,
  output_len~ : Int32 = output.length() - output_offset,
) -> (Int32, Int32) raise {
  guard! input_offset >= 0 && input_offset <= input.length()
  guard! input_len >= 0 && input_len <= input.length() - input_offset
  guard! output_offset >= 0 && output_offset <= output.length()
  guard! output_len >= 0 && output_len <= output.length() - output_offset
  if self.pending_len == 0 {
    return self.write_direct(
      input,
      output,
      input_offset~,
      input_len~,
      output_offset~,
      output_len~,
    )
  }
  let mut copied = 0
  let mut remaining_input_len = input_len
  let mut produced = 0
  let mut old_pending_len = self.pending_len

  while old_pending_len > 0 && produced < output_len {
    let needed = self.raw_minimum_input_size()
    let copied_now = @cmp.minimum(
      @cmp.maximum(0, needed - self.pending_len),
      remaining_input_len,
    )
    if copied_now > 0 {
      self.copy_to_pending(input, input_offset + copied, copied_now)
      copied += copied_now
      remaining_input_len -= copied_now
    }
    let (pending_consumed, pending_produced) = self.write_direct(
      self.pending_buf.unsafe_reinterpret_as_bytes(),
      output,
      input_offset=0,
      input_len=self.pending_len,
      output_offset=output_offset + produced,
      output_len=output_len - produced,
    )
    if pending_consumed == 0 && pending_produced == 0 {
      break
    }
    self.drop_pending(pending_consumed)
    old_pending_len = @cmp.maximum(0, old_pending_len - pending_consumed)
    produced += pending_produced
  }

  if old_pending_len > 0 || produced == output_len {
    return (copied, produced)
  }
  let consumed = copied - self.pending_len
  self.pending_len = 0

  let (direct_consumed, direct_produced) = self.write_direct(
    input,
    output,
    input_offset=input_offset + consumed,
    input_len=input_len - consumed,
    output_offset=output_offset + produced,
    output_len=output_len - produced,
  )
  (consumed + direct_consumed, produced + direct_produced)
}
