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
test "omitted cancellation preserves output and resets explicit callback state" {
  let source = Bytes::makei(9000, i => (i % 23).to_byte())
  for level in [0, 6] {
    let input = deflate_all(source, level~)
    let decoder = Decompressor()
    for _ in 0..<2 {
      let stopped = FixedArray::make(9017, b'\xA5')
      let mut calls = 0
      let error = @test.expect_error(() => {
        decoder.decompress_into(input, stopped, cancelled=() => {
          calls += 1
          calls == 2
        })
      })
      guard error is InflateError(kind, _)
      @test.assert_eq(kind, Cancelled)
      @test.assert_eq(calls, 2)
      for i in 0..<4096 {
        @test.assert_eq(stopped[i], source[i])
      }
      for i in 4096..<9017 {
        @test.assert_eq(stopped[i], b'\xA5')
      }
      let output = FixedArray::make(9017, b'\xA5')
      @test.assert_eq(decoder.decompress_into(input, output).produced, 9000)
      @test.assert_eq(calls, 2)
      for i in 0..<9000 {
        @test.assert_eq(output[i], source[i])
      }
      for i in 9000..<9017 {
        @test.assert_eq(output[i], b'\xA5')
      }
      calls = 0
      @test.assert_eq(
        decoder.decompress_into(input, output, cancelled=() => {
          calls += 1
          false
        }).produced,
        9000,
      )
      @test.assert_eq(calls, 3)
    }
    @test.assert_eq(inflate_all(input), source)
    let output = FixedArray::make(9000, b'\xA5')
    @test.assert_eq(inflate_into(input, output), 9000)
    let mut one_shot_calls = 0
    @test.assert_eq(
      inflate_into(input, output, cancelled=() => {
        one_shot_calls += 1
        false
      }),
      9000,
    )
    @test.assert_eq(one_shot_calls, 3)
    let error = @test.expect_error(() => {
      decoder.decompress_into(input, FixedArray::make(4095, b'\xA5'))
    })
    guard error is InflateError(kind, _)
    @test.assert_eq(kind, OutputLimitExceeded)
  }
}

///|
test "literal fast path preserves capacity growth and cancellation" {
  for capacity in [0, 1, 2, 17] {
    let storage = FixedArray::make(capacity, b'\xA5')
    let decoder = MemDecoder(b"", () => false)
    decoder.out = DecodeOutput::into(storage)
    decoder.next_cancel = 4096
    for i in 0..<capacity {
      decoder.push(i.to_byte())
      @test.assert_eq(decoder.out.length, i + 1)
      for j in (i + 1)..<capacity {
        @test.assert_eq(storage[j], b'\xA5')
      }
    }
    let error = @test.expect_error(() => decoder.push(b'x'))
    guard error is InflateError(kind, _)
    @test.assert_eq(kind, OutputLimitExceeded)
    @test.assert_eq(decoder.out.length, capacity)
    for i in 0..<capacity {
      @test.assert_eq(storage[i], i.to_byte())
    }
  }
  let growing = MemDecoder(b"", () => false)
  growing.next_cancel = 4096
  for i in 0..<33 {
    growing.push(i.to_byte())
  }
  @test.assert_eq(growing.out.to_bytes(), Bytes::makei(33, i => i.to_byte()))
  for capacity in [1, 8] {
    let mut calls = 0
    let decoder = MemDecoder(b"", () => {
      calls += 1
      true
    })
    decoder.out = DecodeOutput::into(FixedArray::make(capacity, b'\xA5'))
    decoder.next_cancel = 1
    let error = @test.expect_error(() => decoder.push(b'x'))
    guard error is InflateError(kind, _)
    @test.assert_eq(kind, Cancelled)
    @test.assert_eq(calls, 1)
    @test.assert_eq(decoder.out.length, 1)
    @test.assert_eq(decoder.out.storage[0], b'x')
    for i in 1..<capacity {
      @test.assert_eq(decoder.out.storage[i], b'\xA5')
    }
  }
}

///|
test "data Huffman decoding preserves following bits across reservoir boundaries" {
  // A complete skewed tree exercises both primary and 15-bit linked entries.
  let lengths = FixedArray::makei(16, i => (i + 1).min(15))
  let codes = FixedArray::makei(16, i => {
    let code = if i == 15 { 32767U } else { (1U << (i + 1)) - 2 }
    reverse_bits(code, lengths[i])
  })
  let huffman = HuffmanDecoder()
  @test.assert_eq(huffman.initialize(lengths), true)
  for
    (table, values, sizes) in [
      (fixed_huffman_decoder, fixed_ll_val, fixed_ll_len),
      (huffman, codes, lengths),
    ] {
    for symbol in 0..<values.length() {
      let word = values[symbol] | (0x55U << sizes[symbol])
      for buffered in 0..<=31 {
        let input = Bytes::makei(4, i => {
          let shift = buffered + i * 8
          if shift < 32 {
            (word >> shift).to_byte()
          } else {
            b'\x00'
          }
        })
        let decoder = MemDecoder(input, () => false)
        decoder.bitbuf = word & ((1U << buffered) - 1)
        decoder.bit_count = buffered
        @test.assert_eq(decoder.huff_sym_data(table), symbol)
        @test.assert_eq(decoder.read_bits(8), 0x55)
      }
    }
  }
  let truncated = MemDecoder(b"", () => false)
  truncated.bitbuf = 0x3FFF
  truncated.bit_count = 14
  let error = @test.expect_error(() => truncated.huff_sym_data(huffman))
  guard error is InflateError(kind, _)
  @test.assert_eq(kind, Truncated)
  let single = HuffmanDecoder()
  @test.assert_eq(single.initialize([1]), true)
  let invalid = MemDecoder(b"", () => false)
  invalid.bitbuf = 1
  invalid.bit_count = 15
  let error = @test.expect_error(() => invalid.huff_sym_data(single))
  guard error is InflateError(kind, _)
  @test.assert_eq(kind, Corrupt)
}

///|
test "decoded short matches preserve exact length for near and distant history" {
  for distance in [1, 2, 3, 4, 5, 8, 15, 16, 17, 255, 256, 257, 32768] {
    let history = Bytes::makei(distance, i => (i * 73 + i / 19).to_byte())
    let symbol = dist_index(distance)
    let info = distance_code_info_table[symbol]
    let encoded = fixed_distance_symbol(symbol) |
      ((distance - (info >> 4)) << 5)
    for length in 3..<=16 {
      let storage = FixedArray::make(distance + length + 7, b'\xA5')
      storage.blit_from_bytes(0, history, 0, distance)
      let decoder = MemDecoder(b"", () => false)
      decoder.out = DecodeOutput::into(storage)
      decoder.out.length = distance
      decoder.next_cancel = distance + length + 1
      let code = 257 + len_to_idx[length]
      let length_info = length_code_info_table[code - 257]
      let extra = length_info & 7
      decoder.bitbuf = ((length - (length_info >> 3)) | (encoded << extra)).reinterpret_as_uint()
      decoder.bit_count = extra + 5 + (info & 15)
      decoder.decode_match(code, None)
      @test.assert_eq(decoder.out.length, distance + length)
      for i in 0..<length {
        @test.assert_eq(storage[distance + i], history[i % distance])
      }
      for i in (distance + length)..<storage.length() {
        @test.assert_eq(storage[i], b'\xA5')
      }
    }
  }
}
