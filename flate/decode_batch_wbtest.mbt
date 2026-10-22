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
test "reused primary workspace resets deep complete sparse invalid and empty trees" {
  let reused = HuffmanDecoder()
  let deep = FixedArray::make(286, 0)
  for i in 0..<14 {
    deep[i] = i + 1
  }
  deep[256] = 15
  deep[284] = 15
  for
    lengths in [
      deep,
      fixed_ll_len,
      [1],
      [],
      deep,
      [1, 1, 1],
      [2, 2],
      fixed_ll_len,
      [0, 1],
      [],
    ] {
    let fresh = HuffmanDecoder()
    let expected = fresh.initialize_litlen(lengths)
    @test.assert_eq(reused.initialize_litlen(lengths), expected)
    for i in 0..<512 {
      @test.assert_eq(reused.chunks[i], fresh.chunks[i])
    }
    @test.assert_eq(reused.min, fresh.min)
    @test.assert_eq(reused.link_mask, fresh.link_mask)
    @test.assert_eq(reused.links.length(), fresh.links.length())
    for i in 0..<fresh.links.length() {
      @test.assert_eq(reused.links[i], fresh.links[i])
    }
  }
}

///|
#cfg(target="native")
let packed_fixed_huffman_decoder : HuffmanDecoder = {
  let huffman = HuffmanDecoder()
  ignore(huffman.initialize_data(fixed_ll_len, LiteralLength))
  huffman
}

///|
#cfg(target="native")
test "batch handles the maximum forty-eight-bit token" {
  let lengths = FixedArray::make(286, 0)
  let distance_lengths = FixedArray::make(30, 0)
  for i in 0..<14 {
    lengths[i] = i + 1
    distance_lengths[i] = i + 1
  }
  lengths[256] = 15
  lengths[284] = 15
  distance_lengths[28] = 15
  distance_lengths[29] = 15
  let literals = HuffmanDecoder()
  let distances = HuffmanDecoder()
  @test.assert_eq(literals.initialize_data(lengths, LiteralLength), true)
  @test.assert_eq(distances.initialize_data(distance_lengths, Distance), true)
  for alignment in 0..<8 {
    let writer = BitWriter()
    writer.write_bits(0, alignment)
    for _ in 0..<4 {
      writer.write_rcode(reverse_bits(32767, 15), 15)
      writer.write_bits(30, 5) // length 257
      writer.write_rcode(reverse_bits(32767, 15), 15)
      writer.write_bits(8191, 13) // distance 32768
    }
    writer.write_rcode(reverse_bits(32766, 15), 15) // EOB
    for _ in 0..<16 {
      writer.write_bits(0x55, 8)
    }
    let storage = FixedArray::make(32768 + 4 * 257 + 258, b'\xA5')
    let history = Bytes::makei(32768, i => (i * 73 + i / 19).to_byte())
    storage.blit_from_bytes(0, history, 0, history.length())
    let decoder = MemDecoder(coverage_finish_bits(writer), () => false)
    ignore(decoder.read_bits(alignment))
    decoder.out = DecodeOutput::into(storage)
    decoder.out.length = history.length()
    decoder.next_cancel = storage.length() + 1
    @test.assert_eq(decoder.decode_batch(literals, Some(distances)), true)
    @test.assert_eq(decoder.out.length, 32768 + 4 * 257)
    @test.assert_eq(decoder.read_bits(8), 0x55)
    for i in 0..<(4 * 257) {
      @test.assert_eq(storage[32768 + i], history[i])
    }
    for i in decoder.out.length..<storage.length() {
      @test.assert_eq(storage[i], b'\xA5')
    }
  }
}

///|
#cfg(target="native")
test "batch and checked tails preserve literal capacity and cancellation boundaries" {
  let distances = HuffmanDecoder()
  @test.assert_eq(
    distances.initialize_data(FixedArray::make(32, 5), Distance),
    true,
  )
  let writer = BitWriter()
  for _ in 0..<600 {
    writer.write_rcode(fixed_ll_val[65], fixed_ll_len[65])
  }
  writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
  for _ in 0..<16 {
    writer.write_bits(0x55, 8)
  }
  let input = coverage_finish_bits(writer)
  for capacity in [599, 600, 601, 858] {
    for checkpoint in [1, 257, 258, 259, 599, 600, 601] {
      let mut calls = 0
      let decoder = MemDecoder(input, () => {
        calls += 1
        true
      })
      let storage = FixedArray::make(capacity, b'\xA5')
      decoder.out = DecodeOutput::into(storage)
      decoder.next_cancel = checkpoint
      if checkpoint <= capacity && checkpoint <= 600 {
        let error = @test.expect_error(() => {
          decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
        })
        guard error is InflateError(kind, _)
        @test.assert_eq(kind, Cancelled)
        @test.assert_eq(calls, 1)
        @test.assert_eq(decoder.out.length, checkpoint)
      } else if capacity < 600 {
        let error = @test.expect_error(() => {
          decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
        })
        guard error is InflateError(kind, _)
        @test.assert_eq(kind, OutputLimitExceeded)
        @test.assert_eq(calls, 0)
        @test.assert_eq(decoder.out.length, capacity)
      } else {
        decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
        @test.assert_eq(calls, 0)
        @test.assert_eq(decoder.out.length, 600)
        @test.assert_eq(decoder.read_bits(8), 0x55)
      }
      for i in 0..<decoder.out.length {
        @test.assert_eq(storage[i], b'A')
      }
      for i in decoder.out.length..<capacity {
        @test.assert_eq(storage[i], b'\xA5')
      }
    }
  }
}

///|
#cfg(target="native")
test "maximum matches preserve four-token reservation cancellation boundaries" {
  let distances = HuffmanDecoder()
  @test.assert_eq(
    distances.initialize_data(FixedArray::make(32, 5), Distance),
    true,
  )
  for alignment in 0..<8 {
    for padding in [16, 32] {
      let writer = BitWriter()
      writer.write_bits(0, alignment)
      for _ in 0..<5 {
        writer.write_rcode(fixed_ll_val[285], fixed_ll_len[285])
        writer.write_bits(fixed_distance_symbol(0), 5)
      }
      writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
      for _ in 0..<padding {
        writer.write_bits(0x55, 8)
      }
      let input = coverage_finish_bits(writer)
      for checkpoint in [1032, 1033, 1034, 1291, 1292] {
        let mut calls = 0
        let decoder = MemDecoder(input, () => {
          calls += 1
          true
        })
        ignore(decoder.read_bits(alignment))
        let storage = FixedArray::make(1549, b'\xA5')
        storage[0] = b'A'
        decoder.out = DecodeOutput::into(storage)
        decoder.out.length = 1
        decoder.next_cancel = checkpoint
        if checkpoint <= 1291 {
          let error = @test.expect_error(() => {
            decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
          })
          guard error is InflateError(kind, _)
          @test.assert_eq(kind, Cancelled)
          @test.assert_eq(calls, 1)
          @test.assert_eq(decoder.out.length, checkpoint)
        } else {
          decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
          @test.assert_eq(decoder.out.length, 1291)
          @test.assert_eq(calls, 0)
          @test.assert_eq(decoder.read_bits(8), 0x55)
        }
        for i in 0..<decoder.out.length {
          @test.assert_eq(storage[i], b'A')
        }
        for i in decoder.out.length..<storage.length() {
          @test.assert_eq(storage[i], b'\xA5')
        }
      }
    }
  }
}

///|
#cfg(target="native")
test "batch matches preserve overlap and unread bits across alignments" {
  let distances = HuffmanDecoder()
  @test.assert_eq(
    distances.initialize_data(FixedArray::make(32, 5), Distance),
    true,
  )
  for
    distance in [
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 257, 32768,
    ] {
    let history = Bytes::makei(distance, i => (i * 73 + i / 19).to_byte())
    for length in 3..<=258 {
      for alignment in 0..<8 {
        let writer = BitWriter()
        writer.write_bits(0, alignment)
        let code = 257 + len_to_idx[length]
        writer.write_rcode(fixed_ll_val[code], fixed_ll_len[code])
        let info = length_code_info_table[code - 257]
        writer.write_bits(length - (info >> 3), info & 7)
        let symbol = dist_index(distance)
        writer.write_bits(fixed_distance_symbol(symbol), 5)
        let info = distance_code_info_table[symbol]
        writer.write_bits(distance - (info >> 4), info & 15)
        writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
        for _ in 0..<16 {
          writer.write_bits(0x55, 8)
        }
        let decoder = MemDecoder(coverage_finish_bits(writer), () => false)
        ignore(decoder.read_bits(alignment))
        let storage = FixedArray::makei(distance + length + 258, i => {
          (i * 37 + 19).to_byte()
        })
        storage.blit_from_bytes(0, history, 0, distance)
        decoder.out = DecodeOutput::into(storage)
        decoder.out.length = distance
        decoder.next_cancel = storage.length() + 1
        @test.assert_eq(
          decoder.decode_batch(packed_fixed_huffman_decoder, Some(distances)),
          true,
        )
        @test.assert_eq(decoder.out.length, distance + length)
        @test.assert_eq(decoder.read_bits(8), 0x55)
        for i in 0..<length {
          @test.assert_eq(storage[distance + i], history[i % distance])
        }
        for i in (distance + length)..<storage.length() {
          @test.assert_eq(storage[i], (i * 37 + 19).to_byte())
        }
      }
    }
  }
}

///|
#cfg(target="native")
test "batch refill preserves exact input position across checked tails" {
  let distances = HuffmanDecoder()
  @test.assert_eq(
    distances.initialize_data(FixedArray::make(32, 5), Distance),
    true,
  )
  for size in [32, 33, 63, 64, 65, 127] {
    let expected = Bytes::makei(size, i => (i * 73 + i / 5).to_byte())
    for alignment in 0..<8 {
      for padding in 0..<=8 {
        let writer = BitWriter()
        writer.write_bits(0, alignment)
        let mut consumed = alignment
        for byte in expected {
          let symbol = byte.to_int()
          writer.write_rcode(fixed_ll_val[symbol], fixed_ll_len[symbol])
          consumed += fixed_ll_len[symbol]
        }
        writer.write_rcode(fixed_ll_val[256], fixed_ll_len[256])
        consumed += fixed_ll_len[256]
        for i in 0..<padding {
          writer.write_bits((i * 71 + 173) & 255, 8)
        }
        let input = coverage_finish_bits(writer)
        for prefetch in [0, 8, 16, 24] {
          let decoder = MemDecoder(input, () => false)
          ignore(decoder.read_bits(alignment))
          decoder.need(prefetch)
          let storage = FixedArray::make(size + 258, b'\xA5')
          decoder.out = DecodeOutput::into(storage)
          decoder.next_cancel = storage.length() + 1
          decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
          @test.assert_eq(decoder.out.length, size)
          @test.assert_eq(decoder.pos * 8 - decoder.bit_count, consumed)
          for i in 0..<size {
            @test.assert_eq(storage[i], expected[i])
          }
          for i in size..<storage.length() {
            @test.assert_eq(storage[i], b'\xA5')
          }
          for i in 0..<padding {
            @test.assert_eq(decoder.read_bits(8), (i * 71 + 173) & 255)
          }
        }
      }
    }
  }
}

///|
#cfg(target="native")
test "peeled literal remains committed before an invalid token" {
  let distances = HuffmanDecoder()
  @test.assert_eq(
    distances.initialize_data(FixedArray::make(32, 5), Distance),
    true,
  )
  for
    (code, distance_symbol) in [
      (286, 0),
      (287, 0),
      (257, 30),
      (257, 31),
      (257, 1),
    ] {
    let writer = BitWriter()
    writer.write_rcode(fixed_ll_val[65], fixed_ll_len[65])
    writer.write_rcode(fixed_ll_val[code], fixed_ll_len[code])
    writer.write_bits(fixed_distance_symbol(distance_symbol), 5)
    for _ in 0..<16 {
      writer.write_bits(0, 8)
    }
    let decoder = MemDecoder(coverage_finish_bits(writer), () => false)
    let storage = FixedArray::make(512, b'\xA5')
    decoder.out = DecodeOutput::into(storage)
    decoder.next_cancel = 4096
    @test.assert_eq(
      decoder.decode_batch(packed_fixed_huffman_decoder, Some(distances)),
      false,
    )
    @test.assert_eq(decoder.pos * 8 - decoder.bit_count, fixed_ll_len[65])
    @test.assert_eq(decoder.out.length, 1)
    @test.assert_eq(storage[0], b'A')
    for i in 1..<storage.length() {
      @test.assert_eq(storage[i], b'\xA5')
    }
    let error = @test.expect_error(() => {
      decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
    })
    guard error is InflateError(kind, _)
    @test.assert_eq(kind, Corrupt)
  }
}

///|
#cfg(target="native")
test "batch invalid tokens fall back without consuming the token" {
  let distances = HuffmanDecoder()
  @test.assert_eq(
    distances.initialize_data(FixedArray::make(32, 5), Distance),
    true,
  )
  for
    (code, distance_symbol) in [
      (286, 0),
      (287, 0),
      (257, 30),
      (257, 31),
      (257, 1),
    ] {
    let writer = BitWriter()
    writer.write_rcode(fixed_ll_val[code], fixed_ll_len[code])
    writer.write_bits(fixed_distance_symbol(distance_symbol), 5)
    for _ in 0..<16 {
      writer.write_bits(0, 8)
    }
    let input = coverage_finish_bits(writer)
    let decoder = MemDecoder(input, () => false)
    let storage = FixedArray::make(512, b'\xA5')
    decoder.out = DecodeOutput::into(storage)
    decoder.out.length = 1
    decoder.next_cancel = 4096
    @test.assert_eq(
      decoder.decode_batch(packed_fixed_huffman_decoder, Some(distances)),
      false,
    )
    @test.assert_eq(decoder.pos, 0)
    @test.assert_eq(decoder.bit_count, 0)
    @test.assert_eq(decoder.out.length, 1)
    for byte in storage {
      @test.assert_eq(byte, b'\xA5')
    }
    let error = @test.expect_error(() => {
      decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
    })
    guard error is InflateError(kind, _)
    @test.assert_eq(kind, Corrupt)
  }
}

///|
#cfg(target="native")
test "prefetched invalid tokens preserve the preceding match" {
  let distances = HuffmanDecoder()
  @test.assert_eq(distances.initialize_distance(FixedArray::make(32, 5)), true)
  for
    (code, distance_symbol) in [
      (286, 0),
      (287, 0),
      (257, 30),
      (257, 31),
      (257, 5),
    ] {
    let writer = BitWriter()
    writer.write_rcode(fixed_ll_val[257], fixed_ll_len[257])
    writer.write_bits(0, 5)
    writer.write_rcode(fixed_ll_val[code], fixed_ll_len[code])
    writer.write_bits(fixed_distance_symbol(distance_symbol), 5)
    for _ in 0..<16 {
      writer.write_bits(0, 8)
    }
    let decoder = MemDecoder(coverage_finish_bits(writer), () => false)
    let storage = FixedArray::makei(512, i => (i * 37 + 19).to_byte())
    storage[0] = b'A'
    decoder.out = DecodeOutput::into(storage)
    decoder.out.length = 1
    decoder.next_cancel = 4096
    @test.assert_eq(
      decoder.decode_batch(packed_fixed_huffman_decoder, Some(distances)),
      false,
    )
    @test.assert_eq(decoder.out.length, 4)
    @test.assert_eq(decoder.pos * 8 - decoder.bit_count, 12)
    let error = @test.expect_error(() => {
      decoder.decode_block(packed_fixed_huffman_decoder, Some(distances))
    })
    guard error is InflateError(kind, _)
    @test.assert_eq(kind, Corrupt)
    @test.assert_eq(decoder.out.length, 4)
    for i in 0..<4 {
      @test.assert_eq(storage[i], b'A')
    }
    for i in 4..<storage.length() {
      @test.assert_eq(storage[i], (i * 37 + 19).to_byte())
    }
  }
}

///|
#cfg(target="native")
test "zero prefetched primary remains invalid after a committed match" {
  let lengths = FixedArray::make(258, 0)
  lengths[257] = 1
  let literals = HuffmanDecoder()
  let distances = HuffmanDecoder()
  @test.assert_eq(literals.initialize_litlen(lengths), true)
  @test.assert_eq(distances.initialize_distance([1]), true)
  let writer = BitWriter()
  writer.write_bits(0, 2) // length three, distance one
  writer.write_bits(1, 1) // unassigned literal/length prefix
  for _ in 0..<16 {
    writer.write_bits(0, 8)
  }
  let decoder = MemDecoder(coverage_finish_bits(writer), () => false)
  let storage = FixedArray::makei(512, i => (i * 37 + 19).to_byte())
  storage[0] = b'A'
  decoder.out = DecodeOutput::into(storage)
  decoder.out.length = 1
  decoder.next_cancel = 4096
  @test.assert_eq(decoder.decode_batch(literals, Some(distances)), false)
  @test.assert_eq(decoder.pos * 8 - decoder.bit_count, 2)
  @test.assert_eq(decoder.out.length, 4)
  let error = @test.expect_error(() => {
    decoder.decode_block(literals, Some(distances))
  })
  guard error is InflateError(kind, _)
  @test.assert_eq(kind, Corrupt)
  for i in 0..<4 {
    @test.assert_eq(storage[i], b'A')
  }
  for i in 4..<storage.length() {
    @test.assert_eq(storage[i], (i * 37 + 19).to_byte())
  }
}

///|
#cfg(target="native")
test "zero prefetched primary after a literal keeps the literal committed" {
  let lengths = FixedArray::make(258, 0)
  lengths[65] = 1
  let literals = HuffmanDecoder()
  let distances = HuffmanDecoder()
  @test.assert_eq(literals.initialize_litlen(lengths), true)
  @test.assert_eq(distances.initialize_distance([1]), true)
  let writer = BitWriter()
  writer.write_bits(0, 1) // literal A
  writer.write_bits(1, 1) // unassigned literal/length prefix
  for _ in 0..<16 {
    writer.write_bits(0, 8)
  }
  let decoder = MemDecoder(coverage_finish_bits(writer), () => false)
  let storage = FixedArray::make(512, b'\xA5')
  decoder.out = DecodeOutput::into(storage)
  decoder.next_cancel = 4096
  @test.assert_eq(decoder.decode_batch(literals, Some(distances)), false)
  @test.assert_eq(decoder.pos * 8 - decoder.bit_count, 1)
  @test.assert_eq(decoder.out.length, 1)
  @test.assert_eq(storage[0], b'A')
  let error = @test.expect_error(() => {
    decoder.decode_block(literals, Some(distances))
  })
  guard error is InflateError(kind, _)
  @test.assert_eq(kind, Corrupt)
  @test.assert_eq(storage[0], b'A')
  for i in 1..<storage.length() {
    @test.assert_eq(storage[i], b'\xA5')
  }
}
