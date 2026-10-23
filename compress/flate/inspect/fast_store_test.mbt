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
fn optional_store_input(size : Int32) -> Bytes {
  Bytes::makei(size, i => (i % 251).to_byte())
}

///|
fn optional_store_stream(
  input : Bytes,
  step : (BytesView, MutArrayView[Byte], @flate.DeflateAction) -> @flate.StepResult,
) -> Bytes {
  let output = FixedArray::make(7, b'\x00')
  let result = @buffer.Buffer()
  for position = 0 {
    let end = (position + 113).min(input.length())
    let action = if end == input.length() { @flate.Finish } else { Continue }
    let progress = step(input[position:end], output.mut_view(), action)
    let next = position + progress.consumed
    let written = progress.produced
    result.write_bytes(Bytes::from_array(output[:written]))
    if progress.status is Done {
      guard next == input.length() else {
        abort("stream did not consume input")
      }
      break result.to_bytes()
    }
    guard next > position || written > 0 else {
      abort("stream made no progress")
    }
    continue next
  }
}

///|
test "fast store propagates through gzip zlib and their streaming encoders" {
  let input = optional_store_input(32768)
  @test.assert_eq(
    @gzip.compress(input),
    @gzip.compress(input, fast_store=false),
  )
  @test.assert_eq(
    @zlib.compress(input),
    @zlib.compress(input, fast_store=false),
  )
  @test.assert_eq(
    @gzip.compress(input, fast_store=true),
    @gzip.compress(input, level=0),
  )
  @test.assert_eq(
    @zlib.compress(input, fast_store=true),
    @zlib.compress(input, level=0),
  )
  @test.assert_eq(
    @gzip.decompress(@gzip.compress_optimal(input, fast_store=true)),
    input,
  )
  @test.assert_eq(
    @zlib.decompress(@zlib.compress_optimal(input, fast_store=true)),
    input,
  )
  @test.assert_eq(
    @gzip.compress_optimal(input, fast_store=true),
    @gzip.compress(input, level=0),
  )
  @test.assert_eq(
    @zlib.compress_optimal(input, fast_store=true),
    @zlib.compress(input, level=0),
  )
  let raw = @flate.Deflater(fast_store=true)
  let bytes = optional_store_stream(input, (src, dst, action) => {
    raw.step(src, dst, action~)
  })
  @test.assert_eq(@flate.inflate_all(bytes), input)
  @test.assert_eq(bytes.length() > input.length(), true)
  let gzip = @gzip.Encoder(fast_store=true)
  let bytes = optional_store_stream(input, (src, dst, action) => {
    gzip.step(src, dst, action~)
  })
  @test.assert_eq(bytes.length() > input.length(), true)
  @test.assert_eq(@gzip.decompress(bytes), input)
  let zlib = @zlib.Encoder(fast_store=true)
  let bytes = optional_store_stream(input, (src, dst, action) => {
    zlib.step(src, dst, action~)
  })
  @test.assert_eq(bytes.length() > input.length(), true)
  @test.assert_eq(@zlib.decompress(bytes), input)
  let dictionary = b"shared dictionary"
  let zlib = @zlib.Encoder(dictionary~, fast_store=true)
  let bytes = optional_store_stream(input[:4096].to_owned(), (src, dst, action) => {
    zlib.step(src, dst, action~)
  })
  @test.assert_eq(bytes.length() > 4096, true)
  let decoder = @zlib.Decoder(dictionary~)
  let output = FixedArray::make(4096, b'\x00')
  @test.assert_eq(decoder.finish(bytes, output.mut_view()).status, Done)
  @test.assert_eq(Bytes::from_array(output), input[:4096].to_owned())
}
