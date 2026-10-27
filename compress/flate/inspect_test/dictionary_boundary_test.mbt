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
test "preset dictionaries retain exactly the final 32 KiB" {
  let dictionary_bytes = Array::make(40000, b'\x00')
  let message_bytes : Array[Byte] = []
  for i in 0..<512 {
    let byte = ((i * 73 + 19) % 251).to_byte()
    dictionary_bytes[40000 - 512 + i] = byte
    message_bytes.push(byte)
  }
  let dictionary = Bytes::from_array(dictionary_bytes)
  let message = Bytes::from_array(message_bytes)
  let deflater = @flate.IncrementalEncoder(dictionary~)
  let compressed_buffer = FixedArray::make(4096, b'\x00')
  let deflate_status_result = deflater.step(
    message,
    compressed_buffer.mut_view(),
    action=Finish,
  )
  let consumed = deflate_status_result.consumed
  let compressed_size = deflate_status_result.produced
  assert_true(deflate_status_result.status is Done)
  @test.assert_eq(consumed, message.length())
  // A correct final-32-KiB dictionary turns the 512-byte suffix into a match.
  assert_true(compressed_size < 100)
  let compressed = Bytes::from_array(compressed_buffer[:compressed_size])
  let inflater = @flate.IncrementalDecoder(dictionary~)
  let output = FixedArray::make(1024, b'\x00')
  let inflate_status_result = inflater.step(compressed, output.mut_view())
  let produced = inflate_status_result.produced
  assert_true(inflate_status_result.status is Done)
  @test.assert_eq(produced, message.length())
  for i in 0..<produced {
    @test.assert_eq(output[i], message[i])
  }
  // `reset(dictionary=...)` is the allocation-reusing configuration path; it
  // must preload the same final 32 KiB as construction does.
  deflater.reset(dictionary~)
  let reset_status_result = deflater.step(
    message,
    compressed_buffer.mut_view(),
    action=Finish,
  )
  assert_true(reset_status_result.status is Done)
  @test.assert_eq(reset_status_result.consumed, message.length())
  @test.assert_eq(reset_status_result.produced, compressed_size)
}

///|
test "whole-buffer dictionary decoding supports both input modes and output forms" {
  for size in [0, 1, 32768, 40000] {
    let dictionary = Bytes::makei(size, i => (i * 73 + i / 19).to_byte())
    let backing = b"before" + dictionary + b"after"
    let dict = backing[6:6 + size]
    let plain = if size == 0 {
      b"no dictionary history"
    } else {
      Bytes::makei(17000, i => dictionary[size - 1 - i % size.min(257)])
    }
    for
      strategy in [
        @flate.Standard(level=6),
        Split(level=6),
        Optimal(iterations=1),
      ] {
      let raw = @flate.deflate_all(plain, strategy~, dictionary=dict)
      let decoder = @flate.Decompressor(dictionary=dict)
      for mode in [@flate.Exact, Prefix] {
        let framed = b"PAD" +
          raw +
          (if mode is Prefix { b"TRAILER" } else { b"" })
        let input = framed[3:]
        for two_pass in [false, true] {
          match mode {
            Exact => {
              let result = @flate.inflate_exact(
                input,
                dictionary=dict,
                two_pass~,
                max_output=plain.length(),
              )
              assert_eq(result, plain)
            }
            Prefix => {
              let result = @flate.inflate_prefix(
                input,
                dictionary=dict,
                two_pass~,
                max_output=plain.length(),
              )
              assert_eq(result.data, plain)
              assert_eq(result.consumed, raw.length())
            }
          }
        }
        let result = decoder.decompress(input, mode~, max_output=plain.length())
        assert_eq(result.data, plain)
        assert_eq(result.consumed, raw.length())
        for reusable in [false, true] {
          let output = FixedArray::make(plain.length() + 11, b'\xA5')
          let view = output.mut_view(start=3, end=3 + plain.length())
          let counts = if reusable {
            decoder.decompress_into(input, view, mode~)
          } else {
            @flate.Decompressor(dictionary=dict).decompress_into(
              input,
              view,
              mode~,
            )
          }
          assert_eq(counts.consumed, raw.length())
          assert_eq(counts.produced, plain.length())
          assert_eq(Bytes::from_array(output[3:3 + plain.length()]), plain)
          for i in 0..<3 {
            assert_eq(output[i], b'\xA5')
          }
          for i in (3 + plain.length())..<output.length() {
            assert_eq(output[i], b'\xA5')
          }
        }
      }
    }
  }
}

///|
test "dictionary decoders preserve history across errors but not prior output" {
  let dictionary = b"a"
  let plain = Bytes::make(20000, b'a')
  let raw = @flate.deflate_all(plain, dictionary~)
  let decoder = @flate.Decompressor(dictionary~)
  let output = FixedArray::make(plain.length(), b'\x00')
  let InflateError(missing, _) = @test.expect_error(() => {
    @flate.inflate_exact(raw)
  })
  @debug.debug_inspect(missing, content="Corrupt")
  for fixed in [false, true] {
    for
      (input, expected) in [
        (raw + b"tail", @flate.TrailingData),
        (raw[:raw.length() - 1].to_owned(), Truncated),
      ] {
      let InflateError(kind, _) = @test.expect_error(() => {
        if fixed {
          ignore(decoder.decompress_into(input, output.mut_view()))
        } else {
          ignore(decoder.decompress(input))
        }
      })
      assert_eq(kind, expected)
      assert_eq(decoder.decompress(raw).data, plain)
    }
    let InflateError(kind, _) = @test.expect_error(() => {
      if fixed {
        ignore(decoder.decompress_into(raw, output.mut_view(end=1)))
      } else {
        ignore(decoder.decompress(raw, max_output=1))
      }
    })
    assert_true(kind is OutputLimitExceeded(_))
    assert_eq(decoder.decompress(raw).data, plain)
    let mut polls = 0
    let InflateError(kind, _) = @test.expect_error(() => {
      let cancelled = () => {
        polls += 1
        polls == 2
      }
      if fixed {
        ignore(decoder.decompress_into(raw, output.mut_view(), cancelled~))
      } else {
        ignore(decoder.decompress(raw, cancelled~))
      }
    })
    assert_eq(kind, Cancelled)
    assert_eq(decoder.decompress(raw).data, plain)
  }
  for two_pass in [false, true] {
    let empty = @flate.deflate_all(b"", dictionary~)
    let result = @flate.inflate_prefix(
      empty + b"tail",
      dictionary~,
      max_output=0,
      two_pass~,
    )
    assert_eq(result.data, b"")
    assert_eq(result.consumed, empty.length())
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.inflate_exact(raw, dictionary~, max_output=-1, two_pass~)
    })
    assert_eq(kind, InvalidArgument)
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.inflate_exact(raw, dictionary~, max_output=1, two_pass~)
    })
    assert_true(kind is OutputLimitExceeded(_))
    for cancel_at in [1, 2, 5] {
      let mut polls = 0
      let InflateError(kind, _) = @test.expect_error(() => {
        @flate.inflate_exact(raw, dictionary~, two_pass~, cancelled=() => {
          polls += 1
          polls == cancel_at
        })
      })
      assert_eq(kind, Cancelled)
    }
  }
}
