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
test "gzip step distinguishes a member boundary from end of input" {
  let first = b"first member"
  let second = b"second member"
  let decoder = @gzip.Decoder()
  let output = FixedArray::make(64, b'\x00')
  let result = decoder.step(@gzip.compress(first), output.mut_view())
  @debug.debug_inspect(result.status, content="NeedMoreInput")
  inspect(
    Bytes::from_array(output[:result.produced]),
    content="b\"first member\"",
  )
  let result = decoder.step(@gzip.compress(second), output.mut_view())
  @debug.debug_inspect(result.status, content="NeedMoreInput")
  inspect(
    Bytes::from_array(output[:result.produced]),
    content="b\"second member\"",
  )
  let result = decoder.step(b"", output.mut_view(), end_of_input=true)
  @debug.debug_inspect(
    result,
    content=(
      #|{ status: Done, consumed: 0, produced: 0 }
    ),
  )
  @debug.debug_inspect(
    decoder.step(b"ignored", output.mut_view()),
    content=(
      #|{ status: Done, consumed: 0, produced: 0 }
    ),
  )
  let single = @gzip.Decoder(multistream=false)
  @debug.debug_inspect(
    single.step(@gzip.compress(first), output.mut_view()).status,
    content="Done",
  )
}

///|
test "container step retains accepted EOF while draining output" {
  let plain = Bytes::make(1000, b'x')
  for gzip in [true, false] {
    let gzip_decoder = @gzip.Decoder()
    let zlib_decoder = @zlib.Decoder()
    let input = if gzip { @gzip.compress(plain) } else { @zlib.compress(plain) }
    let empty = FixedArray::make(0, b'\x00')
    let initial = if gzip {
      gzip_decoder.step(input, empty.mut_view(), end_of_input=true)
    } else {
      zlib_decoder.step(input, empty.mut_view(), end_of_input=true)
    }
    assert_eq(initial.consumed, input.length())
    assert_eq(initial.produced, 0)
    assert_eq(initial.status, NeedMoreOutput)
    let output = FixedArray::make(17, b'\x00')
    let collected : Array[Byte] = []
    for ;; {
      let result = if gzip {
        gzip_decoder.step(b"ignored", output.mut_view())
      } else {
        zlib_decoder.step(b"ignored", output.mut_view())
      }
      assert_eq(result.consumed, 0)
      assert_false(result.status is NeedMoreInput)
      collected.append(output[:result.produced])
      if result.status is Done {
        break
      }
      assert_true(result.produced > 0)
    }
    assert_eq(Bytes::from_array(collected), plain)
  }
}

///|
test "container step checks truncation only after end of input" {
  let output = FixedArray::make(32, b'\x00')
  let gzip = @gzip.Decoder()
  @debug.debug_inspect(
    gzip.step(b"\x1f", output.mut_view()).status,
    content="NeedMoreInput",
  )
  let GzipError(kind, _) = @test.expect_error(() => {
    gzip.step(b"", output.mut_view(), end_of_input=true)
  })
  @debug.debug_inspect(kind, content="Truncated")
  let GzipError(kind, _) = @test.expect_error(() => {
    gzip.step(b"", output.mut_view())
  })
  @debug.debug_inspect(kind, content="Truncated")
  let zlib = @zlib.Decoder()
  @debug.debug_inspect(
    zlib.step(b"\x78", output.mut_view()).status,
    content="NeedMoreInput",
  )
  let ZlibError(kind, _) = @test.expect_error(() => {
    zlib.step(b"", output.mut_view(), end_of_input=true)
  })
  @debug.debug_inspect(kind, content="Truncated")
  let ZlibError(kind, _) = @test.expect_error(() => {
    zlib.step(b"", output.mut_view())
  })
  @debug.debug_inspect(kind, content="Truncated")
  let complete = @zlib.Decoder()
  @debug.debug_inspect(
    complete.step(@zlib.compress(b"complete"), output.mut_view()).status,
    content="Done",
  )
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
