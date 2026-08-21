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

// Randomized properties for the hex codec, checked against a character-level
// reference model. On the linear-memory backends the public functions take
// the vectorized paths for large-enough inputs, so these properties fuzz the
// SIMD code there and the scalar code elsewhere.

///|
fn reference_encode(bytes : Bytes) -> String {
  let digits = "0123456789abcdef"
  let sb = StringBuilder(size_hint=4 * bytes.length())
  for b in bytes {
    sb.write_char(digits.get_char(b.to_int() >> 4).unwrap())
    sb.write_char(digits.get_char(b.to_int() & 0x0F).unwrap())
  }
  sb.to_string()
}

///|
test "quickcheck: decode is the inverse of encode" {
  @quickcheck.check(
    (bytes : Bytes) => {
      let text = @hex.encode(bytes)
      text == reference_encode(bytes) &&
      text.length() == 2 * bytes.length() &&
      @hex.decode(text) == bytes
    },
    count=200,
  )
}

///|
test "quickcheck: decode accepts any case mixture and round-trips" {
  @quickcheck.check(
    (input : (Bytes, Array[Bool])) => {
      let (bytes, flips) = input
      let lower = @hex.encode(bytes)
      let sb = StringBuilder(size_hint=4 * lower.length())
      for i in 0..<lower.length() {
        let c = lower.unsafe_get(i).to_char().unwrap()
        let flip = flips.length() > 0 && flips[i % flips.length()]
        sb.write_char(
          if flip && c >= 'a' && c <= 'f' {
            (c.to_int() - 32).unsafe_to_char()
          } else {
            c
          },
        )
      }
      @hex.decode(sb.to_string()) == bytes
    },
    count=200,
  )
}

///|
test "quickcheck: corrupting any position makes decode raise" {
  @quickcheck.check(
    (input : (Bytes, UInt, UInt)) => {
      let (bytes, pos0, char0) = input
      guard bytes.length() > 0 else { return true }
      let text = @hex.encode(bytes)
      let pos = (pos0 % text.length().reinterpret_as_uint()).reinterpret_as_int()
      // any code unit outside the three hex ranges, spanning ASCII and
      // non-ASCII space
      let bad_pool : ReadOnlyArray[Char] = [
        'g', 'z', 'G', '/', ':', '@', '`', '\u{80}', '中', ' ',
      ]
      let bad = bad_pool[(char0 % bad_pool.length().reinterpret_as_uint()).reinterpret_as_int()]
      let sb = StringBuilder(size_hint=4 * text.length())
      for i in 0..<text.length() {
        sb.write_char(
          if i == pos {
            bad
          } else {
            text.unsafe_get(i).to_char().unwrap()
          },
        )
      }
      try {
        let _ = @hex.decode(sb.to_string())
        false
      } catch {
        Malformed(_) => true
      }
    },
    count=200,
  )
}

///|
test "quickcheck: odd-length inputs always raise" {
  @quickcheck.check(
    (bytes : Bytes) => {
      let text = @hex.encode(bytes) + "a"
      try {
        let _ = @hex.decode(text)
        false
      } catch {
        Malformed(_) => true
      }
    },
    count=100,
  )
}
