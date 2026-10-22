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
/// Header-phase memory must be O(1): FNAME bytes are discarded as they
/// arrive, never banked in `pending`, so an adversarial unterminated FNAME
/// cannot grow decoder memory.
test "gzip header FNAME bytes are discarded, not retained" {
  let decoder = Decoder()
  let output = FixedArray::make(64, b'\x00')
  let header = b"\x1F\x8B\x08\x08\x00\x00\x00\x00\x00\xFF"
  @test.assert_eq(decoder.step(header, output.mut_view()), NeedMoreInput)
  let chunk = Bytes::make(1024, b'x')
  for _ in 0..<64 {
    @test.assert_eq(decoder.step(chunk, output.mut_view()), NeedMoreInput)
    @test.assert_eq(decoder.last_consumed(), chunk.length())
    @test.assert_eq(decoder.last_produced(), 0)
    @test.assert_eq(decoder.pending.length(), 0)
  }
  let plain = b"body after a long filename"
  let normal = compress(plain)
  let rest = b"\x00" + normal[10:].to_owned()
  @test.assert_eq(decoder.step(rest, output.mut_view(), end=true), Done)
  @test.assert_eq(decoder.last_consumed(), rest.length())
  @test.assert_eq(Bytes::from_array(output[:decoder.last_produced()]), plain)
}

///|
/// Successful completion must retain only the cached transport suffix, not the
/// consumed member.
test "gzip completion releases consumed input and caches read-ahead" {
  let gzip_stream = compress(b"release the completed member")
  let suffix = b"NEXT-FRAME"
  let combined : Array[Byte] = []
  for byte in gzip_stream {
    combined.push(byte)
  }
  for byte in suffix {
    combined.push(byte)
  }
  let decoder = Decoder()
  let output = FixedArray::make(128, b'\x00')
  let status = decoder.step(Bytes::from_array(combined), output.mut_view())
  let consumed = decoder.last_consumed()
  let _produced = decoder.last_produced()
  assert_true(status is Done)
  @test.assert_eq(consumed, gzip_stream.length() + suffix.length())
  @test.assert_eq(decoder.pending.length(), 0)
  @test.assert_eq(decoder.pending_pos, 0)
  assert_false(decoder.borrowed_input)
  @test.assert_eq(decoder.unused, suffix)
  @test.assert_eq(decoder.unused_input(), suffix)
  @test.assert_eq(decoder.unused_input(), suffix)
}

///|
/// The public failure latch runs before buffering new input or touching the
/// inflater again.
test "gzip failed state freezes decoder cursors" {
  let malformed : Bytes = [
    0x1F, 0x8B, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0x07, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  ]
  let decoder = Decoder()
  let output = FixedArray::make(1, b'\x00')
  let GzipError(first_kind, first_error) = @test.expect_error(() => {
    decoder.step(malformed, output.mut_view(), end=true)
  })
  @test.assert_eq(decoder.last_consumed(), 0)
  @test.assert_eq(decoder.last_produced(), 0)
  let pending_pos = decoder.pending_pos
  let pending_length = decoder.pending.length()
  let snapshot = decoder.pending.to_owned()
  assert_false(decoder.borrowed_input)
  let GzipError(repeated_kind, repeated_error) = @test.expect_error(() => {
    decoder.step(b"must not be accepted", output.mut_view())
  })
  @test.assert_eq(decoder.last_consumed(), 0)
  @test.assert_eq(decoder.last_produced(), 0)
  assert_true(first_kind == InvalidDeflate)
  assert_true(repeated_kind == first_kind)
  @test.assert_eq(repeated_error, first_error)
  @test.assert_eq(decoder.pending_pos, pending_pos)
  @test.assert_eq(decoder.pending.length(), pending_length)
  @test.assert_eq(decoder.pending.to_owned(), snapshot)
  assert_false(decoder.borrowed_input)
}

///|
// Both output entry points must agree on every call, including checksum
// failures. Known plaintext also catches a bug shared by both entry points.
test "gzip step_into and offset step views preserve the per-call contract" {
  let source = Bytes::makei(70000, i => {
    if i % 4096 < 2600 {
      b"streaming decoders must agree. "[i % 31]
    } else {
      ((i * 40503) >> 5).to_byte()
    }
  })
  for level in [0, 6] {
    let compressed = compress(source, level~)
    let damaged = compressed.to_fixedarray()
    damaged[compressed.length() - 5] = damaged[compressed.length() - 5] ^
      b'\x01'
    for
      (stream, expected_error) in [
        (compressed, None),
        (Bytes::from_array(damaged), Some(ChecksumMismatch)),
      ] {
      for (chunk, room) in [(1 << 20, 32768), (33, 7)] {
        let fixed = Decoder()
        let viewed = Decoder()
        let output = FixedArray::make(room, b'\x00')
        let padded = FixedArray::make(room + 6, b'\xA5')
        let decoded = @buffer.Buffer()
        let mut position = 0
        let mut verdict = None
        for ;; {
          let end = (position + chunk).min(stream.length())
          let input = stream[position:end]
          let status = try
            fixed.step_into(input, output, end=end == stream.length())
          catch {
            GzipError(kind, _) => Err(kind)
          } noraise {
            status => Ok(status)
          }
          let other = try
            viewed.step(
              input,
              padded.mut_view(start=3, end=room + 3),
              end=end == stream.length(),
            )
          catch {
            GzipError(kind, _) => Err(kind)
          } noraise {
            status => Ok(status)
          }
          @test.assert_eq(status, other)
          @test.assert_eq(fixed.last_consumed(), viewed.last_consumed())
          @test.assert_eq(fixed.last_produced(), viewed.last_produced())
          @test.assert_eq(padded[2], b'\xA5')
          @test.assert_eq(padded[room + 3], b'\xA5')
          match status {
            Err(kind) => {
              verdict = Some(kind)
              break
            }
            Ok(status) => {
              let count = fixed.last_produced()
              @test.assert_eq(output[:count], padded[3:3 + count])
              decoded.write_bytes(Bytes::from_array(output[:count]))
              position += fixed.last_consumed()
              if status is Done {
                break
              }
              assert_true(fixed.last_consumed() > 0 || count > 0)
            }
          }
        }
        @test.assert_eq(verdict, expected_error)
        if expected_error is None {
          @test.assert_eq(decoded.to_bytes(), source)
          @test.assert_eq(position, stream.length())
        }
      }
    }
  }
}
