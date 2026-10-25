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
/// Type representing a foreign byte buffer
struct Buffer(UInt64)

///|
#unsafe_skip_stub_check
fn Buffer::is_null_ffi(buf : Buffer) -> Bool = "moonbitlang/async" "c_buffer/is_null"

///|
/// Copy data into a foreign buffer from a MoonBit bytes object
#unsafe_skip_stub_check
#borrow(src)
pub fn Buffer::blit_from_bytes(
  dst : Buffer,
  dst_offset~ : Int32 = 0,
  src~ : Bytes,
  src_offset~ : Int32 = 0,
  len~ : Int32,
) -> Unit = "moonbitlang/async" "c_buffer/blit_to_c"

///|
/// Copy data into a MoonBit array from a foreign buffer
#unsafe_skip_stub_check
#borrow(dst)
pub fn Buffer::blit_to_bytes(
  src : Buffer,
  src_offset~ : Int32 = 0,
  dst~ : FixedArray[Byte],
  dst_offset~ : Int32 = 0,
  len~ : Int32,
) -> Unit = "moonbitlang/async" "c_buffer/blit_from_c"

///|
/// Get the `index`-th byte from a foreign buffer
#unsafe_skip_stub_check
#borrow(buf)
#alias("_[_]")
pub fn Buffer::get(buf : Buffer, index : Int32) -> Byte = "moonbitlang/async" "c_buffer/c_buffer_get"

///|
/// Return the number of bytes before '\0' in a foreign buffer, similar to `strlen`
#unsafe_skip_stub_check
pub fn Buffer::strlen(buf : Buffer) -> Int32 = "moonbitlang/async" "c_buffer/strlen"

///|
/// Allocate a fresh foreign buffer using system allocator
#unsafe_skip_stub_check
#as_free_fn
pub fn Buffer::new(size : Int32) -> Buffer = "moonbitlang/async" "c_buffer/new"

///|
/// Check if a foreign buffer is null pointer
pub fn Buffer::is_null(buf : Buffer) -> Bool {
  buf.is_null_ffi()
}

///|
#unsafe_skip_stub_check
fn Buffer::free_ffi(buf : Buffer) -> Unit = "moonbitlang/async" "c_buffer/free"

///|
/// Free a foreign pointer using system allocator
pub fn Buffer::free(buf : Buffer) -> Unit {
  if !buf.is_null() {
    buf.free_ffi()
  }
}

///|
#unsafe_skip_stub_check
#borrow(os_str)
fn decode_len(os_str : Buffer, offset : Int32, len : Int32) -> Int32 = "moonbitlang/async" "os_string/decode_len"

///|
#unsafe_skip_stub_check
#borrow(os_str, str)
fn fill_string(
  os_str : Buffer,
  offset : Int32,
  len : Int32,
  str : String,
  str_len : Int32,
) -> Unit = "moonbitlang/async" "os_string/decode"

///|
/// Decode a host-native string buffer.
/// The host owns the platform-specific byte decoding and writes UTF-16 code
/// units into guest-owned MoonBit String storage.
pub fn Buffer::decode_as_os_string(
  os_str : Buffer,
  offset~ : Int32 = 0,
  len~ : Int32 = -1,
) -> String {
  let str_len = decode_len(os_str, offset, len)
  let str = String::make(str_len, '\u{0}')
  fill_string(os_str, offset, len, str, str_len)
  str
}

///|
let _unused_import : Unit = ignore(@utf8.encode(""))
