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
/// Error type `Malformed`.
pub suberror Malformed {
  Malformed(BytesView)
} derive(@debug.Debug)

///|
fn drop_utf8_bom(bytes : BytesView, ignore_bom : Bool) -> BytesView {
  let bytes = if ignore_bom && bytes is [.. b"\xef\xbb\xbf", .. rest] {
    rest
  } else {
    bytes
  }
  bytes
}

///|
fn utf8_ascii8_bits(src : Bytes, offset : Int) -> Int {
  src.unsafe_get(offset).to_int() |
  src.unsafe_get(offset + 1).to_int() |
  src.unsafe_get(offset + 2).to_int() |
  src.unsafe_get(offset + 3).to_int() |
  src.unsafe_get(offset + 4).to_int() |
  src.unsafe_get(offset + 5).to_int() |
  src.unsafe_get(offset + 6).to_int() |
  src.unsafe_get(offset + 7).to_int()
}

///|
fn utf8_find_malformed(src : Bytes, src_offset : Int, src_length : Int) -> Int {
  let end = src_offset + src_length
  let mut i = src_offset
  while i + 8 <= end &&
        src.unsafe_get(i).to_int() < 0x80 &&
        (utf8_ascii8_bits(src, i) & 0x80) == 0 {
    i += 8
  }
  while i < end {
    let b = src.unsafe_get(i).to_int()
    if b < 0x80 {
      i += 1
    } else if b < 0xC2 {
      return i - src_offset
    } else if b < 0xE0 {
      if i + 1 >= end {
        return i - src_offset
      }
      let c1 = src.unsafe_get(i + 1).to_int()
      if c1 < 0x80 || c1 > 0xBF {
        return i - src_offset
      }
      i += 2
    } else if b < 0xF0 {
      if i + 2 >= end {
        return i - src_offset
      }
      let c1 = src.unsafe_get(i + 1).to_int()
      let c2 = src.unsafe_get(i + 2).to_int()
      let lo = if b == 0xE0 { 0xA0 } else { 0x80 }
      let hi = if b == 0xED { 0x9F } else { 0xBF }
      if c1 < lo || c1 > hi || c2 < 0x80 || c2 > 0xBF {
        return i - src_offset
      }
      i += 3
    } else if b < 0xF5 {
      if i + 3 >= end {
        return i - src_offset
      }
      let c1 = src.unsafe_get(i + 1).to_int()
      let c2 = src.unsafe_get(i + 2).to_int()
      let c3 = src.unsafe_get(i + 3).to_int()
      let lo = if b == 0xF0 { 0x90 } else { 0x80 }
      let hi = if b == 0xF4 { 0x8F } else { 0xBF }
      if c1 < lo || c1 > hi || c2 < 0x80 || c2 > 0xBF || c3 < 0x80 || c3 > 0xBF {
        return i - src_offset
      }
      i += 4
    } else {
      return i - src_offset
    }
  }
  -1
}
