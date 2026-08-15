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

// Specification tests for UTF-16 encoding and decoding.
//
// `decode` has more than one implementation and picks between them at
// run time. On the non-JS backends it first runs a V128 pre-scan
// (`utf16_needs_scalar_*_v128`) over the input looking for any
// surrogate code unit; if it finds none, it takes a vectorized fast
// path that reinterprets or byte-swaps the buffer wholesale, and
// otherwise it falls back to the scalar matcher. JS always takes the
// scalar path. So the same input can be decoded by three different
// pieces of code depending on backend and content, and they must all
// agree.
//
// The pre-scan is the delicate part: it decides correctness for the
// fast path, it processes sixteen bytes at a time with a scalar tail,
// and it runs from the *view's* start offset, which need not be even
// relative to the backing store. A pre-scan that missed a surrogate
// would hand a lone surrogate to the fast path and produce an
// ill-formed `String` rather than the `Malformed` the caller expects.
//
// So the oracle here is an independent code-unit walk written straight
// from the UTF-16 definition, and the generators are built to land on
// every boundary the pre-scan cares about: surrogates at each of the
// eight lanes of a block, runs whose length straddles sixteen bytes,
// odd byte lengths, and views at odd and even offsets.

// =====================================================================
// The oracle.
// =====================================================================

///|
/// Reads the code units of `bytes` in the given order, dropping a
/// trailing odd byte (which the callers handle separately).
fn units_of(bytes : BytesView, big_endian : Bool) -> Array[Int] {
  let out = []
  let mut index = 0
  while index + 1 < bytes.length() {
    let first = bytes[index].to_int()
    let second = bytes[index + 1].to_int()
    out.push(
      if big_endian {
        (first << 8) | second
      } else {
        (second << 8) | first
      },
    )
    index += 2
  }
  out
}

///|
fn is_high_surrogate(unit : Int) -> Bool {
  unit >= 0xD800 && unit <= 0xDBFF
}

///|
fn is_low_surrogate(unit : Int) -> Bool {
  unit >= 0xDC00 && unit <= 0xDFFF
}

///|
fn is_surrogate(unit : Int) -> Bool {
  unit >= 0xD800 && unit <= 0xDFFF
}

///|
/// The scalars a strict decoder must produce, or `None` together with
/// the *byte* offset at which it must report `Malformed`.
///
/// A well-formed UTF-16 sequence is a high surrogate followed by a low
/// one, or any single non-surrogate unit. Everything else -- a lone
/// surrogate of either kind, or a trailing odd byte -- is ill-formed.
fn oracle_strict(bytes : BytesView, big_endian : Bool) -> (Array[Int]?, Int) {
  let units = units_of(bytes, big_endian)
  let scalars = []
  let mut i = 0
  while i < units.length() {
    let unit = units[i]
    if is_high_surrogate(unit) &&
      i + 1 < units.length() &&
      is_low_surrogate(units[i + 1]) {
      scalars.push(((unit - 0xD800) << 10) + (units[i + 1] - 0xDC00) + 0x10000)
      i += 2
    } else if is_surrogate(unit) {
      return (None, i * 2)
    } else {
      scalars.push(unit)
      i += 1
    }
  }
  // an odd trailing byte is a truncated code unit
  if bytes.length() % 2 != 0 {
    return (None, units.length() * 2)
  }
  (Some(scalars), -1)
}

///|
/// The scalars a lossy decoder must produce: one U+FFFD per ill-formed
/// code unit, and one for a trailing odd byte.
fn oracle_lossy(bytes : BytesView, big_endian : Bool) -> Array[Int] {
  let units = units_of(bytes, big_endian)
  let scalars = []
  let mut i = 0
  while i < units.length() {
    let unit = units[i]
    if is_high_surrogate(unit) &&
      i + 1 < units.length() &&
      is_low_surrogate(units[i + 1]) {
      scalars.push(((unit - 0xD800) << 10) + (units[i + 1] - 0xDC00) + 0x10000)
      i += 2
    } else if is_surrogate(unit) {
      scalars.push(0xFFFD)
      i += 1
    } else {
      scalars.push(unit)
      i += 1
    }
  }
  if bytes.length() % 2 != 0 {
    scalars.push(0xFFFD)
  }
  scalars
}

///|
fn scalars_to_string(scalars : Array[Int]) -> String {
  String::from_array(scalars.map(Int::unsafe_to_char))
}

///|
/// What `decode` did: the text, or the length of the suffix it reported
/// as `Malformed`.
priv enum Outcome {
  Decoded(String)
  Rejected(Int)
}

///|
fn decode_outcome(bytes : BytesView, endianness : @utf16.Endian) -> Outcome {
  try @utf16.decode(bytes, endianness~) catch {
    Malformed(suffix) => Rejected(suffix.length())
  } noraise {
    text => Decoded(text)
  }
}

// =====================================================================
// Checking one input.
// =====================================================================

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

///|
/// Both decoders, in both byte orders, against the oracle.
fn check(bytes : BytesView) -> Bool {
  for big_endian in ([false, true] : Array[_]) {
    let endianness : @utf16.Endian = if big_endian { Big } else { Little }
    let (expected, bad_offset) = oracle_strict(bytes, big_endian)
    let strict_ok = match (decode_outcome(bytes, endianness), expected) {
      (Decoded(text), Some(scalars)) => text == scalars_to_string(scalars)
      (Rejected(length), None) => length == bytes.length() - bad_offset
      _ => false
    }
    guard strict_ok else { return false }
    guard @utf16.decode_lossy(bytes, endianness~) ==
      scalars_to_string(oracle_lossy(bytes, big_endian)) else {
      return false
    }
  }
  true
}

///|
/// The same input, but reached through a view whose start offset inside
/// the backing store is `padding` bytes in.
///
/// The V128 pre-scan indexes from the view's start offset, so an odd
/// offset shifts every sixteen-byte block relative to the code-unit
/// grid. Decoding must not notice.
fn check_at_offset(payload : Bytes, padding : Int) -> Bool {
  let prefix = Bytes::makei(padding, _ => b'\xAA')
  let padded = prefix + payload + b"\x55"
  check(padded[padding:padded.length() - 1])
}

// =====================================================================
// Test data.
// =====================================================================

///|
/// Code units on every boundary of the surrogate block, plus ordinary
/// BMP values. A pre-scan whose range test is wrong by one is wrong on
/// one of these.
let edge_units : Array[Int] = [
  0x0000, 0x0041, 0xD7FF, 0xD800, 0xD801, 0xDBFE, 0xDBFF, 0xDC00, 0xDC01, 0xDFFE,
  0xDFFF, 0xE000, 0xFEFF, 0xFFFD, 0xFFFF,
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
fn push_unit(out : Array[Byte], unit : Int, big_endian : Bool) -> Unit {
  if big_endian {
    out.push((unit >> 8).to_byte())
    out.push((unit & 0xFF).to_byte())
  } else {
    out.push((unit & 0xFF).to_byte())
    out.push((unit >> 8).to_byte())
  }
}

///|
/// Builds a byte string from `(kind, value)` chunks, written in
/// little-endian unit order (the properties then read it back in both
/// orders, so a chunk laid down as a surrogate pair one way is a pair
/// of unrelated units the other -- which is itself worth covering).
///
/// The kinds keep the corpus dense in the cases the pre-scan has to get
/// right: surrogates in isolation, well-formed pairs, long
/// surrogate-free runs that reach the vectorized path, and a lone
/// trailing byte that makes the length odd.
fn build_bytes(chunks : Array[(Int, Int)]) -> Bytes {
  let out = []
  for chunk in chunks {
    let (kind, value) = chunk
    match wrap_index(kind, 6) {
      // a boundary code unit
      0 =>
        push_unit(
          out,
          edge_units[wrap_index(value, edge_units.length())],
          false,
        )
      // a well-formed surrogate pair
      1 => {
        push_unit(out, 0xD800 + wrap_index(value, 0x400), false)
        push_unit(out, 0xDC00 + wrap_index(value / 0x400, 0x400), false)
      }
      // a lone surrogate
      2 => push_unit(out, 0xD800 + wrap_index(value, 0x800), false)
      // an arbitrary BMP unit
      3 => push_unit(out, wrap_index(value, 0x10000), false)
      // a surrogate-free run long enough to reach the V128 loop, of a
      // length that straddles the sixteen-byte block
      4 =>
        for i in 0..<(1 + wrap_index(value, 20)) {
          push_unit(out, 0x0041 + wrap_index(value + i, 0x100), false)
        }
      // a single byte, which makes the total length odd
      _ => out.push(wrap_index(value, 256).to_byte())
    }
  }
  Bytes::from_array(out)
}

// =====================================================================
// The specification.
// =====================================================================

///|
test "quickcheck: decode and decode_lossy match the code-unit oracle" {
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => check(build_bytes(chunks)),
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=2000,
  )
}

///|
test "quickcheck: decoding does not depend on the view's offset" {
  // Two paddings, so the pre-scan's sixteen-byte blocks land on both
  // parities of the code-unit grid.
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let payload = build_bytes(chunks)
      check_at_offset(payload, 0) &&
      check_at_offset(payload, 1) &&
      check_at_offset(payload, 2) &&
      check_at_offset(payload, 15)
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=1000,
  )
}

///|
test "every one- and two-byte input matches the oracle" {
  // 256 + 65536 inputs. This settles the whole single-code-unit space
  // in both byte orders: every lone surrogate, every BMP unit, and
  // every truncated unit.
  for b0 in 0..<256 {
    assert_true(check(Bytes::from_array([b0.to_byte()])))
    for b1 in 0..<256 {
      assert_true(check(Bytes::from_array([b0.to_byte(), b1.to_byte()])))
    }
  }
}

///|
test "every pair of boundary code units matches the oracle" {
  // All ordered pairs from the surrogate-boundary alphabet, in both
  // unit orders, which covers every combination of "high then low",
  // "high then not-low", "low then anything", and the non-surrogate
  // cases at the block edges.
  for first in edge_units {
    for second in edge_units {
      for big_endian in ([false, true] : Array[_]) {
        let out = []
        push_unit(out, first, big_endian)
        push_unit(out, second, big_endian)
        assert_true(check(Bytes::from_array(out)))
        // ...and the same pair with a trailing odd byte
        out.push(b'\x7F')
        assert_true(check(Bytes::from_array(out)))
      }
    }
  }
}

///|
test "a surrogate at every position of a vectorized block is caught" {
  // The pre-scan reads sixteen bytes -- eight code units -- at a time.
  // A surrogate hidden at any lane of any block must send the input to
  // the scalar path; if the pre-scan missed it, the fast path would
  // emit an ill-formed String instead of raising.
  for length in 1..<40 {
    for position in 0..<length {
      for unit in ([0xD800, 0xDBFF, 0xDC00, 0xDFFF] : Array[_]) {
        for big_endian in ([false, true] : Array[_]) {
          let out = []
          for i in 0..<length {
            push_unit(
              out,
              if i == position {
                unit
              } else {
                0x0041
              },
              big_endian,
            )
          }
          assert_true(check(Bytes::from_array(out)))
        }
      }
    }
  }
}

///|
test "surrogate-free runs of every length take the fast path correctly" {
  // The complementary case: nothing for the pre-scan to find, so the
  // vectorized path runs, with a scalar tail for the last few units.
  // Lengths sweep across several block boundaries.
  for length in 0..<40 {
    for big_endian in ([false, true] : Array[_]) {
      let out = []
      for i in 0..<length {
        push_unit(out, 0x0041 + i * 37, big_endian)
      }
      assert_true(check(Bytes::from_array(out)))
      // the same run with a trailing odd byte
      out.push(b'\x21')
      assert_true(check(Bytes::from_array(out)))
    }
  }
}

// =====================================================================
// Round-trips.
// =====================================================================

///|
test "quickcheck: encode then decode is the identity, in both byte orders" {
  @quickcheck.check(
    (text : String) => {
      let little = @utf16.encode(text)
      let big = @utf16.encode(text, endianness=Big)
      // the two orders are byte-swapped images of each other
      big.length() == little.length() &&
      little.length() == text.length() * 2 &&
      (for i in 0..<(little.length() / 2) {
        if little[i * 2] != big[i * 2 + 1] || little[i * 2 + 1] != big[i * 2] {
          break false
        }
      } nobreak {
        true
      }) &&
      @utf16.decode(little) == text &&
      @utf16.decode(big, endianness=Big) == text &&
      @utf16.decode_lossy(little) == text &&
      @utf16.decode_lossy(big, endianness=Big) == text
    },
    count=1000,
  )
}

///|
test "quickcheck: decode then encode is the identity on accepted bytes" {
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let bytes = build_bytes(chunks)
      for big_endian in ([false, true] : Array[_]) {
        let endianness : @utf16.Endian = if big_endian { Big } else { Little }
        match decode_outcome(bytes, endianness) {
          Decoded(text) =>
            if @utf16.encode(text, endianness~) != bytes {
              return false
            }
          Rejected(_) => ()
        }
      }
      true
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
    count=1000,
  )
}

///|
test "quickcheck: decode_lossy output is always well-formed" {
  @quickcheck.check(
    (chunks : Array[(Int, Int)]) => {
      let bytes = build_bytes(chunks)
      for big_endian in ([false, true] : Array[_]) {
        let endianness : @utf16.Endian = if big_endian { Big } else { Little }
        let text = @utf16.decode_lossy(bytes, endianness~)
        // whatever came out must survive a strict round-trip
        if @utf16.decode(@utf16.encode(text, endianness~), endianness~) != text {
          return false
        }
      }
      true
    },
    counterexample_context=chunks => hex(build_bytes(chunks)),
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
      for big_endian in ([false, true] : Array[_]) {
        let endianness : @utf16.Endian = if big_endian { Big } else { Little }
        let plain = @utf16.encode(text, endianness~)
        let marked = @utf16.encode(text, bom=true, endianness~)
        let mark = if big_endian { b"\xFE\xFF" } else { b"\xFF\xFE" }
        if marked != mark + plain {
          return false
        }
        if @utf16.decode(marked, ignore_bom=true, endianness~) != text {
          return false
        }
        if @utf16.decode_lossy(marked, ignore_bom=true, endianness~) != text {
          return false
        }
        // the default keeps it as U+FEFF
        if @utf16.decode(marked, endianness~) != "\u{FEFF}" + text {
          return false
        }
      }
      true
    },
    count=1000,
  )
}

///|
test "a bom is only stripped when it matches the byte order" {
  // U+FEFF little-endian is FF FE; read as big-endian those same bytes
  // are U+FFFE, which is not a mark and must survive.
  assert_eq(@utf16.decode(b"\xFF\xFE", ignore_bom=true), "")
  assert_eq(
    @utf16.decode(b"\xFF\xFE", ignore_bom=true, endianness=Big),
    "\u{FFFE}",
  )
  assert_eq(@utf16.decode(b"\xFE\xFF", ignore_bom=true, endianness=Big), "")
  assert_eq(@utf16.decode(b"\xFE\xFF", ignore_bom=true), "\u{FFFE}")
  // only the leading one goes
  assert_eq(@utf16.decode(b"\xFF\xFE\xFF\xFE", ignore_bom=true), "\u{FEFF}")
  // and a mark in the middle is data
  assert_eq(@utf16.decode(b"\x41\x00\xFF\xFE", ignore_bom=true), "A\u{FEFF}")
}
