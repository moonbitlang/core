// Copyright 2025 International Digital Economy Academy
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
/// A `BytesView` represents a view into a section of a `Bytes` without copying the data.
///
/// # Example
/// 
/// ```mbt
///   let bs = b"\x00\x01\x02\x03\x04\x05"
///   let bv = bs[1:4]
///   inspect(bv.length(), content="3")
///   assert_eq(bv[0], b'\x01')
///   assert_eq(bv[1], b'\x02')
///   assert_eq(bv[2], b'\x03')
/// ```
#builtin.valtype
#deprecated("Use `BytesView` instead")
pub typealias BytesView as View

///|
/// Returns an iterator over the `View`.
/// 
/// # Example
/// 
/// ```mbt
///   let bv = b"\x00\x01\x02\x03\x04\x05"[:]
///   let mut sum = 0
///   bv.iter().each((x) => { sum = sum + x.to_int() })
///   inspect(sum, content="15")
/// ```
pub fn BytesView::iter(self : BytesView) -> Iter[Byte] {
  Iter::new(yield_ => for i in 0..<self.length() {
    guard yield_(self[i]) is IterContinue else { break IterEnd }
  } else {
    IterContinue
  })
}

///|
/// Returns an iterator over the `View`.
/// 
/// # Example
/// 
/// ```mbt
///   let bv = b"\x00\x01\x02\x03\x04\x05"[:]
///   let mut sum = 0
///   bv.iterator().each((x) => { sum = sum + x.to_int() })
///   inspect(sum, content="15")
/// ```
pub fn BytesView::iterator(self : BytesView) -> Iterator[Byte] {
  let mut i = 0
  let len = self.length()
  Iterator::new(fn() {
    guard i < len else { None }
    let result = self.unsafe_get(i)
    i += 1
    Some(result)
  })
}

///|
/// Returns an iterator over the `View` with index.
/// 
/// Example:
///
/// ```moonbit
///   let buf = StringBuilder::new(size_hint=5)
///   let keys = []
///   let it = b"abcde"[:].iterator2()
///   while it.next() is Some((i, x)) {
///     buf.write_string(x.to_string())
///     keys.push( i )
///   }
///   inspect(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
///   inspect(keys, content="[0, 1, 2, 3, 4]")
/// ```
pub fn BytesView::iterator2(self : BytesView) -> Iterator2[Int, Byte] {
  let mut i = 0
  let len = self.length()
  Iterator2::new(fn() {
    guard i < len else { None }
    let result = (i, self.unsafe_get(i))
    i += 1
    Some(result)
  })
}

///|
/// Converts a sequence of 8 bytes into a 64-bit unsigned integer using
/// big-endian byte order. The most significant byte is at index 0, and the least
/// significant byte is at index 7.
///
/// Parameters:
///
/// * `bytes` : A view into a byte sequence that must be at least 8 bytes long.
/// The bytes are interpreted in big-endian order, where the first byte is the
/// most significant byte.
///
/// Returns a 64-bit unsigned integer constructed by concatenating the bytes in
/// big-endian order.
///
/// Throws a runtime error if the byte sequence view is less than 8 bytes long or
/// if attempting to access an index beyond the view's bounds.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x23\x45\x67\x89\xAB\xCD\xEF"[:]
///   inspect(bytes.to_uint64_be(), content="81985529216486895")
/// ```
pub fn BytesView::to_uint64_be(self : BytesView) -> UInt64 {
  (self[0].to_uint().to_uint64() << 56) +
  (self[1].to_uint().to_uint64() << 48) +
  (self[2].to_uint().to_uint64() << 40) +
  (self[3].to_uint().to_uint64() << 32) +
  (self[4].to_uint().to_uint64() << 24) +
  (self[5].to_uint().to_uint64() << 16) +
  (self[6].to_uint().to_uint64() << 8) +
  self[7].to_uint().to_uint64()
}

///|
/// Converts an 8-byte sequence to an unsigned 64-bit integer using little-endian
/// byte order. Each byte in the view is treated as an 8-bit unsigned integer and
/// combined to form the final 64-bit value, with the least significant byte
/// first.
///
/// Parameters:
///
/// * `bytes_view` : A view into a byte sequence that must be exactly 8 bytes
/// long. Each byte represents one byte of the resulting 64-bit integer, with the
/// first byte being the least significant.
///
/// Returns an unsigned 64-bit integer assembled from the bytes in little-endian
/// order.
///
/// Throws a panic if the View is less than 8 bytes long or if trying to
/// access a byte beyond the view's bounds.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"[:]
///   inspect(bytes.to_uint64_le(), content="578437695752307201")
/// ```
pub fn BytesView::to_uint64_le(self : BytesView) -> UInt64 {
  self[0].to_uint().to_uint64() +
  (self[1].to_uint().to_uint64() << 8) +
  (self[2].to_uint().to_uint64() << 16) +
  (self[3].to_uint().to_uint64() << 24) +
  (self[4].to_uint().to_uint64() << 32) +
  (self[5].to_uint().to_uint64() << 40) +
  (self[6].to_uint().to_uint64() << 48) +
  (self[7].to_uint().to_uint64() << 56)
}

///|
/// Converts a 4-byte view of bytes to a 32-bit signed integer by interpreting
/// the bytes in big-endian order (most significant byte first). Interprets the
/// resulting unsigned integer as a signed integer using two's complement
/// representation.
///
/// Parameters:
///
/// * `View` : A view into a byte sequence that must be exactly 4 bytes
/// long. The bytes are interpreted in big-endian order, where the first byte is
/// the most significant byte and the last byte is the least significant byte.
///
/// Returns a 32-bit signed integer constructed from the bytes in big-endian
/// order.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x80\x00\x00\x00"[:] // Represents -2147483648 in two's complement
///   inspect(bytes.to_int_be(), content="-2147483648")
/// ```
pub fn BytesView::to_int_be(self : BytesView) -> Int {
  self.to_uint_be().reinterpret_as_int()
}

///|
/// Converts 4 bytes from a byte sequence into a 32-bit signed integer using
/// little-endian byte order. The bytes are interpreted as follows: the least
/// significant byte is at the lowest address (first position), and the most
/// significant byte is at the highest address (last position).
///
/// Parameters:
///
/// * `bytes_view` : A view into a byte sequence that must be exactly 4 bytes
/// long. The bytes are interpreted as a little-endian representation of a 32-bit
/// integer.
///
/// Returns a 32-bit signed integer (`Int`) constructed from the 4 bytes in
/// little-endian order.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x78\x56\x34\x12"
///   let view = bytes[:]
///   inspect(view.to_int_le(), content="305419896") // 0x12345678 in decimal
/// ```
pub fn BytesView::to_int_le(self : BytesView) -> Int {
  self.to_uint_le().reinterpret_as_int()
}

///|
/// Interprets an 8-byte view as a signed 64-bit integer in big-endian byte
/// order. The highest byte (index 0) is treated as the most significant byte.
///
/// Parameters:
///
/// * `bytes_view` : A view containing exactly 8 bytes to be interpreted as a
/// big-endian signed 64-bit integer.
///
/// Returns a 64-bit signed integer (`Int64`) value constructed by interpreting
/// the bytes in big-endian order.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x80\x00\x00\x00\x00\x00\x00\x00"[:] // Most negative 64-bit integer
///   inspect(bytes.to_int64_be(), content="-9223372036854775808")
/// ```
pub fn BytesView::to_int64_be(self : BytesView) -> Int64 {
  self.to_uint64_be().reinterpret_as_int64()
}

///|
/// Converts a sequence of 8 bytes into a signed 64-bit integer using
/// little-endian byte order. In little-endian order, the least significant byte
/// is stored at the lowest address (first byte).
///
/// Parameters:
///
/// * `bytes_view` : A view into a sequence of exactly 8 bytes. The first byte
/// represents the least significant byte of the resulting integer.
///
/// Returns a 64-bit signed integer (`Int64`) constructed from the bytes in
/// little-endian order.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
///   let view = bytes[:]
///   inspect(view.to_int64_le(), content="578437695752307201")
/// ```
pub fn BytesView::to_int64_le(self : BytesView) -> Int64 {
  self.to_uint64_le().reinterpret_as_int64()
}

///|
/// Converts a 4-byte sequence to a 32-bit floating-point number using big-endian
/// byte order.
///
/// Parameters:
///
/// * `bytes_view` : A view into a byte sequence that must be exactly 4 bytes
/// long. The bytes are interpreted in big-endian order (most significant byte
/// first).
///
/// Returns a 32-bit floating-point number obtained by interpreting the 4 bytes
/// as an IEEE 754 single-precision value.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x40\x48\xF5\xC3" // Represents 3.14 in IEEE 754 format
///   let view = bytes[:]
///   let float = view.to_float_be()
///   // Convert to double for comparison since Float doesn't implement Show
///   inspect(float.to_double(), content="3.140000104904175")
/// ```
pub fn BytesView::to_float_be(self : BytesView) -> Float {
  self.to_uint_be().reinterpret_as_float()
}

///|
/// Converts 4 bytes from a bytes view to a 32-bit floating-point number,
/// interpreting the bytes in little-endian order (least significant byte first).
///
/// Parameters:
///
/// * `self` : A bytes view containing at least 4 bytes to be interpreted as a
/// floating-point number.
///
/// Returns a 32-bit floating-point value constructed from the bytes.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x00\x00\x80\x3F" // Represents 1.0 in little-endian IEEE-754
///   let f = bytes[:].to_float_le()
///   inspect(f.to_double(), content="1")
/// ```
pub fn BytesView::to_float_le(self : BytesView) -> Float {
  self.to_uint_le().reinterpret_as_float()
}

///|
/// Converts the bytes in a byte view to a double-precision floating-point number
/// using big-endian byte order. The byte view must contain exactly 8 bytes,
/// which represent the IEEE 754 double-precision format.
///
/// Parameters:
///
/// * `byte_view` : The byte view containing exactly 8 bytes to be interpreted as
/// a double-precision floating-point number in big-endian order.
///
/// Returns a double-precision floating-point number reconstructed from the
/// bytes.
///
/// Example:
///
/// ```moonbit
///   // Bytes representing 1.0 in IEEE 754 double-precision format (big-endian)
///   let bytes = b"\x3F\xF0\x00\x00\x00\x00\x00\x00"
///   let view = bytes[:]
///   inspect(view.to_double_be(), content="1")
/// ```
pub fn BytesView::to_double_be(self : BytesView) -> Double {
  self.to_uint64_be().reinterpret_as_double()
}

///|
/// Converts the bytes in the view to a double-precision floating-point number
/// using little-endian byte order. Interprets the first 8 bytes as a IEEE 754
/// double-precision binary floating-point format (binary64) value.
///
/// Parameters:
///
/// * `bytes` : The byte view to be converted. Must contain at least 8 bytes.
///
/// Returns a `Double` value representing the bytes interpreted in little-endian
/// order.
///
/// Example:
///
/// ```moonbit
///   let bytes = b"\x00\x00\x00\x00\x00\x00\xF0\x3F" // represents 1.0 in little-endian
///   let view = bytes[:]
///   inspect(view.to_double_le(), content="1")
/// ```
pub fn BytesView::to_double_le(self : BytesView) -> Double {
  self.to_uint64_le().reinterpret_as_double()
}

///|
pub impl Show for BytesView with output(self, logger) {
  logger.write_string("b\"")
  for byte in self {
    if byte is (' '..='~') && byte != '"' && byte != '\\' {
      logger.write_char(byte.to_char())
    } else {
      logger..write_string("\\x")..write_string(byte.to_hex())
    }
  }
  logger.write_string("\"")
}

///|
pub impl Show for Bytes with output(self, logger) {
  BytesView::output(self[:], logger)
}

///|
/// Retrieves the underlying `Bytes` from a `View`.
pub fn BytesView::data(self : BytesView) -> Bytes {
  self.bytes()
}

///|
/// Retrieves the start index of the view.
pub fn BytesView::start_offset(self : BytesView) -> Int {
  self.start()
}

///|
pub fn BytesView::to_bytes(self : BytesView) -> Bytes {
  if self.length() == self.bytes().length() {
    // If the view covers the entire bytes, return the original bytes to avoid copying
    return self.bytes()
  }
  let bytes = FixedArray::make(self.length(), (0 : Byte))
  bytes.blit_from_bytes(0, self.bytes(), self.start_offset(), self.length())
  unsafe_to_bytes(bytes)
}

///|
pub impl ToJson for BytesView with to_json(self) -> Json {
  let sb = StringBuilder::new()
  for byte in self {
    if byte is (' '..='~') && byte != '"' && byte != '\\' {
      sb.write_char(byte.to_char())
    } else {
      sb..write_string("\\x")..write_string(byte.to_hex())
    }
  }
  Json::string(sb.to_string())
}

///|
/// Converts a `Bytes` value to a JSON representation.
/// The representation is picked for easier debugging.
/// Printable ASCII characters (from space to tilde, excluding '"' and '\') are output as-is.
/// All other bytes are represented as \xHH, where HH is the two-digit hexadecimal value of the byte.
pub impl ToJson for Bytes with to_json(self : Bytes) -> Json {
  BytesView::to_json(self[:])
}
