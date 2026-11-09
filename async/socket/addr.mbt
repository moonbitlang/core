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
/// Type for IP address
#derive(Eq, Compare, Hash)
pub enum IpAddr {
  Ipv4(UInt32)
  Ipv6(Bytes, scope_id~ : UInt32)
}

///|
/// Create a IPv4 address without port
pub fn IpAddr::v4(ip : UInt32) -> IpAddr {
  Ipv4(ip)
}

///|
/// Create a IPv6 address without port, with a optional scope ID/zone index.
/// The address part must be exactly 16 bytes/128 bits long.
pub fn IpAddr::v6(ip : Bytes, scope_id~ : UInt32 = 0) -> IpAddr {
  guard! ip.length() is 16
  Ipv6(ip, scope_id~)
}

///|
/// Parse a string into IPv4 or IPv6 address.
/// IPv6 address may contain a optional bracket.
#alias(parse)
pub fn IpAddr::IpAddr(src : StringView) -> IpAddr raise {
  IpAddr::parse_aux(
    src,
    require_bracket=false,
    context="@socket.IpAddr::parse()",
  )
}

///|
/// Type for a network address containing both IP and port
#valtype
#derive(Eq, Compare, Hash)
pub struct Addr {
  ip : IpAddr
  port : UInt16
}

///|
/// Create a network address from IP + port
pub fn Addr::Addr(ip : IpAddr, port : UInt16) -> Addr {
  { ip, port, }
}

///|
fn Addr::to_os_addr(addr : Addr) -> OsAddr {
  match addr.ip {
    Ipv4(ip) => {
      let result = Bytes::make(ipv4_addr_size, 0)
      init_ip_addr(result, ip, addr.port.to_int())
      OsAddr(result)
    }
    Ipv6(ip, scope_id~) => {
      let result = Bytes::make(ipv6_addr_size, 0)
      init_ipv6_addr(result, ip, addr.port.to_int(), scope_id~)
      OsAddr(result)
    }
  }
}

///|
fn Addr::from_os_addr(addr : OsAddr) -> Addr {
  let port = addr.port().to_uint16()
  if addr.is_ipv6() {
    // We know that the actual OS address buffer must be larger than just the IP,
    // so there is no risk of accidental aliasing caused by `to_owned()` here
    let ip = addr.0[ipv6_bytes_offset:ipv6_bytes_offset + 16].to_owned()
    let scope_id = addr.scope_id()
    { ip: Ipv6(ip, scope_id~), port, }
  } else {
    { ip: Ipv4(addr.ip()), port, }
  }
}

///|
fn Addr::family(addr : Addr) -> AddrFamily {
  match addr.ip {
    Ipv4(_) => IPv4
    Ipv6(_) => IPv6
  }
}

///|
pub impl Show for IpAddr with fn output(addr, logger) {
  match addr {
    Ipv4(ip) =>
      logger <+ "\{ip >> 24}.\{(ip >> 16) & 255}.\{(ip >> 8) & 255}.\{ip & 255}"
    Ipv6(ip, scope_id~) => {
      logger.write_char('[')
      write_ipv6_str(ip, logger)
      if scope_id > 0 {
        let interface = if_indextoname(scope_id, context="") catch {
          _ => scope_id.to_string()
        }
        logger <+ "%\{interface}"
      }
      logger.write_char(']')
    }
  }
}

///|
pub extend IpAddr with Show::{to_string}

///|
pub impl @debug.Debug for IpAddr with fn to_repr(self) {
  @debug.Repr::opaque_("IpAddr", @debug.Repr::literal(Show::to_string(self)))
}

///|
pub impl Show for Addr with fn output(addr, logger) {
  logger <+ "\{addr.ip}:\{addr.port}"
}

///|
pub extend Addr with Show::{to_string}

///|
pub impl @debug.Debug for Addr with fn to_repr(self) {
  @debug.Repr::opaque_("Addr", @debug.Repr::literal(Show::to_string(self)))
}

///|
/// Failed to parse an address string
#derive(@debug.Debug, @json.ToJson)
pub suberror InvalidAddr

///|
/// Parse a string into IPv4 or IPv6 address with port,
/// format should be `ip:port` for IPv4 or `[ip]:port` for IPv6
pub fn Addr::parse(src : StringView) -> Addr raise {
  guard src =~ (re":" + (re"[0-9]+$" as port_str), before=ip_str) else {
    raise InvalidAddr
  }
  let port = parse_port(port_str)
  let ip = IpAddr::parse_aux(
    ip_str,
    require_bracket=false,
    context="@socket.Addr::parse()",
  )
  { ip, port, }
}

///|
/// Resolve a IPv4 or IPv6 address by hostname.
///
/// By default, `Addr::resolve` return the first available address.
/// Preference on IPv4 v.s. IPv6 can be configured via `protocol`.
/// See `IpProtocolPreference` for available options.
///
/// Literal IP address would be returned directly without DNS resolution attempt.
/// Literal IPv6 address may contain optional bracket.
pub async fn Addr::resolve(
  host : StringView,
  port~ : UInt16,
  protocol~ : IpProtocolPreference = NoPreference,
) -> Addr {
  Addr::from_os_addr(
    OsAddr::resolve(host, port~, protocol~, context="@socket.Addr::resolve()"),
  )
}

///|
/// Check if an IP address is a multicast address
pub fn IpAddr::is_multicast(ip : IpAddr) -> Bool {
  match ip {
    Ipv4(ip) => (ip >> 24) is (224..<240)
    Ipv6(ip, ..) => ip[0] is 0xff
  }
}
