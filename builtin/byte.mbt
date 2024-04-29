// Copyright 2024 International Digital Economy Academy
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

pub fn op_equal(self : Byte, that : Byte) -> Bool {
  return self.to_int() == that.to_int()
}

pub fn compare(self : Byte, that : Byte) -> Int {
  return self.to_int().compare(that.to_int())
}

fn alphabet(self : Int) -> String {
  match self {
    0 => "0"
    1 => "1"
    2 => "2"
    3 => "3"
    4 => "4"
    5 => "5"
    6 => "6"
    7 => "7"
    8 => "8"
    9 => "9"
    10 => "A"
    11 => "B"
    12 => "C"
    13 => "D"
    14 => "E"
    15 => "F"
    _ => abort("impossible")
  }
}

pub fn to_string(self : Byte) -> String {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  "b'\\x\(hi)\(lo)'"
}

pub fn debug_write(self : Byte, buf : Buffer) -> Unit {
  let i = self.to_int()
  let hi = alphabet(i / 16)
  let lo = alphabet(i % 16)
  buf.write_string("b'\\x")
  buf.write_string(hi)
  buf.write_string(lo)
  buf.write_string("'")
}

/// Convert an `Int` within 0-255 (0x00-0xFF) to `Byte`.
/// 
/// @alert unsafe "Panics if the input value is out of range."
pub fn Byte::from_int(v: Int) -> Byte {
  // TODO: this should be a intrinsics
  match v {
    0x00 => { b'\x00' }
    0x01 => { b'\x01' }
    0x02 => { b'\x02' }
    0x03 => { b'\x03' }
    0x04 => { b'\x04' }
    0x05 => { b'\x05' }
    0x06 => { b'\x06' }
    0x07 => { b'\x07' }
    0x08 => { b'\x08' }
    0x09 => { b'\x09' }
    0x0a => { b'\x0a' }
    0x0b => { b'\x0b' }
    0x0c => { b'\x0c' }
    0x0d => { b'\x0d' }
    0x0e => { b'\x0e' }
    0x0f => { b'\x0f' }
    0x10 => { b'\x10' }
    0x11 => { b'\x11' }
    0x12 => { b'\x12' }
    0x13 => { b'\x13' }
    0x14 => { b'\x14' }
    0x15 => { b'\x15' }
    0x16 => { b'\x16' }
    0x17 => { b'\x17' }
    0x18 => { b'\x18' }
    0x19 => { b'\x19' }
    0x1a => { b'\x1a' }
    0x1b => { b'\x1b' }
    0x1c => { b'\x1c' }
    0x1d => { b'\x1d' }
    0x1e => { b'\x1e' }
    0x1f => { b'\x1f' }
    0x20 => { b'\x20' }
    0x21 => { b'\x21' }
    0x22 => { b'\x22' }
    0x23 => { b'\x23' }
    0x24 => { b'\x24' }
    0x25 => { b'\x25' }
    0x26 => { b'\x26' }
    0x27 => { b'\x27' }
    0x28 => { b'\x28' }
    0x29 => { b'\x29' }
    0x2a => { b'\x2a' }
    0x2b => { b'\x2b' }
    0x2c => { b'\x2c' }
    0x2d => { b'\x2d' }
    0x2e => { b'\x2e' }
    0x2f => { b'\x2f' }
    0x30 => { b'\x30' }
    0x31 => { b'\x31' }
    0x32 => { b'\x32' }
    0x33 => { b'\x33' }
    0x34 => { b'\x34' }
    0x35 => { b'\x35' }
    0x36 => { b'\x36' }
    0x37 => { b'\x37' }
    0x38 => { b'\x38' }
    0x39 => { b'\x39' }
    0x3a => { b'\x3a' }
    0x3b => { b'\x3b' }
    0x3c => { b'\x3c' }
    0x3d => { b'\x3d' }
    0x3e => { b'\x3e' }
    0x3f => { b'\x3f' }
    0x40 => { b'\x40' }
    0x41 => { b'\x41' }
    0x42 => { b'\x42' }
    0x43 => { b'\x43' }
    0x44 => { b'\x44' }
    0x45 => { b'\x45' }
    0x46 => { b'\x46' }
    0x47 => { b'\x47' }
    0x48 => { b'\x48' }
    0x49 => { b'\x49' }
    0x4a => { b'\x4a' }
    0x4b => { b'\x4b' }
    0x4c => { b'\x4c' }
    0x4d => { b'\x4d' }
    0x4e => { b'\x4e' }
    0x4f => { b'\x4f' }
    0x50 => { b'\x50' }
    0x51 => { b'\x51' }
    0x52 => { b'\x52' }
    0x53 => { b'\x53' }
    0x54 => { b'\x54' }
    0x55 => { b'\x55' }
    0x56 => { b'\x56' }
    0x57 => { b'\x57' }
    0x58 => { b'\x58' }
    0x59 => { b'\x59' }
    0x5a => { b'\x5a' }
    0x5b => { b'\x5b' }
    0x5c => { b'\x5c' }
    0x5d => { b'\x5d' }
    0x5e => { b'\x5e' }
    0x5f => { b'\x5f' }
    0x60 => { b'\x60' }
    0x61 => { b'\x61' }
    0x62 => { b'\x62' }
    0x63 => { b'\x63' }
    0x64 => { b'\x64' }
    0x65 => { b'\x65' }
    0x66 => { b'\x66' }
    0x67 => { b'\x67' }
    0x68 => { b'\x68' }
    0x69 => { b'\x69' }
    0x6a => { b'\x6a' }
    0x6b => { b'\x6b' }
    0x6c => { b'\x6c' }
    0x6d => { b'\x6d' }
    0x6e => { b'\x6e' }
    0x6f => { b'\x6f' }
    0x70 => { b'\x70' }
    0x71 => { b'\x71' }
    0x72 => { b'\x72' }
    0x73 => { b'\x73' }
    0x74 => { b'\x74' }
    0x75 => { b'\x75' }
    0x76 => { b'\x76' }
    0x77 => { b'\x77' }
    0x78 => { b'\x78' }
    0x79 => { b'\x79' }
    0x7a => { b'\x7a' }
    0x7b => { b'\x7b' }
    0x7c => { b'\x7c' }
    0x7d => { b'\x7d' }
    0x7e => { b'\x7e' }
    0x7f => { b'\x7f' }
    0x80 => { b'\x80' }
    0x81 => { b'\x81' }
    0x82 => { b'\x82' }
    0x83 => { b'\x83' }
    0x84 => { b'\x84' }
    0x85 => { b'\x85' }
    0x86 => { b'\x86' }
    0x87 => { b'\x87' }
    0x88 => { b'\x88' }
    0x89 => { b'\x89' }
    0x8a => { b'\x8a' }
    0x8b => { b'\x8b' }
    0x8c => { b'\x8c' }
    0x8d => { b'\x8d' }
    0x8e => { b'\x8e' }
    0x8f => { b'\x8f' }
    0x90 => { b'\x90' }
    0x91 => { b'\x91' }
    0x92 => { b'\x92' }
    0x93 => { b'\x93' }
    0x94 => { b'\x94' }
    0x95 => { b'\x95' }
    0x96 => { b'\x96' }
    0x97 => { b'\x97' }
    0x98 => { b'\x98' }
    0x99 => { b'\x99' }
    0x9a => { b'\x9a' }
    0x9b => { b'\x9b' }
    0x9c => { b'\x9c' }
    0x9d => { b'\x9d' }
    0x9e => { b'\x9e' }
    0x9f => { b'\x9f' }
    0xa0 => { b'\xa0' }
    0xa1 => { b'\xa1' }
    0xa2 => { b'\xa2' }
    0xa3 => { b'\xa3' }
    0xa4 => { b'\xa4' }
    0xa5 => { b'\xa5' }
    0xa6 => { b'\xa6' }
    0xa7 => { b'\xa7' }
    0xa8 => { b'\xa8' }
    0xa9 => { b'\xa9' }
    0xaa => { b'\xaa' }
    0xab => { b'\xab' }
    0xac => { b'\xac' }
    0xad => { b'\xad' }
    0xae => { b'\xae' }
    0xaf => { b'\xaf' }
    0xb0 => { b'\xb0' }
    0xb1 => { b'\xb1' }
    0xb2 => { b'\xb2' }
    0xb3 => { b'\xb3' }
    0xb4 => { b'\xb4' }
    0xb5 => { b'\xb5' }
    0xb6 => { b'\xb6' }
    0xb7 => { b'\xb7' }
    0xb8 => { b'\xb8' }
    0xb9 => { b'\xb9' }
    0xba => { b'\xba' }
    0xbb => { b'\xbb' }
    0xbc => { b'\xbc' }
    0xbd => { b'\xbd' }
    0xbe => { b'\xbe' }
    0xbf => { b'\xbf' }
    0xc0 => { b'\xc0' }
    0xc1 => { b'\xc1' }
    0xc2 => { b'\xc2' }
    0xc3 => { b'\xc3' }
    0xc4 => { b'\xc4' }
    0xc5 => { b'\xc5' }
    0xc6 => { b'\xc6' }
    0xc7 => { b'\xc7' }
    0xc8 => { b'\xc8' }
    0xc9 => { b'\xc9' }
    0xca => { b'\xca' }
    0xcb => { b'\xcb' }
    0xcc => { b'\xcc' }
    0xcd => { b'\xcd' }
    0xce => { b'\xce' }
    0xcf => { b'\xcf' }
    0xd0 => { b'\xd0' }
    0xd1 => { b'\xd1' }
    0xd2 => { b'\xd2' }
    0xd3 => { b'\xd3' }
    0xd4 => { b'\xd4' }
    0xd5 => { b'\xd5' }
    0xd6 => { b'\xd6' }
    0xd7 => { b'\xd7' }
    0xd8 => { b'\xd8' }
    0xd9 => { b'\xd9' }
    0xda => { b'\xda' }
    0xdb => { b'\xdb' }
    0xdc => { b'\xdc' }
    0xdd => { b'\xdd' }
    0xde => { b'\xde' }
    0xdf => { b'\xdf' }
    0xe0 => { b'\xe0' }
    0xe1 => { b'\xe1' }
    0xe2 => { b'\xe2' }
    0xe3 => { b'\xe3' }
    0xe4 => { b'\xe4' }
    0xe5 => { b'\xe5' }
    0xe6 => { b'\xe6' }
    0xe7 => { b'\xe7' }
    0xe8 => { b'\xe8' }
    0xe9 => { b'\xe9' }
    0xea => { b'\xea' }
    0xeb => { b'\xeb' }
    0xec => { b'\xec' }
    0xed => { b'\xed' }
    0xee => { b'\xee' }
    0xef => { b'\xef' }
    0xf0 => { b'\xf0' }
    0xf1 => { b'\xf1' }
    0xf2 => { b'\xf2' }
    0xf3 => { b'\xf3' }
    0xf4 => { b'\xf4' }
    0xf5 => { b'\xf5' }
    0xf6 => { b'\xf6' }
    0xf7 => { b'\xf7' }
    0xf8 => { b'\xf8' }
    0xf9 => { b'\xf9' }
    0xfa => { b'\xfa' }
    0xfb => { b'\xfb' }
    0xfc => { b'\xfc' }
    0xfd => { b'\xfd' }
    0xfe => { b'\xfe' }
    0xff => { b'\xff' }
    _ => abort("value \(v) overflows Byte range")
  }
}
