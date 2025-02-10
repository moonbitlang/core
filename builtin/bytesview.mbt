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
/// A `BytesView` is a slice of a `Bytes`.
///
/// # Example
/// 
/// ```
/// let bs = b"\x00\x01\x02\x03\x04\x05"
/// let bv = bs[1:4]
/// assert_eq!(bv.length(), 3)
/// assert_eq!(bv[0], b'\x01')
/// assert_eq!(bv[1], b'\x02')
/// assert_eq!(bv[2], b'\x03')
/// ```
struct BytesView {
  bytes : Bytes
  start : Int
  len : Int
}

///|
/// Returns the number of bytes in the view.
///
/// Parameters:
///
/// * `bytes_view` : The view of a byte sequence.
///
/// Returns an integer representing the length of the view.
///
/// Example:
///
/// ```moonbit
/// test "BytesView::length" {
///   let bytes = b"\x00\x01\x02\x03\x04"
///   let view = bytes[2:4]
///   inspect!(view.length(), content="2")
/// }
/// ```
pub fn BytesView::length(self : BytesView) -> Int {
  self.len
}

///|
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index.
///
/// Throws a runtime error if the index is out of bounds (negative or greater
/// than or equal to the length of the view).
///
/// Example:
///
/// ```moonbit
/// test "BytesView::op_get" {
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4] // view contains [0x02, 0x03, 0x04]
///   inspect!(view[1], content="b'\\x03'")
/// }
/// 
/// test "panic BytesView::op_get/out_of_bounds" {
///   let view = b"\x01\x02\x03"[:]
///   ignore(view[3]) // Index out of bounds
/// }
/// ```
pub fn BytesView::op_get(self : BytesView, index : Int) -> Byte {
  guard index >= 0 && index < self.len else {
    abort(
      "index out of bounds: the len is from 0 to \{self.len} but the index is \{index}",
    )
  }
  self.bytes[self.start + index]
}

///|
/// Retrieves a byte at the specified index from a bytes view without performing
/// bounds checking.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte. The
/// index is relative to the start of the view, not the underlying bytes.
///
/// Returns a single byte from the specified position in the view.
///
/// Throws a panic if the index is out of bounds (less than 0 or greater than or
/// equal to the length of the view).
///
/// Example:
///
/// ```moonbit
/// test "BytesView::unsafe_get" {
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[2:4] // view contains [0x03, 0x04]
///   inspect!(view.unsafe_get(0), content="b'\\x03'")
/// }
/// 
/// test "panic BytesView::unsafe_get/out_of_bounds" {
///   let view = b"\x01\x02\x03"[:]
///   ignore(view.unsafe_get(3)) // Panic: index out of bounds
/// }
/// ```
///
/// @alert unsafe "Panic if index is out of bounds"
pub fn BytesView::unsafe_get(self : BytesView, index : Int) -> Byte {
  self.bytes[self.start + index]
}

///|
/// Creates a new `BytesView` from the given `Bytes`.
/// 
/// # Example
/// 
/// ```
/// let bs = b"\x00\x01\x02\x03\x04\x05"
/// let bv = bs[1:4]
/// assert_eq!(bv.length(), 3)
/// assert_eq!(bv[0], b'\x01')
/// assert_eq!(bv[1], b'\x02')
/// assert_eq!(bv[2], b'\x03')
/// ```
pub fn Bytes::op_as_view(
  self : Bytes,
  start~ : Int = 0,
  end? : Int
) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for BytesView")
  }
  BytesView::{ bytes: self, start, len: end - start }
}

///|
/// Creates a new `BytesView` from the given `BytesView`.
/// 
/// # Example
/// 
/// ```
/// let bv = b"\x00\x01\x02\x03\x04\x05"[:]
/// let bv2 = bv[1:4]
/// assert_eq!(bv2.length(), 3)
/// assert_eq!(bv2[1], b'\x02')
/// ```
pub fn BytesView::op_as_view(
  self : BytesView,
  start~ : Int = 0,
  end? : Int
) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for BytesView")
  }
  BytesView::{ bytes: self.bytes, start: self.start + start, len: end - start }
}

///|
/// Returns an iterator over the `BytesView`.
/// 
/// # Example
/// 
/// ```
/// let bv = b"\x00\x01\x02\x03\x04\x05"[:]
/// let mut sum = 0
/// bv.iter().each(fn(x) { sum = sum + x.to_int() })
/// assert_eq!(sum, 15)
/// ```
pub fn BytesView::iter(self : BytesView) -> Iter[Byte] {
  Iter::new(fn(yield_) {
    for i in 0..<self.len {
      guard yield_(self[i]) is IterContinue else { break IterEnd }

    } else {
      IterContinue
    }
  })
}

///|
/// Converts a 4-byte sequence to an unsigned 32-bit integer using big-endian
/// byte order. The first byte is treated as the most significant byte, and the
/// last byte as the least significant byte.
///
/// Parameters:
///
/// * `self` : A byte view containing exactly 4 bytes to be converted.
///
/// Returns an unsigned 32-bit integer representing the byte sequence.
///
/// Example:
///
/// ```moonbit
/// test "BytesView::to_uint_be" {
///   let bytes = b"\x12\x34\x56\x78"[:]
///   inspect!(bytes.to_uint_be(), content="305419896") // 0x12345678
/// }
/// 
/// test "panic BytesView::to_uint_be/out_of_bounds" {
///   let bytes = b"\x12\x34\x56"[:] // Less than 4 bytes
///   ignore(bytes.to_uint_be()) // Panics with index out of bounds
/// }
/// ```
pub fn BytesView::to_uint_be(self : BytesView) -> UInt {
  (self[0].to_uint() << 24) +
  (self[1].to_uint() << 16) +
  (self[2].to_uint() << 8) +
  self[3].to_uint()
}

///|
/// Converts a sequence of 4 bytes into an unsigned 32-bit integer using
/// little-endian byte order. Each byte in the view contributes 8 bits to the
/// final integer, with the least significant byte at index 0.
///
/// Parameters:
///
/// * `view` : A `BytesView` containing exactly 4 bytes to be interpreted as a
/// little-endian unsigned integer.
///
/// Returns an unsigned 32-bit integer (`UInt`) formed by interpreting the bytes
/// in little-endian order.
///
/// Throws a panic if the view does not contain exactly 4 bytes.
///
/// Example:
///
/// ```moonbit
/// test "BytesView::to_uint_le" {
///   let bytes = b"\x01\x02\x03\x04"
///   let view = bytes[:]
///   inspect!(view.to_uint_le(), content="67305985") // 0x04030201
/// }
/// ```
pub fn BytesView::to_uint_le(self : BytesView) -> UInt {
  self[0].to_uint() +
  (self[1].to_uint() << 8) +
  (self[2].to_uint() << 16) +
  (self[3].to_uint() << 24)
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
/// test "BytesView::to_uint64_be" {
///   let bytes = b"\x01\x23\x45\x67\x89\xAB\xCD\xEF"[:]
///   inspect!(bytes.to_uint64_be(), content="81985529216486895")
/// }
/// 
/// test "panic BytesView::to_uint64_be/short_input" {
///   let bytes = b"\x01\x02\x03"[:]
///   ignore(bytes.to_uint64_be()) // Throws error: index out of bounds
/// }
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
/// Throws a panic if the BytesView is less than 8 bytes long or if trying to
/// access a byte beyond the view's bounds.
///
/// Example:
///
/// ```moonbit
/// test "BytesView::to_uint64_le" {
///   let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"[:]
///   inspect!(bytes.to_uint64_le(), content="578437695752307201")
/// }
/// 
/// test "panic BytesView::to_uint64_le/short_view" {
///   let bytes = b"\x01\x02\x03"[:]
///   ignore(bytes.to_uint64_le()) // Panics: view is too short
/// }
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
/// * `bytesView` : A view into a byte sequence that must be exactly 4 bytes
/// long. The bytes are interpreted in big-endian order, where the first byte is
/// the most significant byte and the last byte is the least significant byte.
///
/// Returns a 32-bit signed integer constructed from the bytes in big-endian
/// order.
///
/// Example:
///
/// ```moonbit
/// test "BytesView::to_int_be" {
///   let bytes = b"\x80\x00\x00\x00"[:] // Represents -2147483648 in two's complement
///   inspect!(bytes.to_int_be(), content="-2147483648")
/// }
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
/// test "BytesView::to_int_le" {
///   let bytes = b"\x78\x56\x34\x12"
///   let view = bytes[:]
///   inspect!(view.to_int_le(), content="305419896") // 0x12345678 in decimal
/// }
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
/// test "BytesView::to_int64_be" {
///   let bytes = b"\x80\x00\x00\x00\x00\x00\x00\x00"[:] // Most negative 64-bit integer
///   inspect!(bytes.to_int64_be(), content="-9223372036854775808")
/// }
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
/// test "BytesView::to_int64_le" {
///   let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
///   let view = bytes[:]
///   inspect!(view.to_int64_le(), content="578437695752307201")
/// }
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
/// test "BytesView::to_float_be" {
///   let bytes = b"\x40\x48\xF5\xC3" // Represents 3.14 in IEEE 754 format
///   let view = bytes[:]
///   let float = view.to_float_be()
///   // Convert to double for comparison since Float doesn't implement Show
///   inspect!(float.to_double(), content="3.140000104904175")
/// }
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
/// test "BytesView::to_float_le" {
///   let bytes = b"\x00\x00\x80\x3F" // Represents 1.0 in little-endian IEEE-754
///   let f = bytes[:].to_float_le()
///   inspect!(f.to_double(), content="1")
/// }
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
/// test "BytesView::to_double_be" {
///   // Bytes representing 1.0 in IEEE 754 double-precision format (big-endian)
///   let bytes = b"\x3F\xF0\x00\x00\x00\x00\x00\x00"
///   let view = bytes[:]
///   inspect!(view.to_double_be(), content="1")
/// }
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
/// test "BytesView::to_double_le" {
///   let bytes = b"\x00\x00\x00\x00\x00\x00\xF0\x3F" // represents 1.0 in little-endian
///   let view = bytes[:]
///   inspect!(view.to_double_le(), content="1")
/// }
/// ```
pub fn BytesView::to_double_le(self : BytesView) -> Double {
  self.to_uint64_le().reinterpret_as_double()
}
