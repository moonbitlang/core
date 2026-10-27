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
let data : Bytes = b"hello, hello, hello world! the quick brown fox."

///|
/// zlib stream produced by python's zlib (wbits=15).
let py_zlib : Bytes = [
  0x78, 0x9C, 0xCB, 0x48, 0xCD, 0xC9, 0xC9, 0xD7, 0x51, 0xC8, 0x40, 0xA2, 0x14, 0xCA,
  0xF3, 0x8B, 0x72, 0x52, 0x14, 0x15, 0x4A, 0x32, 0x52, 0x15, 0x0A, 0x4B, 0x33, 0x93,
  0xB3, 0x15, 0x92, 0x8A, 0xF2, 0xCB, 0xF3, 0x14, 0xD2, 0xF2, 0x2B, 0xF4, 0x00, 0x91,
  0x66, 0x10, 0xBF,
]

///|
test "decompress decodes a python-produced zlib stream" {
  @test.assert_eq(@zlib.decompress(py_zlib), data)
}

///|
/// Optimal (zopfli-style) zlib round-trips and is no larger than level 6.
test "compress_optimal round-trips and is no larger than level 6" {
  let payload = b"the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. pack my box with five dozen liquor jugs."
  let opt = @zlib.compress_optimal(payload)
  @test.assert_eq(@zlib.decompress(opt), payload)
  assert_true(opt.length() <= @zlib.compress(payload, level=6).length())
}

///|
/// Stream ~60 KB through the suspendable `zlib.Encoder` in 500-byte input
/// chunks, draining a 50-byte output buffer — exercising multi-block deflate,
/// header/trailer suspension, and incremental Adler-32 — then verify with the
/// one-shot `decompress`.
test "streaming zlib Encoder round-trips through decompress" {
  let unit = b"streaming zlib test payload, the quick brown fox. "
  let arr : Array[Byte] = []
  for _r in 0..<1200 {
    for i in 0..<unit.length() {
      arr.push(unit[i])
    }
  }
  let src = Bytes::from_array(arr)
  let enc = @zlib.Encoder()
  let obuf = FixedArray::make(50, b'\x00')
  let out = @buffer.Buffer()
  let n = src.length()
  let mut pos = 0
  let mut sent_end = false
  for ;; {
    let last = sent_end || pos + 500 >= n
    let endi = if pos + 500 < n { pos + 500 } else { n }
    let chunk = if sent_end { src[n:n] } else { src[pos:endi] }
    let action : @flate.DeflateAction = if last { Finish } else { Continue }
    let _status_result = enc.step(chunk, obuf.mut_view(), action~)
    let _status = _status_result.status
    let c = _status_result.consumed
    let p = _status_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    pos = pos + c
    if last {
      sent_end = true
    }
    if enc.is_finished() {
      break
    }
  }
  @test.assert_eq(@zlib.decompress(out.to_bytes()), src)
}

///|
/// Decode the python-produced zlib vector through the streaming `zlib.Decoder`,
/// 3 input bytes at a time into a 7-byte output buffer.
test "streaming zlib Decoder decodes a python zlib stream in tiny chunks" {
  let dec = @zlib.Decoder()
  let obuf = FixedArray::make(7, b'\x00')
  let out = @buffer.Buffer()
  let n = py_zlib.length()
  let mut fed = 0
  for ;; {
    let next = if fed + 3 < n { fed + 3 } else { n }
    let _status_result = dec.step(py_zlib[fed:next], obuf.mut_view())
    let _status = _status_result.status
    let c = _status_result.consumed
    let p = _status_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if dec.is_finished() {
      break
    }
  }
  @test.assert_eq(out.to_bytes(), data)
}

///|
test "streaming zlib Decoder: empty" {
  let z = @zlib.compress(b"")
  let dec = @zlib.Decoder()
  let obuf = FixedArray::make(8, b'\x00')
  let out = @buffer.Buffer()
  let n = z.length()
  let mut fed = 0
  for ;; {
    let next = if fed + 1 < n { fed + 1 } else { n }
    let _status_result = dec.step(z[fed:next], obuf.mut_view())
    let _status = _status_result.status
    let c = _status_result.consumed
    let p = _status_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if dec.is_finished() {
      break
    }
  }
  @test.assert_eq(out.to_bytes(), b"")
}

///|
/// Preset dictionary (RFC 1950 FDICT): round-trip through the streaming
/// Encoder/Decoder; a missing or wrong dictionary is rejected via DICTID.
test "zlib preset dictionary round-trip" {
  let dict = b"common preamble shared by both sides of the protocol"
  let msg = b"common preamble shared by both sides of the protocol -- payload"
  let enc = @zlib.Encoder(dictionary=dict)
  let obuf = FixedArray::make(4096, b'\x00')
  let out = @buffer.Buffer()
  let mut sent = false
  for ;; {
    let chunk = if sent { b""[:] } else { msg }
    let st_result = enc.step(chunk, obuf.mut_view(), action=Finish)
    let st = st_result.status
    let p = st_result.produced
    sent = true
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    if st is Done {
      break
    }
  }
  let z = out.to_bytes()
  // With the right dictionary: decodes and verifies the trailer.
  let dec = @zlib.Decoder(dictionary=dict)
  let dbuf = FixedArray::make(4096, b'\x00')
  let got = @buffer.Buffer()
  let n = z.length()
  let mut fed = 0
  for ;; {
    let _status_result = dec.step(z[fed:n], dbuf.mut_view())
    let _status = _status_result.status
    let c = _status_result.consumed
    let p = _status_result.produced
    fed = fed + c
    for i in 0..<p {
      got.write_byte(dbuf[i])
    }
    if dec.is_finished() {
      break
    }
  }
  @test.assert_eq(got.to_bytes(), msg)
  // Without a dictionary: rejected at the header.
  let dec2 = @zlib.Decoder()
  try {
    let __result = dec2.step(z, dbuf.mut_view())
    let _ = __result.status
  } catch {
    ZlibError(kind, _) => assert_true(kind == DictionaryRequired)
  } noraise {
    _ => @test.fail("expected the missing dictionary to be rejected")
  }
  // With the wrong dictionary: DICTID mismatch.
  let dec3 = @zlib.Decoder(dictionary=b"a completely different dictionary")
  try {
    let __result = dec3.step(z, dbuf.mut_view())
    let _ = __result.status
  } catch {
    ZlibError(kind, _) => assert_true(kind == DictionaryMismatch)
  } noraise {
    _ => @test.fail("expected the wrong dictionary to be rejected")
  }
}

///|
test "zlib rejects CINFO values above seven" {
  let valid = @zlib.compress(b"invalid window header")
  let bytes = valid.to_array()
  // 0x881c has CM=8, CINFO=8, and a valid FCHECK, but RFC 1950 permits
  // CINFO only through 7 for DEFLATE.
  bytes[0] = b'\x88'
  bytes[1] = b'\x1C'
  let invalid = Bytes::from_array(bytes)
  let ZlibError(kind, _) = @test.expect_error(() => @zlib.decompress(invalid))
  @test.assert_eq(kind, InvalidHeader)
  let dec = @zlib.Decoder()
  let output = FixedArray::make(64, b'\x00')
  let ZlibError(kind, _) = @test.expect_error(() => {
    dec.step(invalid, output.mut_view())
  })
  @test.assert_eq(kind, InvalidHeader)
}

///|
test "decompress rejects bytes before the Adler trailer" {
  let valid = @zlib.compress(b"exact DEFLATE extent")
  let malformed : Array[Byte] = []
  for i in 0..<(valid.length() - 4) {
    malformed.push(valid[i])
  }
  malformed.push(b'\x00')
  for i in (valid.length() - 4)..<valid.length() {
    malformed.push(valid[i])
  }
  let ZlibError(kind, _) = @test.expect_error(() => {
    @zlib.decompress(Bytes::from_array(malformed))
  })
  @test.assert_eq(kind, TrailingData)
}

///|
test "malformed DEFLATE errors are wrapped as ZlibError" {
  // BFINAL=1, BTYPE=3 is the reserved DEFLATE block type. The remaining four
  // bytes are the Adler-32 of an empty output and are never reached.
  let malformed : Bytes = [0x78, 0x01, 0x07, 0x00, 0x00, 0x00, 0x01]
  let ZlibError(kind, _) = @test.expect_error(() => @zlib.decompress(malformed))
  @test.assert_eq(kind, InvalidDeflate)
  let dec = @zlib.Decoder()
  let output = FixedArray::make(1, b'\x00')
  let ZlibError(kind, _) = @test.expect_error(() => {
    dec.step(malformed, output.mut_view())
  })
  @test.assert_eq(kind, InvalidDeflate)
}

///|
/// Physical EOF is distinct from temporary input starvation in every zlib
/// wrapper state, including the optional DICTID and checksum trailer.
test "streaming zlib Decoder reports truncation at end" {
  let output = FixedArray::make(256, b'\x00')
  let header = @zlib.Decoder()
  let ZlibError(kind, _) = @test.expect_error(() => {
    header.finish(b"\x78", output.mut_view())
  })
  @test.assert_eq(kind, Truncated)

  let dictid = @zlib.Decoder()
  let ZlibError(kind, _) = @test.expect_error(() => {
    dictid.finish(b"\x78\x20\x00\x00", output.mut_view())
  })
  @test.assert_eq(kind, Truncated)

  let body = @zlib.Decoder()
  let ZlibError(kind, _) = @test.expect_error(() => {
    body.finish(b"\x78\x01\x03", output.mut_view())
  })
  @test.assert_eq(kind, Truncated)

  let encoded = @zlib.compress(b"truncated checksum trailer")
  let trailer = @zlib.Decoder()
  let ZlibError(kind, _) = @test.expect_error(() => {
    trailer.finish(encoded[:encoded.length() - 1], output.mut_view())
  })
  @test.assert_eq(kind, Truncated)
}

///|
/// The EOF request survives output suspension and prevents later bytes from
/// being appended to the already-finalized input sequence.
test "streaming zlib Decoder latches end across output backpressure" {
  let source = b"sticky zlib end with one-byte output and repeated repeated data"
  let encoded = @zlib.compress(source)
  let decoder = @zlib.Decoder()
  let no_output = FixedArray::make(0, b'\x00')
  let initial_status_result = decoder.finish(encoded, no_output.mut_view())
  let initial_status = initial_status_result.status
  let initial_consumed = initial_status_result.consumed
  let initial_produced = initial_status_result.produced
  assert_true(initial_status is NeedMoreOutput)
  @test.assert_eq(initial_consumed, encoded.length())
  @test.assert_eq(initial_produced, 0)
  let output = FixedArray::make(1, b'\x00')
  let decoded = @buffer.Buffer()
  let mut first_resume = true
  for _ in 0..<4096 {
    let input = if first_resume { b"late input"[:] } else { b"" }
    let status_result = decoder.step(input, output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, 0)
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    first_resume = false
    if status is Done {
      break
    }
  }
  assert_true(decoder.is_finished())
  @test.assert_eq(decoded.to_bytes(), source)
  @test.assert_eq(decoder.unused_input(), b"")
}

///|
test "streaming zlib Encoder latches flush across header backpressure" {
  let first = b"flush me before the two-byte header has drained"
  let second = b" and then continue the same stream"
  let enc = @zlib.Encoder()
  let output = FixedArray::make(1, b'\x00')
  let compressed = @buffer.Buffer()
  let initial_status_result = enc.step(
    first,
    output.mut_view(),
    action=SyncFlush,
  )
  let initial_status = initial_status_result.status
  let initial_consumed = initial_status_result.consumed
  let initial_produced = initial_status_result.produced
  assert_true(initial_status is NeedMoreOutput)
  @test.assert_eq(initial_consumed, first.length())
  @test.assert_eq(initial_produced, 1)
  compressed.write_byte(output[0])
  let mut flushed = false
  for _ in 0..<4096 {
    let status_result = enc.step(b"", output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, 0)
    assert_true(produced >= 0 && produced <= 1)
    if produced == 1 {
      compressed.write_byte(output[0])
    }
    if status is NeedMoreInput {
      flushed = true
      break
    }
  }
  assert_true(flushed)
  // More than just CMF/FLG proves that the latched request reached Deflater.
  assert_true(compressed.length() > 2)
  let mut sent_second = false
  for _ in 0..<4096 {
    let chunk = if sent_second { b""[:] } else { second }
    let status_result = enc.step(chunk, output.mut_view(), action=Finish)
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, chunk.length())
    assert_true(produced >= 0 && produced <= 1)
    if produced == 1 {
      compressed.write_byte(output[0])
    }
    sent_second = true
    if status is Done {
      break
    }
  }
  assert_true(enc.is_finished())
  let expected = @buffer.Buffer()
  for byte in first {
    expected.write_byte(byte)
  }
  for byte in second {
    expected.write_byte(byte)
  }
  @test.assert_eq(@zlib.decompress(compressed.to_bytes()), expected.to_bytes())
  let terminal_status_result = enc.step(
    b"not part of the stream",
    output.mut_view(),
  )
  let terminal_status = terminal_status_result.status
  let terminal_consumed = terminal_status_result.consumed
  let terminal_produced = terminal_status_result.produced
  assert_true(terminal_status is Done)
  @test.assert_eq(terminal_consumed, 0)
  @test.assert_eq(terminal_produced, 0)
}

///|
test "streaming zlib Encoder leaves input unconsumed after end is latched" {
  let source = b"the final accepted input"
  let enc = @zlib.Encoder()
  let no_output = FixedArray::make(0, b'\x00')
  let initial_status_result = enc.step(
    source,
    no_output.mut_view(),
    action=Finish,
  )
  let initial_status = initial_status_result.status
  let initial_consumed = initial_status_result.consumed
  let initial_produced = initial_status_result.produced
  assert_true(initial_status is NeedMoreOutput)
  @test.assert_eq(initial_consumed, source.length())
  @test.assert_eq(initial_produced, 0)
  let output = FixedArray::make(1, b'\x00')
  let compressed = @buffer.Buffer()
  let late_status_result = enc.step(b"late input", output.mut_view())
  let late_status = late_status_result.status
  let late_consumed = late_status_result.consumed
  let late_produced = late_status_result.produced
  assert_true(late_status is NeedMoreOutput)
  @test.assert_eq(late_consumed, 0)
  @test.assert_eq(late_produced, 1)
  compressed.write_byte(output[0])
  for _ in 0..<4096 {
    let status_result = enc.step(b"", output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, 0)
    if produced == 1 {
      compressed.write_byte(output[0])
    }
    if status is Done {
      break
    }
  }
  assert_true(enc.is_finished())
  @test.assert_eq(@zlib.decompress(compressed.to_bytes()), source)
}

///|
test "streaming zlib Decoder drains large pending input one byte at a time" {
  let source = Bytes::from_array(Array::make(8192, b'\xA5'))
  let compressed = @zlib.compress(source, level=0)
  let dec = @zlib.Decoder()
  let output = FixedArray::make(1, b'\x00')
  let decoded = @buffer.Buffer()
  let mut first_call = true
  for _ in 0..<(source.length() + 64) {
    let chunk = if first_call { compressed[:] } else { b"" }
    let status_result = dec.step(chunk, output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, chunk.length())
    assert_true(produced >= 0 && produced <= 1)
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    first_call = false
    if status is Done {
      break
    }
  }
  assert_true(dec.is_finished())
  @test.assert_eq(decoded.to_bytes(), source)
  let terminal_status_result = dec.step(
    b"not part of the stream",
    output.mut_view(),
  )
  let terminal_status = terminal_status_result.status
  let terminal_consumed = terminal_status_result.consumed
  let terminal_produced = terminal_status_result.produced
  assert_true(terminal_status is Done)
  @test.assert_eq(terminal_consumed, 0)
  @test.assert_eq(terminal_produced, 0)
}

///|
test "streaming zlib Decoder resumes with one-byte input and output" {
  let source = Bytes::from_array(Array::make(700, b'\x5A'))
  let compressed = @zlib.compress(source)
  let dec = @zlib.Decoder()
  let output = FixedArray::make(1, b'\x00')
  let decoded = @buffer.Buffer()
  let mut fed = 0
  for _ in 0..<(source.length() + compressed.length() + 64) {
    let next = if fed < compressed.length() { fed + 1 } else { fed }
    let chunk = compressed[fed:next]
    let status_result = dec.step(chunk, output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    assert_true(consumed >= 0 && consumed <= chunk.length())
    assert_true(produced >= 0 && produced <= 1)
    fed = fed + consumed
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    if status is Done {
      break
    }
    if status is NeedMoreInput && fed == compressed.length() {
      @test.fail(
        "decoder requested input after the complete stream was supplied",
      )
    }
  }
  assert_true(dec.is_finished())
  @test.assert_eq(fed, compressed.length())
  @test.assert_eq(decoded.to_bytes(), source)
}

///|
/// A transport read may cross the zlib trailer into the next protocol frame.
/// The decoder accepts that read-ahead but must make it recoverable after Done.
test "streaming zlib Decoder preserves input after the trailer" {
  let source = b"zlib frame followed by another protocol message"
  let next_frame = b"NEXT-FRAME"
  let encoded = @zlib.compress(source)
  let combined = @buffer.Buffer()
  for byte in encoded {
    combined.write_byte(byte)
  }
  for byte in next_frame {
    combined.write_byte(byte)
  }
  let decoder = @zlib.Decoder()
  let output = FixedArray::make(1, b'\x00')
  let decoded = @buffer.Buffer()
  let mut first = true
  for _ in 0..<4096 {
    let chunk = if first { combined.to_bytes()[:] } else { b"" }
    let status_result = decoder.step(chunk, output.mut_view())
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    @test.assert_eq(consumed, if first { combined.length() } else { 0 })
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    first = false
    if status is Done {
      break
    }
  }
  assert_true(decoder.is_finished())
  @test.assert_eq(decoded.to_bytes(), source)
  @test.assert_eq(decoder.unused_input(), next_frame)
  let status_result = decoder.step(b"late", output.mut_view())
  let status = status_result.status
  let consumed = status_result.consumed
  let produced = status_result.produced
  assert_true(status is Done)
  @test.assert_eq(consumed, 0)
  @test.assert_eq(produced, 0)
  @test.assert_eq(decoder.unused_input(), next_frame)
}

///|
test "streaming zlib checksum survives output reuse before a split trailer" {
  let source = Bytes::makei(12003, i => (i * 71 + i / 13).to_byte())
  let stream = @zlib.compress(source, level=0)
  let body_end = stream.length() - 4
  let decoder = @zlib.Decoder()
  let padded = Array::make(263, b'\xA5')
  let output = padded.mut_view(start=3, end=260)
  let decoded = @buffer.Buffer()
  let mut position = 0
  for ;; {
    let result = decoder.step(stream[position:body_end], output)
    position += result.consumed
    decoded.write_bytes(Bytes::from_array(output[:result.produced]))
    for i in 0..<output.length() {
      output[i] = b'\xCC'
    }
    if result.status is NeedMoreInput {
      break
    }
    assert_true(result.consumed > 0 || result.produced > 0)
  }
  @test.assert_eq(position, body_end)
  @test.assert_eq(decoded.to_bytes(), source)
  for i in 0..<4 {
    let input = stream[body_end + i:body_end + i + 1]
    let result = if i == 3 {
      decoder.finish(input, output)
    } else {
      decoder.step(input, output)
    }
    @test.assert_eq(result.status, if i == 3 { Done } else { NeedMoreInput })
  }
  @test.assert_eq(padded[2], b'\xA5')
  @test.assert_eq(padded[260], b'\xA5')
}
