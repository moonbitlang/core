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
/// Converts a string representation in the specified radix to a `BigInt`.
///
/// Panics if the input is malformed.
///
/// Deprecated: use `@string.parse_bigint`, which raises on malformed input.
#deprecated("Use `@string.parse_bigint` instead")
pub fn BigInt::from_string(input : String, radix~ : Int32 = 10) -> BigInt {
  parse_bigint(input, base=radix) catch {
    Failure(msg) => abort(msg)
    _ => abort("invalid syntax")
  }
}

///|
/// Converts a big-endian byte sequence to a `BigInt`, applying the sign of
/// `signum`: positive gives a positive number, negative a negative number, and
/// 0 gives zero regardless of the input bytes.
#deprecated("Use `BigInt::from_be_bytes` instead, and negate the result for a negative value")
pub fn BigInt::from_octets(input : BytesView, signum~ : Int32 = 1) -> BigInt {
  if signum == 0 {
    return 0N
  }
  let value = BigInt::from_be_bytes(input)
  if signum < 0 {
    -value
  } else {
    value
  }
}

///|
/// Converts a non-negative `BigInt` to big-endian bytes. `length` is a
/// minimum: shorter results are padded with leading zero bytes, longer ones
/// are returned in full.
///
/// Panics if `self` is negative, or if `length` is zero or negative.
#deprecated("Use `BigInt::to_be_bytes` instead; its `length` is the exact output length")
pub fn BigInt::to_octets(self : BigInt, length? : Int32) -> Bytes {
  match length {
    None => self.to_be_bytes()
    Some(length) => {
      guard length > 0 else { abort("negative length") }
      let bytes = self.to_be_bytes()
      if bytes.length() >= length {
        bytes
      } else {
        self.to_be_bytes(length~)
      }
    }
  }
}
