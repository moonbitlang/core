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
fn unsafe_fixedarray_uint16_to_string(buffer : FixedArray[UInt16]) -> String = "%string.unsafe_from_uint16_fixedarray"

///|
#borrow(src)
#intrinsic("%utf16.len_from_utf8")
fn utf16_len_from_utf8(src : Bytes, src_offset : Int, src_length : Int) -> Int {
  let end = src_offset + src_length
  for index = src_offset, len = 0; index < end; {
    let byte = src.unsafe_get(index).to_int()
    if byte < 0x80 {
      continue index + 1, len + 1
    } else if byte < 0xC0 {
      continue index + 1, len
    } else if byte < 0xF0 {
      continue index + 1, len + 1
    } else {
      continue index + 1, len + 2
    }
  } nobreak {
    len
  }
}

///|
#borrow(src, dst)
#intrinsic("%utf8.decode_into_utf16")
fn utf8_decode_into_utf16(
  src : Bytes,
  src_offset : Int,
  src_length : Int,
  dst : FixedArray[UInt16],
  dst_offset : Int,
) -> Int {
  let view = src[src_offset:src_offset + src_length]
  for written = 0, bytes = view {
    match (written, bytes) {
      (written, []) => break written
      (
        written,
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
        dst.unsafe_set(dst_offset + written, Int::to_uint16(b0.to_int()))
        dst.unsafe_set(dst_offset + written + 1, Int::to_uint16(b1.to_int()))
        dst.unsafe_set(dst_offset + written + 2, Int::to_uint16(b2.to_int()))
        dst.unsafe_set(dst_offset + written + 3, Int::to_uint16(b3.to_int()))
        dst.unsafe_set(dst_offset + written + 4, Int::to_uint16(b4.to_int()))
        dst.unsafe_set(dst_offset + written + 5, Int::to_uint16(b5.to_int()))
        dst.unsafe_set(dst_offset + written + 6, Int::to_uint16(b6.to_int()))
        dst.unsafe_set(dst_offset + written + 7, Int::to_uint16(b7.to_int()))
        continue written + 8, rest
      }
      (written, [0..=0x7F as b, .. rest]) => {
        dst.unsafe_set(dst_offset + written, Int::to_uint16(b.to_int()))
        continue written + 1, rest
      }
      (written, [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest]) => {
        let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
        dst.unsafe_set(dst_offset + written, Int::to_uint16(ch))
        continue written + 1, rest
      }
      (
        written,
        [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
        | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
        | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
        | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest],
      ) => {
        let ch = ((b0.to_int() & 0x0F) << 12) |
          ((b1.to_int() & 0x3F) << 6) |
          (b2.to_int() & 0x3F)
        dst.unsafe_set(dst_offset + written, Int::to_uint16(ch))
        continue written + 1, rest
      }
      (
        written,
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
        let ch = ch - 0x10000
        dst.unsafe_set(
          dst_offset + written,
          Int::to_uint16((ch >> 10) + 0xD800),
        )
        dst.unsafe_set(
          dst_offset + written + 1,
          Int::to_uint16((ch & 0x3FF) + 0xDC00),
        )
        continue written + 2, rest
      }
      (_, malformed) => break -(malformed.start_offset() - src_offset + 1)
    }
  }
}

///|
#borrow(src, dst)
#intrinsic("%utf8.decode_lossy_into_utf16")
fn utf8_decode_lossy_into_utf16(
  src : Bytes,
  src_offset : Int,
  src_length : Int,
  dst : FixedArray[UInt16],
  dst_offset : Int,
) -> Int {
  let view = src[src_offset:src_offset + src_length]
  for written = 0, bytes = view {
    match (written, bytes) {
      (written, []) => break written
      (
        written,
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
        dst.unsafe_set(dst_offset + written, Int::to_uint16(b0.to_int()))
        dst.unsafe_set(dst_offset + written + 1, Int::to_uint16(b1.to_int()))
        dst.unsafe_set(dst_offset + written + 2, Int::to_uint16(b2.to_int()))
        dst.unsafe_set(dst_offset + written + 3, Int::to_uint16(b3.to_int()))
        dst.unsafe_set(dst_offset + written + 4, Int::to_uint16(b4.to_int()))
        dst.unsafe_set(dst_offset + written + 5, Int::to_uint16(b5.to_int()))
        dst.unsafe_set(dst_offset + written + 6, Int::to_uint16(b6.to_int()))
        dst.unsafe_set(dst_offset + written + 7, Int::to_uint16(b7.to_int()))
        continue written + 8, rest
      }
      (written, [0..=0x7F as b, .. rest]) => {
        dst.unsafe_set(dst_offset + written, Int::to_uint16(b.to_int()))
        continue written + 1, rest
      }
      (written, [0xC2..=0xDF as b0, 0x80..=0xBF as b1, .. rest]) => {
        let ch = ((b0.to_int() & 0x1F) << 6) | (b1.to_int() & 0x3F)
        dst.unsafe_set(dst_offset + written, Int::to_uint16(ch))
        continue written + 1, rest
      }
      (
        written,
        [0xE0 as b0, 0xA0..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
        | [0xE1..=0xEC as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest]
        | [0xED as b0, 0x80..=0x9F as b1, 0x80..=0xBF as b2, .. rest]
        | [0xEE..=0xEF as b0, 0x80..=0xBF as b1, 0x80..=0xBF as b2, .. rest],
      ) => {
        let ch = ((b0.to_int() & 0x0F) << 12) |
          ((b1.to_int() & 0x3F) << 6) |
          (b2.to_int() & 0x3F)
        dst.unsafe_set(dst_offset + written, Int::to_uint16(ch))
        continue written + 1, rest
      }
      (
        written,
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
        let ch = ch - 0x10000
        dst.unsafe_set(
          dst_offset + written,
          Int::to_uint16((ch >> 10) + 0xD800),
        )
        dst.unsafe_set(
          dst_offset + written + 1,
          Int::to_uint16((ch & 0x3FF) + 0xDC00),
        )
        continue written + 2, rest
      }
      (written, [0xE0, 0xA0..=0xBF, .. rest])
      | (written, [0xE1..=0xEC, 0x80..=0xBF, .. rest])
      | (written, [0xED, 0x80..=0x9F, .. rest])
      | (written, [0xEE..=0xEF, 0x80..=0xBF, .. rest])
      | (written, [0xF0, 0x90..=0xBF, 0x80..=0xBF, .. rest])
      | (written, [0xF1..=0xF3, 0x80..=0xBF, 0x80..=0xBF, .. rest])
      | (written, [0xF4, 0x80..=0x8F, 0x80..=0xBF, .. rest])
      | (written, [0xF0, 0x90..=0xBF, .. rest])
      | (written, [0xF1..=0xF3, 0x80..=0xBF, .. rest])
      | (written, [0xF4, 0x80..=0x8F, .. rest]) => {
        dst.unsafe_set(dst_offset + written, 0xFFFD)
        continue written + 1, rest
      }
      (written, [_, .. rest]) => {
        dst.unsafe_set(dst_offset + written, 0xFFFD)
        continue written + 1, rest
      }
    }
  }
}

///|
/// Decode input bytes/text into structured output.
pub fn decode(
  bytes : BytesView,
  ignore_bom? : Bool = false,
) -> String raise Malformed {
  let bytes = drop_utf8_bom(bytes, ignore_bom)
  let input = bytes.data()
  let src_offset = bytes.start_offset()
  let src_length = bytes.length()
  let dst = FixedArray::make(
    utf16_len_from_utf8(input, src_offset, src_length),
    (0 : UInt16),
  )
  match utf8_decode_into_utf16(input, src_offset, src_length, dst, 0) {
    written if written >= 0 => unsafe_fixedarray_uint16_to_string(dst)
    err => raise Malformed(bytes[-err - 1:])
  }
}

///|
///
/// References :
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-5/#G40630
pub fn decode_lossy(bytes : BytesView, ignore_bom? : Bool = false) -> String {
  let bytes = drop_utf8_bom(bytes, ignore_bom)
  let input = bytes.data()
  let src_offset = bytes.start_offset()
  let src_length = bytes.length()
  let dst = FixedArray::make(src_length * 2, (0 : UInt16))
  let written = match
    utf8_decode_into_utf16(input, src_offset, src_length, dst, 0) {
    ok if ok >= 0 => ok
    _ => utf8_decode_lossy_into_utf16(input, src_offset, src_length, dst, 0)
  }
  let result = FixedArray::make(written, (0 : UInt16))
  result.unsafe_blit(0, dst, 0, written)
  unsafe_fixedarray_uint16_to_string(result)
}
