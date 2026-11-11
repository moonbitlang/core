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
/// The test program of `@tty`'s tests (`async/tty/tty_test.mbt`), run on a fresh
/// controlling terminal by `pty`.
///
/// `ttyd` connects to `127.0.0.1:$TTYD_PORT` and serves JSON-RPC 2.0
/// requests on that connection, one JSON value per line, one request at a time,
/// until the connection is closed. Each method performs one `@tty` operation:
///
/// - `make_raw`: `set_state(get_state().make_raw())`, result `null`
/// - `size`: result `[rows, cols]`
/// - `read_event`, params `{"timeout"?: ms}`: result `{"type":"input","bytes":"<base64>"}`,
///   `{"type":"resize"}`, `{"type":"eof"}`, or `{"type":"timeout"}`
/// - `read`, params `{"max_len": n}`: `@io.Reader::read` into an `n`-byte
///   buffer, result the bytes in base64
/// - `read_exactly`, params `{"len": n}`: `@io.Reader::read_exactly`,
///   result the bytes in base64
/// - `write`, params `{"bytes": "<base64>"}`: result `null`
///
/// An error raised by `@tty` is reported as error `-32000` with its description.
async fn main {
  guard @env.get_env_var("TTYD_PORT") is Some(port) else {
    fail("TTYD_PORT is not set")
  }
  let tty = @tty.open()
  let rpc = @socket.Tcp::connect(@socket.Addr::parse("127.0.0.1:\{port}"))
  defer rpc.close()
  while rpc.read_until(b"\n") is Some(line) {
    let request = @json.parse(@utf8.decode_lossy(line))
    rpc.write(@utf8.encode("\{respond(tty, request).stringify()}\n"))
  }
}

///|
priv suberror RpcError {
  RpcError(code~ : Int32, message~ : String)
}

///|
async fn respond(tty : @tty.Tty, request : Json) -> Json {
  guard request
    is {
      "jsonrpc": "2.0",
      "method": String(name),
      "id"? : id,
      "params"? : params,
      ..
    } else {
    return {
      "jsonrpc": "2.0",
      "id": null,
      "error": { "code": -32600, "message": "Invalid Request" },
    }
  }
  let id = id.unwrap_or(null)
  let params = params.unwrap_or(Json::empty_object())
  try call(tty, name, params) catch {
    RpcError(code~, message~) =>
      {
        "jsonrpc": "2.0",
        "id": id,
        "error": { "code": Json(code), "message": Json(message) },
      }
    err =>
      {
        "jsonrpc": "2.0",
        "id": id,
        "error": { "code": -32000, "message": Json(@debug.to_string(err)) },
      }
  } noraise {
    result => { "jsonrpc": "2.0", "id": id, "result": result }
  }
}

///|
async fn call(tty : @tty.Tty, name : String, params : Json) -> Json {
  match name {
    "make_raw" => {
      tty.set_state(tty.get_state().make_raw())
      null
    }
    "size" => {
      let (rows, cols) = tty.size()
      [rows, cols]
    }
    "read_event" => {
      let event = match params {
        { "timeout": Number(timeout, ..), .. } =>
          match
            @async.with_timeout_opt(timeout.to_int(), () => tty.read_event()) {
            None => return { "type": "timeout" }
            Some(event) => event
          }
        { "timeout": _, .. } =>
          raise invalid_params("`timeout` must be a number")
        _ => tty.read_event()
      }
      match event {
        Some(Input(bytes)) =>
          { "type": "input", "bytes": @base64.encode(bytes) }
        Some(Resize) => { "type": "resize" }
        None => { "type": "eof" }
      }
    }
    "read" => {
      guard params is { "max_len": Number(max_len, ..), .. } else {
        raise invalid_params("`max_len` must be a number")
      }
      let buf = FixedArray::make(max_len.to_int(), b'\x00')
      let n = tty.read_into(buf)
      Json(@base64.encode(Bytes::from_array(buf[:n])))
    }
    "read_exactly" => {
      guard params is { "len": Number(len, ..), .. } else {
        raise invalid_params("`len` must be a number")
      }
      Json(@base64.encode(tty.read_exactly(len.to_int())))
    }
    "write" => {
      guard params is { "bytes": String(bytes), .. } else {
        raise invalid_params("`bytes` must be a base64 string")
      }
      tty.write(@base64.decode(bytes))
      null
    }
    _ => raise RpcError(code=-32601, message="Method not found: \{name}")
  }
}

///|
fn invalid_params(message : String) -> RpcError {
  RpcError(code=-32602, message~)
}
