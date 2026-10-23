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
/// Incompressible (pseudo-random) data must fall back to stored blocks:
/// output ≈ input + ~5 bytes of framing per block, never the ~6% expansion of
/// a forced Huffman path.
test "deflate_all stores incompressible data" {
  let arr : Array[Byte] = []
  let mut x = 0x12345678U
  for _i in 0..<70000 {
    x = x ^ (x << 13)
    x = x ^ (x >> 17)
    x = x ^ (x << 5)
    arr.push((x & 0xFF).reinterpret_as_int().to_byte())
  }
  let src = Bytes::from_array(arr)
  let out = @flate.deflate_all(src)
  // 70000 bytes split into ~16 KB blocks, each falling back to stored at
  // ~5 bytes of framing -> at most input + a few dozen bytes.
  assert_true(out.length() <= src.length() + 64)
  @test.assert_eq(@flate.inflate_all(out), src)
}

///|
/// Sync flush: after `action=SyncFlush`, the flushed prefix alone must decode to
/// everything fed so far (byte-aligned via the empty stored block, ending in
/// the zlib `00 00 FF FF` marker), and the stream then continues across the
/// flush point.
test "Deflater sync flush makes the prefix decodable" {
  let part1 = b"first message, sent immediately. "
  let part2 = b"second message follows after the flush point."
  let enc = @flate.Deflater()
  let obuf = FixedArray::make(4096, b'\x00')
  let st1_result = enc.step(part1, obuf.mut_view(), action=SyncFlush)
  let p1 = st1_result.produced
  assert_true(st1_result.status is NeedMoreInput)
  @test.assert_eq(st1_result.consumed, part1.length())
  // zlib sync-flush signature: the flushed bytes end with 00 00 FF FF.
  assert_true(p1 >= 4)
  @test.assert_eq(obuf[p1 - 4], b'\x00')
  @test.assert_eq(obuf[p1 - 3], b'\x00')
  @test.assert_eq(obuf[p1 - 2], b'\xFF')
  @test.assert_eq(obuf[p1 - 1], b'\xFF')
  // Repeating the same request without new input is idempotent.
  let repeat_status_result = enc.step(b"", obuf.mut_view(), action=SyncFlush)
  assert_true(repeat_status_result.status is NeedMoreInput)
  @test.assert_eq(repeat_status_result.consumed, 0)
  @test.assert_eq(repeat_status_result.produced, 0)
  // The prefix alone already decodes to part1 (stream not finished).
  let prefix = Bytes::from_array(obuf[:p1])
  let inf = @flate.Inflater()
  let dbuf = FixedArray::make(4096, b'\x00')
  let dst_result = inf.step(prefix, dbuf.mut_view())
  assert_true(dst_result.status is NeedMoreInput)
  @test.assert_eq(Bytes::from_array(dbuf[:dst_result.produced]), part1)
  // Continue past the flush point and finish; the whole stream round-trips.
  let out = @buffer.Buffer()
  out.write_bytes(prefix)
  let mut sent_end = false
  for ;; {
    let chunk = if sent_end { b""[:] } else { part2 }
    let st_result = enc.step(chunk, obuf.mut_view(), action=Finish)
    sent_end = true
    out.write_bytes(Bytes::from_array(obuf[:st_result.produced]))
    if st_result.status is Done {
      break
    }
  }
  @test.assert_eq(@flate.inflate_all(out.to_bytes()), part1 + part2)
}

///|
/// A one-shot flush request can arrive while an earlier block is still waiting
/// for output space. It must remain pending even when later drain calls no
/// longer pass `action=SyncFlush`.
test "Deflater latches sync flush across output backpressure" {
  // Exactly one internal high-water window: the whole view is accepted, then
  // its stored block is backpressured before the empty flush request arrives.
  let src = Bytes::from_array(Array::make(16642, b'\x5A'))
  let enc = @flate.Deflater(level=0)
  let no_output = FixedArray::make(0, b'\x00')
  let initial_status_result = enc.step(src, no_output.mut_view())
  assert_true(initial_status_result.status is NeedMoreOutput)
  @test.assert_eq(initial_status_result.consumed, src.length())
  @test.assert_eq(initial_status_result.produced, 0)
  let flush_status_result = enc.step(
    b"",
    no_output.mut_view(),
    action=SyncFlush,
  )
  assert_true(flush_status_result.status is NeedMoreOutput)
  @test.assert_eq(flush_status_result.consumed, 0)
  @test.assert_eq(flush_status_result.produced, 0)
  let obuf = FixedArray::make(257, b'\x00')
  let prefix = @buffer.Buffer()
  for ;; {
    let status_result = enc.step(b"", obuf.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, 0)
    prefix.write_bytes(Bytes::from_array(obuf[:produced]))
    if status is NeedMoreInput {
      break
    }
    assert_true(status is NeedMoreOutput)
  }
  let flushed = prefix.to_bytes()
  assert_true(flushed.length() >= 4)
  @test.assert_eq(flushed[flushed.length() - 4], b'\x00')
  @test.assert_eq(flushed[flushed.length() - 3], b'\x00')
  @test.assert_eq(flushed[flushed.length() - 2], b'\xFF')
  @test.assert_eq(flushed[flushed.length() - 1], b'\xFF')
  let inf = @flate.Inflater()
  let decoded = FixedArray::make(18000, b'\x00')
  let decode_status_result = inf.step(flushed, decoded.mut_view())
  assert_true(decode_status_result.status is NeedMoreInput)
  @test.assert_eq(decode_status_result.consumed, flushed.length())
  @test.assert_eq(decode_status_result.produced, src.length())
  for i in 0..<src.length() {
    @test.assert_eq(decoded[i], src[i])
  }
}
