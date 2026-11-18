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
test "gzip step finishes one exact member and reset starts another" {
  let first = b"first member"
  let second = b"second member"
  let decoder = @gzip.Decoder()
  let output = FixedArray::make(64, b'\x00')
  let result = decoder.step(@gzip.compress(first), output.mut_view())
  @debug.debug_inspect(result.status, content="Done")
  inspect(
    Bytes::from_array(output[:result.produced]),
    content="b\"first member\"",
  )
  @debug.debug_inspect(
    decoder.step(@gzip.compress(second), output.mut_view()),
    content=(
      #|{ status: Done, consumed: 0, produced: 0 }
    ),
  )
  decoder.reset()
  let result = decoder.step(@gzip.compress(second), output.mut_view())
  @debug.debug_inspect(result.status, content="Done")
  inspect(
    Bytes::from_array(output[:result.produced]),
    content="b\"second member\"",
  )
  @debug.debug_inspect(decoder.check_end(), content="Done")
  @debug.debug_inspect(decoder.check_end(), content="Done")
  @debug.debug_inspect(
    decoder.step(b"ignored", output.mut_view()),
    content=(
      #|{ status: Done, consumed: 0, produced: 0 }
    ),
  )
}

///|
test "container decoders retain their documented backpressure behavior" {
  let source = Bytes::make(1000, b'x')
  let empty = FixedArray::make(0, b'\x00')
  let gzip_decoder = @gzip.Decoder()
  let gzip = @gzip.compress(source)
  let gzip_input = gzip[:gzip.length() - 1]
  let gzip_first = gzip_decoder.step(gzip_input, empty.mut_view())
  assert_true(gzip_first.consumed < gzip_input.length())
  assert_eq(gzip_first.status, NeedMoreOutput)

  // zlib still accepts read-ahead, so EOF can be latched while decompressed
  // output remains pending internally.
  let zlib_decoder = @zlib.Decoder()
  let zlib = @zlib.compress(source)
  let zlib_input = zlib[:zlib.length() - 1]
  let zlib_first = zlib_decoder.step(zlib_input, empty.mut_view())
  assert_eq(zlib_first.consumed, zlib_input.length())
  assert_eq(zlib_first.status, NeedMoreOutput)
  assert_eq(zlib_decoder.check_end(), NeedMoreOutput)
  let output = FixedArray::make(17, b'\x00')
  let mut produced = 0
  let error = @test.expect_error(() => {
    for _ in 0..<(source.length() + 1) {
      let result = zlib_decoder.step(b"", output.mut_view())
      assert_eq(result.status, NeedMoreOutput)
      assert_true(result.produced > 0)
      produced += result.produced
    }
  })
  assert_true(produced > 0)
  let repeated = @test.expect_error(() => zlib_decoder.check_end())
  assert_true(error is @zlib.ZlibError(Truncated, _))
  assert_true(repeated is ZlibError(Truncated, _))
}

///|
test "fixed streaming output views match offset array views across history wraps" {
  let source = Bytes::from_array(Array::makei(140000, i => (i % 257).to_byte()))
  for level in [0, 6] {
    let compressed = @flate.deflate_all(source, strategy=Standard(level~))
    for capacity in [1, 257, 32768, 65536] {
      let fixed = @flate.IncrementalDecoder()
      let viewed = @flate.IncrementalDecoder()
      let output = FixedArray::make(capacity, b'\x00')
      let padded = Array::make(capacity + 6, b'\xA5')
      let collected : Array[Byte] = []
      let mut position = 0
      for ;; {
        let end = (position + 97).min(compressed.length())
        let input = compressed[position:end]
        let status_result = fixed.step(input, output.mut_view())
        let status = status_result.status
        assert_false(status is NeedMoreInput && end == compressed.length())
        let other_result = viewed.step(
          input,
          padded.mut_view(start=3, end=3 + capacity),
        )
        @test.assert_eq(status, other_result.status)
        @test.assert_eq(status_result.consumed, other_result.consumed)
        @test.assert_eq(status_result.produced, other_result.produced)
        let count = status_result.produced
        @test.assert_eq(
          Bytes::from_array(output[:count]),
          Bytes::from_array(padded[3:3 + count]),
        )
        @test.assert_eq(padded[2], b'\xA5')
        @test.assert_eq(padded[capacity + 3], b'\xA5')
        collected.append(output[:count])
        position = position + status_result.consumed
        if status is Done {
          break
        }
      }
      @test.assert_eq(Bytes::from_array(collected), source)
      fixed.reset()
      let empty = FixedArray::make(0, b'\x00')
      let result = fixed.step(compressed, empty.mut_view())
      @test.assert_eq(result.status, NeedMoreOutput)
      @test.assert_eq(result.produced, 0)
    }
  }
}
