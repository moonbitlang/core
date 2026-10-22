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
/// Transfers a fully initialized, exclusively owned byte array to immutable
/// Bytes without copying. Both types have the same byte-array representation.
/// SAFETY: the caller must relinquish every mutable alias after this call.
fn owned_zip_buffer_to_bytes(buffer : FixedArray[Byte]) -> Bytes = "%identity"

///|
/// Borrow an output array synchronously for checksum calculation. This alias
/// must never escape the call or survive another write to the output array.
fn borrowed_zip_buffer_bytes(buffer : FixedArray[Byte]) -> Bytes = "%identity"
