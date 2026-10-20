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
/// Connect to a remote host using the happy eyeball algorithm.
/// Preference on IPv4 v.s. IPv6 can be configured via `protocol`:
///
/// - if `protocol` is `NoPreference` (the default behavior),
///   the first successful connection will be returned, regardless of the protocol.
/// - if `protocol` is `FavorV4`,
///   an IPv6 connection will only be returned if no IPv4 address is available
/// - if `protocol` is `OnlyV4`,
///   `connect_to_host` will fail if no IPv4 address is available
/// - if `protocol` is `FavorV6`,
///   an IPv6 connection will only be returned if no IPv4 address is available
/// - if `protocol` is `OnlyV6`,
///   `connect_to_host` will fail if no IPv4 address is available
#warnings("-fragile_catch_all")
pub async fn Tcp::connect_to_host(
  host : StringView,
  port~ : Int32,
  protocol~ : IpProtocolPreference = NoPreference,
) -> Tcp {
  let context = "@socket.Tcp::connect_to_host()"
  let ai = match @event_loop.getaddrinfo(host, context~) {
    Ok(ai) => AddrInfo(ai)
    Err(msg) => raise ResolveHostnameError(msg)
  }
  defer ai.free()
  let mut result = None
  let mut conn_err = None
  async fn connect_with_protocol(protocol : IpProtocolPreference) {
    @async_io.with_task_group() <| group => {
      for ai = ai; !ai.is_null(); ai = ai.next() {
        let addr = ai.to_addr(port)
        match (protocol, addr.is_ipv6()) {
          (OnlyV4 | FavorV4, true) => continue
          (OnlyV6 | FavorV6, false) => continue
          _ => ()
        }
        group.spawn_bg(allow_failure=true) <| () => {
          let conn = Tcp::connect(addr) catch {
            err => {
              if conn_err is None {
                conn_err = Some(err)
              }
              raise err
            }
          }
          // Multiple `connect` attempt may happen to complete simultaneously,
          // Keep only one result and properly close the others in this case.
          if result is None {
            result = Some(conn)
          } else {
            conn.close()
          }
          group.return_immediately()
        }
        @async_io.sleep(250)
      }
    }
  }

  // It is possible that the whole `connect_to_host` call is cancelled,
  // but a connection attempt succeeded just before the cancellation.
  // We need to properly close the result in this case.
  errdefer (if result is Some(conn) { conn.close() })
  match protocol {
    NoPreference | OnlyV4 | OnlyV6 => connect_with_protocol(protocol)
    FavorV4 => {
      connect_with_protocol(OnlyV4)
      if result is None {
        connect_with_protocol(OnlyV6)
      }
    }
    FavorV6 => {
      connect_with_protocol(OnlyV6)
      if result is None {
        connect_with_protocol(OnlyV4)
      }
    }
  }
  match result {
    Some(conn) => conn
    None =>
      match (conn_err, protocol) {
        (Some(err), _) => raise err
        (None, OnlyV4) =>
          raise ResolveHostnameError("No available IPv4 address")
        (None, OnlyV6) =>
          raise ResolveHostnameError("No available IPv6 address")
        (None, _) => panic()
      }
  }
}
