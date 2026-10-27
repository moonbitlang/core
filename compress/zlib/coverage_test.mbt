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
fn expect_one_shot_zlib_error(
  input : Bytes,
  expected_kind : @zlib.ZlibErrorKind,
) -> Unit raise {
  let ZlibError(kind, _) = @test.expect_error(() => @zlib.decompress(input))
  @test.assert_eq(kind, expected_kind)
}

///|
fn expect_streaming_zlib_error(
  input : Bytes,
  expected_kind : @zlib.ZlibErrorKind,
) -> Unit raise {
  let decoder = @zlib.Decoder()
  let output = FixedArray::make(8, b'\x00')
  let ZlibError(kind, _) = @test.expect_error(() => {
    decoder.step(input, output.mut_view())
  })
  @test.assert_eq(kind, expected_kind)
}

///|
test "coverage: one-shot zlib header errors" {
  expect_one_shot_zlib_error(b"\x78\x01\x03\x00\x00", Truncated)
  expect_one_shot_zlib_error(
    [0x79, 0x00, 0x00, 0x00, 0x00, 0x00],
    InvalidHeader,
  )
  expect_one_shot_zlib_error(
    [0x78, 0x00, 0x00, 0x00, 0x00, 0x00],
    InvalidHeader,
  )
  expect_one_shot_zlib_error(
    [0x78, 0x20, 0x00, 0x00, 0x00, 0x01],
    DictionaryRequired,
  )
}

///|
test "coverage: one-shot zlib body and trailer errors" {
  // 0x03 begins a final fixed-Huffman block but omits its end-of-block code.
  expect_one_shot_zlib_error(
    [0x78, 0x01, 0x03, 0x00, 0x00, 0x00, 0x01],
    Truncated,
  )
  let damaged = @zlib.compress(b"one-shot Adler coverage").to_array()
  damaged[damaged.length() - 1] = damaged[damaged.length() - 1] ^ b'\x01'
  expect_one_shot_zlib_error(Bytes::from_array(damaged), ChecksumMismatch)
}

///|
test "coverage: streaming zlib header and FDICT errors" {
  let output = FixedArray::make(1, b'\x00')
  let short = @zlib.Decoder()
  let short_status_result = short.step(b"\x78", output.mut_view())
  let short_status = short_status_result.status
  let short_consumed = short_status_result.consumed
  let short_produced = short_status_result.produced
  assert_true(short_status is NeedMoreInput)
  @test.assert_eq(short_consumed, 1)
  @test.assert_eq(short_produced, 0)

  expect_streaming_zlib_error([0x79, 0x00], InvalidHeader)
  expect_streaming_zlib_error([0x78, 0x00], InvalidHeader)

  // CMF/FLG 0x7820 announces FDICT. Adler-32(b"") is 1, so the first
  // decoder can validate the split DICTID once all four bytes arrive.
  let split = @zlib.Decoder(dictionary=b"")
  let header_status_result = split.step(b"\x78\x20", output.mut_view())
  let header_status = header_status_result.status
  let header_consumed = header_status_result.consumed
  let header_produced = header_status_result.produced
  assert_true(header_status is NeedMoreInput)
  @test.assert_eq(header_consumed, 2)
  @test.assert_eq(header_produced, 0)
  let dict_status_result = split.step(b"\x00\x00\x00\x01", output.mut_view())
  let dict_status = dict_status_result.status
  let dict_consumed = dict_status_result.consumed
  let dict_produced = dict_status_result.produced
  assert_true(dict_status is NeedMoreInput)
  @test.assert_eq(dict_consumed, 4)
  @test.assert_eq(dict_produced, 0)

  expect_streaming_zlib_error(
    [0x78, 0x20, 0x00, 0x00, 0x00, 0x01],
    DictionaryRequired,
  )
  let wrong = @zlib.Decoder(dictionary=b"wrong dictionary")
  let ZlibError(kind, _) = @test.expect_error(() => {
    wrong.step(b"\x78\x20\x00\x00\x00\x01", output.mut_view())
  })
  @test.assert_eq(kind, DictionaryMismatch)
}

///|
test "coverage: streaming truncated DEFLATE and output backpressure" {
  let output = FixedArray::make(1, b'\x00')
  let truncated = @zlib.Decoder()
  let truncated_status_result = truncated.step(
    b"\x78\x01\x03",
    output.mut_view(),
  )
  let truncated_status = truncated_status_result.status
  let truncated_consumed = truncated_status_result.consumed
  let truncated_produced = truncated_status_result.produced
  assert_true(truncated_status is NeedMoreInput)
  @test.assert_eq(truncated_consumed, 3)
  @test.assert_eq(truncated_produced, 0)

  let source = b"one-byte output backpressure must preserve every byte"
  let encoded = @zlib.compress(source)
  let decoder = @zlib.Decoder()
  let no_output = FixedArray::make(0, b'\x00')
  let blocked_status_result = decoder.step(encoded, no_output.mut_view())
  let blocked_status = blocked_status_result.status
  let blocked_consumed = blocked_status_result.consumed
  let blocked_produced = blocked_status_result.produced
  assert_true(blocked_status is NeedMoreOutput)
  @test.assert_eq(blocked_consumed, encoded.length())
  @test.assert_eq(blocked_produced, 0)
  let decoded = @buffer.Buffer()
  for _ in 0..<4096 {
    let status_result = decoder.step(b"", output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, 0)
    assert_true(produced >= 0 && produced <= 1)
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    if status is Done {
      break
    }
  }
  assert_true(decoder.is_finished())
  @test.assert_eq(decoded.to_bytes(), source)
}

///|
test "coverage: streaming Adler mismatch after backpressure" {
  let damaged = @zlib.compress(b"streaming Adler coverage").to_array()
  damaged[damaged.length() - 1] = damaged[damaged.length() - 1] ^ b'\x01'
  let input = Bytes::from_array(damaged)
  let decoder = @zlib.Decoder()
  let output = FixedArray::make(1, b'\x00')
  let mut first = true
  let ZlibError(kind, _) = @test.expect_error(() => {
    for _ in 0..<4096 {
      let chunk = if first { input[:] } else { b"" }
      let status_result = decoder.step(chunk, output.mut_view())
      let status = status_result.status
      let consumed = status_result.consumed
      let produced = status_result.produced
      if consumed != chunk.length() {
        abort("streaming decoder reported an invalid consumed count")
      }
      if produced < 0 || produced > 1 {
        abort("streaming decoder exceeded the output view")
      }
      first = false
      if status is Done {
        break
      }
    }
  })
  @test.assert_eq(kind, ChecksumMismatch)
}
