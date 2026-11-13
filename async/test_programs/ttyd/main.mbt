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
/// - `read`, params `{"max_len"?: n, "timeout"?: ms}`:
///   `Tty::read`, or `Tty::read_into` an `n`-byte buffer with `max_len`
/// - `read_exactly`, params `{"len": n}`:
///   `Tty::read_exactly`
///
///   Both result in `{"type":"input","bytes":"<base64>"}`, `{"type":"resize"}`
///   for `Resized`, `{"type":"eof"}`, or `{"type":"timeout"}` when the read is
///   cancelled after `timeout`.
/// - `peek_exactly`, `drop_exactly`: params `{"len": n}`
/// - `read_until`: read through a newline
/// - `expect_unexpected_eof`: verify the typed error from `read_exactly(2)`
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
    "read" => {
      let max_len = match params {
        { "max_len": Number(max_len, ..), .. } => Some(max_len.to_int())
        { "max_len": _, .. } =>
          raise invalid_params("`max_len` must be a number")
        _ => None
      }
      read_result(params, () => {
        match max_len {
          None => input_result(tty.read())
          Some(max_len) => {
            let buf = FixedArray::make(max_len, b'\x00')
            match tty.read_into(buf) {
              Resized => { "type": "resize" }
              Value(0) => { "type": "eof" }
              Value(n) =>
                {
                  "type": "input",
                  "bytes": @base64.encode(Bytes::from_array(buf[:n])),
                }
            }
          }
        }
      })
    }
    "read_exactly" => {
      guard params is { "len": Number(len, ..), .. } else {
        raise invalid_params("`len` must be a number")
      }
      read_result(params, () => {
        match tty.read_exactly(len.to_int()) {
          Resized => { "type": "resize" }
          Value(bytes) => { "type": "input", "bytes": @base64.encode(bytes) }
        }
      })
    }
    "peek_exactly" => {
      guard params is { "len": Number(len, ..), .. } else {
        raise invalid_params("`len` must be a number")
      }
      match tty.peek_exactly(len.to_int()) {
        Resized => { "type": "resize" }
        Value(bytes) => { "type": "input", "bytes": @base64.encode(bytes) }
      }
    }
    "read_until" =>
      read_result(params, () => input_result(tty.read_until(b"\n")))
    "expect_unexpected_eof" =>
      try tty.read_exactly(2) catch {
        @io.UnexpectedEof => { "type": "unexpected_eof" }
        err => raise err
      } noraise {
        _ => fail("expected ReaderError::UnexpectedEof")
      }
    "drop_exactly" => {
      guard params is { "len": Number(len, ..), .. } else {
        raise invalid_params("`len` must be a number")
      }
      match tty.drop_exactly(len.to_int()) {
        Resized => { "type": "resize" }
        Value(_) => { "type": "dropped" }
      }
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
/// Run the read `f` with the `timeout` in `params`,
/// and describe its result.
async fn read_result(params : Json, f : async () -> Json) -> Json {
  try {
    match params {
      { "timeout": Number(timeout, ..), .. } =>
        match @async.with_timeout_opt(timeout.to_int(), () => f()) {
          None => return { "type": "timeout" }
          Some(result) => result
        }
      { "timeout": _, .. } => raise invalid_params("`timeout` must be a number")
      _ => f()
    }
  } catch {
    @io.UnexpectedEof => { "type": "eof" }
    err => raise err
  }
}

///|
fn input_result(result : @tty.MaybeResized[Bytes?]) -> Json {
  match result {
    Value(Some(bytes)) => { "type": "input", "bytes": @base64.encode(bytes) }
    Value(None) => { "type": "eof" }
    Resized => { "type": "resize" }
  }
}

///|
fn invalid_params(message : String) -> RpcError {
  RpcError(code=-32602, message~)
}
