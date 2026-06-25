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
fn bytes_find_load_u64_le(bytes : FixedArray[Byte], offset : Int) -> UInt64 {
  let mut result = 0UL
  for i in 0..<8 {
    result = result | (bytes.unsafe_get(offset + i).to_uint64() << (i * 8))
  }
  result
}

///|
#coverage.skip
#intrinsic("%v128.v128_load")
#borrow(self)
fn FixedArray::v128_load(self : FixedArray[Byte], offset : Int) -> V128 {
  bytes_find_v128_make(
    bytes_find_load_u64_le(self, offset),
    bytes_find_load_u64_le(self, offset + 8),
  )
}

///|
fn bytes_find_byte_from(
  data : FixedArray[Byte],
  start : Int,
  end : Int,
  byte : Byte,
) -> Int {
  let byte_v = byte.i8x16_splat()
  let mut pos = start
  while pos + 16 <= end {
    let mask = data.v128_load(pos).i8x16_eq(byte_v).i8x16_bitmask()
    if mask != 0 {
      return pos + mask.ctz()
    }
    pos += 16
  }
  while pos < end {
    if data.unsafe_get(pos) == byte {
      return pos
    }
    pos += 1
  }
  -1
}

///|
fn bytes_find_index(target : BytesView, pattern : BytesView) -> Int? {
  let target_len = target.length()
  let pattern_len = pattern.length()
  if pattern_len == 0 {
    return Some(0)
  }
  if pattern_len > target_len {
    return None
  }
  let target_start = target.start_offset()
  let target_end = target_start + target_len
  let data = target.data().to_fixedarray()
  if pattern_len == 1 {
    let found = bytes_find_byte_from(
      data,
      target_start,
      target_end,
      pattern.unsafe_get(0),
    )
    if found < 0 {
      None
    } else {
      Some(found - target_start)
    }
  } else {
    let last_offset = pattern_len - 1
    let last_byte = pattern.unsafe_get(last_offset)
    let mut anchor_pos = target_start + last_offset
    while anchor_pos < target_end {
      let found = bytes_find_byte_from(data, anchor_pos, target_end, last_byte)
      if found < 0 {
        return None
      }
      let candidate = found - target_start - last_offset
      if bytes_find_match_range(target, pattern, candidate, 0, last_offset) {
        return Some(candidate)
      }
      anchor_pos = found + 1
    }
    None
  }
}
