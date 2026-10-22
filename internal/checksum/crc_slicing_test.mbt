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
// Bitwise reference does not share lookup tables with either production path.
fn crc_bitwise_reference(data : BytesView) -> UInt32 {
  let mut crc = 0xFFFFFFFFU
  for byte in data {
    crc = crc ^ byte.to_uint()
    for _ in 0..<8 {
      crc = if (crc & 1) == 0 { crc >> 1 } else { (crc >> 1) ^ 0xEDB88320U }
    }
  }
  crc ^ 0xFFFFFFFFU
}

///|
test "CRC slicing matches bitwise reference for unaligned views and tails" {
  let data = Bytes::from_array(
    Array::makei(16400, i => (i * 73 + i / 19).to_byte()),
  )
  for offset in 0..<8 {
    for
      size in [
        0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 15, 16, 17, 255, 256, 257, 4095, 4096, 4097,
        16384,
      ] {
      let view = data[offset:offset + size]
      let expected = crc_bitwise_reference(view)
      @test.assert_eq(@checksum.crc32(view), expected)
    }
  }
  for byte in [b'\x00', b'\xFF'] {
    let input = Bytes::make(65537, byte)
    @test.assert_eq(@checksum.crc32(input), crc_bitwise_reference(input))
  }
}

///|
test "CRC slicing preserves mixed incremental updates and non-destructive finish" {
  let input = Bytes::from_array(
    Array::makei(8200, i => (i * 37 + i / 11).to_byte()),
  )
  for chunk in [1, 7, 8, 9, 15, 16, 17, 4095, 4096, 4097] {
    let crc = @checksum.Crc32()
    let mut position = 0
    while position < input.length() {
      let end = (position + chunk).min(input.length())
      crc.update(input[position:end])
      crc.update(b"")
      if end % 97 == 0 || end == input.length() {
        let expected = crc_bitwise_reference(input[:end])
        @test.assert_eq(crc.finish(), expected)
        @test.assert_eq(crc.finish(), expected)
      }
      position = end
      if position < input.length() {
        crc.update_byte(input[position])
        position = position + 1
      }
    }
    @test.assert_eq(crc.finish(), crc_bitwise_reference(input))
  }
}

///|
test "CRC wide loads respect backing ends and every short split" {
  for offset in 0..<16 {
    for size in 0..<40 {
      // The view ends exactly at the backing allocation, including empty views.
      let input = Bytes::makei(offset + size, i => {
        (i * 151 + size * 17).to_byte()
      })
      let view = input[offset:]
      let expected = crc_bitwise_reference(view)
      @test.assert_eq(@checksum.crc32(view), expected)
      for split in 0..<(size + 1) {
        let crc = @checksum.Crc32()
        crc.update(view[:split])
        @test.assert_eq(crc.finish(), crc_bitwise_reference(view[:split]))
        crc.update(view[split:])
        @test.assert_eq(crc.finish(), expected)
      }
    }
  }
}
