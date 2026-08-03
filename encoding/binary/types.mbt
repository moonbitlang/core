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
/// Type `Endian` specifies how fixed-width integer values map to byte order.
pub(all) enum Endian {
  Little
  Big
} derive(@debug.Debug)

///|
/// Error type `Malformed`.
pub suberror Malformed {
  Malformed(BytesView)
} derive(@debug.Debug)

///|
/// Maximum byte length of a varint-encoded 16-bit integer.
pub const MAX_VARINT_LEN_16 : Int = 3

///|
/// Maximum byte length of a varint-encoded 32-bit integer.
pub const MAX_VARINT_LEN_32 : Int = 5

///|
/// Maximum byte length of a varint-encoded 64-bit integer.
pub const MAX_VARINT_LEN_64 : Int = 10
