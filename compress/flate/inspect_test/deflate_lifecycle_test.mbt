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
/// `reset()` reuses one engine across independent streams: the Deflater's
/// output matches a fresh compressor's, and the Inflater decodes a second
/// stream cleanly after the first.
test "reset reuses engines across streams" {
  let s1 = b"first stream payload, first stream payload"
  let s2 = b"second stream: completely different bytes!!"
  let d = @flate.Deflater()

  let obuf = FixedArray::make(4096, b'\x00')
  let st1_result = d.step(s1, obuf.mut_view(), action=Finish)
  assert_true(st1_result.status is Done)
  d.reset()

  let st2_result = d.step(s2, obuf.mut_view(), action=Finish)
  assert_true(st2_result.status is Done)
  // Earlier results remain valid after reset and another stream.
  @test.assert_eq(st1_result.consumed, s1.length())
  @test.assert_eq(st2_result.consumed, s2.length())
  @test.assert_eq(
    Bytes::from_array(obuf[:st2_result.produced]),
    @flate.deflate_all(s2),
  )
  let inf = @flate.Inflater()

  let dbuf = FixedArray::make(4096, b'\x00')
  let ist1_result = inf.step(@flate.deflate_all(s1), dbuf.mut_view())
  assert_true(ist1_result.status is Done)
  @test.assert_eq(Bytes::from_array(dbuf[:ist1_result.produced]), s1)
  let sentinel = FixedArray::make(4, b'\xA5')
  let done_status_result = inf.step(@flate.deflate_all(s2), sentinel.mut_view())
  assert_true(done_status_result.status is Done)
  @test.assert_eq(done_status_result.consumed, 0)
  @test.assert_eq(done_status_result.produced, 0)
  for byte in sentinel {
    @test.assert_eq(byte, b'\xA5')
  }
  inf.reset()

  let ist2_result = inf.step(@flate.deflate_all(s2), dbuf.mut_view())
  assert_true(ist2_result.status is Done)
  @test.assert_eq(ist1_result.produced, s1.length())
  @test.assert_eq(ist2_result.produced, s2.length())
  @test.assert_eq(Bytes::from_array(dbuf[:ist2_result.produced]), s2)
}

///|
/// Preset dictionary on the raw engine: back-references reach into the
/// preloaded window, the stream is smaller than without the dictionary, and
/// decoding without it fails (distances reach before the stream start).
test "preset dictionary: raw deflate round-trip" {
  let dict = b"the quick brown fox jumps over the lazy dog"
  let msg = b"the quick brown fox jumps over the lazy dog, again and again!"
  let d = @flate.Deflater(dictionary=dict)
  let obuf = FixedArray::make(4096, b'\x00')
  let st_result = d.step(msg, obuf.mut_view(), action=Finish)
  assert_true(st_result.status is Done)
  let compressed = Bytes::from_array(obuf[:st_result.produced])
  // The dictionary must actually pay: smaller than dictionary-less output.
  assert_true(compressed.length() < @flate.deflate_all(msg).length())
  // With the dictionary: decodes to the message.
  let inf = @flate.Inflater(dictionary=dict)
  let dbuf = FixedArray::make(4096, b'\x00')
  let ist_result = inf.step(compressed, dbuf.mut_view())
  assert_true(ist_result.status is Done)
  @test.assert_eq(Bytes::from_array(dbuf[:ist_result.produced]), msg)
  // Without the dictionary, the first reference reaches before the stream.
  let inf2 = @flate.Inflater()
  let InflateError(kind, _) = @test.expect_error(() => {
    inf2.step(compressed, dbuf.mut_view())
  })
  @test.assert_eq(kind, Corrupt)
}
