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
/// Successful completion must retain only the cached transport suffix, not the
/// consumed zlib stream.
test "zlib completion releases consumed input and caches read-ahead" {
  let stream = compress(b"release the completed zlib stream")
  let suffix = b"NEXT-FRAME"
  let combined : Array[Byte] = []
  for byte in stream {
    combined.push(byte)
  }
  for byte in suffix {
    combined.push(byte)
  }
  let decoder = Decoder()
  let output = FixedArray::make(128, b'\x00')
  let status_result = decoder.step(
    Bytes::from_array(combined),
    output.mut_view(),
  )
  let status = status_result.status
  let consumed = status_result.consumed
  assert_true(status is Done)
  @test.assert_eq(consumed, stream.length() + suffix.length())
  @test.assert_eq(decoder.pending.length(), 0)
  @test.assert_eq(decoder.pending_pos, 0)
  @test.assert_eq(decoder.unused, suffix)
  @test.assert_eq(decoder.unused_input(), suffix)
  @test.assert_eq(decoder.unused_input(), suffix)
}

///|
/// The failure latch is checked before buffering input or advancing either the
/// wrapper cursor.
test "zlib failed state freezes decoder cursors" {
  let malformed : Bytes = [0x78, 0x01, 0x07, 0x00, 0x00, 0x00, 0x01]
  let decoder = Decoder()
  let output = FixedArray::make(1, b'\x00')
  let ZlibError(first_kind, first_error) = @test.expect_error(() => {
    decoder.step(malformed, output.mut_view())
  })

  let pending_pos = decoder.pending_pos
  let pending_length = decoder.pending.length()
  let ZlibError(repeated_kind, repeated_error) = @test.expect_error(() => {
    decoder.step(b"must not be accepted", output.mut_view())
  })

  assert_true(first_kind == InvalidDeflate)
  assert_true(repeated_kind == first_kind)
  @test.assert_eq(repeated_error, first_error)
  let ZlibError(end_kind, end_error) = @test.expect_error(() => {
    decoder.check_end()
  })
  @test.assert_eq(end_kind, first_kind)
  @test.assert_eq(end_error, first_error)
  @test.assert_eq(decoder.pending_pos, pending_pos)
  @test.assert_eq(decoder.pending.length(), pending_length)
}

///|
test "zlib check_end truncation freezes decoder cursors and latches failure" {
  let decoder = Decoder()
  let output = FixedArray::make(8, b'\xA5')
  let result = decoder.step(b"\x78", output.mut_view())
  @test.assert_eq(result.consumed, 1)
  @test.assert_eq(result.produced, 0)
  assert_true(result.status is NeedMoreInput)
  assert_false(decoder.ending)
  let ZlibError(first_kind, first_error) = @test.expect_error(() => {
    decoder.check_end()
  })
  @test.assert_eq(first_kind, Truncated)
  assert_true(decoder.ending)
  let pending_pos = decoder.pending_pos
  let pending_length = decoder.pending.length()
  for _ in 0..<2 {
    let ZlibError(kind, error) = @test.expect_error(() => decoder.check_end())
    @test.assert_eq(kind, first_kind)
    @test.assert_eq(error, first_error)
    let ZlibError(kind, error) = @test.expect_error(() => {
      decoder.step(b"must not be accepted", output.mut_view())
    })
    @test.assert_eq(kind, first_kind)
    @test.assert_eq(error, first_error)
    @test.assert_eq(decoder.pending_pos, pending_pos)
    @test.assert_eq(decoder.pending.length(), pending_length)
    @test.assert_eq(output, FixedArray::make(8, b'\xA5'))
  }
}

///|
// Fixed and array-backed output views must agree on every call, including checksum
// failures. Known plaintext also checks the shared decode implementation.
test "zlib fixed and array-backed output views preserve the per-call contract" {
  let source = Bytes::makei(70000, i => {
    if i % 4096 < 2600 {
      b"streaming decoders must agree. "[i % 31]
    } else {
      ((i * 40503) >> 5).to_byte()
    }
  })
  for level in [0, 6] {
    let compressed = compress(source, strategy=Standard(level~))
    let damaged = compressed.to_fixedarray()
    damaged[compressed.length() - 1] = damaged[compressed.length() - 1] ^
      b'\x01'
    for
      (stream, expected_error) in [
        (compressed, None),
        (Bytes::from_array(damaged), Some(ChecksumMismatch)),
        (compressed[:compressed.length() - 1].to_owned(), Some(Truncated)),
      ] {
      for (chunk, room) in [(1 << 20, 32768), (33, 7)] {
        let fixed = Decoder()
        let viewed = Decoder()
        let output = FixedArray::make(room, b'\x00')
        let padded = Array::make(room + 6, b'\xA5')
        let decoded = @buffer.Buffer()
        let mut position = 0
        let mut verdict = None
        for ;; {
          let end = (position + chunk).min(stream.length())
          let input = stream[position:end]
          let status = try fixed.step(input, output.mut_view()) catch {
            ZlibError(kind, _) => Err(kind)
          } noraise {
            result => Ok((result.status, result.consumed, result.produced))
          }
          let other = try
            viewed.step(input, padded.mut_view(start=3, end=room + 3))
          catch {
            ZlibError(kind, _) => Err(kind)
          } noraise {
            result => Ok((result.status, result.consumed, result.produced))
          }
          @test.assert_eq(status, other)
          @test.assert_eq(padded[2], b'\xA5')
          @test.assert_eq(padded[room + 3], b'\xA5')
          match status {
            Err(kind) => {
              verdict = Some(kind)
              break
            }
            Ok((status, consumed, count)) => {
              @test.assert_eq(output[:count], padded[3:3 + count])
              decoded.write_bytes(Bytes::from_array(output[:count]))
              position += consumed
              if position == stream.length() {
                let end_status = try fixed.check_end() catch {
                  ZlibError(kind, _) => Err(kind)
                } noraise {
                  status => Ok(status)
                }
                let other_end = try viewed.check_end() catch {
                  ZlibError(kind, _) => Err(kind)
                } noraise {
                  status => Ok(status)
                }
                @test.assert_eq(end_status, other_end)
                match end_status {
                  Err(kind) => {
                    verdict = Some(kind)
                    break
                  }
                  Ok(Done) => break
                  Ok(NeedMoreOutput) => ()
                  Ok(NeedMoreInput) => @test.fail("EOF must not request input")
                }
              }
              if status is Done {
                break
              }
              assert_true(consumed > 0 || count > 0)
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
