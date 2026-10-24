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
let encoder_block_overhead_bits = 10

///|
let encoder_window_size_shift : Int32 = 10

///|
let encoder_window_size : Int32 = 1 << encoder_window_size_shift

///|
let encoder_window_mask : Int32 = encoder_window_size - 1

///|
let encoder_max_match_len = 64

///|
let encoder_min_match_len = 3

///|
let encoder_hash_bits : Int32 = encoder_window_size_shift + 2

///|
let encoder_hash_size : Int32 = 1 << encoder_hash_bits

///|
let encoder_hash_mask : Int32 = encoder_hash_size - 1

///|
let encoder_hash_shift : Int32 = (encoder_hash_bits + encoder_min_match_len - 1) /
  encoder_min_match_len

///|
let encoder_hash_chain_length : Int32 = 8

///|
struct Encoder {
  header : Header
  trailer_state : TrailerState
  mut bit_buffer : UInt32
  mut bit_count : Int32
  mut finished : Bool
  mut started : Bool
  history : FixedArray[Byte]
  hash_heads : FixedArray[Int64]
  hash_prev : FixedArray[Int64]
  mut hash_value : Int32
  mut history_offset : Int64
  mut history_pos : Int32
  mut history_len : Int32
}

///|
/// Create an encoder state machine.
/// The gzip header is written by the first successful `write` or `end` call.
#alias(new, deprecated)
pub fn Encoder::Encoder(
  mtime~ : UInt32 = 0U,
  extra_flags~ : Byte = b'\x00',
  operating_system~ : Byte = b'\xff',
) -> Encoder {
  {
    header: Header::new(mtime~, extra_flags~, operating_system~),
    trailer_state: TrailerState::new(),
    bit_buffer: 0U,
    bit_count: 0,
    finished: false,
    started: false,
    history: FixedArray::make(encoder_window_size, b'\x00'),
    hash_heads: FixedArray::make(encoder_hash_size, -1L),
    hash_prev: FixedArray::make(encoder_window_size, -1L),
    hash_value: 0,
    history_offset: 0L,
    history_pos: 0,
    history_len: 0,
  }
}

///|
fn hash_sequence(first : Byte, second : Byte, third : Byte) -> Int32 {
  (
    (
      ((first.to_int() << encoder_hash_shift) ^ second.to_int()) <<
      encoder_hash_shift
    ) ^
    third.to_int()
  ) &
  encoder_hash_mask
}

///|
fn fixed_literal_code(symbol : Int32) -> (UInt32, Int32) {
  if symbol <= 143 {
    (reverse_bits(symbol + 0x30, 8).reinterpret_as_uint(), 8)
  } else if symbol <= 255 {
    (reverse_bits(symbol - 144 + 0x190, 9).reinterpret_as_uint(), 9)
  } else if symbol <= 279 {
    (reverse_bits(symbol - 256, 7).reinterpret_as_uint(), 7)
  } else {
    (reverse_bits(symbol - 280 + 0xc0, 8).reinterpret_as_uint(), 8)
  }
}

///|
fn Encoder::push_byte(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  byte : Byte,
) -> Int32 {
  ignore(self)
  output[output_offset + produced] = byte
  produced + 1
}

///|
fn Encoder::push_bytes(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  bytes : Bytes,
) -> Int32 {
  ignore(self)
  output.blit_from_bytes(output_offset + produced, bytes, 0, bytes.length())
  produced + bytes.length()
}

///|
fn Encoder::write_bits(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  bits : UInt32,
  count : Int32,
) -> Int32 {
  self.bit_buffer = self.bit_buffer | (bits << self.bit_count)
  self.bit_count += count
  let mut produced = produced
  while self.bit_count >= 8 {
    produced = self.push_byte(
      output,
      output_offset,
      produced,
      (self.bit_buffer & 0xffU).to_byte(),
    )
    self.bit_buffer = self.bit_buffer >> 8
    self.bit_count -= 8
  }
  produced
}

///|
fn Encoder::write_header(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
) -> Int32 {
  let produced = self.push_bytes(
    output,
    output_offset,
    produced,
    self.header.to_bytes(),
  )
  self.started = true
  produced
}

///|
fn Encoder::write_literal(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  literal : Byte,
) -> Int32 {
  let (code, bit_len) = fixed_literal_code(literal.to_int())
  self.write_bits(output, output_offset, produced, code, bit_len)
}

///|
fn Encoder::write_end_of_block(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
) -> Int32 {
  let (code, bit_len) = fixed_literal_code(256)
  self.write_bits(output, output_offset, produced, code, bit_len)
}

///|
fn fixed_distance_code(symbol : Int32) -> (UInt32, Int32) {
  (reverse_bits(symbol, 5).reinterpret_as_uint(), 5)
}

///|
fn find_length_code(length : Int32) -> (Int32, Int32, Int32) {
  for i, base in length_bases {
    let extra_bits = length_extras[i]
    let end = if extra_bits == 0 { base } else { base + (1 << extra_bits) - 1 }
    if length <= end {
      return (257 + i, extra_bits, length - base)
    }
  }
  abort("unreachable")
}

///|
fn find_distance_code(distance : Int32) -> (Int32, Int32, Int32) {
  for i, base in distance_bases {
    let extra_bits = distance_extras[i]
    let end = if extra_bits == 0 { base } else { base + (1 << extra_bits) - 1 }
    if distance <= end {
      return (i, extra_bits, distance - base)
    }
  }
  abort("unreachable")
}

///|
fn Encoder::write_match(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  length : Int32,
  distance : Int32,
) -> Int32 {
  let (length_symbol, length_extra_bits, length_extra) = find_length_code(
    length,
  )
  let (length_code, length_bit_len) = fixed_literal_code(length_symbol)
  let mut produced = self.write_bits(
    output, output_offset, produced, length_code, length_bit_len,
  )
  if length_extra_bits > 0 {
    produced = self.write_bits(
      output,
      output_offset,
      produced,
      length_extra.reinterpret_as_uint(),
      length_extra_bits,
    )
  }
  let (distance_symbol, distance_extra_bits, distance_extra) = find_distance_code(
    distance,
  )
  let (distance_code, distance_bit_len) = fixed_distance_code(distance_symbol)
  produced = self.write_bits(
    output, output_offset, produced, distance_code, distance_bit_len,
  )
  if distance_extra_bits > 0 {
    produced = self.write_bits(
      output,
      output_offset,
      produced,
      distance_extra.reinterpret_as_uint(),
      distance_extra_bits,
    )
  }
  produced
}

///|
fn Encoder::append_history_byte(self : Encoder, byte : Byte) -> Unit {
  self.history.unsafe_set(self.history_pos, byte)
  self.history_pos = (self.history_pos + 1) & encoder_window_mask
  self.history_offset += 1
  self.hash_value = ((self.hash_value << encoder_hash_shift) ^ byte.to_int()) &
    encoder_hash_mask
  if self.history_len < encoder_window_size {
    self.history_len += 1
  }
  if self.history_len >= encoder_min_match_len {
    let start = self.history_offset - encoder_min_match_len.to_int64()
    let previous = self.hash_heads.unsafe_get(self.hash_value)
    let previous_distance = start - previous
    let previous = if previous >= 0L &&
      previous_distance > 0L &&
      previous_distance < encoder_window_size.to_int64() {
      previous
    } else {
      -1L
    }
    self.hash_prev.unsafe_set(start.to_int() & encoder_window_mask, previous)
    self.hash_heads.unsafe_set(self.hash_value, start)
  }
}

///|
fn Encoder::append_history_bytes(
  self : Encoder,
  input : Bytes,
  input_offset : Int32,
  input_len : Int32,
) -> Unit {
  for i in 0..<input_len {
    self.append_history_byte(input[input_offset + i])
  }
}

///|
fn Encoder::match_byte(
  self : Encoder,
  input : Bytes,
  input_offset : Int32,
  pos : Int32,
  distance : Int32,
  matched : Int32,
) -> Byte {
  if matched < distance {
    let history_index = (self.history_pos - distance + matched) &
      encoder_window_mask
    self.history.unsafe_get(history_index)
  } else {
    input[input_offset + pos + matched - distance]
  }
}

///|
fn Encoder::find_match(
  self : Encoder,
  input : Bytes,
  input_offset : Int32,
  input_len : Int32,
  pos : Int32,
) -> (Int32, Int32) {
  let max_distance = @cmp.minimum(self.history_len, encoder_window_size)
  let max_match_len = @cmp.minimum(input_len - pos, encoder_max_match_len)
  if max_distance <= 0 || max_match_len < encoder_min_match_len {
    return (0, 0)
  }
  let hash = hash_sequence(
    input[input_offset + pos],
    input[input_offset + pos + 1],
    input[input_offset + pos + 2],
  )
  let mut candidate = self.hash_heads.unsafe_get(hash)
  let mut best_len = 0
  let mut best_distance = 0
  let mut probes = 0
  while candidate >= 0L && probes < encoder_hash_chain_length {
    let distance64 = self.history_offset - candidate
    if distance64 <= 0L || distance64 > max_distance.to_int64() {
      break
    }
    let distance = distance64.to_int()
    let mut matched = 0
    while matched < max_match_len &&
          input[input_offset + pos + matched] ==
          self.match_byte(input, input_offset, pos, distance, matched) {
      matched += 1
    }
    if matched > best_len {
      best_len = matched
      best_distance = distance
      if matched == max_match_len {
        break
      }
    }
    candidate = self.hash_prev.unsafe_get(
      candidate.to_int() & encoder_window_mask,
    )
    probes += 1
  }
  if best_len >= encoder_min_match_len {
    (best_len, best_distance)
  } else {
    (0, 0)
  }
}

///|
fn Encoder::write_fixed_block_header(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  is_final : Bool,
) -> Int32 {
  self.write_bits(
    output,
    output_offset,
    produced,
    if is_final {
      3U
    } else {
      2U
    },
    3,
  )
}

///|
fn Encoder::encode_chunk(
  self : Encoder,
  input : Bytes,
  input_offset : Int32,
  input_len : Int32,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
  is_final : Bool,
) -> Int32 {
  let mut produced = self.write_fixed_block_header(
    output, output_offset, produced, is_final,
  )
  let mut i = 0
  while i < input_len {
    let (match_len, match_distance) = self.find_match(
      input, input_offset, input_len, i,
    )
    if match_len >= encoder_min_match_len {
      produced = self.write_match(
        output, output_offset, produced, match_len, match_distance,
      )
      self.append_history_bytes(input, input_offset + i, match_len)
      i += match_len
    } else {
      produced = self.write_literal(
        output,
        output_offset,
        produced,
        input[input_offset + i],
      )
      self.append_history_byte(input[input_offset + i])
      i += 1
    }
  }
  self.write_end_of_block(output, output_offset, produced)
}

///|
fn Encoder::flush_partial_byte(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset : Int32,
  produced : Int32,
) -> Int32 {
  if self.bit_count > 0 {
    let produced = self.push_byte(
      output,
      output_offset,
      produced,
      (self.bit_buffer & 0xffU).to_byte(),
    )
    self.bit_buffer = 0U
    self.bit_count = 0
    produced
  } else {
    produced
  }
}

///|
/// Return the minimum output space required for the next successful call.
/// `end=true` means the caller wants to terminate the stream now, so this
/// includes the final block and trailer.
pub fn Encoder::minimum_output_space(self : Encoder, end~ : Bool) -> Int32 {
  guard !self.finished else { return 0 }
  let header = if self.started { 0 } else { HEADER_SIZE }
  if end {
    header + (self.bit_count + encoder_block_overhead_bits + 7) / 8 + 8
  } else {
    header + (self.bit_count + 19 + 7) / 8
  }
}

///|
/// Encode plain input into `output`.
/// The caller must provide at least `minimum_output_space(end=false)` bytes of
/// output space, and the input buffer must be non-empty.
/// The result is `(consumed, produced)`,
/// where `consumed` is the number of bytes consumed from the input
/// and `produced` is the number of bytes written to the output.
/// `write` must not be called on a stream where `.end()` is already called.
pub fn Encoder::write(
  self : Encoder,
  input : Bytes,
  output : FixedArray[Byte],
  input_offset~ : Int32 = 0,
  input_len~ : Int32 = input.length() - input_offset,
  output_offset~ : Int32 = 0,
  output_len~ : Int32 = output.length() - output_offset,
) -> (Int32, Int32) {
  guard! !self.finished
  guard input_len > 0 else { return (0, 0) }
  let mut produced = 0
  if !self.started {
    produced = self.write_header(output, output_offset, produced)
  }
  let available_bits = (output_len - produced) * 8 -
    self.bit_count -
    encoder_block_overhead_bits
  let max_len = available_bits / 9
  guard max_len > 0 else { return (0, produced) }
  let consumed = @cmp.minimum(input_len, max_len)
  self.trailer_state.update(input[input_offset:input_offset + consumed])
  produced = self.encode_chunk(
    input, input_offset, consumed, output, output_offset, produced, false,
  )
  (consumed, produced)
}

///|
/// Finish the gzip stream by writing the final block and trailer into `output`.
/// The caller must provide at least `minimum_output_space(end=true)` bytes.
/// Returns the number of bytes written to `output`.
/// The encoder must not be finished (i.e. `.end()` can be called only once).
pub fn Encoder::end(
  self : Encoder,
  output : FixedArray[Byte],
  output_offset~ : Int32 = 0,
  output_len~ : Int32 = output.length() - output_offset,
) -> Int32 {
  guard !self.finished else { return 0 }
  let mut produced = 0
  let trailer = self.trailer_state.snapshot()
  guard! self.minimum_output_space(end=true) <= output_len
  if !self.started {
    produced = self.write_header(output, output_offset, produced)
  }
  produced = self.encode_chunk(b"", 0, 0, output, output_offset, produced, true)
  produced = self.flush_partial_byte(output, output_offset, produced)
  produced = self.push_bytes(
    output,
    output_offset,
    produced,
    Trailer::new(trailer.crc32, trailer.input_size).to_bytes(),
  )
  self.finished = true
  produced
}
