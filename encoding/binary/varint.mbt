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
/// Encodes an unsigned 64-bit integer as a variable-length byte sequence.
///
/// The encoding is compatible with Go's `encoding/binary` varint helpers.
pub fn encode_uvarint(value : UInt64) -> Bytes {
  let buffer = @buffer.Buffer(size_hint=MAX_VARINT_LEN_64)
  let mut x = value
  while x >= 0x80UL {
    buffer.write_byte(((x & 0x7fUL).to_int() | 0x80).to_byte())
    x = x >> 7
  }
  buffer.write_byte(x.to_byte())
  buffer.to_bytes()
}

///|
/// Decodes an unsigned 64-bit integer from a variable-length byte sequence.
///
/// Returns the decoded value and the number of consumed bytes. Trailing bytes
/// are left unread. Raises `Malformed` when the input is incomplete or would
/// overflow `UInt64`.
pub fn uvarint(bytes : BytesView) -> (UInt64, Int) raise Malformed {
  let mut value = 0UL
  let mut shift = 0
  for i in 0..<bytes.length() {
    let byte = bytes[i].to_uint64()
    if byte < 0x80UL {
      guard i != MAX_VARINT_LEN_64 - 1 || byte <= 1UL else {
        raise Malformed(bytes)
      }
      return (value | (byte << shift), i + 1)
    }
    guard i != MAX_VARINT_LEN_64 - 1 else { raise Malformed(bytes) }
    value = value | ((byte & 0x7fUL) << shift)
    shift += 7
  }
  raise Malformed(bytes)
}

///|
/// Encodes a signed 64-bit integer as a variable-length byte sequence.
///
/// Negative values use the same zig-zag mapping as Go's `encoding/binary`
/// `PutVarint`.
pub fn encode_varint(value : Int64) -> Bytes {
  let mut x = value.reinterpret_as_uint64() << 1
  if value < 0L {
    x = x.lnot()
  }
  encode_uvarint(x)
}

///|
/// Decodes a signed 64-bit integer from a variable-length byte sequence.
///
/// Returns the decoded value and the number of consumed bytes. Trailing bytes
/// are left unread. Raises `Malformed` when the input is incomplete or would
/// overflow `Int64`.
pub fn varint(bytes : BytesView) -> (Int64, Int) raise Malformed {
  let (unsigned, consumed) = uvarint(bytes)
  let mut value = (unsigned >> 1).reinterpret_as_int64()
  if (unsigned & 1UL) != 0UL {
    value = value.lnot()
  }
  (value, consumed)
}
