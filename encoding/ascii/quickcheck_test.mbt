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

// Property-based tests for ASCII decoding: `decode` and `decode_lossy` must
// agree with a byte-by-byte model on arbitrary payloads and on views whose
// out-of-view neighbors are invalid bytes, for lengths on both sides of the
// SIMD crossover, with the `Malformed` view pointing at exactly the first
// invalid byte.

///|
/// A valid ASCII byte biased toward the range boundaries.
fn valid_byte(seed : Int) -> Byte {
  match seed & 0x7 {
    0 => b'\x00'
    1 => b'\x7F'
    2 => b'A'
    3 => b' '
    _ => ((seed >> 3) & 0x7F).to_byte()
  }
}

///|
/// Maps an arbitrary Int into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
fn model_decode_lossy(payload : Array[Byte]) -> String {
  let buf = StringBuilder(size_hint=payload.length())
  for b in payload {
    if b <= b'\x7F' {
      buf.write_char(b.to_int().unsafe_to_char())
    } else {
      buf.write_char('\u{FFFD}')
    }
  }
  buf.to_string()
}

///|
/// Embeds `payload` between runs of invalid `0xFF` bytes and returns the view
/// covering exactly `payload`, so any scan that reads beyond the view sees
/// bytes that must not influence the result.
fn poisoned_view(payload : Array[Byte], pad : Int) -> BytesView {
  let full : Array[Byte] = []
  for _ in 0..<pad {
    full.push(b'\xFF')
  }
  full.append(payload)
  for _ in 0..<16 {
    full.push(b'\xFF')
  }
  Bytes::from_array(full)[pad:pad + payload.length()]
}

///|
test "quickcheck: decode agrees with the byte model on valid payloads" {
  @quickcheck.check(count=300, (input : (Array[Int], Int)) => {
    let (seeds, pad_seed) = input
    let payload = seeds.map(valid_byte)
    let view = poisoned_view(payload, wrap_index(pad_seed, 17))
    let expected = model_decode_lossy(payload)
    try @ascii.decode(view) catch {
      Malformed(_) => false
    } noraise {
      decoded =>
        decoded == expected &&
        // A fully valid payload decodes identically through the lossy
        // decoder, and re-encoding restores the original bytes.
        @ascii.decode_lossy(view) == expected &&
        @ascii.encode(decoded) == Bytes::from_array(payload)
    }
  })
}

///|
test "quickcheck: Malformed points at the first invalid byte" {
  @quickcheck.check(count=300, (input : (Array[Int], Int, Int)) => {
    let (seeds, plant_seed, pad_seed) = input
    guard seeds.length() > 0 else { return true }
    let payload = seeds.map(valid_byte)
    let plant = wrap_index(plant_seed, payload.length())
    payload[plant] = if (plant_seed & 1) == 0 { b'\x80' } else { b'\xFF' }
    let view = poisoned_view(payload, wrap_index(pad_seed, 17))
    // The remaining view starts at the first invalid byte (the planted one,
    // unless the seeds already produced an earlier one).
    let mut first = plant
    for i, b in payload {
      if b > b'\x7F' {
        first = i
        break
      }
    }
    try @ascii.decode(view) catch {
      Malformed(rest) =>
        rest.to_owned() == Bytes::from_array(payload)[first:].to_owned() &&
        @ascii.decode_lossy(view) == model_decode_lossy(payload)
    } noraise {
      _ => false
    }
  })
}

///|
/// Exhaustively plants an invalid byte at every position for lengths around
/// the 16-byte SIMD blocks and the 64-byte crossover.
test "decode malformed position sweep" {
  let lengths = [1, 15, 16, 17, 31, 32, 63, 64, 65, 80, 96]
  for len in lengths {
    let clean = Array::make(len, b'A')
    let view = poisoned_view(clean, 3)
    assert_eq(try! @ascii.decode(view), "A".repeat(len))
    for pos in 0..<len {
      let payload = Array::make(len, b'A')
      payload[pos] = b'\x80'
      let view = poisoned_view(payload, 3)
      try @ascii.decode(view) catch {
        Malformed(rest) => assert_eq(rest.length(), len - pos)
      } noraise {
        _ => fail("expected Malformed at \{pos} for length \{len}")
      }
      assert_eq(@ascii.decode_lossy(view), model_decode_lossy(payload))
    }
  }
}
