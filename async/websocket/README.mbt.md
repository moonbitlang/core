# WebSocket API for MoonBit Async Library

This module provides RFC 6455-compliant WebSocket client and server support for `moonbitlang/async`.

## Features

- **WebSocket server** with support for integration into a normal HTTP server
- **WebSocket client** with support for **TLS and proxy**

## Quick Start

### WebSocket server
```moonbit check
// A simple WebSocket echo server that listen on path `/ws`,
// and reply clients with whatever they send.

///|
#cfg(any(target="native", target="wasm"))
async fn websocket_echo_server(addr : @socket.Addr) -> Unit {
  let server = @http.Server(addr)
  // WebSocket server are built on top of a HTTP server.
  // This allows mixing WebSocket and HTTP in a single server.
  server.run_forever((request, conn) => {
    guard request.path is "/ws" else { conn.send_response(404, "NotFound") }
    let ws = @websocket.from_http_server(request, conn)
    defer ws.close()
    for ;; {
      // Receive a new message using `ws.recv()`
      // WebSocket message can be very long,
      // so `ws.recv()` does not read the full message into memory.
      // Instead, it returns a `@websocket.Message` type,
      // whose content can be read lazily via `@io.BinaryReader`.
      let msg = ws.recv()
      // Reply the client with the message we just received.
      // `msg.kind` is either `Text` (UTF-8 encoded text message)
      // or `Binary` (plain binary message).
      //
      // Sending message can also be performed lazily.
      // `.start_message(message_kind)` begins a new message,
      // after which message content can be written lazily to the WebSocket tunnel.
      // After all message content is written,
      // `.end_message()` should be called to terminate the message.
      // Fragmentation of message will be performed automatically.
      ws..start_message(msg.kind)..write_reader(msg).end_message()
    }
  })
}
```

### WebSocket client
```moonbit check
///|
#cfg(any(target="native", target="wasm"))
async test "WebSocket client example" {
  @async.with_task_group(group => {
    let port = 8340
    let addr = @socket.Addr::parse("127.0.0.1:\{port}")
    group.spawn_bg(no_wait=true, () => websocket_echo_server(addr))

    // Create a new client via `@websocket.connect`.
    // TLs encrypted WebSocket tunnel can be created via `wss://` URL.
    let ws = @websocket.connect("ws://127.0.0.1:\{port}/ws")
    defer ws.close()
    // convenient helper for sending small text message
    ws.send_text("abcd")
    inspect(ws.recv().text.read_all(), content="abcd")
    // gracefully terminate the WebSocket tunnel
    ws.send_close()
  })
}
```

## API Reference

### `Conn`
The type `@websocket.Conn` represents a WebSocket tunnel.
It can be created in the following three ways:

- `@websocket.connect(url : String, headers?, proxy?)`: connect to `url` via HTTP, perform WebSocket handshake and establish a new tunnel.
    If the url starts with `ws://`, the tunnel will be unencrypted, and handshake is performed via plain HTTP.
    If the url starts with `wss://`, a TLS encrypted tunnel will be created, and handshake is performed via HTTPS.
    The optional argument `headers` can be used to specify addition headers in the handshake.
    The optional argument `proxy` can be used to specify a HTTP(s) proxy for the tunnel.
- `@websocket.from_http_client(client : @http.Client, path: String)`:
    similar to `@websocket.connect`, but create the WebSocket tunnel using an existing http client.
- `@websocket.from_http_server(request : @http.Request, conn : @http.ServerConnection)`:
    process a WebSocket handshake request `request` from a client,
    and upgrade the HTTP server connection `conn` to a WebSocket tunnel.

After successfully establishing a WebSocket tunnel,
the following API can be used to do things with the tunnel:

- `recv() -> Message`: receive a new message from the tunnel.
    The kind of the message can be retrieved via `msg.kind`.
    `recv()` will not actually receive the content of the message,
    the content of the message should be obtained by reading from the `Message` type.
- `send_text(text : StringView)`: send a new text message
- `send_binary(data : BytesView)`: send a new binary message
- `start_message(kind : MessageKind)`: start a new message of kind `kind`.
     The content of the new message can be written to the WebSocket tunnel
     through its `@io.BinaryWriter` API, or through `.text` as `@io.TextWriter`
- `end_message()`: terminate current message created via `start_message()`,
     flush remaining content of message to the server
- `send_close()`: gracefully terminate the WebSocket tunnel by sending a `CLOSE` frame.
     This method should only be used when no network or protocol error occurs.
- `close()`: dispose a WebSocket tunnel, release related resource.
     The underlying HTTP connection will be closed as well.
- `impl @io.BinaryWriter for Conn`: write binary content to the message currently being sent, created via `.start_message()`
- `ping()`: actively send a WebSocket PING message and wait for corresponding PONG reply.
    `.ping()` can be called inside another message being sent.
    However, `.ping()` must be called when there is another task receiving message from the tunnel in parallel,
    otherwise the PONG reply can not be fetched, and `.ping()` will hang forever.

### `Message`
A single message received from a WebSocket tunnel.

- field `kind`: the kind of the message
- `impl @io.BinaryReader for Message`: read binary content of the message.
    For example, content of the whole message can be obtained via `.read_all()`


### `CloseCode`
WebSocket close code.

```moonbit no-check
///|
pub(all) enum CloseCode {
  Normal // 1000
  GoingAway // 1001
  ProtocolError // 1002
  UnsupportedData // 1003
  Abnormal // 1006
  InvalidFramePayload // 1007
  PolicyViolation // 1008
  MessageTooBig // 1009
  MissingExtension // 1010
  InternalError // 1011
  Other(UInt16)
} derive(Debug, Eq)
```

### Error Types

#### `WebSocketError`
```moonbit no-check
///|
suberror WebSocketError {
  // Connection was closed with specific code.
  // with an optional message for close reason.
  ConnectionClosed(CloseCode, String?)
  InvalidHandshake(String) // Handshake failed with detailed reason
  ProtocolError // Malformed frame
} derive(Debug)
```
