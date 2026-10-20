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
/// A Tcp connection
pub struct Tcp {
  /// The local address of a TCP connection
  addr : Addr
  priv io : @event_loop.IoHandle
  priv reader_ctrl : @io.BinaryReaderController
  priv writer_ctrl : @io.BinaryWriterController
}

///|
/// Close a TCP connection, release associated resource
pub fn Tcp::close(self : Tcp) -> Unit {
  self.io.close()
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a TCP connection
pub fn Tcp::fd(self : Tcp) -> @fd_util.Fd {
  self.io.fd()
}

///|
/// A TCP server that can accept new connections
pub struct TcpServer {
  /// The actual listen address of the server
  addr : Addr
  priv io : @event_loop.IoHandle
}

///|
/// Create a TCP server that is bound to `addr`,
/// listening for incoming connections.
///
/// If `addr` is the IPv6 wildcard address `[::]`
/// and `dual_stack` is `true` (`true` by default),
/// the server will work in dual stack mode,
/// accepting connections from both IPv4 clients and IPv6 clients.
/// The address of IPv4 clients are represented via IPv4-mapped IPv6 address.
///
/// If `addr` is not `[::]`, `dual_stack` is ignored.
///
/// If the port of `addr` is zero, the server will be bound to a random port,
/// assigned by the operating system.
/// The actual listen address can be retrieved via `.addr()`.
///
/// If `reuse_addr` is `true` (`false` by default),
/// the `SO_REUSEADDR` option will be enabled on the server,
/// allowing binding to `addr` even if there are still
/// dead-ish `TIME_WAIT` sockets on that address.
///
/// On Windows, `TIME_WAIT` sockets are always ignored,
/// so the behavior is always `reuse_addr=true` and `reuse_addr` will be ignored.
///
/// On MacOS (BSD), `reuse_addr` has the extra side effect that
/// a server binding to a specific address may "steal" the specific interface
/// from a previous wildcard bind (`0.0.0.0`),
/// and similarly a server binding to a wildcard address can bind to
/// the remaining interfaces if a bind to a specific interface already exists.
/// This side effect cannot be isolated, so `reuse_addr` should be used with this in mind.
///
/// If `reuse_port_lb` is `true` (`false` by default), `SO_REUSEPORT` is enabled
/// so several sockets — typically one per worker process — can bind the same
/// address at once while the kernel load-balances incoming connections across
/// them. This is the usual basis for a multi-process server: a supervisor
/// `exec`s N workers, each binds the same address with this option, and the
/// kernel spreads connections, so no socket needs to be shared between processes.
///
/// The load-balancing semantic is Linux-only. `SO_REUSEPORT` also exists on the
/// BSDs and MacOS, but there it does not evenly distribute connections — which
/// socket accepts a given connection is unspecified — so `reuse_port_lb` takes
/// effect only on Linux, including Wasm hosted by Moonrun on Linux, and is
/// ignored everywhere else (BSD, MacOS, Windows).
#alias(new, deprecated)
pub async fn TcpServer::TcpServer(
  addr : Addr,
  dual_stack~ : Bool = true,
  reuse_addr~ : Bool = false,
  reuse_port_lb~ : Bool = false,
) -> TcpServer {
  let context = "@socket.TcpServer::new()"
  let family = addr.family()
  let sock = make_tcp_socket(family, context~)
  let io = @event_loop.IoHandle::from_fd(sock, kind=Socket, read_only=true)
  errdefer io.close()
  if addr.is_ipv6() && addr.is_ipv6_wildcard() {
    if 0 != set_ipv6_only(sock, !dual_stack) {
      @os_error.check_errno(context)
    }
  }
  if !(@event_loop.platform is Windows) && reuse_addr {
    guard allow_reuse_addr(sock) >= 0 else { @os_error.check_errno(context) }
  }
  if @event_loop.platform is Linux && reuse_port_lb {
    guard allow_reuse_port(sock) >= 0 else { @os_error.check_errno(context) }
  }
  io.bind(addr.0, context~)
  if 0 != listen_ffi(sock) {
    @os_error.check_errno(context)
  }
  // If `addr` specifies zero as the listen port,
  // the OS will assign a random port for us,
  // in this case, we need to retrieve the actual port via `getsockname`.
  let addr = getsockname(sock, family, context~)
  { io, addr, }
}

///|
/// Get the address the server is listening on
#deprecated("use `.addr` instead")
pub fn TcpServer::addr(server : TcpServer) -> Addr {
  server.addr
}

///|
/// Start the main loop of a TCP server,
/// keep listening for new connections
/// and handle connections using the callback `f`.
/// `f` will be supplied the new connection and the address of the client.
///
/// The client connection will be closed automatically after `f` exits,
/// so `f` must not close the client connection.
/// The server will be automatically closed if `run_forever` fails.
///
/// If `allow_failure` is `true` (`true` by default),
/// failure in `f` will be silently ignored.
///
/// If `max_connections` is present,
/// at most `max_connections` clients are allowed in parallel.
/// New clients will only get handled after a previous client terminates.
pub async fn TcpServer::run_forever(
  self : TcpServer,
  f : async (Tcp, Addr) -> Unit,
  allow_failure~ : Bool = true,
  max_connections? : Int32,
) -> Unit {
  defer self.close()
  let conn_limit = match max_connections {
    None => None
    Some(n) => Some(@async_io.Semaphore(n))
  }
  @async_io.with_task_group() <| group => {
    for ;; {
      // only accept the connection if we have enough
      // concurrency budget.
      if conn_limit is Some(limit) {
        limit.acquire()
      }
      // if `accept` failed, the whole group will fail anyway,
      // so no need to release the semaphore here.
      let (conn, addr) = self.accept()
      group.spawn_bg(allow_failure~) <| () => {
        defer conn.close()
        if conn_limit is Some(limit) {
          defer limit.release()
          f(conn, addr)
        } else {
          f(conn, addr)
        }
      }
    }
  }
}

///|
/// Close a TCP server, release associated resource
pub fn TcpServer::close(self : TcpServer) -> Unit {
  self.io.close()
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a TCP server
pub fn TcpServer::fd(self : TcpServer) -> @fd_util.Fd {
  self.io.fd()
}

///|
#cfg(not(platform="windows"))
async fn TcpServer::accept_unix(self : TcpServer) -> (Tcp, Addr) {
  // Create a big enough Addr to hold both IPv4 and IPv6 address
  let addr = Addr::empty(self.addr.family())
  let conn = self.io.accept_unix(addr.0, context="@socket.TcpServer::accept()")
  errdefer conn.close()
  if disable_nagle(conn.fd()) < 0 {
    @os_error.check_errno("@socket.TcpServer::accept(): set TCP_NODELAY")
  }
  @fd_util.set_cloexec(conn.fd(), context="@socket.TcpServer::accept()")
  // The local address of a server connection is the same as the listen address
  (
    {
      io: conn,
      addr: self.addr,
      reader_ctrl: BinaryReaderController(),
      writer_ctrl: BinaryWriterController(),
    },
    addr,
  )
}

///|
/// Accept a new connection on a listening TCP server.
/// The accepted connection will be returned together with the address of peer.
#cfg(any(target="wasm", platform="windows"))
async fn TcpServer::accept_windows(self : TcpServer) -> (Tcp, Addr) {
  let context = "@socket.TcpServer::accept()"
  let family = self.addr.family()
  let conn_sock = make_tcp_socket(family, context~)
  let conn = @event_loop.IoHandle::from_fd(conn_sock, kind=Socket)
  errdefer conn.close()
  let addr = Addr::empty(family)
  self.io.accept_windows(conn, addr.0, context~)
  if disable_nagle(conn_sock) < 0 {
    @os_error.check_errno("@socket.TcpServer::accept(): set TCP_NODELAY")
  }
  // The local address of a server connection is the same as the listen address
  (
    {
      io: conn,
      addr: self.addr,
      reader_ctrl: BinaryReaderController(),
      writer_ctrl: BinaryWriterController(),
    },
    addr,
  )
}

///|
/// Accept a new connection on a listening TCP server.
/// The accepted connection will be returned together with the address of peer.
#cfg(all(target="native", not(platform="windows")))
pub async fn TcpServer::accept(self : TcpServer) -> (Tcp, Addr) {
  self.accept_unix()
}

///|
/// Accept a new connection on a listening TCP server.
/// The accepted connection will be returned together with the address of peer.
#cfg(platform="windows")
pub async fn TcpServer::accept(self : TcpServer) -> (Tcp, Addr) {
  self.accept_windows()
}

///|
/// Accept a new connection on a listening TCP server.
/// The accepted connection will be returned together with the address of peer.
#cfg(target="wasm")
pub async fn TcpServer::accept(self : TcpServer) -> (Tcp, Addr) {
  if @event_loop.platform is Windows {
    self.accept_windows()
  } else {
    self.accept_unix()
  }
}

///|
/// Enable TCP keep alive on the socket.
///
/// `idle_before_keep_alive` is the duration of idle time in seconds to wait
/// before sending the first keep alive probe.
///
/// `keep_alive_count` is the number of keep alive probe to try
/// before closing the connection.
///
/// `keep_alive_interval` is the time in seconds between two keep alive probes.
pub fn Tcp::enable_keepalive(
  self : Tcp,
  idle_before_keep_alive~ : Int32 = -1,
  keep_alive_count~ : Int32 = -1,
  keep_alive_interval~ : Int32 = -1,
) -> Unit raise {
  let ret = enable_keepalive_ffi(
    self.io.fd(),
    idle_before_keep_alive,
    keep_alive_count,
    keep_alive_interval,
  )
  if ret < 0 {
    @os_error.check_errno("@socket.Tcp::enable_keepalive()")
  }
}

///|
/// Make connection to a remote address using `connect(2)` system call.
pub async fn Tcp::connect(addr : Addr) -> Tcp {
  let context = "@socket.Tcp::connect()"
  let family = addr.family()
  let sock = make_tcp_socket(family, context~)
  let conn = @event_loop.IoHandle::from_fd(sock, kind=Socket)
  errdefer conn.close()
  if disable_nagle(sock) < 0 {
    @os_error.check_errno("@socket.Tcp::connect(): set TCP_NODELAY")
  }
  conn.connect(addr.0, context~)
  let addr = getsockname(sock, family, context~)
  {
    io: conn,
    addr,
    reader_ctrl: BinaryReaderController(),
    writer_ctrl: BinaryWriterController(),
  }
}

///|
/// Get the local address of a TCP connection.
pub fn Tcp::addr(sock : Tcp) -> Addr {
  sock.addr
}

///|
pub impl @io.BinaryReader for Tcp

///|
impl @io.BinaryReaderImpl for Tcp with fn raw_read_impl(
  self,
  buf,
  offset~,
  max_len~,
) {
  self.io.read(
    buf,
    offset~,
    len=max_len,
    context="impl @io.BinaryReader for @socket.Tcp",
  )
}

///|
impl @io.BinaryReaderImpl for Tcp with fn get_controller(self) {
  self.reader_ctrl
}

///|
pub extend Tcp with @io.BinaryReader::{
  read_into,
  read,
  read_at_least,
  peek,
  peek_at_least,
  read_exactly,
  drop_exactly,
  peek_exactly,
  read_all,
  drop_all,
  read_until,
  peek_until,
}

///|
pub impl @io.BinaryWriter for Tcp

///|
impl @io.BinaryWriterImpl for Tcp with fn raw_write_impl(
  self,
  buf,
  offset~,
  len~,
) {
  self.io.write(
    buf,
    offset~,
    len~,
    context="impl @io.BinaryWriter for @socket.Tcp",
  )
}

///|
impl @io.BinaryWriterImpl for Tcp with fn get_controller(self) {
  self.writer_ctrl
}

///|
pub extend Tcp with @io.BinaryWriter::{write, write_reader}
