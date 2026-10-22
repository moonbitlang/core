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
test "gzip wrappers bound accepted input under output backpressure" {
  let source = Bytes::from_array(Array::make(200000, b'\x5A'))
  let no_output = FixedArray::make(0, b'\x00')

  let encoder = Encoder(level=0)
  let enc_status = encoder.step(source, no_output.mut_view(), action=Finish)
  let enc_consumed = encoder.last_consumed()
  let enc_produced = encoder.last_produced()
  assert_true(enc_status is NeedMoreOutput)
  assert_true(enc_consumed > 0)
  assert_true(enc_consumed < source.length())
  @test.assert_eq(enc_produced, 0)

  let compressed = compress(source, level=0)
  let decoder = Decoder()
  @test.assert_eq(decoder.unused_input(), b"")
  let dec_status = decoder.finish_into(compressed, no_output)
  let dec_consumed = decoder.last_consumed()
  let dec_produced = decoder.last_produced()
  assert_true(dec_status is NeedMoreOutput)
  @test.assert_eq(dec_consumed, DECODER_INPUT_LIMIT)
  assert_true(dec_consumed < compressed.length())
  @test.assert_eq(dec_produced, 0)
  assert_true(decoder.pending.length() <= DECODER_INPUT_LIMIT)
  assert_false(decoder.borrowed_input)
  assert_false(decoder.ending)
  for _ in 0..<8 {
    let status = decoder.finish_into(compressed[dec_consumed:], no_output)
    let consumed = decoder.last_consumed()
    let produced = decoder.last_produced()
    assert_true(status is NeedMoreOutput)
    @test.assert_eq(consumed, 0)
    @test.assert_eq(produced, 0)
    assert_true(decoder.pending.length() <= DECODER_INPUT_LIMIT)
    assert_false(decoder.borrowed_input)
    assert_false(decoder.ending)
  }
}
