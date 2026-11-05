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
/// Handle a WebSocket handshake request
/// and convert an existing HTTP server connection to a WebSocket tunnel.
///
/// - `request`: the WebSocket handshake request
/// - `conn`: the HTTP server connection
///
/// If the handshake succeeds, a new WebSocket tunnel will be created and returned.
///
/// The ownership of `conn` will be transferred to
/// `@websocket.ServerConnection::from_http`,
/// so the user must NOT use or close the HTTP server connection anymore.
#as_free_fn
pub async fn Conn::from_http_server(
  request : @http.RequestHeader,
  conn : @http.ServerConnection,
) -> Conn {
  errdefer conn.close()
  async fn bad_request(msg : String) {
    conn.send_response(400, "Bad Request")
    conn.text.write(msg)
    conn.end_response()
    raise InvalidHandshake(msg)
  }

  guard request.meth is Get else { bad_request("Invalid request: must be GET") }

  // Validate WebSocket handshake headers
  guard request.headers.get("upgrade") is Some(upgrade) &&
    upgrade.to_lower() == "websocket" else {
    bad_request("Missing or invalid Upgrade header")
  }
  guard request.headers.get("connection") is Some(connection) &&
    connection.to_lower().contains("upgrade") else {
    bad_request("Missing or invalid Connection header")
  }
  guard request.headers.get("sec-websocket-version") is Some(version) &&
    version == "13" else {
    bad_request("Missing or unsupported WebSocket version")
  }
  guard request.headers.get("sec-websocket-key") is Some(key) else {
    bad_request("Missing Sec-WebSocket-Key header")
  }

  // Generate accept key
  let accept_key = generate_accept_key(key)
  conn
  ..send_response(101, "Switching Protocols", extra_headers={
    "Upgrade": "websocket",
    "Connection": "Upgrade",
    "Sec-WebSocket-Accept": accept_key,
  })
  ..end_response()
  .enter_passthrough_mode()
  Conn::new(conn, 4096, mask=None)
}
