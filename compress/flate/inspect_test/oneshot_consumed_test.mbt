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
// another protocol frame, and replace that count after every call.

///|
fn consumed_streams() -> Array[(Bytes, Bytes)] {
  let text = Bytes::makei(70000, i => b"a repeated phrase "[i % 18])
  let noise = Bytes::makei(70000, i => (i * 73 + i / 19).to_byte())
  [
    (@flate.deflate_all(b""), b""),
    (hello_stored, b"hello"),
    (v_fixed_aaa, b"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
    (v_dynamic_text, dynamic_plain),
    (@flate.deflate_all(noise, level=0), noise),
    (@flate.deflate_all(text), text),
    // Fixed block followed by a stored block: prefetched bytes must be
    // returned before the stored header is read.
    (b"\x4A\x04\x04\x02\x00\xFD\xFF\x62\x63", b"abc"),
  ]
}

///|
test "Decompressor returns both byte counts and preserves trailing input" {
  let decoder = @flate.Decompressor()
  @test.assert_eq(decoder.last_consumed(), 0)
  for (raw, plain) in consumed_streams() {
    for tail in [Bytes::make(17, b'\x00'), Bytes::make(17, b'\xFF')] {
      for extra in [0, 1, 7, 8, 9, 17] {
        let around = b"PAD" + raw + tail[:extra].to_owned() + b"OUTSIDE"
        let input = around[3:3 + raw.length() + extra]
        for slack in [0, 300] {
          let output = FixedArray::make(plain.length() + slack, b'\xA5')
          let result = decoder.decompress_into(input, output)
          @test.assert_eq(result.produced, plain.length())
          @test.assert_eq(result.consumed, raw.length())
          @test.assert_eq(Bytes::from_array(output[:plain.length()]), plain)
          @test.assert_eq(decoder.last_consumed(), raw.length())
          for i in plain.length()..<output.length() {
            @test.assert_eq(output[i], b'\xA5')
          }
        }
        @test.assert_eq(decoder.decompress(input), plain)
        @test.assert_eq(decoder.last_consumed(), raw.length())
      }
    }
  }
}

///|
test "Decompressor::last_consumed follows every call of one decompressor" {
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
      @test.assert_eq(decoder.decompress(raw), plain)
      @test.assert_eq(decoder.last_consumed(), raw.length())
      let InflateError(kind, _) = @test.expect_error(() => {
        if fixed {
          ignore(decoder.decompress_into(input, output))
        } else {
          ignore(decoder.decompress(input))
        }
      })
      @test.assert_eq(kind, expected)
      @test.assert_eq(decoder.last_consumed(), 0)
      @test.assert_eq(
        decoder.decompress_into(raw, output).produced,
        plain.length(),
      )
      @test.assert_eq(Bytes::from_array(output), plain)
      @test.assert_eq(decoder.last_consumed(), raw.length())
    }
    if fixed {
      for cancel_at in [1, 2] {
        let mut polls = 0
        let cancelled = () => {
          polls += 1
          polls == cancel_at
        }
        let InflateError(kind, _) = @test.expect_error(() => {
          ignore(decoder.decompress_into(raw, output, cancelled~))
        })
        @test.assert_eq(kind, Cancelled)
        @test.assert_eq(polls, cancel_at)
        @test.assert_eq(decoder.last_consumed(), 0)
        @test.assert_eq(decoder.decompress(raw), plain)
        @test.assert_eq(decoder.last_consumed(), raw.length())
      }
    }
  }
}

///|
test "Decompressor::last_consumed is zero after a call that raises" {
  let decoder = @flate.Decompressor()
  let output = FixedArray::make(16, b'\x00')
  let raw = b"\x4A\x04\x04\x02\x00\xFD\xFF\x62\x63"
  let behind = raw + raw
  for cut in 0..<raw.length() {
    @test.assert_eq(decoder.decompress_into(behind, output).produced, 3)
    @test.assert_eq(Bytes::from_array(output[:3]), b"abc")
    @test.assert_eq(decoder.last_consumed(), raw.length())
    let InflateError(kind, _) = @test.expect_error(() => {
      decoder.decompress_into(behind[:cut], output)
    })
    @test.assert_eq(kind, Truncated)
    @test.assert_eq(decoder.last_consumed(), 0)
  }
}

///|
test "decompress and decompress_into take turns on one decompressor" {
  let decoder = @flate.Decompressor()
  for (raw, plain) in consumed_streams() {
    @test.assert_eq(decoder.decompress(raw + b"behind"), plain)
    @test.assert_eq(decoder.last_consumed(), raw.length())
    if plain.length() > 0 {
      let short = FixedArray::make(plain.length() - 1, b'\x00')
      let InflateError(kind, _) = @test.expect_error(() => {
        decoder.decompress_into(raw, short)
      })
      @test.assert_eq(kind, OutputLimitExceeded)
      @test.assert_eq(decoder.last_consumed(), 0)
    }
    @test.assert_eq(decoder.decompress(raw), plain)
    let output = FixedArray::make(plain.length(), b'\x00')
    @test.assert_eq(
      decoder.decompress_into(raw, output).produced,
      plain.length(),
    )
    @test.assert_eq(Bytes::from_array(output), plain)
    @test.assert_eq(decoder.last_consumed(), raw.length())
  }
}
