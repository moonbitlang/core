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
struct Addr(Bytes) derive(Eq, Compare, Hash)

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
/// Create a new IPv4 address
pub fn Addr::new(ip : UInt32, port : Int32) -> Addr {
  let addr = Bytes::make(ipv4_addr_size, 0)
  init_ip_addr(addr, ip, port)
  Addr(addr)
}

///|
#cfg(target="native")
#borrow(addr, ip)
extern "C" fn init_ipv6_addr(
  addr : Bytes,
  ip : FixedArray[Byte],
  port : Int32,
  scope_id~ : UInt32,
) -> Unit = "moonbit_rt_init_ipv6_addr"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr, ip)
fn init_ipv6_addr(
  addr : Bytes,
  ip : FixedArray[Byte],
  port : Int32,
  scope_id~ : UInt32,
) -> Unit = "moonbitlang/async" "socket/init_ipv6_addr"

///|
fn Addr::new_ipv6(
  ip : FixedArray[Byte],
  port : Int32,
  scope_id~ : UInt32,
) -> Addr {
  let addr = Bytes::make(ipv6_addr_size, 0)
  init_ipv6_addr(addr, ip, port, scope_id~)
  Addr(addr)
}

///|
let empty_ipv6_bytes : FixedArray[Byte] = FixedArray::make(16, 0)

///|
fn Addr::empty(family : AddrFamily) -> Addr {
  match family {
    IPv4 => {
      let addr = Bytes::make(ipv4_addr_size, 0)
      init_ip_addr(addr, 0, 0)
      Addr(addr)
    }
    IPv6 => {
      let addr = Bytes::make(ipv6_addr_size, 0)
      init_ipv6_addr(addr, empty_ipv6_bytes, 0, scope_id=0)
      Addr(addr)
    }
  }
}

///|
/// Get the IPv4 address of a network address. The address must be an IPv4 address
#cfg(target="native")
#borrow(addr)
pub extern "C" fn Addr::ip(addr : Addr) -> UInt32 = "moonbit_rt_ip_addr_get_ip"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn ip_addr_get_ip(addr : Addr, addr_len~ : Int32 = addr.0.length()) -> UInt32 = "moonbitlang/async" "socket/ip_addr_get_ip"

///|
/// Get the IPv4 address of a network address. The address must be an IPv4 address
#cfg(target="wasm")
pub fn Addr::ip(addr : Addr) -> UInt32 {
  ip_addr_get_ip(addr)
}

///|
/// Get the port number of a network address
#cfg(target="native")
#borrow(addr)
pub extern "C" fn Addr::port(addr : Addr) -> Int32 = "moonbit_rt_ip_addr_get_port"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn ip_addr_get_port(addr : Addr, addr_len~ : Int32 = addr.0.length()) -> Int32 = "moonbitlang/async" "socket/ip_addr_get_port"

///|
/// Get the port number of a network address
#cfg(target="wasm")
pub fn Addr::port(addr : Addr) -> Int32 {
  ip_addr_get_port(addr)
}

///|
/// Check if an network address is IPv6
#cfg(target="native")
#borrow(addr)
pub extern "C" fn Addr::is_ipv6(addr : Addr) -> Bool = "moonbit_rt_addr_is_ipv6"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn addr_is_ipv6(addr : Addr, addr_len~ : Int32 = addr.0.length()) -> Bool = "moonbitlang/async" "socket/addr_is_ipv6"

///|
/// Check if an network address is IPv6
#cfg(target="wasm")
pub fn Addr::is_ipv6(addr : Addr) -> Bool {
  addr_is_ipv6(addr)
}

///|
/// Check if an network address is a multicast
#cfg(target="native")
#borrow(addr)
pub extern "C" fn Addr::is_multicast(addr : Addr) -> Bool = "moonbit_rt_addr_is_multicast"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn addr_is_multicast(addr : Addr, addr_len~ : Int32 = addr.0.length()) -> Bool = "moonbitlang/async" "socket/addr_is_multicast"

///|
/// Check if an network address is a multicast
#cfg(target="wasm")
pub fn Addr::is_multicast(addr : Addr) -> Bool {
  addr_is_multicast(addr)
}

///|
fn Addr::family(self : Addr) -> AddrFamily {
  if self.is_ipv6() {
    IPv6
  } else {
    IPv4
  }
}

///|
let ipv4_any : @lazy.Lazy[Addr] = Lazy(() => Addr::new(0, 0))

///|
let ipv6_any : @lazy.Lazy[Addr] = Lazy(() => {
  Addr::new_ipv6(FixedArray::make(16, 0), 0, scope_id=0)
})

///|
fn Addr::any(family : AddrFamily) -> Addr {
  match family {
    IPv4 => ipv4_any.force()
    IPv6 => ipv6_any.force()
  }
}

///|
#cfg(target="native")
extern "C" fn Addr::get_ipv6_bytes_offset() -> Int32 = "moonbit_rt_addr_get_ipv6_bytes_offset"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn Addr::get_ipv6_bytes_offset() -> Int32 = "moonbitlang/async" "socket/addr_get_ipv6_bytes_offset"

///|
/// The offset of IPv6 bytes in `struct sockaddr_in6`
let ipv6_bytes_offset : Int32 = Addr::get_ipv6_bytes_offset()

///|
#cfg(target="native")
#borrow(addr)
extern "C" fn Addr::scope_id(addr : Addr) -> UInt32 = "moonbit_rt_addr_get_ipv6_scope_id"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn Addr::scope_id(addr : Addr, addr_len~ : Int32 = addr.0.length()) -> UInt32 = "moonbitlang/async" "socket/addr_get_ipv6_scope_id"

///|
#cfg(target="native")
#borrow(addr)
extern "C" fn Addr::is_ipv6_wildcard(addr : Addr) -> Bool = "moonbit_rt_addr_is_ipv6_wildcard"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
#borrow(addr)
fn Addr::is_ipv6_wildcard(
  addr : Addr,
  addr_len~ : Int32 = addr.0.length(),
) -> Bool = "moonbitlang/async" "socket/addr_is_ipv6_wildcard"

///|
pub impl Show for Addr with fn output(self, logger) {
  if self.is_ipv6() {
    // IPv6 address format
    logger <+ "["
    write_ipv6_str(self.0[ipv6_bytes_offset:], logger)
    let scope_id = self.scope_id()
    if scope_id > 0 {
      let interface = if_indextoname(scope_id, context="") catch {
        _ => scope_id.to_string()
      }
      logger <+ "%\{interface}"
    }
    logger <+ "]:\{self.port()}"
  } else {
    // IPv4 address format
    let ip = self.ip()
    let port = self.port()
    logger <+
      "\{ip >> 24}.\{(ip >> 16) & 255}.\{(ip >> 8) & 255}.\{ip & 255}:\{port}"
  }
}

///|
pub extend Addr with Show::{to_string}

///|
pub impl @debug.Debug for Addr with fn to_repr(self) {
  @debug.Repr::opaque_("Addr", @debug.Repr::literal(Show::to_string(self)))
}

///|
/// Failed to parse an address string
pub suberror InvalidAddr derive(@debug.Debug, @json.ToJson)

///|
/// Parse a string into IPv4 or IPv6 address, format should be `ip:port` for IPv4 or `[ip]:port` for IPv6
// TODO: faster implementation
pub fn Addr::parse(src : String) -> Addr raise {
  if src.has_prefix("[") {
    let (ip_bytes, port, interface) = try_parse_ipv6(src)
    let scope_id = if interface is Some(interface) {
      parse_ipv6_zone_suffix(interface, context="@socket.Addr::parse()")
    } else {
      0
    }
    Addr::new_ipv6(ip_bytes, port, scope_id~)
  } else {
    // IPv4 format: ip:port
    let (ip, port) = try_parse_ipv4(src) catch { _ => raise InvalidAddr }
    guard 0 <= port && port < 65536 else { raise InvalidAddr }
    Addr::new(ip, port)
  }
}

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
/// Convert AddrInfo to Addr(support both IPv4 and IPv6)
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
fn AddrInfo::to_addr(self : AddrInfo, port : Int32) -> Addr {
  let addr = Bytes::make(self.addr_size(), 0)
  self.fill_addr(addr, port)
  Addr(addr)
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
pub suberror ResolveHostnameError {
  ResolveHostnameError(String)
} derive(@debug.Debug, @json.ToJson)

///|
/// IPv4/IPv6 preference when resolving a host name
pub(all) enum IpProtocolPreference {
  OnlyV4
  OnlyV6
  FavorV4
  FavorV6
  NoPreference
} derive(@debug.Debug)

///|
/// Resolve a IPv4 or IPv6 address by hostname.
///
/// By default, `Addr::resolve` return the first available address.
/// Preference on IPv4 v.s. IPv6 can be configured via `protocol`.
/// See `IPProtocolPreference` for available options.
pub async fn Addr::resolve(
  host : String,
  port~ : Int32,
  protocol~ : IpProtocolPreference = NoPreference,
) -> Addr {
  // TODO: Add option to prefer ipv6 or ipv4
  let context = "@socket.Addr::resolve()"
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
