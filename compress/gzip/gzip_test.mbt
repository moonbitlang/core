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
/// gzip stream produced by python's zlib (wbits=31).
let py_gzip : Bytes = [
  0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x03, 0xCB, 0x48, 0xCD, 0xC9,
  0xC9, 0xD7, 0x51, 0xC8, 0x40, 0xA2, 0x14, 0xCA, 0xF3, 0x8B, 0x72, 0x52, 0x14, 0x15,
  0x4A, 0x32, 0x52, 0x15, 0x0A, 0x4B, 0x33, 0x93, 0xB3, 0x15, 0x92, 0x8A, 0xF2, 0xCB,
  0xF3, 0x14, 0xD2, 0xF2, 0x2B, 0xF4, 0x00, 0xB3, 0x50, 0x37, 0xEC, 0x2F, 0x00, 0x00,
  0x00,
]

///|
test "decompress decodes a python-produced gzip stream" {
  @test.assert_eq(@gzip.decompress(py_gzip), data)
}

///|
/// Complete RFC 1952 golden for a level-0 stored member. Python's
/// `gzip.compress(b"abc", compresslevel=0, mtime=0)` produces the same raw
/// DEFLATE bytes and trailer; its header advertises fast compression with
/// XFL=4, while this encoder deliberately uses the valid neutral XFL=0.
test "compress level 0 matches a complete standard golden" {
  let golden : Bytes = [
    // Fixed gzip header (MTIME=0, XFL=0, OS=unknown).
    0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF,
    // Final stored DEFLATE block: LEN=3, NLEN=0xFFFC, then "abc".
     0x01, 0x03, 0x00, 0xFC, 0xFF, 0x61, 0x62, 0x63,
    // CRC32("abc")=0x352441C2 (little-endian), ISIZE=3.
     0xC2, 0x41, 0x24, 0x35, 0x03, 0x00, 0x00, 0x00,
  ]
  @test.assert_eq(@gzip.compress(b"abc", level=0), golden)
}

///|
/// Optimal (zopfli-style) gzip round-trips and is no larger than level 6.
test "compress_optimal round-trips and is no larger than level 6" {
  let payload = b"the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. pack my box with five dozen liquor jugs."
  let opt = @gzip.compress_optimal(payload)
  @test.assert_eq(@gzip.decompress(opt), payload)
  assert_true(opt.length() <= @gzip.compress(payload, level=6).length())
}

///|
/// Concatenate byte sequences.
fn concat_bytes(parts : Array[Bytes]) -> Bytes {
  let b = @buffer.Buffer()
  for part in parts {
    for x in part {
      b.write_byte(x)
    }
  }
  b.to_bytes()
}

///|
/// Copy the first `n` bytes of `data` into an owned value.
fn prefix_bytes(data : Bytes, n : Int32) -> Bytes {
  let out = @buffer.Buffer()
  for i in 0..<n {
    out.write_byte(data[i])
  }
  out.to_bytes()
}

///|
/// Multi-member gzip (RFC 1952 §2.2): concatenated members decode to the joined
/// payloads. The middle member is python's real stream, proving interop.
test "decompress decodes a multi-member stream" {
  let stream = concat_bytes([
    @gzip.compress(b"first. "),
    py_gzip,
    @gzip.compress(b" last."),
  ])
  let want = concat_bytes([b"first. ", data, b" last."])
  @test.assert_eq(@gzip.decompress(stream), want)
}

///|
/// A member boundary may coincide with an input boundary, and the next call
/// may contain only the first magic byte. Neither boundary means EOF without
/// `finish`; both must suspend for more input.
test "streaming gzip Decoder suspends across a split member magic" {
  let first_payload = b"first member"
  let second_payload = b"second member"
  let first = @gzip.compress(first_payload)
  let second = @gzip.compress(second_payload)
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(128, b'\x00')
  let out = @buffer.Buffer()
  let at_boundary_result = dec.step(first, obuf.mut_view())
  let at_boundary = at_boundary_result.status
  let first_used = at_boundary_result.consumed
  let first_produced = at_boundary_result.produced
  assert_true(at_boundary is NeedMoreInput)
  @test.assert_eq(first_used, first.length())
  for i in 0..<first_produced {
    out.write_byte(obuf[i])
  }
  let at_magic_result = dec.step(second[0:1], obuf.mut_view())
  let at_magic = at_magic_result.status
  let magic_used = at_magic_result.consumed
  let magic_produced = at_magic_result.produced
  assert_true(at_magic is NeedMoreInput)
  @test.assert_eq(magic_used, 1)
  @test.assert_eq(magic_produced, 0)
  let _done_result = dec.finish(second[1:], obuf.mut_view())
  let _done = _done_result.status
  let rest_used = _done_result.consumed
  let rest_produced = _done_result.produced
  @test.assert_eq(rest_used, second.length() - 1)
  for i in 0..<rest_produced {
    out.write_byte(obuf[i])
  }
  assert_true(dec.is_finished())
  @test.assert_eq(out.to_bytes(), concat_bytes([first_payload, second_payload]))
}

///|
/// Multi-member fed 3 input bytes at a time: with `end` marking true EOF, the
/// decoder never mistakes a chunk boundary that lands on a member boundary for
/// the end of the stream — the case the buffered heuristic alone could not
/// handle. Three members, the middle one python's real stream.
test "streaming gzip Decoder decodes a multi-member stream in tiny chunks" {
  let stream = concat_bytes([
    @gzip.compress(b"one "),
    py_gzip,
    @gzip.compress(b" three"),
  ])
  let want = concat_bytes([b"one ", data, b" three"])
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(5, b'\x00')
  let out = @buffer.Buffer()
  let n = stream.length()
  let mut fed = 0
  for ;; {
    let next = if fed + 3 < n { fed + 3 } else { n }
    let _st_result = if next == n {
      dec.finish(stream[fed:next], obuf.mut_view())
    } else {
      dec.step(stream[fed:next], obuf.mut_view())
    }
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if dec.is_finished() {
      break
    }
  }
  @test.assert_eq(out.to_bytes(), want)
}

///|
/// Stream ~60 KB through the suspendable `gzip.Encoder` in 500-byte input
/// chunks, draining a 50-byte output buffer — exercising multi-block deflate,
/// header/trailer suspension, and incremental CRC-32 — then verify with the
/// one-shot `decompress`.
test "streaming gzip Encoder round-trips through decompress" {
  let unit = b"streaming gzip test payload, the quick brown fox. "
  let arr : Array[Byte] = []
  for _r in 0..<1200 {
    for i in 0..<unit.length() {
      arr.push(unit[i])
    }
  }
  let src = Bytes::from_array(arr)
  let enc = @gzip.Encoder()
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
    let _st_result = enc.step(chunk, obuf.mut_view(), action~)
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
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
  @test.assert_eq(@gzip.decompress(out.to_bytes()), src)
}

///|
test "streaming gzip Encoder: empty input" {
  let enc = @gzip.Encoder()
  let obuf = FixedArray::make(64, b'\x00')
  let out = @buffer.Buffer()
  for ;; {
    let _st_result = enc.step(b"", obuf.mut_view(), action=Finish)
    let _st = _st_result.status
    let _c = _st_result.consumed
    let p = _st_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    if enc.is_finished() {
      break
    }
  }
  @test.assert_eq(@gzip.decompress(out.to_bytes()), b"")
}

///|
test "streaming gzip Decoder: empty" {
  let gz = @gzip.compress(b"")
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(8, b'\x00')
  let out = @buffer.Buffer()
  let n = gz.length()
  let mut fed = 0
  for ;; {
    let next = if fed + 1 < n { fed + 1 } else { n }
    let _st_result = if next == n {
      dec.finish(gz[fed:next], obuf.mut_view())
    } else {
      dec.step(gz[fed:next], obuf.mut_view())
    }
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
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
/// A gzip stream carrying every optional header field (FEXTRA, FNAME,
/// FCOMMENT, FHCRC), decoded by the streaming Decoder one byte at a time —
/// exercising suspension inside each header field state.
test "streaming gzip Decoder validates optional header fields" {
  let payload = b"optional header fields payload, the quick brown fox."
  let gz = @gzip.compress(payload)
  let arr : Array[Byte] = []
  // Fixed header with FLG = FHCRC | FEXTRA | FNAME | FCOMMENT = 0x1E.
  for b in [0x1F, 0x8B, 0x08, 0x1E, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF] {
    arr.push(b.to_byte())
  }
  // FEXTRA: XLEN = 4, then 4 payload bytes.
  for b in [0x04, 0x00, 0xDE, 0xAD, 0xBE, 0xEF] {
    arr.push(b.to_byte())
  }
  // FNAME and FCOMMENT, NUL-terminated.
  for b in b"a-rather-long-file-name.txt" {
    arr.push(b)
  }
  arr.push(b'\x00')
  for b in b"a header comment" {
    arr.push(b)
  }
  arr.push(b'\x00')
  // FHCRC: low sixteen bits of CRC-32 over all preceding header bytes.
  let header_crc = @checksum.crc32(Bytes::from_array(arr))
  arr.push((header_crc & 0xff).to_byte())
  arr.push(((header_crc >> 8) & 0xff).to_byte())
  // DEFLATE body + trailer, reused from the canonical stream.
  for i in 10..<gz.length() {
    arr.push(gz[i])
  }
  let full = Bytes::from_array(arr)
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(11, b'\x00')
  let out = @buffer.Buffer()
  let n = full.length()
  let mut fed = 0
  for ;; {
    let next = if fed + 1 < n { fed + 1 } else { n }
    let _st_result = if next == n {
      dec.finish(full[fed:next], obuf.mut_view())
    } else {
      dec.step(full[fed:next], obuf.mut_view())
    }
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if dec.is_finished() {
      break
    }
  }
  @test.assert_eq(out.to_bytes(), payload)
  // The one-shot path validates the same header and trailer.
  @test.assert_eq(@gzip.decompress(full), payload)
}

///|
/// RFC 1952 reserves the top three FLG bits and requires a decoder to reject a
/// member when any of them is non-zero.
test "gzip decoders reject reserved FLG bits" {
  let gz = @gzip.compress(b"reserved flag payload")
  let arr : Array[Byte] = []
  for b in gz {
    arr.push(b)
  }
  arr[3] = (arr[3].to_int() | 0x20).to_byte()
  let bad = Bytes::from_array(arr)
  try ignore(@gzip.decompress(bad)) catch {
    GzipError(kind, _) => assert_true(kind == InvalidHeader)
  } noraise {
    _ => @test.fail("one-shot decoding accepted a reserved FLG bit")
  }
  let dec = @gzip.Decoder()
  let out = FixedArray::make(64, b'\x00')
  try ignore(dec.finish(bad, out.mut_view())) catch {
    GzipError(kind, _) => assert_true(kind == InvalidHeader)
  } noraise {
    _ => @test.fail("streaming decoding accepted a reserved FLG bit")
  }
}

///|
/// EOF is an error in every incomplete streaming state, including before the
/// first fixed header and while waiting for the trailer.
test "streaming gzip Decoder rejects truncated input at end" {
  let out = FixedArray::make(256, b'\x00')
  let empty_dec = @gzip.Decoder()
  try ignore(empty_dec.finish(b"", out.mut_view())) catch {
    GzipError(kind, _) => assert_true(kind == Truncated)
  } noraise {
    _ => @test.fail("empty EOF was accepted as a complete gzip stream")
  }

  let gz = @gzip.compress(b"missing trailer byte")
  let truncated = prefix_bytes(gz, gz.length() - 1)
  let dec = @gzip.Decoder()
  try ignore(dec.finish(truncated, out.mut_view())) catch {
    GzipError(kind, _) => assert_true(kind == Truncated)
  } noraise {
    _ => @test.fail("truncated trailer was accepted")
  }
}

///|
/// Malformed raw DEFLATE errors are part of the gzip abstraction boundary and
/// must not escape as `@flate.InflateError`.
test "gzip decoders wrap malformed DEFLATE as GzipError" {
  // BFINAL=1, BTYPE=3 is the reserved DEFLATE block type. Trailer bytes are
  // present so failure necessarily comes from the inner inflater.
  let bad : Bytes = [
    0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x07, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ]
  try ignore(@gzip.decompress(bad)) catch {
    GzipError(kind, _) => assert_true(kind == InvalidDeflate)
  } noraise {
    _ => @test.fail("one-shot decoding accepted a reserved DEFLATE block")
  }
  let dec = @gzip.Decoder()
  let out = FixedArray::make(64, b'\x00')
  try ignore(dec.finish(bad, out.mut_view())) catch {
    GzipError(kind, _) => assert_true(kind == InvalidDeflate)
  } noraise {
    _ => @test.fail("streaming decoding accepted a reserved DEFLATE block")
  }
}

///|
/// The final-input signal survives output backpressure, and terminal calls do
/// not claim to consume bytes that cannot belong to the completed stream.
test "streaming gzip Decoder latches end across one-byte output" {
  let payload = b"end latch with one-byte output and a long repeated repeated repeated tail"
  let gz = @gzip.compress(payload)
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(1, b'\x00')
  let plain = @buffer.Buffer()
  let mut first = true
  let mut finished = false
  for _i in 0..<4096 {
    let view = if first { gz[:] } else { b"" }
    let st_result = if first {
      dec.finish(view, obuf.mut_view())
    } else {
      dec.step(view, obuf.mut_view())
    }
    let st = st_result.status
    let c = st_result.consumed
    let p = st_result.produced
    @test.assert_eq(c, if first { gz.length() } else { 0 })
    assert_true(p <= 1)
    if p == 1 {
      plain.write_byte(obuf[0])
    }
    first = false
    if st is Done {
      finished = true
      break
    }
  }
  assert_true(finished)
  @test.assert_eq(plain.to_bytes(), payload)
  let st_result = dec.step(b"ignored", obuf.mut_view())
  let st = st_result.status
  let c = st_result.consumed
  let p = st_result.produced
  assert_true(st is Done)
  @test.assert_eq(c, 0)
  @test.assert_eq(p, 0)
}

///|
/// Feed and drain one byte at a time through long back-reference copies. This
/// is the minimum-buffer suspend/resume contract used by async adapters.
test "streaming gzip Decoder resumes with one-byte input and output" {
  let unit = b"one-byte streaming contract; "
  let bytes : Array[Byte] = []
  for _r in 0..<80 {
    for b in unit {
      bytes.push(b)
    }
  }
  let payload = Bytes::from_array(bytes)
  let gz = @gzip.compress(payload)
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(1, b'\x00')
  let plain = @buffer.Buffer()
  let mut fed = 0
  let mut finished = false
  for _i in 0..<20000 {
    let next = if fed < gz.length() { fed + 1 } else { fed }
    let view = if fed < gz.length() { gz[fed:next] } else { b"" }
    let _st_result = if next == gz.length() {
      dec.finish(view, obuf.mut_view())
    } else {
      dec.step(view, obuf.mut_view())
    }
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    fed = fed + c
    assert_true(p <= 1)
    if p == 1 {
      plain.write_byte(obuf[0])
    }
    if dec.is_finished() {
      finished = true
      break
    }
  }
  assert_true(finished)
  @test.assert_eq(fed, gz.length())
  @test.assert_eq(plain.to_bytes(), payload)
}

///|
/// Drain a sizeable stored stream one byte at a time. Besides minimum-buffer
/// correctness, this crosses the decoder's compaction threshold and guards the
/// amortized-linear pending-buffer path end to end.
test "streaming gzip Decoder drains a large stored member one byte at a time" {
  let bytes : Array[Byte] = []
  for i in 0..<8192 {
    bytes.push((i & 0xFF).to_byte())
  }
  let payload = Bytes::from_array(bytes)
  let gz = @gzip.compress(payload, level=0)
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(1, b'\x00')
  let plain = @buffer.Buffer()
  let mut first = true
  let mut finished = false
  for _i in 0..<20000 {
    let view = if first { gz[:] } else { b"" }
    let _st_result = if first {
      dec.finish(view, obuf.mut_view())
    } else {
      dec.step(view, obuf.mut_view())
    }
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    @test.assert_eq(c, if first { gz.length() } else { 0 })
    if p == 1 {
      plain.write_byte(obuf[0])
    }
    first = false
    if dec.is_finished() {
      finished = true
      break
    }
  }
  assert_true(finished)
  @test.assert_eq(plain.to_bytes(), payload)
}

///|
/// A flush requested while the ten-byte wrapper header is still backpressured
/// must reach the inner deflater on a later call. Only the first call carries
/// `action=SyncFlush`; all output buffers are one byte.
test "streaming gzip Encoder latches flush across header backpressure" {
  let first = b"data that must be visible at the sync-flush boundary"
  let rest = b" and data after that boundary"
  let enc = @gzip.Encoder()
  let obuf = FixedArray::make(1, b'\x00')
  let encoded = @buffer.Buffer()
  let mut first_call = true
  let mut flushed = false
  for _i in 0..<4096 {
    let view = if first_call { first[:] } else { b"" }
    let action : @flate.DeflateAction = if first_call {
      SyncFlush
    } else {
      Continue
    }
    let st_result = enc.step(view, obuf.mut_view(), action~)
    let st = st_result.status
    let c = st_result.consumed
    let p = st_result.produced
    @test.assert_eq(c, if first_call { first.length() } else { 0 })
    if p == 1 {
      encoded.write_byte(obuf[0])
    }
    first_call = false
    if st is NeedMoreInput {
      flushed = true
      break
    }
  }
  assert_true(flushed)

  // The non-final prefix must already be independently decodable through the
  // sync-flush point.
  let prefix = encoded.to_bytes()
  let dec = @gzip.Decoder()
  let plain = @buffer.Buffer()
  let mut fed_prefix = false
  let mut reached_boundary = false
  for _i in 0..<4096 {
    let view = if fed_prefix { b""[:] } else { prefix }
    let st_result = dec.step(view, obuf.mut_view())
    let st = st_result.status
    let _c = st_result.consumed
    let p = st_result.produced
    fed_prefix = true
    if p == 1 {
      plain.write_byte(obuf[0])
    }
    if st is NeedMoreInput {
      reached_boundary = true
      break
    }
  }
  assert_true(reached_boundary)
  @test.assert_eq(plain.to_bytes(), first)

  // Continue the same encoder, signal end once, and drain without repeating
  // either control flag.
  let mut sent_rest = false
  let mut encoder_done = false
  for _i in 0..<4096 {
    let view = if sent_rest { b""[:] } else { rest }
    let action : @flate.DeflateAction = if sent_rest {
      Continue
    } else {
      Finish
    }
    let st_result = enc.step(view, obuf.mut_view(), action~)
    let st = st_result.status
    let c = st_result.consumed
    let p = st_result.produced
    @test.assert_eq(c, if sent_rest { 0 } else { rest.length() })
    if p == 1 {
      encoded.write_byte(obuf[0])
    }
    sent_rest = true
    if st is Done {
      encoder_done = true
      break
    }
  }
  assert_true(encoder_done)
  @test.assert_eq(
    @gzip.decompress(encoded.to_bytes()),
    concat_bytes([first, rest]),
  )
  let st_result = enc.step(b"ignored", obuf.mut_view())
  let st = st_result.status
  let c = st_result.consumed
  let p = st_result.produced
  assert_true(st is Done)
  @test.assert_eq(c, 0)
  @test.assert_eq(p, 0)
}

///|
/// A transport read may cross the final member trailer into the next protocol
/// frame. The gzip decoder must finish without discarding that read-ahead.
test "streaming gzip Decoder preserves input after the final member" {
  let source = b"gzip member followed by another protocol message"
  let next_frame = b"NEXT-FRAME"
  let encoded = @gzip.compress(source)
  let combined = @buffer.Buffer()
  for byte in encoded {
    combined.write_byte(byte)
  }
  for byte in next_frame {
    combined.write_byte(byte)
  }
  let decoder = @gzip.Decoder()
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
/// In a framed protocol the next frame may itself begin with gzip magic. The
/// explicit one-member mode makes the first trailer an unambiguous boundary.
test "streaming gzip Decoder can stop after one member" {
  let first_payload = b"first framed member"
  let second_member = @gzip.compress(b"belongs to the next frame")
  let first_member = @gzip.compress(first_payload)
  let combined = @buffer.Buffer()
  for byte in first_member {
    combined.write_byte(byte)
  }
  for byte in second_member {
    combined.write_byte(byte)
  }
  let decoder = @gzip.Decoder(multistream=false)
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
  @test.assert_eq(decoded.to_bytes(), first_payload)
  @test.assert_eq(decoder.unused_input(), second_member)
}

///|
test "gzip.decompress decodes a file of thousands of members" {
  let plain = Bytes::makei(300, i => (i * 7).to_byte())
  let framed = @gzip.compress(plain)
  let file = @buffer.Buffer()
  let joined = @buffer.Buffer()
  for _ in 0..<3000 {
    file.write_bytes(framed)
    joined.write_bytes(plain)
  }
  @test.assert_eq(@gzip.decompress(file.to_bytes()), joined.to_bytes())
}

///|
test "streaming gzip verifies independent members while output is reused" {
  let payloads = [
    b"short first member",
    Bytes::makei(12003, i => (i * 71 + i / 13).to_byte()),
    b"short final member",
  ]
  let stream = concat_bytes(
    payloads.map(payload => @gzip.compress(payload, level=0)),
  )
  let decoder = @gzip.Decoder()
  let padded = Array::make(263, b'\xA5')
  let output = padded.mut_view(start=3, end=260)
  let decoded = @buffer.Buffer()
  let mut position = 0
  for ;; {
    let result = decoder.finish(stream[position:], output)
    position += result.consumed
    decoded.write_bytes(Bytes::from_array(output[:result.produced]))
    for i in 0..<output.length() {
      output[i] = b'\xCC'
    }
    if result.status is Done {
      break
    }
    assert_true(result.consumed > 0 || result.produced > 0)
  }
  @test.assert_eq(position, stream.length())
  @test.assert_eq(decoded.to_bytes(), concat_bytes(payloads))
  @test.assert_eq(padded[2], b'\xA5')
  @test.assert_eq(padded[260], b'\xA5')
}
