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
// Lengths sweep every residue modulo three (encode) and modulo sixteen
// (decode), so every block-count, tail, and padding combination is covered.

///|
/// Deterministic pseudo-random bytes, so the corpus covers all 256 byte
/// values and every sextet class rather than a repeated pattern.
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
  for length in 0..<200 {
    let bytes = sample_bytes(length)
    @test.assert_eq(encode(bytes), encode_scalar(bytes))
    @test.assert_eq(
      encode(bytes, padding=false),
      encode_scalar(bytes, padding=false),
    )
  }
}

///|
test "decode agrees with the scalar decoder across all block counts" {
  for length in 0..<200 {
    let bytes = sample_bytes(length)
    for padding in [true, false] {
      let text = encode(bytes, padding~)
      let decoded = decode(text)
      @test.assert_eq(decoded, bytes)
      @test.assert_eq(decoded, decode_scalar(text, false))
    }
  }
}

///|
/// The lengths above cover every tail and block-count residue, but only the
/// sizes below run enough vector iterations to expose an error that
/// accumulates across blocks.
test "encode and decode agree with the scalar paths on large inputs" {
  for length in [1023, 1024, 1025, 4096, 65536] {
    let bytes = sample_bytes(length)
    let text = encode(bytes)
    @test.assert_eq(text, encode_scalar(bytes))
    @test.assert_eq(decode(text), bytes)
    @test.assert_eq(decode(text), decode_scalar(text, false))
  }
}

///|
/// Views carry a non-zero start offset into the backing string, which the
/// vector loads have to account for.
test "decode handles a non-zero view offset" {
  for length in 40..<80 {
    let bytes = sample_bytes(length)
    let text = "!!!" + encode(bytes)
    let view = text[3:]
    @test.assert_eq(decode(view), bytes)
    @test.assert_eq(decode(view), decode_scalar(view, false))
  }
}

///|
/// Every position of every canonical encoding is corrupted with a character
/// the fast path must reject, and the result must match the scalar decoder
/// exactly, error for error.
test "corrupted input matches the scalar decoder" {
  let intruders = ['$', ' ', '=', '\u{4e2d}', '\u{0}', '\u{ff}']
  for length in 30..<40 {
    let text = encode(sample_bytes(length))
    let chars = text.to_array()
    for position in 0..<chars.length() {
      let original = chars[position]
      for intruder in intruders {
        chars[position] = intruder
        let mutated = String::from_array(chars)
        let fast = decode(mutated) catch { _ => b"\xff\xfe malformed" }
        let slow = decode_scalar(mutated, false) catch {
          _ => b"\xff\xfe malformed"
        }
        @test.assert_eq(fast, slow)
      }
      chars[position] = original
    }
  }
}
