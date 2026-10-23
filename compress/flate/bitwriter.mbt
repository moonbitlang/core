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

// LSB-first bit sink for the encode pipeline. DEFLATE packs bits LSB-first
// into bytes, but Huffman codes are written MSB-first.

///|
priv struct BitWriter {
  out : Array[Byte]
  mut bitbuf : Int32
  mut bit_count : Int32 // bits currently held in `bitbuf`, not yet flushed to a byte
  mut direct_output : FixedArray[Byte]?
  growable : Bool
  mut direct_pos : Int32
  mut overflowed : Bool
}

///|
fn BitWriter::BitWriter() -> BitWriter {
  {
    out: [],
    bitbuf: 0,
    bit_count: 0,
    direct_output: None,
    direct_pos: 0,
    growable: false,
    overflowed: false,
  }
}

///|
/// Create a bit writer that emits directly into `output`. Writes past its end
/// are recorded so the caller can report capacity exhaustion after encoding.
fn BitWriter::into(output : FixedArray[Byte]) -> BitWriter {
  {
    out: [],
    bitbuf: 0,
    bit_count: 0,
    direct_output: Some(output),
    direct_pos: 0,
    growable: false,
    overflowed: false,
  }
}

///|
/// Reusable, geometrically growing output for complete in-memory streams.
/// Unlike the caller-owned fixed buffer this can expand without recompressing.
fn BitWriter::growing(output : FixedArray[Byte]) -> BitWriter {
  { ..BitWriter::into(output), growable: true, }
}

///|
/// Keep capacity arithmetic separate so Int-boundary growth can be checked
/// without allocating gigabyte-sized buffers.
fn bitwriter_growth_capacity(current : Int32, required : Int32) -> Int32 {
  let doubled = if current <= 0x3fff_ffff { current * 2 } else { required }
  required.max(doubled).max(64)
}

///|
/// Counts are non-negative. Reject an unrepresentable growing result before
/// adding, just as deflate_bound rejects an unrepresentable output capacity.
fn bitwriter_output_length(written : Int32, additional : Int32) -> Int32 {
  guard additional <= 0x7fff_ffff - written else {
    abort("DEFLATE output capacity overflow")
  }
  written + additional
}

///|
fn BitWriter::grow(
  self : BitWriter,
  output : FixedArray[Byte],
  required : Int32,
) -> FixedArray[Byte] {
  let grown = FixedArray::make_and_blit(
    output,
    allocate_len=bitwriter_growth_capacity(output.length(), required),
    init=b'\x00',
    len=self.direct_pos,
  )
  self.direct_output = Some(grown)
  grown
}

///|
/// Emit one whole byte to the configured destination. The normal writer grows
/// `out`; a fixed writer counts only bytes actually written and latches
/// capacity exhaustion, so continued encoding cannot overflow its cursor.
#inline
fn BitWriter::write_byte(self : BitWriter, byte : Byte) -> Unit {
  if self.direct_output is Some(output) {
    if self.direct_pos < output.length() {
      output[self.direct_pos] = byte
      self.direct_pos += 1
    } else if self.growable {
      let required = bitwriter_output_length(self.direct_pos, 1)
      let grown = self.grow(output, required)
      grown[self.direct_pos] = byte
      self.direct_pos = required
    } else {
      self.overflowed = true
    }
  } else {
    self.out.push(byte)
  }
}

///|
/// Write a byte-aligned payload. Count only the prefix that fits in a fixed
/// buffer, retaining the overflow flag after any earlier exhaustion.
fn BitWriter::write_bytes(
  self : BitWriter,
  input : BytesView,
  offset : Int32,
  length : Int32,
) -> Unit {
  if self.direct_output is Some(output) {
    let output = if self.growable && length > output.length() - self.direct_pos {
      self.grow(output, bitwriter_output_length(self.direct_pos, length))
    } else {
      output
    }
    let count = length.min((output.length() - self.direct_pos).max(0))
    if count > 0 {
      output.blit_from_bytes(
        self.direct_pos,
        input.data(),
        input.start_offset() + offset,
        count,
      )
    }
    self.direct_pos += count
    if count < length {
      self.overflowed = true
    }
  } else {
    append_payload(self.out, input[offset:offset + length])
  }
}

///|
/// Append a byte-aligned payload to the growing array sink. Core has no bulk
/// append of bytes to an array of bytes: stage them in a fixed array, which
/// appends as one block.
#cfg(not(target="js"))
fn append_payload(out : Array[Byte], payload : BytesView) -> Unit {
  let staged = FixedArray::make(payload.length(), b'\x00')
  staged.blit_from_bytesview(0, payload)
  out.append(staged)
}

///|
/// On js the staged block gains little (the array sink itself is the cost:
/// 5 to 7 % at level 0), and once it has run, V8 runs the decoders of the
/// same process 9 to 17 % slower (measured with node 25; they share no code
/// with this function). Keep the byte iterator there.
#cfg(target="js")
fn append_payload(out : Array[Byte], payload : BytesView) -> Unit {
  out.push_iter(payload.iter())
}

///|
/// Write the first `length` bytes of `bytes`, exactly as `length` calls of
/// `write_byte` would: a fixed writer counts only the prefix that fits and
/// records the overflow. Only the 64-bit token writer hands bytes over in bulk.
#cfg(any(target="native", target="wasm"))
fn BitWriter::write_array(
  self : BitWriter,
  bytes : FixedArray[Byte],
  length : Int32,
) -> Unit {
  if self.direct_output is Some(output) {
    let output = if self.growable && length > output.length() - self.direct_pos {
      self.grow(output, bitwriter_output_length(self.direct_pos, length))
    } else {
      output
    }
    let count = length.min((output.length() - self.direct_pos).max(0))
    if count > 0 {
      bytes.blit_to(output, len=count, dst_offset=self.direct_pos)
    }
    self.direct_pos += count
    if count < length {
      self.overflowed = true
    }
  } else {
    self.out.append(bytes[:length])
  }
}

///|
fn BitWriter::write_bit(self : BitWriter, bit : Int32) -> Unit {
  self.bitbuf = self.bitbuf | (bit << self.bit_count)
  self.bit_count = self.bit_count + 1
  if self.bit_count == 8 {
    self.write_byte((self.bitbuf & 0xFF).to_byte())
    self.bitbuf = 0
    self.bit_count = 0
  }
}

///|
/// Write the low `n` bits of `value`, LSB-first. Batched: the bits are shifted
/// into the accumulator in one step and complete bytes flushed whole, instead
/// of looping one bit at a time.
fn BitWriter::write_bits(self : BitWriter, value : Int32, n : Int32) -> Unit {
  self.bitbuf = self.bitbuf | ((value & ((1 << n) - 1)) << self.bit_count)
  self.bit_count = self.bit_count + n
  while self.bit_count >= 8 {
    self.write_byte((self.bitbuf & 0xFF).to_byte())
    self.bitbuf = self.bitbuf >> 8
    self.bit_count = self.bit_count - 8
  }
}

///|
/// Write an already-bit-reversed Huffman code, LSB-first.
fn BitWriter::write_rcode(self : BitWriter, code : UInt32, n : Int32) -> Unit {
  self.write_bits(code.reinterpret_as_int(), n)
}

///|
/// Pad any sub-byte remainder in `bitbuf` out to a whole byte (zero-filling the
/// high bits) and emit it. Required before a byte-aligned stored block and at
/// the very end of a stream
fn BitWriter::flush(self : BitWriter) -> Unit {
  if self.bit_count > 0 {
    self.write_byte((self.bitbuf & 0xFF).to_byte())
    self.bitbuf = 0
    self.bit_count = 0
  }
}
