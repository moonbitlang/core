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

/// Byte order, aka "endianness".
/// 
/// # Note
/// 
///  - Little-endian is the de-facto standard practice for current computer architectures, and the standardized byte order of WASM. 
/// 
/// # Warn
/// 
/// Assumes system native endian as little-endian.
/// 
/// A variant of `NativeEndian` may be introduced in the future.
pub enum Endianness {
  // Little-endian.
  LittleEndian
  // Big-endian.
  BigEndian
  // Same as `BigEndian`. The network byte order defined by [IETF RFC 1700](https://datatracker.ietf.org/doc/html/rfc1700).
  NetworkEndian

  // non-exhaustive
} derive(Debug, Show, Eq)

/// Convert byte index from specified endianness to native endianness (or vice-versa).
pub fn convert_index(self: Endianness, src_idx: Int, bytes_count: Int) -> Int {
  // TODO: this assumes native endianness is LE, this may not fit to targets other than WASM.
  if self == Endianness::LittleEndian {
    src_idx
  } else if self == Endianness::BigEndian || self == Endianness::NetworkEndian {
    bytes_count - 1 - src_idx
  } else {
    abort("invalid endianness")
  }
}
