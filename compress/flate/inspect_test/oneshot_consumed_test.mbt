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

// A decoder must report the DEFLATE boundary even after reading ahead into
// another protocol frame, and keep each returned result independent of reuse.

///|
fn consumed_streams() -> Array[(Bytes, Bytes)] {
  let text = Bytes::makei(70000, i => b"a repeated phrase "[i % 18])
  let noise = Bytes::makei(70000, i => (i * 73 + i / 19).to_byte())
  [
    (@flate.deflate_all(b""), b""),
    (hello_stored, b"hello"),
    (v_fixed_aaa, b"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
    (v_dynamic_text, dynamic_plain),
    (@flate.deflate_all(noise, strategy=Standard(level=0)), noise),
    (@flate.deflate_all(text), text),
    // Fixed block followed by a stored block: prefetched bytes must be
    // returned before the stored header is read.
    (b"\x4A\x04\x04\x02\x00\xFD\xFF\x62\x63", b"abc"),
  ]
}

///|
test "Decompressor returns both byte counts and preserves trailing input" {
  let decoder = @flate.Decompressor()
  let tails = [b""]
  for byte in [b'\x00', b'\xFF'] {
    for size in [1, 7, 8, 9, 17] {
      tails.push(Bytes::make(size, byte))
    }
  }
  for (raw, plain) in consumed_streams() {
    for tail in tails {
      let around = b"PAD" + raw + tail + b"OUTSIDE"
      let input = around[3:3 + raw.length() + tail.length()]
      for slack in [0, 300] {
        let output = FixedArray::make(plain.length() + slack, b'\xA5')
        let result = decoder.decompress_into(
          input,
          output.mut_view(),
          mode=Prefix,
        )
        @test.assert_eq(result.produced, plain.length())
        @test.assert_eq(result.consumed, raw.length())
        @test.assert_eq(Bytes::from_array(output[:plain.length()]), plain)
        for i in plain.length()..<output.length() {
          @test.assert_eq(output[i], b'\xA5')
        }
      }
      let result = decoder.decompress(
        input,
        mode=Prefix,
        max_output=plain.length(),
      )
      @test.assert_eq(result.data, plain)
      @test.assert_eq(result.consumed, raw.length())
    }
  }
}

///|
test "Decompressor results survive reuse and failures" {
  let plain = Bytes::makei(10000, i => (i % 17).to_byte())
  let raw = @flate.deflate_all(plain)
  let output = FixedArray::make(plain.length(), b'\x00')
  let decoder = @flate.Decompressor()
  for fixed in [true, false] {
    for
      (input, expected) in [
        (b"\x07", @flate.Corrupt),
        (raw[:raw.length() - 1].to_owned(), Truncated),
      ] {
      let previous = decoder.decompress(raw)
      @test.assert_eq(previous.data, plain)
      @test.assert_eq(previous.consumed, raw.length())
      let InflateError(kind, _) = @test.expect_error(() => {
        if fixed {
          ignore(decoder.decompress_into(input, output.mut_view()))
        } else {
          ignore(decoder.decompress(input))
        }
      })
      @test.assert_eq(kind, expected)
      @test.assert_eq(previous.data, plain)
      @test.assert_eq(previous.consumed, raw.length())
      @test.assert_eq(
        decoder.decompress_into(raw, output.mut_view()).produced,
        plain.length(),
      )
      @test.assert_eq(Bytes::from_array(output), plain)
    }
    for cancel_at in [1, 2] {
      let mut polls = 0
      let cancelled = () => {
        polls += 1
        polls == cancel_at
      }
      let InflateError(kind, _) = @test.expect_error(() => {
        if fixed {
          ignore(decoder.decompress_into(raw, output.mut_view(), cancelled~))
        } else {
          ignore(decoder.decompress(raw, max_output=plain.length(), cancelled~))
        }
      })
      @test.assert_eq(kind, Cancelled)
      @test.assert_eq(decoder.decompress(raw).data, plain)
      @test.assert_eq(polls, cancel_at)
    }
  }
}

///|
test "Decompressor can be reused after truncated prefixes" {
  let decoder = @flate.Decompressor()
  let output = FixedArray::make(16, b'\x00')
  let raw = b"\x4A\x04\x04\x02\x00\xFD\xFF\x62\x63"
  let behind = raw + raw
  for cut in 0..<raw.length() {
    @test.assert_eq(
      decoder.decompress_into(behind, output.mut_view(), mode=Prefix).produced,
      3,
    )
    @test.assert_eq(Bytes::from_array(output[:3]), b"abc")
    let InflateError(kind, _) = @test.expect_error(() => {
      decoder.decompress_into(behind[:cut], output.mut_view())
    })
    @test.assert_eq(kind, Truncated)
  }
}

///|
test "decompress and decompress_into take turns on one decompressor" {
  let decoder = @flate.Decompressor()
  for (raw, plain) in consumed_streams() {
    let result = decoder.decompress(raw + b"behind", mode=Prefix)
    @test.assert_eq(result.data, plain)
    @test.assert_eq(result.consumed, raw.length())
    if plain.length() > 0 {
      let short = FixedArray::make(plain.length() - 1, b'\x00')
      for fixed in [true, false] {
        let InflateError(kind, _) = @test.expect_error(() => {
          if fixed {
            ignore(decoder.decompress_into(raw, short.mut_view()))
          } else {
            ignore(decoder.decompress(raw, max_output=short.length()))
          }
        })
        @test.assert_eq(
          kind,
          OutputLimitExceeded(
            limit=short.length().to_uint64(),
            observed=plain.length().to_uint64(),
          ),
        )
      }
    }
    @test.assert_eq(decoder.decompress(raw).data, plain)
    let output = FixedArray::make(plain.length(), b'\x00')
    @test.assert_eq(
      decoder.decompress_into(raw, output.mut_view()).produced,
      plain.length(),
    )
    @test.assert_eq(Bytes::from_array(output), plain)
  }
  let InflateError(kind, _) = @test.expect_error(() => {
    decoder.decompress(b"", max_output=-1)
  })
  @test.assert_eq(kind, InvalidArgument)
}

///|
test "whole-buffer exact and prefix functions have distinct return contracts" {
  let decoder = @flate.Decompressor()
  for (raw, plain) in consumed_streams() {
    let framed = b"PAD" + raw + b"TRAILER"
    let input = framed[3:]
    for two_pass in [false, true] {
      let result : @flate.Decompressed = @flate.inflate_prefix(input, two_pass~)
      assert_eq(result.data, plain)
      assert_eq(result.consumed, raw.length())
      assert_eq(input[result.consumed:].to_owned(), b"TRAILER")
      let exact : Bytes = @flate.inflate_exact(raw, two_pass~)
      assert_eq(exact, result.data)
      let InflateError(kind, _) = @test.expect_error(() => {
        @flate.inflate_exact(input, two_pass~)
      })
      assert_eq(kind, TrailingData)
    }
    let output = FixedArray::make(plain.length(), b'\x00')
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.Decompressor().decompress_into(input, output.mut_view())
    })
    assert_eq(kind, TrailingData)
    let counts = @flate.Decompressor().decompress_into(
      input,
      output.mut_view(),
      mode=Prefix,
    )
    assert_eq(counts.consumed, raw.length())
    assert_eq(counts.produced, plain.length())
    assert_eq(Bytes::from_array(output), plain)
    let InflateError(kind, _) = @test.expect_error(() => {
      decoder.decompress(input)
    })
    assert_eq(kind, TrailingData)
    let InflateError(kind, _) = @test.expect_error(() => {
      decoder.decompress_into(input, output.mut_view())
    })
    assert_eq(kind, TrailingData)
    assert_eq(decoder.decompress(raw).data, plain)
  }
}
