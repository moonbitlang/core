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
test "inflate_all rejects malformed block structure with the correct category" {
  for
    (input, expected) in [
      (b"", @flate.Truncated),
      (b"\x07", Corrupt), // reserved block type
      (b"\x01\x01\x00\x00\x00", Corrupt), // bad NLEN
      (b"\x01\x02\x00\xFD\xFF\xAA", Truncated), // short stored payload
      (b"\x05\x00\x00\x00\x00", Corrupt), // empty code-length alphabet
    ] {
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.inflate_all(input)
    })
    @test.assert_eq(kind, expected)
  }
}

///|
test "streaming Inflater rejects a reserved block immediately" {
  let inflater = @flate.Inflater()

  let output = FixedArray::make(1, b'\x00')
  // A complete non-final stored block leaves the decoder waiting for another
  // block and returns progress that remains valid even if the next call fails.
  let prefix : Bytes = [0x00, 0x01, 0x00, 0xFE, 0xFF, 0x41]
  let prefix_status_result = inflater.step(prefix, output.mut_view())
  let prefix_status = prefix_status_result.status
  assert_true(prefix_status is NeedMoreInput)
  @test.assert_eq(prefix_status_result.consumed, prefix.length())
  @test.assert_eq(prefix_status_result.produced, 1)
  let InflateError(kind, _) = @test.expect_error(() => {
    inflater.step(([0x07] : Bytes), output.mut_view())
  })
  @test.assert_eq(kind, Corrupt)
  @test.assert_eq(prefix_status_result.consumed, prefix.length())
  @test.assert_eq(prefix_status_result.produced, 1)
}

///|
test "streaming Inflater keeps corruption errors until reset" {
  let inflater = @flate.Inflater()
  let output = FixedArray::make(64, b'\x00')
  for input in [([0x07] : Bytes), ([0x01] : Bytes)] {
    let InflateError(kind, _) = @test.expect_error(() => {
      inflater.step(input, output.mut_view())
    })
    @test.assert_eq(kind, Corrupt)
  }
  inflater.reset()

  let source = b"reset clears the terminal error"
  let compressed = @flate.deflate_all(source)
  let status_result = inflater.step(compressed, output.mut_view())
  let status = status_result.status
  let consumed = status_result.consumed
  let produced = status_result.produced
  assert_true(status is Done)
  @test.assert_eq(consumed, compressed.length())
  @test.assert_eq(produced, source.length())
  @test.assert_eq(Bytes::from_array(output[:produced]), source)
}
