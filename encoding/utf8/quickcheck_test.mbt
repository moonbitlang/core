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

// Specification tests for UTF-8 encoding and decoding.
//
// The suite is differential: it pins `decode`, `decode_lossy`, and
// `encode` against an oracle transcribed *from the standard*, not from
// the implementation —
//
//   * `lead_class` is a literal transcription of Table 3-7 of the
//     Unicode 16.0 core spec (the well-formed UTF-8 byte sequences);
//   * `scan` implements D93b, the "maximal subpart of an ill-formed
//     subsequence" rule that fixes how many U+FFFD a lossy decoder
//     must emit and where a strict decoder must report the failure;
//   * `push_scalar` is the closed-form encoder from the same chapter.
//
// This matters because the package has two independent implementations
// selected by target — a hand-written scanner (`decode_nonjs.mbt`) and
// the platform `TextDecoder`/`TextEncoder` (`decode_js.mbt`) — and both
// the scanner and the encoder additionally carry `#intrinsic`
// annotations, so a backend may substitute its own code generation for
// the MoonBit body entirely. An oracle written against the spec is the
// only thing all of those must agree with.
//
// Coverage is exhaustive where the input space allows (every 1- and
// 2-byte string, every 3- and 4-byte string over a boundary alphabet)
// and property-based elsewhere, with generators that deliberately
// concentrate on near-miss sequences: boundary bytes, scalars at the
// class edges, and truncated encodings.

// =====================================================================
// Oracle: Unicode 16.0 core spec, Table 3-7 and D93b.
// =====================================================================

///|
/// Table 3-7, transposed to "given the first byte, what is the total
/// length and what range must the *second* byte lie in". Every byte
/// after the second is always `80..BF`.
///
/// Returns `(length, lo, hi)`, with `length == 0` for a byte that
/// begins no well-formed sequence at all (`80..C1` and `F5..FF`) and
/// `length == 1` for ASCII, where the range is unused.
fn lead_class(b0 : Int) -> (Int, Int, Int) {
  if b0 <= 0x7F {
    (1, 0, 0)
  } else if b0 < 0xC2 {
    (0, 0, 0) // continuation bytes, and the overlong leads C0/C1
  } else if b0 <= 0xDF {
    (2, 0x80, 0xBF)
  } else if b0 == 0xE0 {
    (3, 0xA0, 0xBF) // excludes the overlong three-byte forms
  } else if b0 <= 0xEC {
    (3, 0x80, 0xBF)
  } else if b0 == 0xED {
    (3, 0x80, 0x9F) // excludes the surrogate block D800..DFFF
  } else if b0 <= 0xEF {
    (3, 0x80, 0xBF)
  } else if b0 == 0xF0 {
    (4, 0x90, 0xBF) // excludes the overlong four-byte forms
  } else if b0 <= 0xF3 {
    (4, 0x80, 0xBF)
  } else if b0 == 0xF4 {
    (4, 0x80, 0x8F) // excludes everything above U+10FFFF
  } else {
    (0, 0, 0) // F5..FF
  }
}

///|
/// Scans one sequence starting at `index`.
///
/// Returns `(scalar, consumed)` for a well-formed sequence, or
/// `(-1, consumed)` when the bytes at `index` are ill-formed — in which
/// case `consumed` is the length of the *maximal subpart* (D93b): the
/// longest prefix that is still a prefix of some well-formed sequence,
/// and at least one byte. That is exactly the quantity a conformant
/// lossy decoder replaces with a single U+FFFD.
fn scan(bytes : ArrayView[Byte], index : Int) -> (Int, Int) {
  let b0 = bytes[index].to_int()
  let (length, lo, hi) = lead_class(b0)
  if length == 0 {
    return (-1, 1)
  }
  if length == 1 {
    return (b0, 1)
  }
  for k in 1..<length {
    if index + k >= bytes.length() {
      return (-1, k) // truncated by the end of input
    }
    let bk = bytes[index + k].to_int()
    let (lo, hi) = if k == 1 { (lo, hi) } else { (0x80, 0xBF) }
    if bk < lo || bk > hi {
      return (-1, k) // the first k bytes were the maximal subpart
    }
  }
  let mut scalar = if length == 2 {
    b0 & 0x1F
  } else if length == 3 {
    b0 & 0x0F
  } else {
    b0 & 0x07
  }
  for k in 1..<length {
    scalar = (scalar << 6) | (bytes[index + k].to_int() & 0x3F)
  }
  (scalar, length)
}

///|
/// The scalars a strict decoder must produce, or `None` together with
/// the offset at which it must report `Malformed`.
fn oracle_strict(bytes : ArrayView[Byte]) -> (Array[Int]?, Int) {
  let scalars = []
  let mut index = 0
  while index < bytes.length() {
    let (scalar, consumed) = scan(bytes, index)
    if scalar < 0 {
      return (None, index)
    }
    scalars.push(scalar)
    index += consumed
  }
  (Some(scalars), -1)
}

///|
/// The scalars a lossy decoder must produce: one U+FFFD per maximal
/// subpart of each ill-formed subsequence.
fn oracle_lossy(bytes : ArrayView[Byte]) -> Array[Int] {
  let scalars = []
  let mut index = 0
  while index < bytes.length() {
    let (scalar, consumed) = scan(bytes, index)
    scalars.push(if scalar < 0 { 0xFFFD } else { scalar })
    index += consumed
  }
  scalars
}

///|
/// The closed-form UTF-8 encoder for a single scalar.
fn push_scalar(out : Array[Byte], scalar : Int) -> Unit {
  if scalar <= 0x7F {
    out.push(scalar.to_byte())
  } else if scalar <= 0x7FF {
    out.push((0xC0 | (scalar >> 6)).to_byte())
    out.push((0x80 | (scalar & 0x3F)).to_byte())
  } else if scalar <= 0xFFFF {
    out.push((0xE0 | (scalar >> 12)).to_byte())
    out.push((0x80 | ((scalar >> 6) & 0x3F)).to_byte())
    out.push((0x80 | (scalar & 0x3F)).to_byte())
  } else {
    out.push((0xF0 | (scalar >> 18)).to_byte())
    out.push((0x80 | ((scalar >> 12) & 0x3F)).to_byte())
    out.push((0x80 | ((scalar >> 6) & 0x3F)).to_byte())
    out.push((0x80 | (scalar & 0x3F)).to_byte())
  }
}

///|
/// Materializes oracle scalars as a `String`, so results can be
/// compared with `decode`'s output directly.
fn scalars_to_string(scalars : Array[Int]) -> String {
  String::from_array(scalars.map(Int::unsafe_to_char))
}

///|
/// What `decode` did, flattened into a value the properties can compare
/// against the oracle: the decoded text, or the length of the suffix it
/// reported as `Malformed`.
priv enum Outcome {
  Decoded(String)
  Rejected(Int)
}

///|
fn decode_outcome(bytes : BytesView) -> Outcome {
  try @utf8.decode(bytes) catch {
    Malformed(suffix) => Rejected(suffix.length())
  } noraise {
    text => Decoded(text)
  }
}

// =====================================================================
// Test data.
// =====================================================================

///|
/// Every byte value that sits on a boundary of some range in Table 3-7,
/// plus one value strictly inside each range. A decoder that is wrong
/// by one anywhere in the table is wrong on one of these.
let edge_bytes : Array[Byte] = [
  b'\x00', b'\x41', b'\x7F', b'\x80', b'\x81', b'\x8F', b'\x90', b'\x9F', b'\xA0',
  b'\xBF', b'\xC0', b'\xC1', b'\xC2', b'\xD0', b'\xDF', b'\xE0', b'\xE1', b'\xEC',
  b'\xED', b'\xEE', b'\xEF', b'\xF0', b'\xF1', b'\xF3', b'\xF4', b'\xF5', b'\xFF',
]

///|
/// Scalars on the boundaries of the 1/2/3/4-byte length classes, around
/// the surrogate block, and at the U+10FFFF ceiling.
let edge_scalars : Array[Int] = [
  0x00, 0x01, 0x7F, 0x80, 0x7FF, 0x800, 0xD7FF, 0xE000, 0xFFFD, 0xFEFF, 0xFFFF, 0x10000,
  0x3FFFF, 0x40000, 0xFFFFF, 0x100000, 0x10FFFE, 0x10FFFF,
]

///|
/// Maps an arbitrary `Int` into `0..<modulus` without discarding cases.
fn wrap_index(value : Int, modulus : Int) -> Int {
  let r = value % modulus
  if r < 0 {
    r + modulus
  } else {
    r
  }
}

///|
/// An arbitrary scalar value: any code point except the surrogates.
fn wrap_scalar(value : Int) -> Int {
  let cp = wrap_index(value, 0x110000 - 0x800)
  if cp >= 0xD800 {
    cp + 0x800
  } else {
    cp
  }
}

///|
/// Builds a byte string out of `(kind, value)` chunks. The kinds are
/// chosen so that the generated corpus is dense in *near misses* —
/// sequences that are one byte or one bit away from well-formed — which
/// is where a decoder's range checks actually get decided. Purely
/// random bytes would almost never produce a valid multi-byte sequence
/// at all, and would exercise only the "reject immediately" path.
fn build_bytes(chunks : Array[(Int, Int)]) -> Bytes {
  let out = []
  for chunk in chunks {
    let (kind, value) = chunk
    match wrap_index(kind, 5) {
      // a byte from the boundary alphabet
      0 => out.push(edge_bytes[wrap_index(value, edge_bytes.length())])
      // a well-formed sequence for a boundary scalar
      1 =>
        push_scalar(out, edge_scalars[wrap_index(value, edge_scalars.length())])
      // a well-formed sequence for an arbitrary scalar
      2 => push_scalar(out, wrap_scalar(value))
      // a well-formed sequence with its last byte chopped off
      3 => {
        let head = []
        push_scalar(
          head,
          edge_scalars[wrap_index(value, edge_scalars.length())],
        )
        for i in 0..<(head.length() - 1) {
          out.push(head[i])
        }
      }
      // an arbitrary raw byte
      _ => out.push(wrap_index(value, 256).to_byte())
    }
  }
  Bytes::from_array(out)
}

///|
/// Renders bytes as hex, so a shrunk counterexample is readable.
fn hex(bytes : BytesView) -> String {
  let digits : ReadOnlyArray[Char] = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
  ]
  let out = StringBuilder()
  for b in bytes {
    let v = b.to_int()
    out.write_char(digits[v >> 4])
    out.write_char(digits[v & 0xF])
    out.write_char(' ')
  }
  out.to_string()
}

// =====================================================================
// The specification, checked against the oracle.
// =====================================================================

///|
/// `decode` accepts exactly the well-formed strings, returns exactly the
/// scalars Table 3-7 assigns to them, and — when it rejects — reports a
/// suffix beginning at the first ill-formed byte.
fn check_strict(bytes : Bytes) -> Bool {
  let array = bytes.to_array()
  let (expected, bad_offset) = oracle_strict(array)
  match (decode_outcome(bytes), expected) {
    (Decoded(text), Some(scalars)) => text == scalars_to_string(scalars)
    // the payload is the input from the first ill-formed byte on
    (Rejected(length), None) => length == bytes.length() - bad_offset
    // accepted an ill-formed string, or rejected a well-formed one
    _ => false
  }
}

///|
/// `decode_lossy` is total, and replaces each maximal subpart of an
/// ill-formed subsequence with exactly one U+FFFD (D93b).
fn check_lossy(bytes : Bytes) -> Bool {
  @utf8.decode_lossy(bytes) == scalars_to_string(oracle_lossy(bytes.to_array()))
}

///|
test "quickcheck: decode and decode_lossy match the Table 3-7 oracle" {
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let bytes = build_bytes(chunks)
      check_strict(bytes) && check_lossy(bytes)
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=2000,
  )
}

///|
test "every one- and two-byte string matches the oracle" {
  // 256 + 65536 inputs: this settles the whole of Table 3-7's first two
  // columns exhaustively, including every overlong lead (C0/C1), every
  // out-of-range lead (F5..FF), every bare continuation byte, and every
  // truncated two-byte prefix.
  for b0 in 0..<256 {
    let one = Bytes::from_array([b0.to_byte()])
    assert_true(check_strict(one))
    assert_true(check_lossy(one))
    for b1 in 0..<256 {
      let two = Bytes::from_array([b0.to_byte(), b1.to_byte()])
      assert_true(check_strict(two))
      assert_true(check_lossy(two))
    }
  }
}

///|
test "every three- and four-byte string over the boundary alphabet matches the oracle" {
  // The full 3- and 4-byte spaces are too large to enumerate, but every
  // range boundary in Table 3-7 is represented in `edge_bytes`, so a
  // decoder whose bounds are off by one — or which forgets the
  // surrogate (ED 80..9F) or overlong (E0 A0..BF, F0 90..BF) carve-outs
  // — fails here.
  for b0 in edge_bytes {
    for b1 in edge_bytes {
      for b2 in edge_bytes {
        let three = Bytes::from_array([b0, b1, b2])
        assert_true(check_strict(three))
        assert_true(check_lossy(three))
        for b3 in edge_bytes {
          let four = Bytes::from_array([b0, b1, b2, b3])
          assert_true(check_strict(four))
          assert_true(check_lossy(four))
        }
      }
    }
  }
}

// =====================================================================
// Round-trips.
// =====================================================================

///|
test "quickcheck: encode then decode is the identity on strings" {
  @quickcheck.check(
    (text : String) => @utf8.decode(@utf8.encode(text)) == text,
    count=1000,
  )
}

///|
test "quickcheck: decode then encode is the identity on accepted bytes" {
  // UTF-8 is a canonical encoding: each scalar has exactly one
  // well-formed representation. So `decode` must be injective, which
  // this round-trip pins — a decoder that accepted an overlong form
  // would re-encode it to different (shorter) bytes and fail here.
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let bytes = build_bytes(chunks)
      match decode_outcome(bytes) {
        Decoded(text) => @utf8.encode(text) == bytes
        Rejected(_) => true
      }
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=1000,
  )
}

///|
test "quickcheck: decode_lossy output is always well-formed" {
  // Whatever `decode_lossy` returns must itself survive a strict
  // round-trip — a lossy decoder that emitted an unpaired surrogate
  // would break here.
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let text = @utf8.decode_lossy(build_bytes(chunks))
      @utf8.decode(@utf8.encode(text)) == text
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=1000,
  )
}

///|
test "quickcheck: decode_lossy agrees with decode whenever decode succeeds" {
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let bytes = build_bytes(chunks)
      match decode_outcome(bytes) {
        Decoded(text) => @utf8.decode_lossy(bytes) == text
        Rejected(_) => true
      }
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=1000,
  )
}

///|
test "every scalar round-trips, with the byte length Table 3-6 prescribes" {
  fn expected_length(scalar : Int) -> Int {
    if scalar <= 0x7F {
      1
    } else if scalar <= 0x7FF {
      2
    } else if scalar <= 0xFFFF {
      3
    } else {
      4
    }
  }

  fn check(scalar : Int) -> Unit raise {
    let text = String::from_array([scalar.unsafe_to_char()])
    let bytes = @utf8.encode(text)
    assert_eq(bytes.length(), expected_length(scalar))
    assert_eq(
      bytes,
      Bytes::from_array(
        {
          let o = []
          push_scalar(o, scalar)
          o
        },
      ),
    )
    assert_eq(@utf8.decode(bytes), text)
    assert_eq(@utf8.decode_lossy(bytes), text)
  }

  for scalar in edge_scalars {
    check(scalar)
  }
  // A strided sweep of the whole scalar range. The stride is coprime
  // with every class width, so it lands inside all four length classes
  // and on both sides of the surrogate block.
  for scalar = 0; scalar < 0x110000; scalar = scalar + 743 {
    if scalar < 0xD800 || scalar > 0xDFFF {
      check(scalar)
    }
  }
}

///|
test "quickcheck: encoding is a homomorphism from concatenation" {
  // Decoding has no state that crosses a scalar boundary, so splitting
  // a string anywhere and encoding the halves separately must give the
  // same bytes — and the concatenation must decode back to the whole.
  @quickcheck.check(
    (input : (String, String)) => {
      let (a, b) = input
      let joined = a + b
      let bytes = @utf8.encode(a) + @utf8.encode(b)
      @utf8.encode(joined) == bytes && @utf8.decode(bytes) == joined
    },
    count=1000,
  )
}

// =====================================================================
// The byte order mark.
// =====================================================================

///|
test "quickcheck: bom emission and ignore_bom are inverse" {
  @quickcheck.check(
    (text : String) => {
      let plain = @utf8.encode(text)
      let marked = @utf8.encode(text, bom=true)
      // `bom=true` prepends exactly the three-byte BOM
      marked == b"\xEF\xBB\xBF" + plain &&
      // `ignore_bom=true` strips it back off, and only ever one
      @utf8.decode(marked, ignore_bom=true) == text &&
      @utf8.decode_lossy(marked, ignore_bom=true) == text &&
      // ...while the default preserves it as U+FEFF
      @utf8.decode(marked) == "\u{FEFF}" + text &&
      @utf8.decode_lossy(marked) == "\u{FEFF}" + text
    },
    count=1000,
  )
}

///|
test "ignore_bom only strips a leading bom" {
  let bom = "\u{FEFF}"
  // a BOM in the middle is data, not a mark
  let text = "a\u{FEFF}b"
  assert_eq(@utf8.decode(@utf8.encode(text), ignore_bom=true), text)
  // two leading BOMs: exactly one is stripped
  let doubled = bom + bom + "x"
  assert_eq(@utf8.decode(@utf8.encode(doubled), ignore_bom=true), bom + "x")
  // the BOM alone
  assert_eq(@utf8.decode(@utf8.encode(bom), ignore_bom=true), "")
  assert_eq(@utf8.decode(@utf8.encode(bom)), bom)
  // an empty input is not a truncated BOM
  assert_eq(@utf8.decode(b"", ignore_bom=true), "")
  assert_eq(@utf8.decode_lossy(b"", ignore_bom=true), "")
  // a truncated BOM is ill-formed, not a mark
  assert_true(decode_outcome(b"\xEF\xBB") is Rejected(_))
  assert_eq(@utf8.decode_lossy(b"\xEF\xBB", ignore_bom=true), "\u{FFFD}")
}

// =====================================================================
// Truncation.
// =====================================================================

///|
test "quickcheck: every proper prefix of a sequence is rejected at its start" {
  // Chopping the last byte off a well-formed string must fail, and must
  // point at the start of the sequence that lost the byte — not at the
  // point where the scanner noticed. This is the offset half of the
  // `Malformed` contract, which `check_strict` pins only in aggregate.
  @quickcheck.check(
    (input : (Int, Int)) => {
      let (index, _) = input
      let scalar = edge_scalars[wrap_index(index, edge_scalars.length())]
      let tail = []
      push_scalar(tail, scalar)
      if tail.length() == 1 {
        return true // ASCII has no proper prefix to truncate
      }
      let prefix = @utf8.encode("abc")
      for drop in 1..<tail.length() {
        let bytes = prefix +
          Bytes::from_array(tail[0:tail.length() - drop].to_owned())
        guard decode_outcome(bytes) is Rejected(length) else { return false }
        // the suffix starts at the lead byte, three ASCII bytes in
        guard length == bytes.length() - 3 else { return false }
        // and lossy replaces the whole truncated remainder with one U+FFFD
        guard @utf8.decode_lossy(bytes) == "abc\u{FFFD}" else { return false }
      }
      true
    },
    count=200,
  )
}

///|
test "quickcheck: a well-formed string decodes the same from any split point" {
  // `decode` is applied to a `BytesView`; decoding a view must not
  // depend on the view's offset within its backing store.
  @quickcheck.check(
    (input : (String, Int)) => {
      let bytes = @utf8.encode(input.0)
      let padded = b"\xFF\xFE\xFD" + bytes + b"\xFF"
      let view = padded[3:padded.length() - 1]
      @utf8.decode(view) == input.0 && @utf8.decode_lossy(view) == input.0
    },
    count=500,
  )
}
