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
enum Step {
  Min
  Max
}

///|
fn encode(
  data : Bytes,
  input_step~ : Step = Max,
  output_step~ : Step = Max,
) -> Bytes raise {
  let output = FixedArray::make(data.length() * 4 + 256, b'\x00')
  let encoder = @gzip_internal.Encoder()
  let mut input_offset = 0
  let mut output_offset = 0
  let mut step = 0
  while input_offset < data.length() {
    step += 1
    let input_len = match input_step {
      Min => 1
      Max => data.length() - input_offset
    }
    let output_len = match output_step {
      Min => encoder.minimum_output_space(end=false)
      Max => output.length() - output_offset
    }
    guard! input_len > 0 && output_len > 0
    let (consumed, produced) = encoder.write(
      data,
      input_offset~,
      input_len~,
      output,
      output_offset~,
      output_len~,
    )
    guard! consumed < input_len + 1
    guard! produced < output_len + 1
    input_offset += consumed
    output_offset += produced
    if step > data.length() * 2 {
      raise Failure::Failure("too many steps")
    }
  }
  output_offset += encoder.end(
    output,
    output_offset~,
    output_len=output.length() - output_offset,
  )
  output.unsafe_reinterpret_as_bytes()[:output_offset].to_owned()
}

///|
fn decode(
  compressed : Bytes,
  expected_len~ : Int32,
  input_step~ : Step = Max,
  output_step~ : Step = Max,
) -> Bytes raise {
  let output = FixedArray::make(
    if expected_len > 0 {
      expected_len * 2
    } else {
      1
    },
    b'\x00',
  )
  let decoder = @gzip_internal.Decoder()
  let mut input_offset = 0
  let mut output_offset = 0
  let mut step = 0
  let max_steps = compressed.length() * 2 + output.length() + 1
  while !decoder.is_finished() {
    step += 1
    let input_len = match input_step {
      Min => decoder.minimum_input_size()
      Max => compressed.length() - input_offset
    }
    let output_len = match output_step {
      Min => 1
      Max => output.length() - output_offset
    }
    guard! input_len > 0 && output_len > 0
    let (consumed, produced) = decoder.write(
      compressed,
      input_offset~,
      input_len~,
      output,
      output_offset~,
      output_len~,
    )
    guard! consumed < input_len + 1
    guard! produced < output_len + 1
    input_offset += consumed
    output_offset += produced
    if step > max_steps {
      raise Failure::Failure("too many steps")
    }
  }
  guard! input_offset == compressed.length()
  output.unsafe_reinterpret_as_bytes()[:output_offset].to_owned()
}

///|
test "gzip decode one byte partial chunks" {
  let data = b"A simple message to compress"
  let compressed = encode(data)
  let output = FixedArray::make(data.length() * 2, b'\x00')
  let decoder = @gzip_internal.Decoder()
  let mut input_offset = 0
  let mut output_offset = 0
  while !decoder.is_finished() {
    let min_len = decoder.minimum_input_size()
    if min_len > 1 {
      decoder.write_partial_data(compressed, input_offset~, input_len=1)
      input_offset += 1
    } else {
      let (consumed, produced) = decoder.write(
        compressed,
        input_offset~,
        input_len=1,
        output,
        output_offset~,
        output_len=output.length() - output_offset,
      )
      input_offset += consumed
      output_offset += produced
    }
  }
  inspect(input_offset, content="48")
  inspect(compressed.length(), content="48")
  inspect(
    output.unsafe_reinterpret_as_bytes()[:output_offset],
    content=(
      #|b"A simple message to compress"
    ),
  )
}

///|
test "gzip decode partial resume copied bytes" {
  let data = b"A simple message to compress"
  let compressed = encode(data)
  let expected = decode(compressed, expected_len=data.length())
  let output = FixedArray::make(data.length() * 2, b'\x00')
  let decoder = @gzip_internal.Decoder()

  let (prefix_consumed, prefix_produced) = decoder.write(
    compressed,
    input_len=11,
    output,
    output_len=output.length(),
  )
  guard! prefix_consumed == 11
  decoder.write_partial_data(compressed, input_offset=11, input_len=5)
  let (consumed, produced) = decoder.write(
    compressed,
    input_offset=16,
    input_len=compressed.length() - 16,
    output,
    output_offset=prefix_produced,
    output_len=output.length() - prefix_produced,
  )
  guard! 16 + consumed == compressed.length()
  guard! decoder.is_finished()
  assert_eq(
    output.unsafe_reinterpret_as_bytes()[:prefix_produced + produced].to_owned(),
    expected,
  )
}

///|
test "gzip encode min input 1" {
  let data = b"hello_gzip_world"
  let compressed = encode(data, input_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip encode min output 1" {
  let data = b"hello_gzip_world"
  let compressed = encode(data, output_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip decode min input 1" {
  let data = b"hello_gzip_world"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), input_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip decode min output 1" {
  let data = b"hello_gzip_world"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), output_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip encode min input abcdef" {
  let data = b"abcdef"
  let compressed = encode(data, input_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip encode min output abcdef" {
  let data = b"abcdef"
  let compressed = encode(data, output_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip decode min input abcdef" {
  let data = b"abcdef"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), input_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip decode min output abcdef" {
  let data = b"abcdef"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), output_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip encode min input abcdefgh" {
  let data = b"abcdefgh"
  let compressed = encode(data, input_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip encode min output abcdefgh" {
  let data = b"abcdefgh"
  let compressed = encode(data, output_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip decode min input abcdefgh" {
  let data = b"abcdefgh"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), input_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip decode min output abcdefgh" {
  let data = b"abcdefgh"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), output_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip encode min input hello node huffman" {
  let data = b"hello from node huffman stream"
  let compressed = encode(data, input_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip encode min output hello node huffman" {
  let data = b"hello from node huffman stream"
  let compressed = encode(data, output_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
test "gzip decode min input hello node huffman" {
  let data = b"hello from node huffman stream"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), input_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip decode min output hello node huffman" {
  let data = b"hello from node huffman stream"
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), output_step=Min)
  assert_eq(data, data2)
}

///|
test "gzip encoder hash table survives history wrap" {
  let data = Bytes::makei(70000, i => (i % 251).to_byte())
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
#cfg(any(target="native", target="wasm"))
async test "gzip encode min input source file" {
  let data = @fs.read_binary("async/internal/gzip_internal/decoder.mbt")
  let compressed = encode(data, input_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
#cfg(any(target="native", target="wasm"))
async test "gzip encode min output source file" {
  let data = @fs.read_binary("async/internal/gzip_internal/decoder.mbt")
  let compressed = encode(data, output_step=Min)
  let data2 = decode(compressed, expected_len=data.length())
  assert_eq(data, data2)
}

///|
#cfg(any(target="native", target="wasm"))
async test "gzip decode min input source file" {
  let data = @fs.read_binary("async/internal/gzip_internal/decoder.mbt")
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), input_step=Min)
  assert_eq(data, data2)
}

///|
#cfg(any(target="native", target="wasm"))
async test "gzip decode min output source file" {
  let data = @fs.read_binary("async/internal/gzip_internal/decoder.mbt")
  let compressed = encode(data)
  let data2 = decode(compressed, expected_len=data.length(), output_step=Min)
  assert_eq(data, data2)
}
