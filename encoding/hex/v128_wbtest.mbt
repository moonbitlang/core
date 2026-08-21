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

// Differential tests pinning the vectorized paths against the scalar ones.
// Lengths sweep every residue modulo sixteen (encode blocks) and modulo
// thirty-two (decode blocks), so every block-count and tail combination is
// covered. On the backends without the vectorized paths these compare the
// scalar implementation with itself, which keeps the file portable.

///|
/// Deterministic pseudo-random bytes covering all 256 byte values.
fn sample_bytes(length : Int) -> Bytes {
  let out = FixedArray::make(length, b'\x00')
  let mut state = 0x2545F491U
  for i in 0..<length {
    state = state * 1664525 + 1013904223
    out[i] = ((state >> 16) & 0xFF).reinterpret_as_int().to_byte()
  }
  out.unsafe_reinterpret_as_bytes()
}

///|
test "encode agrees with the scalar encoder across all tail residues" {
  for length in 0..<80 {
    let bytes = sample_bytes(length)
    @test.assert_eq(encode(bytes), encode_scalar(bytes))
  }
}

///|
test "decode agrees with the scalar decoder across all block counts" {
  for length in 0..<80 {
    let bytes = sample_bytes(length)
    let lowercase = encode(bytes)
    @test.assert_eq(decode(lowercase), bytes)
    @test.assert_eq(decode(lowercase), decode_scalar(lowercase))
    // uppercase exercise the letter-range adjustment lanes
    let uppercase = lowercase.to_upper()
    @test.assert_eq(decode(uppercase), bytes)
    @test.assert_eq(decode(uppercase), decode_scalar(uppercase))
  }
}

///|
/// Builds a string from raw UTF-16 code units, so that a test can plant code
/// units -- lone surrogates included -- that no `Char` can express.
fn string_of_code_units(units : ArrayView[Int]) -> String {
  let out = FixedArray::make(units.length() * 2, b'\x00')
  for i, unit in units {
    out[i * 2] = (unit & 0xFF).to_byte()
    out[i * 2 + 1] = ((unit >> 8) & 0xFF).to_byte()
  }
  out.unsafe_reinterpret_as_bytes().to_unchecked_string()
}

///|
/// The tests above compare the public entry points against the scalar ones,
/// which stay green even if the fast paths stopped being reached. This one
/// calls them directly: `encode_v128` must agree with the scalar encoder,
/// and `decode_v128` must accept a well-formed block rather than defer.
/// (Which path the entry points dispatch to is a `#cfg` decision; the
/// benchmarks are what would show a regression there.)
#cfg(any(target="native", target="wasm"))
test "the vector paths are engaged, not merely present" {
  let bytes = sample_bytes(48)
  let text = encode_scalar(bytes)
  @test.assert_eq(encode_v128(bytes), text)
  match decode_v128(text) {
    Some(decoded) => @test.assert_eq(decoded, bytes)
    None => fail("decode_v128 declined a well-formed block")
  }
}

///|
test "non-ASCII code units are rejected in every lane" {
  // The six above 0x00FF each have a low byte that is a valid hex
  // character, so a decoder that truncated code units instead of
  // saturating them would accept the input and decode it to the wrong
  // bytes. 0x00FF is the value saturation itself produces and 0x0000 the
  // value the signed lanes fold the high half onto, so both must be
  // rejected on their own account too.
  let aliasing_units = [
    0x0000, 0x00FF, 0x0130, 0x0161, 0xD830, 0xDC30, 0xFF41, 0x1030,
  ]
  // one whole block, so the planted code unit always lands in the fast path
  let body = encode_scalar(sample_bytes(16))
  for unit in aliasing_units {
    for position in 0..<body.length() {
      let units = Array::makei(body.length(), i => {
        if i == position {
          unit
        } else {
          body.unsafe_get(i).to_int()
        }
      })
      let corrupted = string_of_code_units(units)
      let raised = try {
        let _ = decode(corrupted)
        false
      } catch {
        Malformed(_) => true
      }
      assert_true(raised)
    }
  }
}

///|
test "vectorized paths honor view start and end offsets" {
  // A view can start and stop anywhere inside its backing buffer, and the
  // fast paths index from `start_offset`, so both bounds must be respected.
  // The padding on either side is itself valid hex, which means a base or
  // length mistake decodes successfully to the wrong bytes instead of
  // failing over to the scalar decoder and quietly producing the right
  // answer.
  for length in 32..<72 {
    for pad in 1..<5 {
      let padded = sample_bytes(pad + length + pad)
      let bytes_view = padded[pad:pad + length]
      @test.assert_eq(encode(bytes_view), encode_scalar(bytes_view))
      let body = encode_scalar(bytes_view)
      let sb = StringBuilder(size_hint=4 * (pad + body.length() + pad))
      for _ in 0..<pad {
        sb.write_char('a')
      }
      sb.write_string(body)
      for _ in 0..<pad {
        sb.write_char('b')
      }
      let text = sb.to_string()
      let text_view = text[pad:pad + body.length()]
      @test.assert_eq(decode(text_view), bytes_view.to_owned())
      @test.assert_eq(decode(text_view), decode_scalar(text_view))
    }
  }
}

///|
test "invalid characters at every lane position defer to the scalar error" {
  // a valid 64-digit body with one invalid character planted at each
  // position: the fast path must reject the block and the scalar decoder
  // must raise, regardless of which lane the invalid byte lands in
  let body = encode(sample_bytes(32))
  for position in 0..<body.length() {
    let sb = StringBuilder(size_hint=4 * body.length())
    for i in 0..<body.length() {
      sb.write_char(
        if i == position {
          'g'
        } else {
          body.unsafe_get(i).to_char().unwrap()
        },
      )
    }
    let corrupted = sb.to_string()
    let raised = try {
      let _ = decode(corrupted)
      false
    } catch {
      Malformed(_) => true
    }
    assert_true(raised)
  }
}
