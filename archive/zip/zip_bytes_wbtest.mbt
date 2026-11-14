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
/// Little-endian readers at arbitrary offsets, for inspecting written archives.

///|
fn read_u16_le_at(bytes : BytesView, offset : Int32) -> Int32 {
  guard bytes[offset:] is [u16le(value), ..] else { abort("short u16 read") }
  value.reinterpret_as_int()
}

///|
fn read_u32_le_at_raw(bytes : BytesView, offset : Int32) -> UInt32 {
  guard bytes[offset:] is [u32le(value), ..] else { abort("short u32 read") }
  value
}

///|
fn read_u64_le_at(bytes : BytesView, offset : Int32) -> UInt64 {
  guard bytes[offset:] is [u64le(value), ..] else { abort("short u64 read") }
  value
}
