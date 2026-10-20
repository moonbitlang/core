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
#external
pub type Buffer

///|
/// Copy data into a foreign buffer from a MoonBit bytes object
#borrow(src)
pub extern "C" fn Buffer::blit_from_bytes(
  dst : Buffer,
  dst_offset~ : Int32 = 0,
  src~ : Bytes,
  src_offset~ : Int32 = 0,
  len~ : Int32,
) = "moonbit_rt_blit_to_c"

///|
/// Copy data into a MoonBit array from a foreign buffer
#borrow(dst)
pub extern "C" fn Buffer::blit_to_bytes(
  src : Buffer,
  src_offset~ : Int32 = 0,
  dst~ : FixedArray[Byte],
  dst_offset~ : Int32 = 0,
  len~ : Int32,
) = "moonbit_rt_blit_from_c"

///|
/// Get the `index`-th byte from a foreign buffer
#borrow(buf)
#alias("_[_]")
pub extern "C" fn Buffer::get(buf : Buffer, index : Int32) -> Byte = "moonbit_rt_c_buffer_get"

///|
/// Return the number of bytes before '\0' in a foreign buffer, similar to `strlen`
pub extern "C" fn Buffer::strlen(buf : Buffer, offset~ : Int32 = 0) -> Int32 = "moonbit_rt_strlen"

///|
/// Check if a foreign buffer is null pointer
pub extern "C" fn Buffer::is_null(ptr : Buffer) -> Bool = "moonbit_rt_pointer_is_null"

///|
/// Free a foreign pointer using system allocator
pub extern "C" fn Buffer::free(buf : Buffer) = "free"

///|
/// Allocate a fresh foreign buffer using system allocator
#as_free_fn
pub extern "C" fn Buffer::new(size : Int32) -> Buffer = "moonbit_rt_make_c_buffer"

///|
/// Decode a host-native string buffer.
/// The host owns the platform-specific byte decoding and writes UTF-16 code
/// units into guest-owned MoonBit String storage.
#cfg(not(platform="windows"))
pub fn Buffer::decode_as_os_string(
  self : Buffer,
  offset~ : Int32 = 0,
  len~ : Int32 = self.strlen(offset~),
) -> String {
  let data = FixedArray::make(len, b'\x00')
  self.blit_to_bytes(dst=data, src_offset=offset, len~)
  @utf8.decode_lossy(data.unsafe_reinterpret_as_bytes())
}

///|
/// Decode a host-native string buffer.
/// The host owns the platform-specific byte decoding and writes UTF-16 code
/// units into guest-owned MoonBit String storage.
#cfg(platform="windows")
pub extern "C" fn Buffer::decode_as_os_string(
  self : Buffer,
  offset~ : Int32 = 0,
  len~ : Int32 = -1,
) -> String = "moonbit_rt_c_buffer_as_string"

///|
#cfg(platform="windows")
let _unused_import : Unit = ignore(@utf8.encode(""))
