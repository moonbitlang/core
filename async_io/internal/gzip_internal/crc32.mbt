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
fn make_crc32_table(slice : Int32) -> FixedArray[UInt32] {
  FixedArray::makei(256, fn(i) {
    let mut crc = i.reinterpret_as_uint()
    for _ in 0..<(8 * (slice + 1)) {
      crc = if (crc & 1U) == 0U { crc >> 1 } else { (crc >> 1) ^ 0xedb88320U }
    }
    crc
  })
}

///|
let crc32_table0 : FixedArray[UInt32] = make_crc32_table(0)

///|
let crc32_table1 : FixedArray[UInt32] = make_crc32_table(1)

///|
let crc32_table2 : FixedArray[UInt32] = make_crc32_table(2)

///|
let crc32_table3 : FixedArray[UInt32] = make_crc32_table(3)

///|
let crc32_table4 : FixedArray[UInt32] = make_crc32_table(4)

///|
let crc32_table5 : FixedArray[UInt32] = make_crc32_table(5)

///|
let crc32_table6 : FixedArray[UInt32] = make_crc32_table(6)

///|
let crc32_table7 : FixedArray[UInt32] = make_crc32_table(7)

///|
fn crc32_update(current : UInt32, chunk : BytesView) -> UInt32 {
  let len = chunk.length()
  for crc = current, i = 0; i + 8 <= len; {
    let first = crc ^ chunk.unsafe_read_uint32_le(i)
    let crc = crc32_table7.unsafe_get((first & 0xffU).reinterpret_as_int()) ^
      crc32_table6.unsafe_get(((first >> 8) & 0xffU).reinterpret_as_int()) ^
      crc32_table5.unsafe_get(((first >> 16) & 0xffU).reinterpret_as_int()) ^
      crc32_table4.unsafe_get((first >> 24).reinterpret_as_int()) ^
      crc32_table3.unsafe_get(chunk.unsafe_get(i + 4).to_int()) ^
      crc32_table2.unsafe_get(chunk.unsafe_get(i + 5).to_int()) ^
      crc32_table1.unsafe_get(chunk.unsafe_get(i + 6).to_int()) ^
      crc32_table0.unsafe_get(chunk.unsafe_get(i + 7).to_int())
    continue crc, i + 8
  } nobreak {
    for crc = crc, i = i; i < len; {
      let index = ((crc ^ chunk.unsafe_get(i).to_uint()) & 0xffU).reinterpret_as_int()
      let crc = crc32_table0.unsafe_get(index) ^ (crc >> 8)
      continue crc, i + 1
    } nobreak {
      crc
    }
  }
}
