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

// Independent golden values from Python zlib; the Stonehedge CRC vector
// is also published by gmlewis/crc32.

///|
test "crc32 matches the zlib reference (and gmlewis golden vector)" {
  for
    (input, expected) in [
      (b"", 0x00000000U),
      (b"hello", 0x3610A686U),
      (b"C is as portable as Stonehedge!!", 0x7D0A377FU),
      (b"The quick brown fox jumps over the lazy dog", 0x414FA339U),
      (Bytes::makei(256, i => i.to_byte()), 0x29058C73U),
    ] {
    @test.assert_eq(@checksum.crc32(input), expected)
  }
}

///|
test "adler32 matches the zlib reference" {
  for
    (input, expected) in [
      (b"", 0x00000001U),
      (b"hello", 0x062C0215U),
      (b"C is as portable as Stonehedge!!", 0xB55B0B09U),
      (b"The quick brown fox jumps over the lazy dog", 0x5BDC0FDAU),
      (Bytes::makei(256, i => i.to_byte()), 0xADF67F81U),
    ] {
    @test.assert_eq(@checksum.adler32(input), expected)
  }
}

///|
test "array view checksums match byte updates across offsets and block boundaries" {
  let source = Bytes::makei(12000, i => ((i * 71 + i / 13) & 255).to_byte())
  let fixed = source.to_fixedarray()
  let array = source.to_array()
  for size in [0, 1, 7, 8, 15, 16, 257, 3799, 3800, 3801, 11000] {
    for data in [fixed[3:3 + size], array[3:3 + size]] {
      let crc = @checksum.Crc32()
      let adler = @checksum.Adler32()
      // A preceding update and two unequal array pieces exercise accumulation.
      crc.update(b"prefix")
      adler.update(b"prefix")
      let mid = size / 3
      crc.update_array(data[:mid])
      crc.update_array(data[mid:])
      adler.update_array(data[:mid])
      adler.update_array(data[mid:])
      let expected = b"prefix" + source[3:3 + size].to_owned()
      @test.assert_eq(crc.finish(), @checksum.crc32(expected))
      @test.assert_eq(adler.finish(), @checksum.adler32(expected))
    }
  }
}
