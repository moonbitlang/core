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
pub suberror Malformed BytesView

///|
pub fn decode(
  bytes : BytesView,
  ignore_bom? : Bool = false,
) -> String raise Malformed {
  let bytes = if ignore_bom && bytes is [.. "\xef\xbb\xbf", .. rest] {
    rest
  } else {
    bytes
  }
  let t : FixedArray[Byte] = FixedArray::make(bytes.length() * 2, 0)
  let tlen = loop (0, bytes) {
    (tlen, []) => tlen
    (
      tlen,
      [
        _..=0x7F as b0,
        _..=0x7F as b1,
        _..=0x7F as b2,
        _..=0x7F as b3,
        _..=0x7F as b4,
        _..=0x7F as b5,
        _..=0x7F as b6,
        _..=0x7F as b7,
        .. rest,
      ],
    ) => {
      t.unsafe_set(tlen, b0)
      t.unsafe_set(tlen + 2, b1)
      t.unsafe_set(tlen + 4, b2)
      t.unsafe_set(tlen + 6, b3)
      t.unsafe_set(tlen + 8, b4)
      t.unsafe_set(tlen + 10, b5)
      t.unsafe_set(tlen + 12, b6)
      t.unsafe_set(tlen + 14, b7)
      continue (tlen + 16, rest)
    }
    (tlen, [0..=0x7F as b, .. rest]) => {
      t.unsafe_set(tlen, b)
      continue (tlen + 2, rest)
    }
    (tlen, [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest]) => {
      let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      t.unsafe_set(tlen, ch.to_byte())
      t.unsafe_set(tlen + 1, (ch >> 8).to_byte())
      continue (tlen + 2, rest)
    }
    (
      tlen,
      [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
      | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
      | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
      | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest],
    ) => {
      let ch = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      t.unsafe_set(tlen, ch.to_byte())
      t.unsafe_set(tlen + 1, (ch >> 8).to_byte())
      continue (tlen + 2, rest)
    }
    (
      tlen,
      [
        0xF0 as b0,
        0x90..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. rest,
      ]
      | [
        0xF1..=0xF3 as b0,
        0x80..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. rest,
      ]
      | [
        0xF4 as b0,
        0x80..=0x8F as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. rest,
      ],
    ) => {
      let ch = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      let chm = ch - 0x10000
      let ch1 = (chm >> 10) + 0xD800
      let ch2 = (chm & 0x3FF) + 0xDC00
      t.unsafe_set(tlen, ch1.to_byte())
      t.unsafe_set(tlen + 1, (ch1 >> 8).to_byte())
      t.unsafe_set(tlen + 2, ch2.to_byte())
      t.unsafe_set(tlen + 3, (ch2 >> 8).to_byte())
      continue (tlen + 4, rest)
    }
    (_, _ as bytes) => raise Malformed(bytes)
  }
  t.unsafe_reinterpret_as_bytes().to_unchecked_string(offset=0, length=tlen)
}

///|
/// 
/// References : 
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-5/#G40630
pub fn decode_lossy(bytes : BytesView, ignore_bom? : Bool = false) -> String {
  let bytes = if ignore_bom && bytes is [.. "\xef\xbb\xbf", .. rest] {
    rest
  } else {
    bytes
  }
  let t : FixedArray[Byte] = FixedArray::make(bytes.length() * 2, 0)
  let tlen = loop (0, bytes) {
    (tlen, []) => tlen
    (
      tlen,
      [
        _..=0x7F as b0,
        _..=0x7F as b1,
        _..=0x7F as b2,
        _..=0x7F as b3,
        _..=0x7F as b4,
        _..=0x7F as b5,
        _..=0x7F as b6,
        _..=0x7F as b7,
        .. rest,
      ],
    ) => {
      t.unsafe_set(tlen, b0)
      t.unsafe_set(tlen + 2, b1)
      t.unsafe_set(tlen + 4, b2)
      t.unsafe_set(tlen + 6, b3)
      t.unsafe_set(tlen + 8, b4)
      t.unsafe_set(tlen + 10, b5)
      t.unsafe_set(tlen + 12, b6)
      t.unsafe_set(tlen + 14, b7)
      continue (tlen + 16, rest)
    }
    (tlen, [0..=0x7F as b, .. rest]) => {
      t.unsafe_set(tlen, b)
      continue (tlen + 2, rest)
    }
    (tlen, [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest]) => {
      let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
      t.unsafe_set(tlen, ch.to_byte())
      t.unsafe_set(tlen + 1, (ch >> 8).to_byte())
      continue (tlen + 2, rest)
    }
    (
      tlen,
      [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
      | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
      | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
      | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest],
    ) => {
      let ch = ((b0.to_int() & 0x0F) << 12) |
        ((b1.to_int() & 0x3F) << 6) |
        (b2.to_int() & 0x3F)
      t.unsafe_set(tlen, ch.to_byte())
      t.unsafe_set(tlen + 1, (ch >> 8).to_byte())
      continue (tlen + 2, rest)
    }
    (
      tlen,
      [
        0xF0 as b0,
        0x90..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. rest,
      ]
      | [
        0xF1..=0xF3 as b0,
        0x80..=0xBF as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. rest,
      ]
      | [
        0xF4 as b0,
        0x80..=0x8F as b1,
        0x80..=0xBF as b2,
        0x80..=0xBF as b3,
        .. rest,
      ],
    ) => {
      let ch = ((b0.to_int() & 0x07) << 18) |
        ((b1.to_int() & 0x3F) << 12) |
        ((b2.to_int() & 0x3F) << 6) |
        (b3.to_int() & 0x3F)
      let chm = ch - 0x10000
      let ch1 = (chm >> 10) + 0xD800
      let ch2 = (chm & 0x3FF) + 0xDC00
      t.unsafe_set(tlen, ch1.to_byte())
      t.unsafe_set(tlen + 1, (ch1 >> 8).to_byte())
      t.unsafe_set(tlen + 2, ch2.to_byte())
      t.unsafe_set(tlen + 3, (ch2 >> 8).to_byte())
      continue (tlen + 4, rest)
    }
    // Invalid 3-byte sequences - replace with U_REP
    (tlen, [0xE0, 0xA0..=0xBF, .. rest])
    | (tlen, [0xE1..=0xEC, 0x80..=0xBF, .. rest])
    | (tlen, [0xED, 0x80..=0x9F, .. rest])
    | (tlen, [0xEE..=0xEF, 0x80..=0xBF, .. rest]) => {
      // Write U_REP (U+FFFD) in UTF-16LE: 0xFFFD
      t.unsafe_set(tlen, 0xFD)
      t.unsafe_set(tlen + 1, 0xFF)
      continue (tlen + 2, rest)
    }
    // Invalid 4-byte sequences - replace with U_REP
    (tlen, [0xF0, 0x90..=0xBF, 0x80..=0xBF, .. rest])
    | (tlen, [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF, .. rest])
    | (tlen, [0xF4, 0x80..=0x8F, 0x80..=0xBF, .. rest]) => {
      // Write U_REP (U+FFFD) in UTF-16LE: 0xFFFD
      t.unsafe_set(tlen, 0xFD)
      t.unsafe_set(tlen + 1, 0xFF)
      continue (tlen + 2, rest)
    }
    (tlen, [0xF0, 0x90..=0xBF, .. rest])
    | (tlen, [0xF1..=0xF3, 0x80..=0xBF, .. rest])
    | (tlen, [0xF4, 0x80..=0x8F, .. rest]) => {
      // Write U_REP (U+FFFD) in UTF-16LE: 0xFFFD
      t.unsafe_set(tlen, 0xFD)
      t.unsafe_set(tlen + 1, 0xFF)
      continue (tlen + 2, rest)
    }
    // Any other invalid byte - replace with U_REP
    (tlen, [_, .. rest]) => {
      // Write U_REP (U+FFFD) in UTF-16LE: 0xFFFD
      t.unsafe_set(tlen, 0xFD)
      t.unsafe_set(tlen + 1, 0xFF)
      continue (tlen + 2, rest)
    }
  }
  t.unsafe_reinterpret_as_bytes().to_unchecked_string(offset=0, length=tlen)
}
