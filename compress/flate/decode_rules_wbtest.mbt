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
/// HLIT is validated immediately: a reserved value must not be hidden by a
/// missing HDIST field. The byte contains BFINAL=1, BTYPE=dynamic, HLIT=31 and
/// no further input.
test "reserved HLIT wins over a truncated HDIST" {
  let data : Bytes = [0xFD]
  let InflateError(kind, _) = @test.expect_error(() => inflate_prefix(data))
  @test.assert_eq(kind, Corrupt)
  let inflater = IncrementalDecoder()
  let output = FixedArray::make(1, b'\x00')
  let InflateError(kind, _) = @test.expect_error(() => {
    inflater.step(data, output.mut_view())
  })
  @test.assert_eq(kind, Corrupt)
}

///|
fn dictionary_token_stream(tokens : Array[Int32]) -> Bytes {
  let writer = BitWriter()
  writer.write_bits(1, 1)
  writer.write_fixed_block(tokens)
  writer.flush()
  Bytes::from_array(writer.out)
}

///|
test "dictionary matches cross into output and resume batched decoding" {
  let dictionary = Bytes::makei(40000, i => (i * 73 + i / 19).to_byte())
  for distance in [1, 2, 16, 32768] {
    for leading_literal in [false, true] {
      let tokens : Array[Int32] = []
      let expected : Array[Byte] = []
      if leading_literal {
        tokens.push(127)
        expected.push(b'\x7f')
      }
      tokens.push((258 << 16) | distance)
      for _ in 0..<258 {
        let at = dictionary.length() + expected.length() - distance
        expected.push(
          if at < dictionary.length() {
            dictionary[at]
          } else {
            expected[at - dictionary.length()]
          },
        )
      }
      tokens.push((258 << 16) | 1)
      for _ in 0..<258 {
        expected.push(expected[expected.length() - 1])
      }
      for i in 0..<32 {
        tokens.push(i)
        expected.push(i.to_byte())
      }
      let raw = dictionary_token_stream(tokens)
      let plain = Bytes::from_array(expected)
      for two_pass in [false, true] {
        let result = inflate_prefix(raw + b"tail", dictionary~, two_pass~)
        @test.assert_eq(result.data, plain)
        @test.assert_eq(result.consumed, raw.length())
      }
      let output = FixedArray::make(plain.length() + 20, b'\xA5')
      let counts = Decompressor(dictionary~).decompress_into(
        raw,
        output.mut_view(start=5, end=5 + plain.length()),
      )
      @test.assert_eq(counts.produced, plain.length())
      @test.assert_eq(counts.consumed, raw.length())
      @test.assert_eq(Bytes::from_array(output[5:5 + plain.length()]), plain)
      for i in 0..<5 {
        @test.assert_eq(output[i], b'\xA5')
      }
      for i in (5 + plain.length())..<output.length() {
        @test.assert_eq(output[i], b'\xA5')
      }
    }
  }
}

///|
test "reused dictionary decoder rejects history from previous streams" {
  let decoder = Decompressor(dictionary=b"a")
  let valid = dictionary_token_stream([(258 << 16) | 1])
  let invalid = dictionary_token_stream([(3 << 16) | 2])
  let output = FixedArray::make(258, b'\x00')
  for fixed in [false, true] {
    @test.assert_eq(decoder.decompress(valid).data, Bytes::make(258, b'a'))
    let InflateError(kind, _) = @test.expect_error(() => {
      if fixed {
        ignore(decoder.decompress_into(invalid, output.mut_view()))
      } else {
        ignore(decoder.decompress(invalid))
      }
    })
    @test.assert_eq(kind, Corrupt)
    @test.assert_eq(decoder.decompress(valid).data, Bytes::make(258, b'a'))
  }
}
