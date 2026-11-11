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
priv enum AddrFamily {
  IPv4 = 4
  IPv6 = 6
}

///|
priv struct OsAddr(Bytes)

///|
#cfg(target="native")
extern "C" fn get_ipv4_addr_size() -> Int32 = "moonbit_rt_ipv4_addr_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_ipv4_addr_size() -> Int32 = "moonbitlang/async" "socket/ipv4_addr_size"

///|
let ipv4_addr_size : Int32 = get_ipv4_addr_size()

///|
#cfg(target="native")
extern "C" fn get_ipv6_addr_size() -> Int32 = "moonbit_rt_ipv6_addr_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn get_ipv6_addr_size() -> Int32 = "moonbitlang/async" "socket/ipv6_addr_size"

///|
let ipv6_addr_size : Int32 = get_ipv6_addr_size()

///|
#cfg(target="native")
#borrow(addr)
extern "C" fn init_ip_addr(addr : Bytes, ip : UInt32, port : Int32) -> Unit = "moonbit_rt_init_ip_addr"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn init_ip_addr(addr : Bytes, ip : UInt32, port : Int32) -> Unit = "moonbitlang/async" "socket/init_ip_addr"

///|
fn OsAddr::new(ip : UInt32, port : Int32) -> OsAddr {
  let addr = Bytes::make(ipv4_addr_size, 0)
  init_ip_addr(addr, ip, port)
  OsAddr(addr)
}

///|
#cfg(target="native")
#borrow(addr, ip)
extern "C" fn init_ipv6_addr(
  addr : Bytes,
  ip : Bytes,
  port : Int32,
  scope_id~ : UInt32,
) -> Unit = "moonbit_rt_init_ipv6_addr"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr, ip)
fn init_ipv6_addr(
  addr : Bytes,
  ip : Bytes,
  port : Int32,
  scope_id~ : UInt32,
) -> Unit = "moonbitlang/async" "socket/init_ipv6_addr"

///|
fn OsAddr::new_ipv6(ip : Bytes, port : Int32, scope_id~ : UInt32) -> OsAddr {
  let addr = Bytes::make(ipv6_addr_size, 0)
  init_ipv6_addr(addr, ip, port, scope_id~)
  OsAddr(addr)
}

///|
let empty_ipv6_bytes : Bytes = Bytes::make(16, 0)

///|
fn OsAddr::empty(family : AddrFamily) -> OsAddr {
  match family {
    IPv4 => {
      let addr = Bytes::make(ipv4_addr_size, 0)
      init_ip_addr(addr, 0, 0)
      OsAddr(addr)
    }
    IPv6 => {
      let addr = Bytes::make(ipv6_addr_size, 0)
      init_ipv6_addr(addr, empty_ipv6_bytes, 0, scope_id=0)
      OsAddr(addr)
    }
  }
}

///|
/// Get the IPv4 address of a network address. The address must be an IPv4 address
#cfg(target="native")
#borrow(addr)
extern "C" fn OsAddr::ip(addr : OsAddr) -> UInt32 = "moonbit_rt_ip_addr_get_ip"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn ip_addr_get_ip(addr : OsAddr, addr_len~ : Int32 = addr.0.length()) -> UInt32 = "moonbitlang/async" "socket/ip_addr_get_ip"

///|
/// Get the IPv4 address of a network address. The address must be an IPv4 address
#cfg(target="wasm")
fn OsAddr::ip(addr : OsAddr) -> UInt32 {
  ip_addr_get_ip(addr)
}

///|
/// Get the port number of a network address
#cfg(target="native")
#borrow(addr)
extern "C" fn OsAddr::port(addr : OsAddr) -> Int32 = "moonbit_rt_ip_addr_get_port"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn ip_addr_get_port(
  addr : OsAddr,
  addr_len~ : Int32 = addr.0.length(),
) -> Int32 = "moonbitlang/async" "socket/ip_addr_get_port"

///|
/// Get the port number of a network address
#cfg(target="wasm")
fn OsAddr::port(addr : OsAddr) -> Int32 {
  ip_addr_get_port(addr)
}

///|
/// Check if an network address is IPv6
#cfg(target="native")
#borrow(addr)
extern "C" fn OsAddr::is_ipv6(addr : OsAddr) -> Bool = "moonbit_rt_addr_is_ipv6"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn addr_is_ipv6(addr : OsAddr, addr_len~ : Int32 = addr.0.length()) -> Bool = "moonbitlang/async" "socket/addr_is_ipv6"

///|
/// Check if an network address is IPv6
#cfg(target="wasm")
fn OsAddr::is_ipv6(addr : OsAddr) -> Bool {
  addr_is_ipv6(addr)
}

///|
fn OsAddr::family(self : OsAddr) -> AddrFamily {
  if self.is_ipv6() {
    IPv6
  } else {
    IPv4
  }
}

///|
let ipv4_any : @lazy.Lazy[OsAddr] = Lazy(() => OsAddr::new(0, 0))

///|
let ipv6_any : @lazy.Lazy[OsAddr] = Lazy(() => {
  OsAddr::new_ipv6(Bytes::make(16, 0), 0, scope_id=0)
})

///|
fn OsAddr::any(family : AddrFamily) -> OsAddr {
  match family {
    IPv4 => ipv4_any.force()
    IPv6 => ipv6_any.force()
  }
}

///|
#cfg(target="native")
extern "C" fn OsAddr::get_ipv6_bytes_offset() -> Int32 = "moonbit_rt_addr_get_ipv6_bytes_offset"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn OsAddr::get_ipv6_bytes_offset() -> Int32 = "moonbitlang/async" "socket/addr_get_ipv6_bytes_offset"

///|
/// The offset of IPv6 bytes in `struct sockaddr_in6`
let ipv6_bytes_offset : Int32 = OsAddr::get_ipv6_bytes_offset()

///|
#cfg(target="native")
#borrow(addr)
extern "C" fn OsAddr::scope_id(addr : OsAddr) -> UInt32 = "moonbit_rt_addr_get_ipv6_scope_id"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn OsAddr::scope_id(
  addr : OsAddr,
  addr_len~ : Int32 = addr.0.length(),
) -> UInt32 = "moonbitlang/async" "socket/addr_get_ipv6_scope_id"

///|
priv struct AddrInfo(@event_loop.AddrInfo)

///|
#cfg(target="native")
extern "C" fn AddrInfo::is_null(self : AddrInfo) -> Bool = "moonbit_rt_addrinfo_is_null"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn AddrInfo::is_null(self : AddrInfo) -> Bool = "moonbitlang/async" "socket/addrinfo_is_null"

///|
/// Convert AddrInfo to OsAddr(support both IPv4 and IPv6)
#cfg(target="native")
extern "C" fn AddrInfo::addr_size(self : AddrInfo) -> Int32 = "moonbit_rt_addrinfo_addr_size"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn AddrInfo::addr_size(self : AddrInfo) -> Int32 = "moonbitlang/async" "socket/addrinfo_addr_size"

///|
#cfg(target="native")
#borrow(out)
extern "C" fn AddrInfo::fill_addr(
  self : AddrInfo,
  out : Bytes,
  port : Int32,
) -> Unit = "moonbit_rt_addrinfo_fill_addr"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(out)
fn AddrInfo::fill_addr(
  self : AddrInfo,
  out : Bytes,
  port : Int32,
  out_len~ : Int32 = out.length(),
) -> Unit = "moonbitlang/async" "socket/addrinfo_fill_addr"

///|
fn AddrInfo::to_addr(self : AddrInfo, port : UInt16) -> OsAddr {
  let addr = Bytes::make(self.addr_size(), 0)
  self.fill_addr(addr, port.to_int())
  OsAddr(addr)
}

///|
#cfg(target="native")
extern "C" fn AddrInfo::next(self : AddrInfo) -> AddrInfo = "moonbit_rt_addrinfo_get_next"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn AddrInfo::next(self : AddrInfo) -> AddrInfo = "moonbitlang/async" "socket/addrinfo_get_next"

///|
#cfg(not(any(platform="windows", target="wasm")))
extern "C" fn AddrInfo::free(self : AddrInfo) = "freeaddrinfo"

///|
#cfg(platform="windows")
extern "C" fn AddrInfo::free(self : AddrInfo) = "moonbit_rt_freeaddrinfo"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn AddrInfo::free(self : AddrInfo) -> Unit = "moonbitlang/async" "socket/addrinfo_free"

///|
/// Error message from failure in resolving a network hostname.
/// The content of the error message is platfrom-dependent,
/// so users should never depend on it.
#derive(@debug.Debug, @json.ToJson)
pub suberror ResolveHostnameError {
  ResolveHostnameError(String)
}

///|
pub impl Show for ResolveHostnameError with fn to_string(self) {
  let ResolveHostnameError(msg) = self
  msg
}

///|
pub extend ResolveHostnameError with Show::{to_string}

///|
/// IPv4/IPv6 preference when resolving a host name
#derive(@debug.Debug)
pub(all) enum IpProtocolPreference {
  OnlyV4
  OnlyV6
  FavorV4
  FavorV6
  NoPreference
}

///|
async fn OsAddr::resolve(
  host : StringView,
  port~ : UInt16,
  protocol~ : IpProtocolPreference = NoPreference,
  context~ : String,
) -> OsAddr {
  try IpAddr::parse_aux(host, require_bracket=false, context~) catch {
    InvalidAddr => ()
    err => raise err
  } noraise {
    ip => return { ip, port, }.to_os_addr()
  }
  let ai_root = match @event_loop.getaddrinfo(host, context~) {
    Ok(ai_root) => AddrInfo(ai_root)
    Err(msg) => raise ResolveHostnameError(msg)
  }
  defer ai_root.free()
  let first_addr = ai_root.to_addr(port)

  // search for address with preferred protocol
  match protocol {
    FavorV4 | OnlyV4 => {
      if !first_addr.is_ipv6() {
        return first_addr
      }
      for ai = ai_root.next(); !ai.is_null(); ai = ai.next() {
        let addr = ai.to_addr(port)
        if !addr.is_ipv6() {
          return addr
        }
      }
      if protocol is OnlyV4 {
        raise ResolveHostnameError("No available IPv4 address")
      } else {
        first_addr
      }
    }
    FavorV6 | OnlyV6 => {
      if first_addr.is_ipv6() {
        return first_addr
      }
      for ai = ai_root.next(); !ai.is_null(); ai = ai.next() {
        let addr = ai.to_addr(port)
        if addr.is_ipv6() {
          return addr
        }
      }
      if protocol is OnlyV6 {
        raise ResolveHostnameError("No available IPv6 address")
      } else {
        first_addr
      }
    }
    NoPreference => first_addr
  }
}
