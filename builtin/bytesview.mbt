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
fn BytesView::bytes(self : BytesView) -> Bytes = "%bytesview.bytes"

///|
fn BytesView::start(self : BytesView) -> Int = "%bytesview.start"

///|
fn BytesView::len(self : BytesView) -> Int = "%bytesview.len"

///|
fn BytesView::make(b : Bytes, start : Int, len : Int) -> BytesView = "%bytesview.make"

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
/// ```mbt check
/// test {
///   let bytes = b"\x00\x01\x02\x03\x04"
///   let view = bytes[2:4]
///   inspect(view.length(), content="2")
/// }
/// ```
pub fn BytesView::length(self : BytesView) -> Int {
  self.len()
}

///|
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index if the index is valid.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4] // view contains [0x02, 0x03, 0x04]
///   inspect(view[1], content="b'\\x03'")
/// }
/// ```
#alias("_[_]")
pub fn BytesView::at(self : BytesView, index : Int) -> Byte {
  guard index >= 0 && index < self.length() else {
    abort(
      "index out of bounds: the len is from 0 to \{self.length()} but the index is \{index}",
    )
  }
  self.bytes()[self.start() + index]
}

///|
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index, or None if the index is out of bounds.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4]
///   let result = view.get(1)
///   inspect(result, content="Some(b'\\x03')")
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[1:4]
///   let result = view.get(5)
///   inspect(result, content="None")
/// }
/// ```
pub fn BytesView::get(self : BytesView, index : Int) -> Byte? {
  guard index >= 0 && index < self.length() else { None }
  Some(self.bytes().unsafe_get(self.start() + index))
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
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03\x04\x05"
///   let view = bytes[2:4] // view contains [0x03, 0x04]
///   inspect(view.unsafe_get(0), content="b'\\x03'")
/// }
/// ```
///
#internal(unsafe, "Panic if index is out of bounds")
#doc(hidden)
pub fn BytesView::unsafe_get(self : BytesView, index : Int) -> Byte {
  self.bytes()[self.start() + index]
}

///|
/// Creates a new `View` from the given `Bytes`.
/// 
/// # Example
/// 
/// ```mbt check
/// test {
///   let bs = b"\x00\x01\x02\x03\x04\x05"
///   let bv = bs[1:4]
///   inspect(bv.length(), content="3")
///   assert_eq(bv[0], b'\x01')
///   assert_eq(bv[1], b'\x02')
///   assert_eq(bv[2], b'\x03')
/// }
/// ```
#alias("_[_:_]")
pub fn Bytes::sub(self : Bytes, start? : Int = 0, end? : Int) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for View")
  }
  BytesView::make(self, start, end - start)
}

///|
/// Creates a new `View` from the given `View`.
/// 
/// # Example
/// 
/// ```mbt check
/// test {
///   let bv = b"\x00\x01\x02\x03\x04\x05"[:]
///   let bv2 = bv[1:4]
///   inspect(bv2.length(), content="3")
///   assert_eq(bv2[1], b'\x02')
/// }
/// ```
#alias("_[_:_]")
pub fn BytesView::sub(
  self : BytesView,
  start? : Int = 0,
  end? : Int,
) -> BytesView {
  let len = self.length()
  let end = match end {
    None => len
    Some(end) => if end < 0 { len + end } else { end }
  }
  let start = if start < 0 { len + start } else { start }
  guard start >= 0 && start <= end && end <= len else {
    abort("Invalid index for View")
  }
  BytesView::make(self.bytes(), self.start() + start, end - start)
}

///|
/// Returns an iterator over the `View`.
/// 
/// # Example
/// 
/// ```mbt check
/// test {
///   let bv = b"\x00\x01\x02\x03\x04\x05"[:]
///   let mut sum = 0
///   bv.iter().each(x => sum = sum + x.to_int())
///   inspect(sum, content="15")
/// }
/// ```
#alias(iterator, deprecated)
pub fn BytesView::iter(self : BytesView) -> Iter[Byte] {
  let mut i = 0
  let len = self.length()
  Iter::new(fn() {
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
/// ```mbt check
/// test {
///   let buf = StringBuilder::new(size_hint=5)
///   let keys = []
///   let it = b"abcde"[:].iter2()
///   while it.next() is Some((i, x)) {
///     buf.write_string(x.to_string())
///     keys.push(i)
///   }
///   inspect(buf, content="b'\\x61'b'\\x62'b'\\x63'b'\\x64'b'\\x65'")
///   inspect(keys, content="[0, 1, 2, 3, 4]")
/// }
/// ```
#alias(iterator2, deprecated)
pub fn BytesView::iter2(self : BytesView) -> Iter2[Int, Byte] {
  let mut i = 0
  let len = self.length()
  Iter2::new(fn() {
    guard i < len else { None }
    let result = (i, self.unsafe_get(i))
    i += 1
    Some(result)
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
/// ```mbt check
/// test {
///   let bytes = b"\x12\x34\x56\x78"
///   guard bytes is [u32be(x), ..]
///   inspect(x, content="305419896") // 0x12345678
/// }
/// ```
#deprecated("Use bits pattern directly")
#doc(hidden)
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
/// * `view` : A `View` containing exactly 4 bytes to be interpreted as a
/// little-endian unsigned integer.
///
/// Returns an unsigned 32-bit integer (`UInt`) formed by interpreting the bytes
/// in little-endian order.
///
/// Throws a panic if the view does not contain exactly 4 bytes.
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03\x04"
///   guard bytes is [u32le(x), ..]
///   inspect(x, content="67305985") // 0x04030201
/// }
/// ```
#deprecated("Use bits pattern directly")
#doc(hidden)
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
/// ```mbt check
/// test {
///   let bytes = b"\x01\x23\x45\x67\x89\xAB\xCD\xEF"
///   guard bytes is [u64be(x), ..]
///   inspect(x, content="81985529216486895")
/// }
/// ```
#deprecated("Use bits pattern directly")
#doc(hidden)
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
/// ```mbt check
/// test {
///   let bytes = b"\x01\x02\x03\x04\x05\x06\x07\x08"
///   guard bytes is [u64le(x), ..]
///   inspect(x, content="578437695752307201")
/// }
/// ```
#deprecated("Use bits pattern directly")
#doc(hidden)
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
#deprecated
#doc(hidden)
pub fn BytesView::to_int_be(self : BytesView) -> Int {
  guard self is [u32be(u32), ..]
  u32.reinterpret_as_int()
}

///|
#deprecated
#doc(hidden)
pub fn BytesView::to_int_le(self : BytesView) -> Int {
  guard self is [u32le(u32), ..]
  u32.reinterpret_as_int()
}

///|
#deprecated
#doc(hidden)
pub fn BytesView::to_int64_be(self : BytesView) -> Int64 {
  guard self is [u64be(u64), ..]
  u64.reinterpret_as_int64()
}

///|
#deprecated
#doc(hidden)
pub fn BytesView::to_int64_le(self : BytesView) -> Int64 {
  guard self is [u64le(u64), ..]
  u64.reinterpret_as_int64()
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
/// ```mbt check
/// test {
///   // Bytes representing 1.0 in IEEE 754 double-precision format (big-endian)
///   let bytes = b"\x3F\xF0\x00\x00\x00\x00\x00\x00"
///   guard bytes is [u64be(bits), ..]
///   inspect(bits.reinterpret_as_double(), content="1")
/// }
/// ```
#deprecated("Use bits pattern directly")
#doc(hidden)
pub fn BytesView::to_double_be(self : BytesView) -> Double {
  guard self is [u64be(u64), ..]
  u64.reinterpret_as_double()
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
/// ```mbt check
/// test {
///   let bytes = b"\x00\x00\x00\x00\x00\x00\xF0\x3F" // represents 1.0 in little-endian
///   guard bytes is [u64le(bits), ..]
///   inspect(bits.reinterpret_as_double(), content="1")
/// }
/// ```
#deprecated("Use bits pattern directly")
#doc(hidden)
pub fn BytesView::to_double_le(self : BytesView) -> Double {
  guard self is [u64le(u64), ..]
  u64.reinterpret_as_double()
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
/// Compares two views for equality. Returns true only if both views
/// have the same length and contain identical bytes in the same order.
///
/// Parameters:
///
/// * `self` : The first view to compare.
/// * `other` : The second view to compare.
///
/// Returns `true` if the byte sequences are equal, `false` otherwise.
///
/// Example:
/// ```mbt check
/// test {
///   let bytes = b"abcabc"
///   inspect(bytes[0:3] == bytes[3:6], content="true")
///   inspect(bytes[0:3] == bytes[2:5], content="false")
///   inspect(bytes[0:4] == bytes[3:6], content="false")
/// }
/// ```
pub impl Eq for BytesView with equal(self, other) -> Bool {
  guard self.length() == other.length() else { return false }
  for i in 0..<self.length() {
    guard self.unsafe_get(i) == other.unsafe_get(i) else { return false }
  }
  true
}

///|
/// Compares two views based on shortlex order. First compares the lengths of
/// the views, then compares bytes pairwise until a difference is found or
/// all bytes have been compared.
///
/// Parameters:
///
/// * `self` : The first view to compare.
/// * `other` : The second byte sequence to compare.
///
/// Returns an integer indicating the relative order:
///
/// * A negative value if `self` is less than `other`
/// * Zero if `self` equals `other`
/// * A positive value if `self` is greater than `other`
///
/// Example:
///
/// ```mbt check
/// test {
///   let bytes = b"abcabc"
///   inspect(bytes[0:3].compare(bytes[3:6]), content="0") // abc = abc
///   inspect(bytes[0:3].compare(bytes[2:5]), content="-1") // abc < cab
///   inspect(bytes[1:4].compare(bytes[3:6]), content="1") // bca > abc
///   inspect(bytes[0:3].compare(bytes[0:4]), content="-1") // abc < abca
///   inspect(bytes[1:5].compare(bytes[2:5]), content="1") // bcab > cab
/// }
/// ```
pub impl Compare for BytesView with compare(self, other) -> Int {
  let self_len = self.length()
  let other_len = other.length()
  let cmp = self_len.compare(other_len)
  guard cmp == 0 else { return cmp }
  for i in 0..<self_len {
    let b1 = self.unsafe_get(i)
    let b2 = other.unsafe_get(i)
    let cmp = b1.compare(b2)
    guard cmp == 0 else { return cmp }
  }
  0
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
