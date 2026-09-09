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

// Randomized properties for the percent codec, checked against independent
// reference models. `encode` replaces unpaired surrogates, so the round-trip
// property compares against a UTF-16 repair oracle rather than the input.

///|
/// Replaces every unpaired surrogate code unit with U+FFFD and keeps
/// everything else, including well-formed pairs, unchanged.
fn repair_utf16(text : String) -> String {
  let units = text.code_units()
  let out = StringBuilder(size_hint=2 * units.length())
  let mut i = 0
  while i < units.length() {
    let unit = units[i]
    if unit.is_leading_surrogate() &&
      i + 1 < units.length() &&
      units[i + 1].is_trailing_surrogate() {
      let code_point = 0x10000 +
        ((unit.to_int() - 0xD800) << 10) +
        (units[i + 1].to_int() - 0xDC00)
      out.write_char(code_point.unsafe_to_char())
      i += 2
    } else if unit.is_leading_surrogate() || unit.is_trailing_surrogate() {
      out.write_char('\u{FFFD}')
      i += 1
    } else {
      out.write_char(unit.to_int().unsafe_to_char())
      i += 1
    }
  }
  out.to_string()
}

///|
/// Escapes every byte of the repaired text's UTF-8 form that is not in the
/// unreserved set, one byte at a time.
fn reference_encode(text : String) -> String {
  let digits = "0123456789ABCDEF"
  let out = StringBuilder()
  for byte in @utf8.encode(repair_utf16(text)) {
    let n = byte.to_int()
    if n < 0x80 &&
      n.unsafe_to_char()
      is ('A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '.' | '_' | '~') {
      out.write_char(n.unsafe_to_char())
    } else {
      out.write_char('%')
      out.write_char(digits.get_char(n >> 4).unwrap())
      out.write_char(digits.get_char(n & 0x0F).unwrap())
    }
  }
  out.to_string()
}

///|
/// Strings whose code units are drawn from a small alphabet that mixes
/// unreserved characters, `%`, hexadecimal digits, non-ASCII characters and
/// both surrogate halves, so malformed escapes and unpaired surrogates are
/// frequent.
priv struct Spiky(String) derive(@debug.Debug)

///|
let spiky_alphabet : Array[Int] = [
  'a', 'Z', '0', '-', '~', '%', '2', 'F', 'g', ' ', '+', 'é', '中', 0xFEFF, 0xFFFD,
  0xD800, 0xDBFF, 0xDC00, 0xDFFF, 0x1F319,
]

///|
impl @quickcheck.Arbitrary for Spiky with fn arbitrary(size, state) {
  let len = if size == 0 { 0 } else { state.next_positive_int() % size }
  let out = StringBuilder()
  for _ in 0..<len {
    let unit = spiky_alphabet[state.next_positive_int() %
      spiky_alphabet.length()]
    out.write_char(unit.unsafe_to_char())
  }
  Spiky(out.to_string())
}

///|
impl @shrink.Shrink for Spiky with fn shrink(self) {
  // Drop one code unit at a time so a counterexample stays in the alphabet.
  let units = self.0.code_units()
  let candidates = []
  for i in 0..<units.length() {
    let out = StringBuilder()
    for j in 0..<units.length() {
      if j != i {
        out.write_char(units[j].to_int().unsafe_to_char())
      }
    }
    candidates.push(Spiky(out.to_string()))
  }
  candidates.iter()
}

///|
test "quickcheck: encode matches the reference and round-trips through decode" {
  @quickcheck.check(
    (text : String) => {
      let encoded = @percent.encode(text)
      encoded == reference_encode(text) &&
      encoded.iter().all(c => c.to_int() < 0x80) &&
      @percent.decode(encoded) == repair_utf16(text)
    },
    count=200,
  )
  @quickcheck.check(
    (input : Spiky) => {
      let text = input.0
      let encoded = @percent.encode(text)
      encoded == reference_encode(text) &&
      @percent.decode(encoded) == repair_utf16(text) &&
      @percent.decode_lossy(encoded) == repair_utf16(text)
    },
    count=300,
  )
}

///|
test "quickcheck: decode_lossy agrees with decode whenever decode succeeds" {
  @quickcheck.check(
    (input : Spiky) => {
      try @percent.decode(input.0) catch {
        Malformed(reported) => reported == input.0
      } noraise {
        decoded => @percent.decode_lossy(input.0) == decoded
      }
    },
    count=300,
  )
}

///|
test "quickcheck: decoding never changes text without escapes" {
  @quickcheck.check(
    (input : Spiky) => {
      let text = input.0
      text.contains("%") ||
      (@percent.decode(text) == text && @percent.decode_lossy(text) == text)
    },
    count=200,
  )
}
