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
/// A UDP client "connected" to a remote UDP server.
///
/// UDP is a connectionless protocol, here "connected" means
/// the client always send packet to and receive packet from
/// the specified remote server.
///
/// UDP does not really have a clear client/server distinction,
/// especially when multicast is involved.
/// The essence of `UdpClient` is a UDP socket without a fixed/well-known port.
pub struct UdpClient {
  /// Local address of the client
  addr : Addr
  priv io : @event_loop.IoHandle
  priv mut dst_addr : Addr?
}

///|
/// Create a new UDP client connected to server at `addr`.
/// The client always send packet to and receive packet from
/// the specified remote server.
///
/// If `addr` is a multicast address,
/// `connect` will not be called under the hood,
/// and the client may receive packets from arbitrary peer.
/// However, since the port of the client is random,
/// the client effectively can only receive packets
/// from multicast servers that have received packets from this client.
#alias(new, deprecated)
pub async fn UdpClient::UdpClient(addr : Addr) -> UdpClient {
  let context = "@socket.UdpClient::new()"
  let family = addr.family()
  let sock = make_udp_socket(family, multicast=false, context~)
  let io = @event_loop.IoHandle::from_fd(sock, kind=Socket, read_only=true)
  errdefer io.close()
  let dst_addr = if addr.is_multicast() {
    if @event_loop.platform is Windows {
      let local_addr = Addr::any(family)
      io.bind(local_addr.0, context~)
    }
    Some(addr)
  } else if 0 != connect_ffi(sock, addr) {
    @os_error.check_errno(context)
    None
  } else {
    None
  }
  let local_addr = getsockname(sock, family, context~)
  { io, addr: local_addr, dst_addr, }
}

///|
/// Close a UDP client, release associated resource
pub fn UdpClient::close(self : UdpClient) -> Unit {
  self.io.close()
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a UDP client
pub fn UdpClient::fd(self : UdpClient) -> @fd_util.Fd {
  self.io.fd()
}

///|
/// Set the outgoing interface used for sending multicast packets with this client.
///
/// This function is IPv4-only. For IPv6, use `set_multicast_interface_v6` instead.
pub fn UdpClient::set_multicast_interface(
  self : UdpClient,
  addr : Addr,
) -> Unit raise {
  let context = "@socket.UdpClient::set_multicast_interface()"
  guard! self.addr.family() is IPv4
  guard addr.family() is IPv4 else {
    raise Failure::Failure("\{context}: expected IPv4 address")
  }
  set_multicast_interface(self.io.fd(), addr, context~)
}

///|
/// Set the outgoing interface used for sending multicast packets with this client.
/// The interface is provided via IPv6 zone suffix index.
/// It can either be a decimal string for a raw interface index,
/// or a network interface name.
///
/// This function is IPv6-only. For IPv4, use `set_multicast_interface` instead.
pub fn UdpClient::set_multicast_interface_v6(
  self : UdpClient,
  interface : String,
) -> Unit raise {
  guard! self.addr.family() is IPv6
  let context = "@socket.UdpClient::set_multicast_interface_v6()"
  set_multicast_interface_v6(
    self.io.fd(),
    parse_ipv6_zone_suffix(interface, context~),
    context~,
  )
}

///|
/// Set the multicast TTL (or hop limit for IPv6) for this client.
/// `ttl=0` means packet never goes out of local machine.
/// `ttl=1` means packet never goes out of local subnet.
pub fn UdpClient::set_multicast_ttl(
  self : UdpClient,
  ttl : Int32,
) -> Unit raise {
  set_multicast_ttl(
    self.io.fd(),
    ttl,
    family=self.addr.family(),
    context="@socket.UdpClient::set_multicast_ttl()",
  )
}

///|
/// Set the multicast loopback option for this client.
/// On Windows: make sure multicast packets sent from local machine is not received by this client.
/// On other systems: make sure multicast packets sent by this client are not routed back to local machine
///
/// Note that the loopback setting does not apply for localhost traffic.
pub fn UdpClient::set_multicast_loopback(
  self : UdpClient,
  loopback : Bool,
) -> Unit raise {
  set_multicast_loopback(
    self.io.fd(),
    loopback,
    family=self.addr.family(),
    context="@socket.UdpClient::set_multicast_loopback()",
  )
}

///|
/// Connect the client to a remote address,
/// subsequently the client will send packets to this address,
/// and only receive packets from this address.
///
/// Unicast UDP clients are connected automatically,
/// so `connect` is mainly useful for turning a multicast client into a unicast one.
/// The typical workflow is to create the client as a multicast client,
/// send multicast packets, and wait for response from servers listening on the multicast address.
/// Once a responding server is found, use `connect` to turn the client into a unicast one,
/// and start point-to-point communication with the discovered server.
pub fn UdpClient::connect(self : UdpClient, addr : Addr) -> Unit raise {
  let context = "@socket.UdpClient::connect()"
  if 0 != connect_ffi(self.io.fd(), addr) {
    @os_error.check_errno(context)
  }
  self.dst_addr = None
}

///|
/// A UDP server bound to a listen address and receive packets from clients.
///
/// UDP does not really have a clear client/server distinction,
/// especially when multicast is involved.
/// The essence of `UdpServer` is a UDP socket with a fixed/well-known port.
pub struct UdpServer {
  addr : Addr
  priv io : @event_loop.IoHandle
  priv is_multicast_only : Bool
}

///|
/// Close a UDP server, release associated resource
pub fn UdpServer::close(self : UdpServer) -> Unit {
  self.io.close()
}

///|
/// Get the underlying file descriptor/Windows HANDLE of a UDP server
pub fn UdpServer::fd(self : UdpServer) -> @fd_util.Fd {
  self.io.fd()
}

///|
/// Create a UDP server listening at `addr`.
///
/// If `addr` is the IPv6 wildcard address `[::]`
/// and `dual_stack` is `true` (`true` by default),
/// the server will work in dual stack mode,
/// receiving packets from both IPv4 peers and IPv6 peers.
/// The address of IPv4 peers are represented via IPv4-mapped IPv6 address.
///
/// If `addr` is not `[::]`, `dual_stack` is ignored.
///
/// If the port of `addr` is zero, the server will be bound to a random port,
/// assigned by the operating system.
/// The actual listen address can be retrieved via `.addr()`.
///
/// The server will only receive packets whose destination address matches `addr`.
/// So if you want to receive multicast traffic,
/// the server should be bound to `0.0.0.0` or `[::]`.
/// DO NOT bind the server to a multicast address: this is not supported on Windows.
/// For multicast-only servers, use `UdpServer::multicast()` instead.
#alias(new, deprecated)
pub async fn UdpServer::UdpServer(
  addr : Addr,
  dual_stack~ : Bool = true,
) -> UdpServer {
  let context = "@socket.UdpServer::new()"
  let family = addr.family()
  let sock = make_udp_socket(family, multicast=false, context~)
  let io = @event_loop.IoHandle::from_fd(sock, kind=Socket)
  errdefer io.close()
  if addr.is_ipv6() && addr.is_ipv6_wildcard() {
    if 0 != set_ipv6_only(sock, !dual_stack) {
      @os_error.check_errno(context)
    }
  }
  io.bind(addr.0, context~)
  // If `addr` specifies zero as the listen port,
  // the OS will assign a random port for us,
  // in this case, we need to retrieve the actual port via `getsockname`.
  let addr = getsockname(sock, family, context~)
  { io, addr, is_multicast_only: false, }
}

///|
/// Create a multicast-only UDP server listening for multicast packets towards `multi_addr`. 
/// The server will only receive packets towards `multi_addr`,
/// no unicast traffic will be received.
///
/// Multicast only servers created via `UdpServer::multicast` are shared.
/// There can be multiple such server listening on the same address at the same time.
///
/// The server will automatically join the IP multicast group at `multi_addr`,
/// using interface `interface_addr` (defaults to a random interface chosen by the OS).
/// Only the IP part of `interface_addr` matters, the port is irrelevant.
///
/// Due to OS limitation, currently every multicast-only server
/// can listen for only one multicast IP.
/// Calling `join_multicast_group` on server created by `UdpServer::multicast`
/// with different address simply does not work.
/// Users can join the same IP with a different interface using `join_multicast_group`, though.
///
/// Currently this function is IPv4 only.
/// There is no simple way to implement multicast-only IPv6 socket on Linux/MacOS.
pub async fn UdpServer::multicast(
  multi_addr : Addr,
  interface_addr~ : Addr = Addr::new(0, 0),
) -> UdpServer {
  let context = "@socket.UdpServer::multicast()"
  let family = multi_addr.family()
  guard family is IPv4 else {
    abort("@socket.UdpServer::multicast() is IPv4 only")
  }
  let sock = make_udp_socket(family, multicast=true, context~)
  let io = @event_loop.IoHandle::from_fd(sock, kind=Socket)
  errdefer io.close()
  if @event_loop.platform is Windows {
    let local_addr = Addr::new(0, multi_addr.port())
    io.bind(local_addr.0, context~)
  } else {
    io.bind(multi_addr.0, context~)
  }
  join_multicast_group(sock, multi_addr, interface_addr, context~)
  // If `addr` specifies zero as the listen port,
  // the OS will assign a random port for us,
  // in this case, we need to retrieve the actual port via `getsockname`.
  let addr = getsockname(sock, family, context~)
  { io, addr, is_multicast_only: true, }
}

///|
/// Set the outgoing interface used for sending multicast packets with this server.
///
/// This function is IPv4-only. For IPv6, use `set_multicast_interface_v6` instead.
pub fn UdpServer::set_multicast_interface(
  self : UdpServer,
  addr : Addr,
) -> Unit raise {
  guard! self.addr.family() is IPv4
  set_multicast_interface(
    self.io.fd(),
    addr,
    context="@socket.UdpServer::set_multicast_interface()",
  )
}

///|
/// Set the outgoing interface used for sending multicast packets with this client.
/// The interface is provided via IPv6 zone suffix index.
/// It can either be a decimal string for a raw interface index,
/// or a network interface name.
///
/// This function is IPv6-only. For IPv4, use `set_multicast_interface` instead.
pub fn UdpServer::set_multicast_interface_v6(
  self : UdpServer,
  interface : String,
) -> Unit raise {
  guard! self.addr.family() is IPv6
  let context = "@socket.UdpServer::set_multicast_interface_v6()"
  set_multicast_interface_v6(
    self.io.fd(),
    parse_ipv6_zone_suffix(interface, context~),
    context~,
  )
}

///|
/// Set the multicast TTL (or hop limit for IPv6) for this client.
/// `ttl=0` means packet never goes out of local machine.
/// `ttl=1` means packet never goes out of local subnet.
pub fn UdpServer::set_multicast_ttl(
  self : UdpServer,
  ttl : Int32,
) -> Unit raise {
  set_multicast_ttl(
    self.io.fd(),
    ttl,
    family=self.addr.family(),
    context="@socket.UdpServer::set_multicast_ttl()",
  )
}

///|
/// Set the multicast loopback option for this server.
/// On Windows: make sure multicast packets sent from local machine is not received by this server.
/// On other systems: make sure multicast packets sent by this server are not routed back to local machine
///
/// Note that the loopback setting does not apply for localhost traffic.
pub fn UdpServer::set_multicast_loopback(
  self : UdpServer,
  loopback : Bool,
) -> Unit raise {
  set_multicast_loopback(
    self.io.fd(),
    loopback,
    family=self.addr.family(),
    context="@socket.UdpServer::set_multicast_loopback()",
  )
}

///|
/// Let the server join multicast group at address `multi_addr`, via interface `interface_addr`.
/// `interface_addr` defaults to a random interface chosen by the OS.
/// Only the IP part of `multi_addr` and `interface_addr` matters, the port is irrelevant.
///
/// Note that `join_multicast_group` is mainly about IGMP related stuff,
/// it does not serve as a packet filter.
/// A UDP server can receive all packets whose destination match the server's address.
/// Some consquence of this:
///
/// - The port to receive multicast traffic is determined on server creation
///
/// - if the server is bound to a specific interface, it will not receive any multicast traffic,
///   because multicast traffic has special destination IP
///
/// - multicast-only server created by `UdpServer::multicast` cannot join
///   multiple multicast groups with different IP address.
///
/// This function is IPv4 only. For IPv6 multicast, use `join_multicast_group_v6` instead.
pub fn UdpServer::join_multicast_group(
  self : UdpServer,
  multi_addr : Addr,
  interface_addr~ : Addr = Addr::new(0, 0),
) -> Unit raise {
  let context = "@socket.UdpServer::join_multicast_group()"
  guard self.addr.family() is IPv4 else { abort("\{context} is IPv4 only") }
  guard multi_addr.family() is IPv4 && interface_addr.family() is IPv4 else {
    raise Failure::Failure("\{context}: expected IPv4 address")
  }
  join_multicast_group(self.io.fd(), multi_addr, interface_addr, context~)
}

///|
/// Let the server join multicast group at address `multi_addr`, via interface `interface`.
/// `interface`, if provided, should use IPv6 zone suffix syntax,
/// meaning it can either be a decimal string for raw interface index, or a network interface name.
/// `interface` defaults to "0", meaning a default output interface chosen by the OS.
/// For interface-local/link-local multicast packets, the interface must be explicitly specified.
/// Only the IP part of `multi_addr` matters, the port is irrelevant.
///
/// Note that `join_multicast_group` is mainly about IGMP related stuff,
/// it does not serve as a packet filter.
/// A UDP server can receive all packets whose destination match the server's address.
/// Some consquence of this:
///
/// - The port to receive multicast traffic is determined on server creation
///
/// - if the server is bound to a specific interface, it will not receive any multicast traffic,
///   because multicast traffic has special destination IP
///
/// This function is IPv6 only. For IPv4 multicast, use `join_multicast_group` instead.
pub fn UdpServer::join_multicast_group_v6(
  self : UdpServer,
  multi_addr : Addr,
  interface~ : String = "0",
) -> Unit raise {
  let context = "@socket.UdpServer::join_multicast_group_v6()"
  guard self.addr.family() is IPv6 else { abort("\{context} is IPv6 only") }
  guard multi_addr.family() is IPv6 else {
    raise Failure::Failure("\{context}: expected IPv6 address")
  }
  join_multicast_group_v6(
    self.io.fd(),
    multi_addr,
    parse_ipv6_zone_suffix(interface, context~),
    context~,
  )
}

///|
/// Validate that `buf[offset:offset + max_len]` stays inside `buf`
/// before the range is forwarded to native receive calls,
/// which perform no bounds checking of their own.
fn check_recv_bounds(
  buf : FixedArray[Byte],
  offset~ : Int32,
  max_len~ : Int32,
  context~ : String,
) -> Unit raise {
  guard offset >= 0 &&
    offset <= buf.length() &&
    max_len >= 0 &&
    max_len <= buf.length() - offset else {
    raise Failure::Failure("\{context}: destination range out of bounds")
  }
}

///|
/// Receive packet from a UDP client.
/// For `udp.recv(buf, offset~, max_len~)`,
/// at most `max_len` bytes of data will be written to `buf`, starting from `offset`.
/// The number of received bytes will be returned.
///
/// UDP is a datagram based protocol,
/// and `recv` will always receive exactly one UDP packet.
/// If the buffer is smaller than the received packet,
/// the rest of the packet will be lost.
///
/// At most one task can read from a UDP client at any time.
/// To allow multiple reader,
/// use a worker task for reading and use `@async.Queue` to distribute the data.
pub async fn UdpClient::recv(
  self : UdpClient,
  buf : FixedArray[Byte],
  offset~ : Int32 = 0,
  max_len~ : Int32 = buf.length() - offset,
) -> Int32 {
  check_recv_bounds(buf, offset~, max_len~, context="@socket.UdpClient::recv()")
  self.io.read(buf, offset~, len=max_len, context="@socket.UdpClient::recv()")
}

///|
/// Similar to `recv`, but additionally return the address of the packet's sender.
/// Unicast `UdpClient` can only receive traffic from the target server,
/// so this is mainly useful for multicast clients.
pub async fn UdpClient::recvfrom(
  self : UdpClient,
  buf : FixedArray[Byte],
  offset~ : Int32 = 0,
  max_len~ : Int32 = buf.length() - offset,
) -> (Int32, Addr) {
  check_recv_bounds(
    buf,
    offset~,
    max_len~,
    context="@socket.UdpClient::recvfrom()",
  )
  // Create a big enough Addr to hold both IPv4 and IPv6 address
  let addr = Addr::empty(self.addr.family())
  let n_read = self.io.recvfrom(
    buf,
    offset~,
    len=max_len,
    addr=addr.0,
    context="@socket.UdpClient::recvfrom()",
  )
  (n_read, addr)
}

///|
/// Receive packet from a UDP server, and obtain the source address of the packet.
/// For `udp.recvfrom(buf, offset~, max_len~)`,
/// at most `max_len` bytes of data will be written to `buf`, starting from `offset`.
/// The number of received bytes and the source address of the packet will be returned.
///
/// UDP is a datagram based protocol,
/// and `recv` will always receive exactly one UDP packet.
/// If the buffer is smaller than the received packet,
/// the rest of the packet will be lost.
///
/// At most one task can read from a UDP server at any time.
/// To allow multiple reader,
/// use a worker task for reading and use `@async.Queue` to distribute the data.
pub async fn UdpServer::recvfrom(
  self : UdpServer,
  buf : FixedArray[Byte],
  offset~ : Int32 = 0,
  max_len~ : Int32 = buf.length() - offset,
) -> (Int32, Addr) {
  check_recv_bounds(
    buf,
    offset~,
    max_len~,
    context="@socket.UdpServer::recvfrom()",
  )
  // Create a big enough Addr to hold both IPv4 and IPv6 address
  let addr = Addr::empty(self.addr.family())
  let n_read = self.io.recvfrom(
    buf,
    offset~,
    len=max_len,
    addr=addr.0,
    context="@socket.UdpServer::recvfrom()",
  )
  (n_read, addr)
}

///|
/// Send data through a UDP client.
///
/// UDP is a datagram based protocol, every call of `send` will send exactly one packet.
///
/// At most one task can write to a UDP client at any time.
/// To allow multiple writers,
/// use a worker task for reading and use `@async.Queue` to gather the data.
pub async fn UdpClient::send(
  self : UdpClient,
  buf : Bytes,
  offset~ : Int32 = 0,
  len~ : Int32 = buf.length() - offset,
) -> Unit {
  let context = "@socket.UdpClient::send()"
  let _ = match self.dst_addr {
    Some(Addr(addr)) => self.io.sendto(buf, offset~, len~, addr~, context~)
    None => self.io.write(buf, offset~, len~, context~)
  }
}

///|
/// Send a packet to `addr` through a UDP server.
///
/// UDP is a datagram based protocol, every call of `send` will send exactly one packet.
///
/// At most one task can write to a UDP server at any time.
/// To allow multiple writers,
/// use a worker task for reading and use `@async.Queue` to gather the data.
pub async fn UdpServer::sendto(
  self : UdpServer,
  buf : Bytes,
  addr : Addr,
  offset~ : Int32 = 0,
  len~ : Int32 = buf.length() - offset,
) -> Unit {
  guard !self.is_multicast_only else {
    raise Failure::Failure(
      "multicast-only sockets created with `@socket.UdpServer::multicast()` cannot be used for sending",
    )
  }
  self.io.sendto(
    buf,
    offset~,
    len~,
    addr=addr.0,
    context="@socket.UdpServer::sendto()",
  )
  |> ignore
}
