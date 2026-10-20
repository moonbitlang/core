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
#cfg(all(target="native", not(platform="windows")))
extern "C" fn gai_strerror(code : Int32) -> @c_buffer.Buffer = "gai_strerror"

///|
#cfg(all(target="native", not(platform="windows")))
fn gai_error_to_string(code : Int32) -> String {
  gai_strerror(code).decode_as_os_string()
}

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(buf, addr)
extern "C" fn recvfrom_unix_ffi(
  fd : @fd_util.Fd,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
) -> Int32 = "moonbit_rt_async_recvfrom"

///|
#unsafe_skip_stub_check
#borrow(buf, addr)
#cfg(target="wasm")
fn recvfrom_unix_ffi(
  fd : @fd_util.Fd,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> Int32 = "moonbitlang/async" "socket/recvfrom/unix"

///|
#cfg(not(platform="windows"))
async fn IoHandle::recvfrom_unix(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  context~ : String,
) -> Int32 {
  let ret = recvfrom_unix_ffi(handle.fd, buf, offset~, len~, addr~)
  if ret >= 0 {
    // The `pause` here prevent a busy loop from exhausting the whole program,
    // and give chance for other tasks to execute.
    @coroutine.pause_nocancel()
    return ret
  }
  let ret = if @errno_util.is_nonblocking_io_error() {
    handle.wait_read()
    recvfrom_unix_ffi(handle.fd, buf, offset~, len~, addr~)
  } else {
    ret
  }
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret
}

///|
/// Receive a new UDP packet from the UDP socket `handle`.
/// The content of the packet would be written to `buf[offset:offset+len]`,
/// while the source address of the packet would be written to `addr`.
#cfg(all(target="native", not(platform="windows")))
pub async fn IoHandle::recvfrom(
  handle : IoHandle,
  buf : FixedArray[Byte],
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  handle.recvfrom_unix(buf, offset~, len~, addr~, context~)
}

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(buf, addr)
extern "C" fn sendto_unix_ffi(
  fd : @fd_util.Fd,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
) -> Int32 = "moonbit_rt_async_sendto"

///|
#unsafe_skip_stub_check
#borrow(buf, addr)
#cfg(target="wasm")
fn sendto_unix_ffi(
  fd : @fd_util.Fd,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> Int32 = "moonbitlang/async" "socket/sendto/unix"

///|
#cfg(not(platform="windows"))
async fn IoHandle::sendto_unix(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  context~ : String,
) -> Int32 {
  let ret = sendto_unix_ffi(handle.fd, buf, offset~, len~, addr~)
  if ret >= 0 {
    @coroutine.pause_nocancel()
    return ret
  }
  let ret = if @errno_util.is_nonblocking_io_error() {
    handle.wait_write()
    sendto_unix_ffi(handle.fd, buf, offset~, len~, addr~)
  } else {
    ret
  }
  if ret < 0 {
    @os_error.check_errno(context)
  }
  ret
}

///|
/// Send a UDP packet to `addr` using the UDP socket `handle`
#cfg(all(target="native", not(platform="windows")))
pub async fn IoHandle::sendto(
  handle : IoHandle,
  buf : Bytes,
  offset~ : Int32,
  len~ : Int32,
  addr~ : Bytes,
  context~ : String,
) -> Int32 {
  @coroutine.check_cancellation()
  handle.sendto_unix(buf, offset~, len~, addr~, context~)
}

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(addr)
extern "C" fn connect_unix_ffi(sock : @fd_util.Fd, addr : Bytes) -> Int32 = "moonbit_rt_async_connect"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn connect_unix_ffi(
  sock : @fd_util.Fd,
  addr : Bytes,
  addr_len~ : Int32 = addr.length(),
) -> Int32 = "moonbitlang/async" "socket/connect/unix"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn get_socket_err(sock : @fd_util.Fd) -> Int32 = "moonbit_rt_getsockerr"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_socket_err(sock : @fd_util.Fd) -> Int32 = "moonbitlang/async" "socket/getsockerr/unix"

///|
#cfg(not(platform="windows"))
async fn IoHandle::connect_unix(
  handle : IoHandle,
  addr : Bytes,
  context~ : String,
) -> Unit {
  if 0 == connect_unix_ffi(handle.fd, addr) {
    return
  }
  if @errno_util.is_nonblocking_io_error() {
    handle.wait_write()
    let err = get_socket_err(handle.fd)
    if err < 0 {
      @os_error.check_errno(context)
    } else if err > 0 {
      raise @os_error.from_errno(err, context~)
    }
  } else {
    @os_error.check_errno(context)
  }
}

///|
/// Connect to remote peer at `addr` asynchronously on a TCP Socket
#cfg(all(target="native", not(platform="windows")))
pub async fn IoHandle::connect(
  handle : IoHandle,
  addr : Bytes,
  context~ : String,
) -> Unit {
  @coroutine.check_cancellation()
  handle.connect_unix(addr, context~)
}

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(addr_buf)
extern "C" fn accept_unix_ffi(
  sock : @fd_util.Fd,
  addr_buf : Bytes,
) -> @fd_util.Fd = "moonbit_rt_async_accept"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr_buf)
fn accept_unix_ffi(
  sock : @fd_util.Fd,
  addr_buf : Bytes,
  addr_len~ : Int32 = addr_buf.length(),
) -> @fd_util.Fd = "moonbitlang/async" "socket/accept/unix"

///|
/// Accept a new connection from a TCP server socket on Unix.
/// On Unix, `accept` will create and return a fresh socket object for the new connection.
#cfg(not(platform="windows"))
pub async fn IoHandle::accept_unix(
  handle : IoHandle,
  addr : Bytes,
  context~ : String,
) -> IoHandle {
  @coroutine.check_cancellation()
  let conn = accept_unix_ffi(handle.fd, addr)
  let conn = if @fd_util.fd_is_valid(conn) {
    // The `pause` here prevent a busy `accept` loop from exhausting the whole program,
    // and give chance for other tasks to execute.
    @coroutine.pause_nocancel()
    conn
  } else if @errno_util.is_nonblocking_io_error() {
    handle.wait_read()
    accept_unix_ffi(handle.fd, addr)
  } else {
    conn
  }
  if !@fd_util.fd_is_valid(conn) {
    @os_error.check_errno(context)
  }
  IoHandle::from_fd(conn, kind=Socket)
}
