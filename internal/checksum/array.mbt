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
/// Fold a borrowed byte array view into the checksum. Copy in bounded chunks
/// to use the wide byte kernel without retaining the view.
#cfg(any(target="native", target="wasm"))
pub fn Crc32::update_array(checksum : Crc32, data : ArrayView[Byte]) -> Unit {
  let mut position = 0
  while position < data.length() {
    let end = position + (data.length() - position).min(4096)
    checksum.update(Bytes::from_array(data[position:end]))
    position = end
  }
}

///|
/// Fold a borrowed byte array view into the checksum. Copy in bounded chunks
/// to use the wide byte kernel without retaining the view.
#cfg(any(target="native", target="wasm"))
pub fn Adler32::update_array(
  checksum : Adler32,
  data : ArrayView[Byte],
) -> Unit {
  let mut position = 0
  while position < data.length() {
    let end = position + (data.length() - position).min(4096)
    checksum.update(Bytes::from_array(data[position:end]))
    position = end
  }
}

///|
/// Fold a borrowed byte array view into the checksum. The view is not retained.
#cfg(not(any(target="native", target="wasm")))
pub fn Crc32::update_array(self : Crc32, data : ArrayView[Byte]) -> Unit {
  let mut crc = self.state
  let mut position = 0
  while data.length() - position >= 8 {
    // SAFETY: the loop leaves eight bytes inside the view. Every table index
    // selects one of the first eight 256-entry slices.
    crc = crc32_table.unsafe_get(
        1792 +
        ((crc & 0xFF).reinterpret_as_int() ^ data.unsafe_get(position).to_int()),
      ) ^
      crc32_table.unsafe_get(
        1536 +
        (
          ((crc >> 8) & 0xFF).reinterpret_as_int() ^
          data.unsafe_get(position + 1).to_int()
        ),
      ) ^
      crc32_table.unsafe_get(
        1280 +
        (
          ((crc >> 16) & 0xFF).reinterpret_as_int() ^
          data.unsafe_get(position + 2).to_int()
        ),
      ) ^
      crc32_table.unsafe_get(
        1024 +
        (
          (crc >> 24).reinterpret_as_int() ^
          data.unsafe_get(position + 3).to_int()
        ),
      ) ^
      crc32_table.unsafe_get(768 + data.unsafe_get(position + 4).to_int()) ^
      crc32_table.unsafe_get(512 + data.unsafe_get(position + 5).to_int()) ^
      crc32_table.unsafe_get(256 + data.unsafe_get(position + 6).to_int()) ^
      crc32_table.unsafe_get(data.unsafe_get(position + 7).to_int())
    position += 8
  }
  for i in position..<data.length() {
    crc = crc32_table.unsafe_get(
        ((crc ^ data.unsafe_get(i).to_uint()) & 0xFF).reinterpret_as_int(),
      ) ^
      (crc >> 8)
  }
  self.state = crc
}

///|
/// Fold a borrowed byte array view into the checksum. The view is not retained.
#cfg(not(any(target="native", target="wasm")))
pub fn Adler32::update_array(self : Adler32, data : ArrayView[Byte]) -> Unit {
  let mut a = self.a
  let mut b = self.b
  let mut start = 0
  while start < data.length() {
    let end = start + (data.length() - start).min(ADLER_BLOCK_SIZE)
    let mut a_sum = 0
    let mut weighted_sum = 0
    let mut i = start
    let groups_end = adler_groups_end(start, end)
    while i < groups_end {
      // SAFETY: i is below the end of the whole eight-byte groups.
      let packed = adler_group_sums(
        data.unsafe_get(i).to_int(),
        data.unsafe_get(i + 1).to_int(),
        data.unsafe_get(i + 2).to_int(),
        data.unsafe_get(i + 3).to_int(),
        data.unsafe_get(i + 4).to_int(),
        data.unsafe_get(i + 5).to_int(),
        data.unsafe_get(i + 6).to_int(),
        data.unsafe_get(i + 7).to_int(),
      )
      a_sum += a
      weighted_sum += packed >> 16
      a += packed & 0xFFFF
      i += 8
    }
    b += (a_sum << 3) + weighted_sum
    while i < end {
      a += data.unsafe_get(i).to_int()
      b += a
      i += 1
    }
    a %= ADLER_MODULUS
    b %= ADLER_MODULUS
    start = end
  }
  self.a = a
  self.b = b
}
