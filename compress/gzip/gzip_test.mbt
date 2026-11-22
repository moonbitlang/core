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
  @test.assert_eq(@gzip.compress(b"abc", strategy=Standard(level=0)), golden)
}

///|
/// Optimal (zopfli-style) gzip round-trips and is no larger than level 6.
test "Optimal strategy round-trips and is no larger than level 6" {
  let payload = b"the quick brown fox jumps over the lazy dog. the quick brown fox jumps over the lazy dog. pack my box with five dozen liquor jugs."
  let opt = @gzip.compress(payload, strategy=Optimal(iterations=15))
  @test.assert_eq(@gzip.decompress(opt), payload)
  assert_true(
    opt.length() <= @gzip.compress(payload, strategy=Standard(level=6)).length(),
  )
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
/// The incremental decoder finishes at one exact member boundary. Resetting it
/// reuses the core for a following member, whose header may arrive in pieces.
test "streaming gzip Decoder resets across a split member magic" {
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
  assert_true(at_boundary is Done)
  @test.assert_eq(first_used, first.length())
  for i in 0..<first_produced {
    out.write_byte(obuf[i])
  }
  dec.reset()
  let at_magic_result = dec.step(second[0:1], obuf.mut_view())
  let at_magic = at_magic_result.status
  let magic_used = at_magic_result.consumed
  let magic_produced = at_magic_result.produced
  assert_true(at_magic is NeedMoreInput)
  @test.assert_eq(magic_used, 1)
  @test.assert_eq(magic_produced, 0)
  let _done_result = dec.step(second[1:], obuf.mut_view())
  let rest_used = _done_result.consumed
  let rest_produced = _done_result.produced
  @test.assert_eq(rest_used, second.length() - 1)
  assert_true(_done_result.status is Done)
  for i in 0..<rest_produced {
    out.write_byte(obuf[i])
  }
  assert_true(dec.is_finished())
  @test.assert_eq(out.to_bytes(), concat_bytes([first_payload, second_payload]))
}

///|
test "streaming gzip Decoder reset clears a failed member" {
  let dec = @gzip.Decoder()
  let output = FixedArray::make(128, b'\x00')
  try ignore(dec.step(Bytes::make(10, b'\x00'), output.mut_view())) catch {
    GzipError(kind, _) => assert_true(kind == InvalidHeader)
  } noraise {
    _ => @test.fail("invalid gzip header was accepted")
  }
  dec.reset()
  let payload = b"fresh member after reset"
  let result = dec.step(@gzip.compress(payload), output.mut_view())
  assert_true(result.status is Done)
  @test.assert_eq(Bytes::from_array(output[:result.produced]), payload)
}

///|
/// Decode concatenated members in three-byte chunks by resetting the same core
/// at each exact boundary. The middle member is python's real stream.
test "streaming gzip Decoder reset loop decodes multi-member tiny chunks" {
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
  let mut members = 0
  for ;; {
    let next = if fed + 3 < n { fed + 3 } else { n }
    let _st_result = dec.step(stream[fed:next], obuf.mut_view())
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if _st is Done {
      members += 1
      if fed == n {
        break
      }
      dec.reset()
    } else {
      assert_true(c > 0 || p > 0)
    }
  }
  @test.assert_eq(members, 3)
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
  enc.reset()
  assert_false(enc.is_finished())
  ignore(enc.step(b"discard", [].mut_view(), action=Finish))
  enc.reset()
  let fresh = FixedArray::make(64, b'\x00')
  let result = enc.step(b"new stream", fresh.mut_view(), action=Finish)
  assert_true(result.status is Done)
  @test.assert_eq(
    @gzip.decompress(Bytes::from_array(fresh[:result.produced])),
    b"new stream",
  )
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
  let mut ending = false
  for ;; {
    let next = if fed + 1 < n { fed + 1 } else { n }
    let _st_result = dec.step(gz[fed:next], obuf.mut_view())
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if fed == n && !ending {
      ending = true
      ignore(dec.check_end())
    }
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
  let mut ending = false
  for ;; {
    let next = if fed + 1 < n { fed + 1 } else { n }
    let _st_result = dec.step(full[fed:next], obuf.mut_view())
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    for i in 0..<p {
      out.write_byte(obuf[i])
    }
    fed = fed + c
    if fed == n && !ending {
      ending = true
      ignore(dec.check_end())
    }
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
  try ignore(dec.step(bad, out.mut_view())) catch {
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
  try ignore(empty_dec.check_end()) catch {
    GzipError(kind, _) => assert_true(kind == Truncated)
  } noraise {
    _ => @test.fail("empty EOF was accepted as a complete gzip stream")
  }

  let gz = @gzip.compress(b"missing trailer byte")
  let truncated = prefix_bytes(gz, gz.length() - 1)
  let dec = @gzip.Decoder()
  let result = dec.step(truncated, out.mut_view())
  @test.assert_eq(result.consumed, truncated.length())
  @test.assert_eq(
    Bytes::from_array(out[:result.produced]),
    b"missing trailer byte",
  )
  try ignore(dec.check_end()) catch {
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
  try ignore(dec.step(bad, out.mut_view())) catch {
    GzipError(kind, _) => assert_true(kind == InvalidDeflate)
  } noraise {
    _ => @test.fail("streaming decoding accepted a reserved DEFLATE block")
  }
}

///|
/// EOF remains latched while a partially emitted match drains. Input offered
/// after EOF is never consumed, and the missing remainder is eventually
/// reported as truncation.
test "streaming gzip Decoder latches EOF across pending match output" {
  let payload = Bytes::make(4096, b'x')
  let gz = @gzip.compress(payload)
  let probe = @gzip.Decoder()
  let initial_output = FixedArray::make(2, b'\x00')
  let probe_result = probe.step(gz, initial_output.mut_view())
  assert_true(probe_result.status is NeedMoreOutput)
  assert_true(probe_result.consumed > 10)
  assert_true(probe_result.consumed < gz.length())

  // Reproduce the suspension using exactly the accepted prefix, making this
  // a valid EOF declaration for an intentionally truncated source.
  let prefix = gz[:probe_result.consumed]
  let dec = @gzip.Decoder()
  let first = dec.step(prefix, initial_output.mut_view())
  @test.assert_eq(first.consumed, prefix.length())
  @test.assert_eq(first.produced, 2)
  assert_true(first.status is NeedMoreOutput)
  assert_true(dec.check_end() is NeedMoreOutput)

  let byte = FixedArray::make(1, b'\x00')
  let mut drained = 0
  let error = @test.expect_error(() => {
    for _ in 0..<payload.length() {
      let result = dec.step(b"late input", byte.mut_view())
      @test.assert_eq(result.consumed, 0)
      assert_true(result.status is NeedMoreOutput)
      @test.assert_eq(result.produced, 1)
      drained += 1
    }
  })
  assert_true(error is @gzip.GzipError(Truncated, _))
  // More than a few literal bytes remained, so this exercised suspended match
  // copying rather than only an output-full boundary between symbols.
  assert_true(drained > 32)
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
  let mut ending = false
  let mut finished = false
  for _i in 0..<20000 {
    let next = if fed < gz.length() { fed + 1 } else { fed }
    let view = if fed < gz.length() { gz[fed:next] } else { b"" }
    let _st_result = dec.step(view, obuf.mut_view())
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    fed = fed + c
    if fed == gz.length() && !ending {
      ending = true
      ignore(dec.check_end())
    }
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
/// Drain a sizeable stored stream one byte at a time, exercising the
/// minimum-buffer suspend/resume path end to end.
test "streaming gzip Decoder drains a large stored member one byte at a time" {
  let bytes : Array[Byte] = []
  for i in 0..<8192 {
    bytes.push((i & 0xFF).to_byte())
  }
  let payload = Bytes::from_array(bytes)
  let gz = @gzip.compress(payload, strategy=Standard(level=0))
  let dec = @gzip.Decoder()
  let obuf = FixedArray::make(1, b'\x00')
  let plain = @buffer.Buffer()
  let mut position = 0
  let mut ending = false
  let mut finished = false
  for _i in 0..<20000 {
    let _st_result = dec.step(gz[position:], obuf.mut_view())
    let _st = _st_result.status
    let c = _st_result.consumed
    let p = _st_result.produced
    position += c
    if position == gz.length() && !ending {
      ending = true
      ignore(dec.check_end())
    }
    if p == 1 {
      plain.write_byte(obuf[0])
    }
    if dec.is_finished() {
      finished = true
      break
    }
  }
  assert_true(finished)
  @test.assert_eq(position, gz.length())
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
  let mut position = 0
  let mut reached_boundary = false
  for _i in 0..<4096 {
    let st_result = dec.step(prefix[position:], obuf.mut_view())
    let st = st_result.status
    position += st_result.consumed
    let p = st_result.produced
    if p == 1 {
      plain.write_byte(obuf[0])
    }
    if st is NeedMoreInput && position == prefix.length() {
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
  let mut position = 0
  for _ in 0..<4096 {
    let status_result = decoder.step(
      combined.to_bytes()[position:],
      output.mut_view(),
    )
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    position += consumed
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    if status is Done {
      break
    }
  }
  assert_true(decoder.is_finished())
  @test.assert_eq(decoded.to_bytes(), source)
  @test.assert_eq(position, encoded.length())
  @test.assert_eq(combined.to_bytes()[position:].to_owned(), next_frame)
  let status_result = decoder.step(b"late", output.mut_view())
  let status = status_result.status
  let consumed = status_result.consumed
  let produced = status_result.produced
  assert_true(status is Done)
  @test.assert_eq(consumed, 0)
  @test.assert_eq(produced, 0)
}

///|
/// The core always stops after one member even when the following frame begins
/// with gzip magic.
test "streaming gzip Decoder stops after one member" {
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
  let decoder = @gzip.Decoder()
  let output = FixedArray::make(1, b'\x00')
  let decoded = @buffer.Buffer()
  let mut position = 0
  for _ in 0..<4096 {
    let status_result = decoder.step(
      combined.to_bytes()[position:],
      output.mut_view(),
    )
    let status = status_result.status
    let consumed = status_result.consumed
    let produced = status_result.produced
    position += consumed
    if produced == 1 {
      decoded.write_byte(output[0])
    }
    if status is Done {
      break
    }
  }
  assert_true(decoder.is_finished())
  @test.assert_eq(decoded.to_bytes(), first_payload)
  @test.assert_eq(position, first_member.length())
  @test.assert_eq(combined.to_bytes()[position:].to_owned(), second_member)
}

///|
test "gzip.decompress decodes a file of thousands of members" {
  let plain = Bytes::makei(300, i => (i * 7).to_byte())
  let framed = @gzip.compress(plain)
  let file = @buffer.Buffer()
  let joined = @buffer.Buffer()
  for _ in 0..<3000 {
    file.write_bytesview(framed)
    joined.write_bytesview(plain)
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
    payloads.map(payload => @gzip.compress(payload, strategy=Standard(level=0))),
  )
  let decoder = @gzip.Decoder()
  let padded = Array::make(263, b'\xA5')
  let output = padded.mut_view(start=3, end=260)
  let decoded = @buffer.Buffer()
  let mut position = 0
  let mut members = 0
  for ;; {
    let result = decoder.step(stream[position:], output)
    position += result.consumed
    decoded.write_bytesview(Bytes::from_array(output[:result.produced]))
    for i in 0..<output.length() {
      output[i] = b'\xCC'
    }
    if result.status is Done {
      members += 1
      if position == stream.length() {
        break
      }
      decoder.reset()
    } else {
      assert_true(result.consumed > 0 || result.produced > 0)
    }
  }
  @test.assert_eq(members, payloads.length())
  @test.assert_eq(position, stream.length())
  @test.assert_eq(decoded.to_bytes(), concat_bytes(payloads))
  @test.assert_eq(padded[2], b'\xA5')
  @test.assert_eq(padded[260], b'\xA5')
}
