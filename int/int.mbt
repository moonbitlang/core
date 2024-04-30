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

let max_val = 2147483647

let min_val = -2147483648

pub fn Int::from_int(i : Int) -> Int {
  i
}

pub fn abs(self : Int) -> Int {
  if self < 0 {
    -self
  } else {
    self
  }
}

pub fn signum(self : Int) -> Int {
  if self < 0 {
    -1
  } else if self > 0 {
    1
  } else {
    0
  }
}

// Returns the largest positive finite value of Int
pub fn Int::max_value() -> Int {
  max_val
}

// Returns the smallest positive nonzero value of Int
pub fn Int::min_value() -> Int {
  min_val
}

pub fn hash(self : Int) -> Int {
  self
}

/// Write bytes representation of an `Int` by specified endianness into target view of `Byte`.
/// 
/// # Example
/// 
/// ```
/// let bytes = Bytes::[0x4D, 0x00, 0x7A, 0x00, 0x7A, 0x00, 0x42, 0x00]
/// 0x51546708.into_view(@representation.Endianness::LittleEndian, bytes[2..6])
/// @assertion.assert_eq(bytes.to_string(), "M\u{6708}\u{5154}B")? 
/// // "M\u{6708}\u{5154}B" 
/// // => "M月兔B" 
/// // => hex:4D,00,08,67,54,51,42,00 (UTF-16)
/// ```
/// 
/// Note: `into_byte_view_le()` and `into_byte_view_be()` can be used as a shorthand 
/// to avoid writing `Endianness` enum variant explicitly.
/// 
/// # Panics
/// 
/// 4 bytes of data are required in view. Panics when insufficient.
pub fn into_byte_view[V: @byte.ByteMutView](self: Int, view: V, endian: @representation.Endianness) -> Unit {
  if view.length() < 4 {
    let len = view.length()
    abort("insufficient length: \(len) provided, 4 required")
  }
  for bs = 0; bs < 4; bs = bs + 1 {
    let bd = endian.convert_index(bs, 4)
    view[bd] = Byte::from_int(self.lsr(bs * 8).land(0xFF))
  }
}

/// Write bytes representation of an `Int` by little-endian into target view of `Byte`. A shorthand 
/// of `into_byte_view(V, @representation.Endianness::LittleEndian)`.
/// 
/// # Panics
/// 
/// 4 bytes of data are required in view. Panics when insufficient.
pub fn into_byte_view_le[V: @byte.ByteMutView](self: Int, view: V) -> Unit {
  self.into_byte_view(view, @representation.Endianness::LittleEndian)
}

/// Write bytes representation of an `Int` by little-endian into target view of `Byte`. A shorthand 
/// of `into_byte_view(V, @representation.Endianness::LittleEndian)`.
/// 
/// # Panics
/// 
/// 4 bytes of data are required in view. Panics when insufficient.
pub fn into_byte_view_be[V: @byte.ByteMutView](self: Int, view: V) -> Unit {
  self.into_byte_view(view, @representation.Endianness::BigEndian)
}

/// Extract an `Int` from the source view of `Byte` by specified endianness.
/// 
/// # Example
/// 
/// ```
/// let bytes = Bytes::[0xAA, 0x01, 0x02, 0x03, 0x04, 0xDD]
/// @assertion.assert_eq(
///   Int::from_byte_view(bytes[1..4], @representation.Endianness::LittleEndian), 
///   0x04030201
/// )? 
/// ```
/// 
/// Note: `from_byte_view_le()` and `from_byte_view_be()` can be used as a shorthand 
/// to avoid writing `Endianness` enum variant explicitly.
/// 
/// # Panics
/// 
/// 4 bytes of data are required in view. Panics when insufficient.
pub fn Int::from_byte_view[V: @byte.ByteView](view: V, endian: @representation.Endianness) -> Int {
  if view.length() < 4 {
    let len = view.length()
    abort("insufficient length: \(len) provided, 4 required")
  }
  let mut r = 0
  for bd = 0; bd < 4; bd = bd + 1 {
    let bs = endian.convert_index(bd, 4)
    r = r.lor(view[bs].to_int().land(0xff).lsl(8 * bd))
  }
  r
}

/// Extract an `Int` from the source view of `Byte` by little-endian. A shorthand 
/// of `from_byte_view(V, @representation.Endianness::LittleEndian)`.
/// 
/// # Panics
/// 
/// 4 bytes of data are required in view. Panics when insufficient.
pub fn Int::from_byte_view_le[V: @byte.ByteView](view: V) -> Int {
  Int::from_byte_view(view, @representation.Endianness::LittleEndian)
}

/// Extract an `Int` from the source view of `Byte` by big-endian. A shorthand 
/// of `from_byte_view(V, @representation.Endianness::BigEndian)`.
/// 
/// # Panics
/// 
/// 4 bytes of data are required in view. Panics when insufficient.
pub fn Int::from_byte_view_be[V: @byte.ByteView](view: V) -> Int {
  Int::from_byte_view(view, @representation.Endianness::BigEndian)
}
