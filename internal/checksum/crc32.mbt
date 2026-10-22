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
/// CRC-32 (IEEE 802.3 / ISO 3309, polynomial 0xEDB88320 reflected) as used by
/// gzip and ZIP. Shared primitive: `@checksum.crc32`.
fn build_crc32_table() -> FixedArray[UInt32] {
  let t = FixedArray::make(16 * 256, 0U)
  for n in 0..<256 {
    let mut c = n.reinterpret_as_uint()
    for _k in 0..<8 {
      c = if (c & 1) != 0 { 0xEDB88320 ^ (c >> 1) } else { c >> 1 }
    }
    t[n] = c
  }
  // Sixteen slices occupy 16 KiB. Slice k is the remainder after k further
  // zero bytes. Keep slice zero
  // compatible with the byte-at-a-time tail and incremental update_byte.
  for slice in 1..<16 {
    for n in 0..<256 {
      let previous = t[(slice - 1) * 256 + n]
      t[slice * 256 + n] = t[(previous & 0xFF).reinterpret_as_int()] ^
        (previous >> 8)
    }
  }
  t
}

///|
let crc32_table : FixedArray[UInt32] = build_crc32_table()

///|
/// Incremental CRC-32 accumulator. Feed bytes with `update` across as many
/// calls as you like, then read the result with `finish`; this is what a
/// streaming gzip/ZIP container uses so it never has to hold the whole input.
struct Crc32 {
  mut state : UInt32 // running CRC, before the final one's-complement
}

///|
/// Create a fresh CRC-32 accumulator.
pub fn Crc32::Crc32() -> Crc32 {
  { state: 0xFFFFFFFF, }
}

///|
/// Keep the larger kernel separate so short updates do not pay its register
/// save/restore cost. Called only when at least one full block is available.
fn crc32_blocks16(initial : UInt32, data : BytesView) -> UInt32 {
  let mut crc = initial
  let mut position = 0
  let bytes = data.data()
  let start = data.start_offset()
  while data.length() - position >= 16 {
    // SAFETY: the loop proves sixteen bytes remain inside the view. Its backing
    // offset plus position cannot overflow because the view lies inside Bytes.
    let offset = start + position
    let first = crc ^ bytes.unsafe_read_uint32_le(offset)
    // Each index selects one of sixteen 256-entry slices. Masked bytes and
    // unsigned shifts keep every index in the private 4096-entry table.
    crc = crc32_table.unsafe_get(3840 + (first & 0xFF).reinterpret_as_int()) ^
      crc32_table.unsafe_get(3584 + ((first >> 8) & 0xFF).reinterpret_as_int()) ^
      crc32_table.unsafe_get(3328 + ((first >> 16) & 0xFF).reinterpret_as_int()) ^
      crc32_table.unsafe_get(3072 + (first >> 24).reinterpret_as_int()) ^
      crc32_table.unsafe_get(2816 + bytes.unsafe_get(offset + 4).to_int()) ^
      crc32_table.unsafe_get(2560 + bytes.unsafe_get(offset + 5).to_int()) ^
      crc32_table.unsafe_get(2304 + bytes.unsafe_get(offset + 6).to_int()) ^
      crc32_table.unsafe_get(2048 + bytes.unsafe_get(offset + 7).to_int()) ^
      crc32_table.unsafe_get(1792 + bytes.unsafe_get(offset + 8).to_int()) ^
      crc32_table.unsafe_get(1536 + bytes.unsafe_get(offset + 9).to_int()) ^
      crc32_table.unsafe_get(1280 + bytes.unsafe_get(offset + 10).to_int()) ^
      crc32_table.unsafe_get(1024 + bytes.unsafe_get(offset + 11).to_int()) ^
      crc32_table.unsafe_get(768 + bytes.unsafe_get(offset + 12).to_int()) ^
      crc32_table.unsafe_get(512 + bytes.unsafe_get(offset + 13).to_int()) ^
      crc32_table.unsafe_get(256 + bytes.unsafe_get(offset + 14).to_int()) ^
      crc32_table.unsafe_get(bytes.unsafe_get(offset + 15).to_int())
    position = position + 16
  }
  crc
}

///|
/// Fold sixteen bytes at a time using independent table lookups, then handle
/// an eight-byte block and the scalar tail. Little-endian loads support
/// unaligned views on every backend, independently of host byte order.
pub fn Crc32::update(self : Crc32, data : BytesView) -> Unit {
  let mut crc = self.state
  // Short streaming updates need neither the wide kernel nor a backing Bytes
  // reference. Keep their original checked scalar path before acquiring it.
  guard data.length() >= 8 else {
    for i in 0..<data.length() {
      crc = crc32_table[((crc ^ data[i].to_uint()) & 0xFF).reinterpret_as_int()] ^
        (crc >> 8)
    }
    self.state = crc
    return
  }
  let mut position = 0
  let bytes = data.data()
  let start = data.start_offset()
  if data.length() >= 16 {
    crc = crc32_blocks16(crc, data)
    position = data.length() & 0xfffffff0
  }
  if data.length() - position >= 8 {
    // SAFETY: the condition proves eight bytes remain inside the view. Its backing
    // offset plus position cannot overflow because the view lies inside Bytes.
    let offset = start + position
    let first = crc ^ bytes.unsafe_read_uint32_le(offset)
    // Each index selects one of eight 256-entry slices. Masked bytes and
    // unsigned shifts keep every index in the first 2048 entries of the private table.
    crc = crc32_table.unsafe_get(1792 + (first & 0xFF).reinterpret_as_int()) ^
      crc32_table.unsafe_get(1536 + ((first >> 8) & 0xFF).reinterpret_as_int()) ^
      crc32_table.unsafe_get(1280 + ((first >> 16) & 0xFF).reinterpret_as_int()) ^
      crc32_table.unsafe_get(1024 + (first >> 24).reinterpret_as_int()) ^
      crc32_table.unsafe_get(768 + bytes.unsafe_get(offset + 4).to_int()) ^
      crc32_table.unsafe_get(512 + bytes.unsafe_get(offset + 5).to_int()) ^
      crc32_table.unsafe_get(256 + bytes.unsafe_get(offset + 6).to_int()) ^
      crc32_table.unsafe_get(bytes.unsafe_get(offset + 7).to_int())
    position = position + 8
  }
  for i in position..<data.length() {
    crc = crc32_table[((crc ^ data[i].to_uint()) & 0xFF).reinterpret_as_int()] ^
      (crc >> 8)
  }
  self.state = crc
}

///|
/// Fold a single byte into the running checksum. Lets a caller checksum bytes
/// it can only reach one at a time (e.g. read back from a `MutArrayView`
/// output) without materializing a `Bytes`.
pub fn Crc32::update_byte(self : Crc32, b : Byte) -> Unit {
  self.state = crc32_table[((self.state ^ b.to_uint()) & 0xFF).reinterpret_as_int()] ^
    (self.state >> 8)
}

///|
/// The CRC-32 of everything fed so far. Non-destructive: more `update`s may
/// follow.
pub fn Crc32::finish(self : Crc32) -> UInt32 {
  self.state ^ 0xFFFFFFFF
}

///|
/// Compute the CRC-32 checksum of `data` in one shot.
pub fn crc32(data : BytesView) -> UInt32 {
  let d = Crc32()
  d.update(data)
  d.finish()
}
