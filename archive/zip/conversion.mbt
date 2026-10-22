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
/// Checked numeric conversions for ZIP size/offset fields. ZIP stores sizes and
/// offsets as unsigned 32- or 64-bit integers, but the in-memory model uses the
/// platform `Int`; a value that does not fit the signed range cannot be
/// materialized and is rejected.

///|
/// Converts a `UInt` to `Int`, raising when the value exceeds the signed range.
fn UInt32::to_int_checked(self : UInt32) -> Int32 raise ZipError {
  guard self <= (0x7FFFFFFF : UInt32) else {
    raise ZipError(UnsupportedFeature, "zip: u32 exceeds the Int range")
  }
  self.reinterpret_as_int()
}

///|
/// Converts a `UInt64` to `Int`, raising when the value exceeds the signed
/// range.
fn UInt64::to_int_checked(self : UInt64) -> Int32 raise ZipError {
  guard self <= (0x7FFFFFFF : UInt64) else {
    raise ZipError(UnsupportedFeature, "zip: u64 exceeds the Int range")
  }
  self.to_int()
}

///|
/// Converts an `Int` to `UInt`, raising when the value is negative.
fn Int32::to_uint_checked(self : Int32) -> UInt32 raise ZipError {
  guard self >= 0 else {
    raise ZipError(UnsupportedFeature, "zip: negative u32 value")
  }
  self.reinterpret_as_uint()
}

///|
/// Converts an `Int` to `UInt64`, raising when the value is negative.
fn Int32::to_uint64_checked(self : Int32) -> UInt64 raise ZipError {
  guard self >= 0 else {
    raise ZipError(UnsupportedFeature, "zip: negative u64 value")
  }
  UInt64::extend_uint(self.reinterpret_as_uint())
}
