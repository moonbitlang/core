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
extern "C" fn make_tcp_socket_ffi(family : AddrFamily) -> @fd_util.Fd = "moonbit_rt_make_tcp_socket"

///|
#cfg(not(platform="windows"))
fn make_tcp_socket(family : AddrFamily, context~ : String) -> @fd_util.Fd raise {
  let sock = make_tcp_socket_ffi(family)
  if sock < 0 {
    @os_error.check_errno(context)
  }
  @fd_util.set_cloexec(sock, context~)
  sock
}

///|
#cfg(platform="windows")
fn make_tcp_socket(family : AddrFamily, context~ : String) -> @fd_util.Fd raise {
  let sock = make_tcp_socket_ffi(family)
  if !@fd_util.fd_is_valid(sock) {
    @os_error.check_errno(context)
  }
  sock
}

///|
extern "C" fn make_udp_socket_ffi(
  family : AddrFamily,
  multicast~ : Bool,
) -> @fd_util.Fd = "moonbit_rt_make_udp_socket"

///|
#cfg(not(platform="windows"))
fn make_udp_socket(
  family : AddrFamily,
  multicast~ : Bool,
  context~ : String,
) -> @fd_util.Fd raise {
  let sock = make_udp_socket_ffi(family, multicast~)
  if sock < 0 {
    @os_error.check_errno(context)
  }
  @fd_util.set_cloexec(sock, context~)
  sock
}

///|
#cfg(platform="windows")
fn make_udp_socket(
  family : AddrFamily,
  multicast~ : Bool,
  context~ : String,
) -> @fd_util.Fd raise {
  let sock = make_udp_socket_ffi(family, multicast~)
  if !@fd_util.fd_is_valid(sock) {
    @os_error.check_errno(context)
  }
  sock
}

///|
#borrow(multi_addr, local_addr)
extern "C" fn join_multicast_group_ffi(
  sock : @fd_util.Fd,
  multi_addr : Addr,
  local_addr : Addr,
) -> Int32 = "moonbit_rt_join_multicast_group"

///|
fn join_multicast_group(
  sock : @fd_util.Fd,
  multi_addr : Addr,
  local_addr : Addr,
  context~ : String,
) -> Unit raise {
  if join_multicast_group_ffi(sock, multi_addr, local_addr) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#borrow(multi_addr)
extern "C" fn join_multicast_group_v6_ffi(
  sock : @fd_util.Fd,
  multi_addr : Addr,
  interface_index : UInt32,
) -> Int32 = "moonbit_rt_join_multicast_group_v6"

///|
fn join_multicast_group_v6(
  sock : @fd_util.Fd,
  multi_addr : Addr,
  interface_index : UInt32,
  context~ : String,
) -> Unit raise {
  if join_multicast_group_v6_ffi(sock, multi_addr, interface_index) < 0 {
    @os_error.check_errno(context)
  }
}

///|
#borrow(local_addr)
extern "C" fn set_multicast_interface_ffi(
  sock : @fd_util.Fd,
  local_addr : Addr,
) -> Int32 = "moonbit_rt_set_multicast_interface"

///|
fn set_multicast_interface(
  sock : @fd_util.Fd,
  local_addr : Addr,
  context~ : String,
) -> Unit raise {
  if set_multicast_interface_ffi(sock, local_addr) < 0 {
    @os_error.check_errno(context)
  }
}

///|
extern "C" fn set_multicast_interface_v6_ffi(
  sock : @fd_util.Fd,
  interface_index : UInt32,
) -> Int32 = "moonbit_rt_set_multicast_interface_v6"

///|
fn set_multicast_interface_v6(
  sock : @fd_util.Fd,
  interface_index : UInt32,
  context~ : String,
) -> Unit raise {
  if set_multicast_interface_v6_ffi(sock, interface_index) < 0 {
    @os_error.check_errno(context)
  }
}

///|
extern "C" fn set_multicast_ttl_ffi(
  sock : @fd_util.Fd,
  ttl : Int32,
  family~ : AddrFamily,
) -> Int32 = "moonbit_rt_set_multicast_ttl"

///|
fn set_multicast_ttl(
  sock : @fd_util.Fd,
  ttl : Int32,
  family~ : AddrFamily,
  context~ : String,
) -> Unit raise {
  if set_multicast_ttl_ffi(sock, ttl, family~) < 0 {
    @os_error.check_errno(context)
  }
}

///|
extern "C" fn set_multicast_loopback_ffi(
  sock : @fd_util.Fd,
  loopback : Bool,
  family~ : AddrFamily,
) -> Int32 = "moonbit_rt_set_multicast_loopback"

///|
fn set_multicast_loopback(
  sock : @fd_util.Fd,
  loopback : Bool,
  family~ : AddrFamily,
  context~ : String,
) -> Unit raise {
  if set_multicast_loopback_ffi(sock, loopback, family~) < 0 {
    @os_error.check_errno(context)
  }
}

///|
extern "C" fn set_ipv6_only(sock : @fd_util.Fd, dual_stack : Bool) -> Int32 = "moonbit_rt_set_ipv6_only"

///|
extern "C" fn listen_ffi(sock : @fd_util.Fd) -> Int32 = "moonbit_rt_listen"

///|
#borrow(addr)
extern "C" fn connect_ffi(sock : @fd_util.Fd, addr : Addr) -> Int32 = "moonbit_rt_udp_client_connect"

///|
extern "C" fn disable_nagle(sock : @fd_util.Fd) -> Int32 = "moonbit_rt_disable_nagle"

///|
extern "C" fn allow_reuse_addr(sock : @fd_util.Fd) -> Int32 = "moonbit_rt_allow_reuse_addr"

///|
extern "C" fn allow_reuse_port(sock : @fd_util.Fd) -> Int32 = "moonbit_rt_allow_reuse_port"

///|
extern "C" fn enable_keepalive_ffi(
  sock : @fd_util.Fd,
  keep_idle : Int32,
  keep_count : Int32,
  keep_intv : Int32,
) -> Int32 = "moonbit_rt_enable_keepalive"

///|
#borrow(addr_out)
extern "C" fn getsockname_ffi(sock : @fd_util.Fd, addr_out : Addr) -> Int32 = "moonbit_rt_getsockname"

///|
fn getsockname(
  sock : @fd_util.Fd,
  family : AddrFamily,
  context~ : String,
) -> Addr raise {
  let addr = Addr::empty(family)
  if getsockname_ffi(sock, addr) < 0 {
    @os_error.check_errno(context)
  }
  addr
}
