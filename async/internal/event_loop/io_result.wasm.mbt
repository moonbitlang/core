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
priv struct IoResultHandle(UInt64)

///|
/// In WASM backend, letting overlapped Windows syscall hold reference to
/// (mapped) physical address of WASM memory is unsafe,
/// because `memory.grow` may change the base address of WASM memory.
/// Hence for all output buffer passed to overlapped Windows syscall,
/// we need to allocate a temporary buffer in the runtime instead,
/// and copy output data to the MoonBit buffer only after job completion.
/// To align with native API, this copy phase is implemented as a callback.
#valtype
priv struct IoResult {
  handle : IoResultHandle
  copy_output : ((IoResultHandle, Int32) -> Unit)?
}

///|
fn IoResult::IoResult(
  handle : IoResultHandle,
  copy_output? : (IoResultHandle, Int32) -> Unit,
) -> IoResult {
  { handle, copy_output, }
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::for_file_read(
  len~ : Int32,
  position~ : Int64,
) -> IoResultHandle = "moonbitlang/async" "io/make_file_read_io_result/windows"

///|
#unsafe_skip_stub_check
#borrow(dst)
fn IoResultHandle::copy_read(
  result : IoResultHandle,
  dst : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
) -> Unit = "moonbitlang/async" "io/io_result_copy_read/windows"

///|
fn IoResult::for_file_read(
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
) -> IoResult {
  IoResult(IoResultHandle::for_file_read(len~, position~), copy_output=(
    handle,
    n,
  ) => handle.copy_read(buf, offset~, len=n))
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn IoResultHandle::for_file_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
) -> IoResultHandle = "moonbitlang/async" "io/make_file_write_io_result/windows"

///|
fn IoResult::for_file_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  position~ : Int64,
) -> IoResult {
  IoResult(IoResultHandle::for_file_write(buf, offset~, len~, position~))
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::for_socket_read(
  len~ : Int32,
  flags~ : Int32,
) -> IoResultHandle = "moonbitlang/async" "io/make_socket_read_io_result/windows"

///|
fn IoResult::for_socket_read(
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
) -> IoResult {
  IoResult(IoResultHandle::for_socket_read(len~, flags~), copy_output=(
    handle,
    n,
  ) => handle.copy_read(buf, offset~, len=n))
}

///|
#unsafe_skip_stub_check
#borrow(buf)
fn IoResultHandle::for_socket_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
) -> IoResultHandle = "moonbitlang/async" "io/make_socket_write_io_result/windows"

///|
fn IoResult::for_socket_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
) -> IoResult {
  IoResult(IoResultHandle::for_socket_write(buf, offset~, len~, flags~))
}

///|
#unsafe_skip_stub_check
#borrow(addr)
fn IoResultHandle::for_socket_with_addr_read(
  len~ : Int32,
  flags~ : Int32,
  addr~ : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> IoResultHandle = "moonbitlang/async" "io/make_socket_with_addr_read_io_result/windows"

///|
#unsafe_skip_stub_check
#borrow(dst, addr)
fn IoResultHandle::copy_read_with_addr(
  result : IoResultHandle,
  dst : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> Unit = "moonbitlang/async" "io/io_result_copy_read_with_addr/windows"

///|
fn IoResult::for_socket_with_addr_read(
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
  addr~ : Bytes,
) -> IoResult {
  let handle = IoResultHandle::for_socket_with_addr_read(len~, flags~, addr~)
  IoResult(handle, copy_output=(handle, n) => {
    handle.copy_read_with_addr(buf, offset~, len=n, addr~)
  })
}

///|
#unsafe_skip_stub_check
#borrow(buf, addr)
fn IoResultHandle::for_socket_with_addr_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
  addr~ : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> IoResultHandle = "moonbitlang/async" "io/make_socket_with_addr_write_io_result/windows"

///|
fn IoResult::for_socket_with_addr_write(
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  flags~ : Int32,
  addr~ : Bytes,
) -> IoResult {
  IoResult(
    IoResultHandle::for_socket_with_addr_write(
      buf,
      offset~,
      len~,
      flags~,
      addr~,
    ),
  )
}

///|
#unsafe_skip_stub_check
#borrow(addr)
fn IoResultHandle::for_connect(
  addr : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> IoResultHandle = "moonbitlang/async" "io/make_connect_io_result/windows"

///|
fn IoResult::for_connect(addr : Bytes) -> IoResult {
  IoResult(IoResultHandle::for_connect(addr))
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::for_accept(addr_len : Int32) -> IoResultHandle = "moonbitlang/async" "io/make_accept_io_result/windows"

///|
fn IoResult::for_accept(addr_len : Int32) -> IoResult {
  IoResult(IoResultHandle::for_accept(addr_len))
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::for_read_dir_changes(buf : UInt64) -> IoResultHandle = "moonbitlang/async" "io/make_read_dir_changes_io_result/windows"

///|
fn IoResult::for_read_dir_changes(buf : UInt64, len~ : Int32) -> IoResult {
  ignore(len)
  IoResult(IoResultHandle::for_read_dir_changes(buf))
}

///|
#unsafe_skip_stub_check
#borrow(dst)
fn IoResultHandle::get_accept_peer_addr(
  self : IoResultHandle,
  dst : Bytes,
  dst_len~ : Int32 = dst.length(),
) -> Unit = "moonbitlang/async" "io/get_accept_peer_addr/windows"

///|
fn IoResult::get_accept_peer_addr(self : IoResult, dst : Bytes) -> Unit {
  self.handle.get_accept_peer_addr(dst)
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::free(self : IoResultHandle) -> Unit = "moonbitlang/async" "io/free_io_result/windows"

///|
fn IoResult::free(self : IoResult) -> Unit {
  self.handle.free()
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::event(self : IoResultHandle) -> Int32 = "moonbitlang/async" "io/io_result_get_event/windows"

///|
#unsafe_skip_stub_check
fn IoResultHandle::cancel_ffi(
  self : IoResultHandle,
  handle : @fd_util.Fd,
) -> Int32 = "moonbitlang/async" "io/cancel_io_result/windows"

///|
fn IoResult::cancel_ffi(self : IoResult, handle : @fd_util.Fd) -> Int32 {
  self.handle.cancel_ffi(handle)
}

///|
#unsafe_skip_stub_check
fn IoResultHandle::status_ffi(
  result : IoResultHandle,
  handle : @fd_util.Fd,
) -> Int32 = "moonbitlang/async" "io/io_result_get_status/windows"

///|
fn IoResult::status_ffi(result : IoResult, handle : @fd_util.Fd) -> Int32 {
  result.handle.status_ffi(handle)
}

///|
fn IoResult::copy_read_result(result : IoResult, n : Int32) -> Unit {
  if result.copy_output is Some(copy_output) {
    copy_output(result.handle, n)
  }
}
