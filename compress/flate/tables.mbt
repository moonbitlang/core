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
const WINDOW_SIZE : Int32 = 32768

///|
const MAX_NUM_LIT : Int32 = 286

///|
const MAX_NUM_DIST : Int32 = 30

///|
const NUM_CODES : Int32 = 19

///|
/// Order in which code-length code lengths are stored (RFC 1951 §3.2.7).
let code_order : FixedArray[Int32] = [
  16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
]

// ---- length / distance symbol tables ----

///|
let len_base : FixedArray[Int32] = [
  3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83,
  99, 115, 131, 163, 195, 227, 258,
]

///|
let len_extra : FixedArray[Int32] = [
  0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5,
  5, 0,
]

///|
fn build_length_code_info_table() -> FixedArray[Int32] {
  FixedArray::makei(29, index => (len_base[index] << 3) | len_extra[index])
}

///|
/// Packed `(base << 3) | extra_bits` data shared directly by both decoders.
let length_code_info_table : FixedArray[Int32] = build_length_code_info_table()

///|
fn build_len_to_idx() -> FixedArray[Int32] {
  let m = FixedArray::make(259, 0)
  for idx in 0..<29 {
    let lo = len_base[idx]
    let hi = if idx + 1 < 29 { len_base[idx + 1] } else { 259 }
    m.fill(idx, start=lo, end=hi)
  }
  m
}

///|
let len_to_idx : FixedArray[Int32] = build_len_to_idx()

///|
let dist_base : FixedArray[Int32] = [
  1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193, 257, 385, 513, 769,
  1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
]

///|
let dist_extra : FixedArray[Int32] = [
  0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11,
  12, 12, 13, 13,
]

///|
fn build_distance_code_info_table() -> FixedArray[Int32] {
  FixedArray::makei(MAX_NUM_DIST, symbol => {
    (dist_base[symbol] << 4) | dist_extra[symbol]
  })
}

///|
/// Packed `(base << 4) | extra_bits` data shared directly by both decoders.
let distance_code_info_table : FixedArray[Int32] = build_distance_code_info_table()

///|
fn build_dist_to_idx() -> FixedArray[Byte] {
  let slots = FixedArray::make(256, b'\x00')
  for symbol in 0..<16 {
    slots.fill(
      symbol.to_byte(),
      start=dist_base[symbol] - 1,
      end=dist_base[symbol + 1] - 1,
    )
  }
  slots
}

///|
/// Distance minus one to symbol for distances 1..256.
let dist_to_idx : FixedArray[Byte] = build_dist_to_idx()

///|
/// Requires 1 <= distance <= WINDOW_SIZE. Like libdeflate's small offset map,
/// reuse the first 256 entries for larger distances by scaling down by 128
/// and adding 14 symbols. Unsigned subtraction and shift select 0 or 7 without
/// a branch; a signed right shift would give the wrong result above 256.
#inline
fn dist_index(distance : Int32) -> Int32 {
  let shift = ((256U - distance.reinterpret_as_uint()) >> 29).reinterpret_as_int()
  dist_to_idx[(distance - 1) >> shift].to_int() + (shift << 1)
}

// ---- fixed Huffman literal/length codes (MSB-first) ----

///|
fn build_fixed_litlen_info() -> FixedArray[Int32] {
  FixedArray::makei(288, symbol => {
    match symbol {
      _ if symbol < 144 => ((0x30 + symbol) << 4) | 8
      _ if symbol < 256 => ((0x190 + (symbol - 144)) << 4) | 9
      _ if symbol < 280 => ((symbol - 256) << 4) | 7
      _ => ((0xC0 + (symbol - 280)) << 4) | 8
    }
  })
}

///|
/// Pack each fixed literal/length code as `(code << 4) | bit_length` so the
/// module initializer and fixed-block hot path need only one table.
let fixed_litlen_info : FixedArray[Int32] = build_fixed_litlen_info()

///|
/// Unpacked fixed literal/length tables (bit-reversed code words and code
/// lengths) for the unified token writer.
fn build_fixed_ll_val() -> FixedArray[UInt32] {
  fixed_litlen_info.map(info => {
    reverse_bits((info >> 4).reinterpret_as_uint(), info & 0xF)
  })
}

///|
let fixed_ll_val : FixedArray[UInt32] = build_fixed_ll_val()

///|
fn build_fixed_ll_len() -> FixedArray[Int32] {
  fixed_litlen_info.map(info => info & 0xF)
}

///|
let fixed_ll_len : FixedArray[Int32] = build_fixed_ll_len()

///|
/// Bit-reversed 5-bit fixed distance codes (code = distance symbol).
fn build_fixed_dist_val() -> FixedArray[UInt32] {
  FixedArray::makei(MAX_NUM_DIST, d => reverse_bits(d.reinterpret_as_uint(), 5))
}

///|
let fixed_dist_val : FixedArray[UInt32] = build_fixed_dist_val()

///|
/// The fixed distance codes are all 5 bits.
let fixed_dist_len : FixedArray[Int32] = FixedArray::make(MAX_NUM_DIST, 5)

// ---- bit reversal ----

///|
/// Bit-reversal of a byte (DEFLATE Huffman codes are read MSB-first while the
/// bit stream is filled LSB-first, so codes are looked up bit-reversed).
fn reverse8(x : Byte) -> Byte {
  rev8tab[x.to_int()].to_byte()
}

///|
fn reverse16(x : UInt32) -> UInt32 {
  rev8tab[((x & 0xff00) >> 8).reinterpret_as_int()] |
  (rev8tab[(x & 0xff).reinterpret_as_int()] << 8)
}

///|
let rev8tab : FixedArray[UInt32] = [
  0, 128, 64, 192, 32, 160, 96, 224, 16, 144, 80, 208, 48, 176, 112, 240, 8, 136,
  72, 200, 40, 168, 104, 232, 24, 152, 88, 216, 56, 184, 120, 248, 4, 132, 68, 196,
  36, 164, 100, 228, 20, 148, 84, 212, 52, 180, 116, 244, 12, 140, 76, 204, 44, 172,
  108, 236, 28, 156, 92, 220, 60, 188, 124, 252, 2, 130, 66, 194, 34, 162, 98, 226,
  18, 146, 82, 210, 50, 178, 114, 242, 10, 138, 74, 202, 42, 170, 106, 234, 26, 154,
  90, 218, 58, 186, 122, 250, 6, 134, 70, 198, 38, 166, 102, 230, 22, 150, 86, 214,
  54, 182, 118, 246, 14, 142, 78, 206, 46, 174, 110, 238, 30, 158, 94, 222, 62, 190,
  126, 254, 1, 129, 65, 193, 33, 161, 97, 225, 17, 145, 81, 209, 49, 177, 113, 241,
  9, 137, 73, 201, 41, 169, 105, 233, 25, 153, 89, 217, 57, 185, 121, 249, 5, 133,
  69, 197, 37, 165, 101, 229, 21, 149, 85, 213, 53, 181, 117, 245, 13, 141, 77, 205,
  45, 173, 109, 237, 29, 157, 93, 221, 61, 189, 125, 253, 3, 131, 67, 195, 35, 163,
  99, 227, 19, 147, 83, 211, 51, 179, 115, 243, 11, 139, 75, 203, 43, 171, 107, 235,
  27, 155, 91, 219, 59, 187, 123, 251, 7, 135, 71, 199, 39, 167, 103, 231, 23, 151,
  87, 215, 55, 183, 119, 247, 15, 143, 79, 207, 47, 175, 111, 239, 31, 159, 95, 223,
  63, 191, 127, 255,
]
