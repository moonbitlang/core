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
#cfg(platform="windows")
#external
priv type IoResult

///|
#cfg(platform="windows")
#owned(buf)
extern "C" fn IoResult::for_file_read(
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
) -> IoResult = "moonbit_rt_make_file_read_io_result"

///|
#cfg(platform="windows")
#owned(buf)
extern "C" fn IoResult::for_file_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
) -> IoResult = "moonbit_rt_make_file_write_io_result"

///|
#cfg(platform="windows")
#owned(buf)
extern "C" fn IoResult::for_socket_read(
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
) -> IoResult = "moonbit_rt_make_socket_read_io_result"

///|
#cfg(platform="windows")
#owned(buf)
extern "C" fn IoResult::for_socket_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
) -> IoResult = "moonbit_rt_make_socket_write_io_result"

///|
#cfg(platform="windows")
#owned(buf, addr)
extern "C" fn IoResult::for_socket_with_addr_read(
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
  addr~ : Bytes,
) -> IoResult = "moonbit_rt_make_socket_with_addr_read_io_result"

///|
#cfg(platform="windows")
#owned(buf, addr)
extern "C" fn IoResult::for_socket_with_addr_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
  addr~ : Bytes,
) -> IoResult = "moonbit_rt_make_socket_with_addr_write_io_result"

///|
#cfg(platform="windows")
#owned(addr)
extern "C" fn IoResult::for_connect(addr : Bytes) -> IoResult = "moonbit_rt_make_connect_io_result"

///|
#cfg(platform="windows")
extern "C" fn IoResult::for_accept(addr_len : Int32) -> IoResult = "moonbit_rt_make_accept_io_result"

///|
#cfg(platform="windows")
#borrow(dst)
extern "C" fn IoResult::get_accept_peer_addr(
  result : IoResult,
  dst : Bytes,
) -> Unit = "moonbit_rt_get_accept_peer_addr"

///|
#cfg(platform="windows")
extern "C" fn IoResult::for_read_dir_changes(
  buf : @c_buffer.Buffer,
  len~ : Int32,
) -> IoResult = "moonbit_rt_make_read_dir_changes_io_result"

///|
#cfg(platform="windows")
extern "C" fn IoResult::free(self : IoResult) = "moonbit_rt_free_io_result"

///|
#cfg(platform="windows")
extern "C" fn IoResult::event(self : IoResult) -> Int32 = "moonbit_rt_io_result_get_event"

///|
#cfg(platform="windows")
extern "C" fn IoResult::cancel_ffi(
  self : IoResult,
  handle : @fd_util.Fd,
) -> Int32 = "moonbit_rt_cancel_io_result"

///|
#cfg(platform="windows")
extern "C" fn IoResult::status_ffi(
  result : IoResult,
  handle : @fd_util.Fd,
) -> Int32 = "moonbit_rt_io_result_get_status"

///|
/// There is no need to copy data on completion of an IOCP operation in native backend.
/// This is mainly used to align the API shape with WASM.
#cfg(platform="windows")
fn IoResult::copy_read_result(result : IoResult, _ : Int32) -> Unit {
  ignore(result)
}
