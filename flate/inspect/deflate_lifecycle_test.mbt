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
  @test.assert_eq(d.last_consumed(), 0)
  @test.assert_eq(d.last_produced(), 0)
  let obuf = FixedArray::make(4096, b'\x00')
  let st1 = d.step(s1, obuf.mut_view(), action=Finish)
  assert_true(st1 is Done)
  d.reset()
  @test.assert_eq(d.last_consumed(), 0)
  @test.assert_eq(d.last_produced(), 0)
  let st2 = d.step(s2, obuf.mut_view(), action=Finish)
  let p2 = d.last_produced()
  assert_true(st2 is Done)
  let reused : Array[Byte] = []
  for i in 0..<p2 {
    reused.push(obuf[i])
  }
  @test.assert_eq(Bytes::from_array(reused), @flate.deflate_all(s2))
  let inf = @flate.Inflater()
  @test.assert_eq(inf.last_consumed(), 0)
  @test.assert_eq(inf.last_produced(), 0)
  let dbuf = FixedArray::make(4096, b'\x00')
  let ist1 = inf.step(@flate.deflate_all(s1), dbuf.mut_view())
  let ip1 = inf.last_produced()
  assert_true(ist1 is Done)
  let got1 : Array[Byte] = []
  for i in 0..<ip1 {
    got1.push(dbuf[i])
  }
  @test.assert_eq(Bytes::from_array(got1), s1)
  let sentinel = FixedArray::make(4, b'\xA5')
  let done_status = inf.step(@flate.deflate_all(s2), sentinel.mut_view())
  assert_true(done_status is Done)
  @test.assert_eq(inf.last_consumed(), 0)
  @test.assert_eq(inf.last_produced(), 0)
  for byte in sentinel {
    @test.assert_eq(byte, b'\xA5')
  }
  inf.reset()
  @test.assert_eq(inf.last_consumed(), 0)
  @test.assert_eq(inf.last_produced(), 0)
  let ist2 = inf.step(@flate.deflate_all(s2), dbuf.mut_view())
  let ip2 = inf.last_produced()
  assert_true(ist2 is Done)
  let got2 : Array[Byte] = []
  for i in 0..<ip2 {
    got2.push(dbuf[i])
  }
  @test.assert_eq(Bytes::from_array(got2), s2)
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
  let st = d.step(msg, obuf.mut_view(), action=Finish)
  let p = d.last_produced()
  assert_true(st is Done)
  let comp : Array[Byte] = []
  for i in 0..<p {
    comp.push(obuf[i])
  }
  let compressed = Bytes::from_array(comp)
  // The dictionary must actually pay: smaller than dictionary-less output.
  assert_true(compressed.length() < @flate.deflate_all(msg).length())
  // With the dictionary: decodes to the message.
  let inf = @flate.Inflater(dictionary=dict)
  let dbuf = FixedArray::make(4096, b'\x00')
  let ist = inf.step(compressed, dbuf.mut_view())
  let ip = inf.last_produced()
  assert_true(ist is Done)
  let got : Array[Byte] = []
  for i in 0..<ip {
    got.push(dbuf[i])
  }
  @test.assert_eq(Bytes::from_array(got), msg)
  // Without the dictionary, the first reference reaches before the stream.
  let inf2 = @flate.Inflater()
  let InflateError(kind, _) = @test.expect_error(() => {
    inf2.step(compressed, dbuf.mut_view())
  })
  @test.assert_eq(kind, Corrupt)
}
