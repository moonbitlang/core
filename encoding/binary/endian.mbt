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
/// Decodes the first two bytes as an unsigned 16-bit integer using this byte
/// order. Raises `Malformed` if fewer than two bytes are available.
pub fn Endian::decode_uint16(
  self : Endian,
  bytes : BytesView,
) -> UInt16 raise Malformed {
  match self {
    Big =>
      match bytes {
        [u16be(value), ..] => value.to_uint16()
        _ => raise Malformed(bytes)
      }
    Little =>
      match bytes {
        [u16le(value), ..] => value.to_uint16()
        _ => raise Malformed(bytes)
      }
  }
}

///|
/// Decodes the first four bytes as an unsigned 32-bit integer using this byte
/// order. Raises `Malformed` if fewer than four bytes are available.
pub fn Endian::decode_uint32(
  self : Endian,
  bytes : BytesView,
) -> UInt raise Malformed {
  match self {
    Big =>
      match bytes {
        [u32be(value), ..] => value
        _ => raise Malformed(bytes)
      }
    Little =>
      match bytes {
        [u32le(value), ..] => value
        _ => raise Malformed(bytes)
      }
  }
}

///|
/// Decodes the first eight bytes as an unsigned 64-bit integer using this byte
/// order. Raises `Malformed` if fewer than eight bytes are available.
pub fn Endian::decode_uint64(
  self : Endian,
  bytes : BytesView,
) -> UInt64 raise Malformed {
  match self {
    Big =>
      match bytes {
        [u64be(value), ..] => value
        _ => raise Malformed(bytes)
      }
    Little =>
      match bytes {
        [u64le(value), ..] => value
        _ => raise Malformed(bytes)
      }
  }
}

///|
/// Encodes an unsigned 16-bit integer into a new two-byte sequence using this
/// byte order.
pub fn Endian::encode_uint16(self : Endian, value : UInt16) -> Bytes {
  match self {
    Big => [(value >> 8).to_byte(), value.to_byte()]
    Little => [value.to_byte(), (value >> 8).to_byte()]
  }
}

///|
/// Encodes an unsigned 32-bit integer into a new four-byte sequence using this
/// byte order.
pub fn Endian::encode_uint32(self : Endian, value : UInt) -> Bytes {
  match self {
    Big =>
      [
        (value >> 24).to_byte(),
        (value >> 16).to_byte(),
        (value >> 8).to_byte(),
        value.to_byte(),
      ]
    Little =>
      [
        value.to_byte(),
        (value >> 8).to_byte(),
        (value >> 16).to_byte(),
        (value >> 24).to_byte(),
      ]
  }
}

///|
/// Encodes an unsigned 64-bit integer into a new eight-byte sequence using this
/// byte order.
pub fn Endian::encode_uint64(self : Endian, value : UInt64) -> Bytes {
  match self {
    Big =>
      [
        (value >> 56).to_byte(),
        (value >> 48).to_byte(),
        (value >> 40).to_byte(),
        (value >> 32).to_byte(),
        (value >> 24).to_byte(),
        (value >> 16).to_byte(),
        (value >> 8).to_byte(),
        value.to_byte(),
      ]
    Little =>
      [
        value.to_byte(),
        (value >> 8).to_byte(),
        (value >> 16).to_byte(),
        (value >> 24).to_byte(),
        (value >> 32).to_byte(),
        (value >> 40).to_byte(),
        (value >> 48).to_byte(),
        (value >> 56).to_byte(),
      ]
  }
}
