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
/// Read one message from `data` with `read`, and describe the outcome.
async fn read_line_outcome(
  data : Bytes,
  read : async (Reader) -> String,
) -> String {
  let mem = @io.MemoryReader(async fn(w) { w.write(data) })
  defer mem.close()
  let reader = Reader::new(mem)
  read(reader) catch {
    e => @debug.to_string(e)
  }
}

///|
async test "chunk size lines" {
  let log = StringBuilder()
  for
    line in [
      "1f", "1f;a", "1f ;a", "1f\t; a = b ; c", "1f;a=\"x\\\"y\"", "1f;a=\"é\"",
      "1f;a=\"中\"", "1f;", "1f;a=", "1f;a=\"x", "1f;a\"b\"", "1f;a b", "1f ", "1f;a=b c",
    ] {
    let data = b"HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n" +
      @utf8.encode(line) +
      b"\r\n0123456789abcdef0123456789abcde\r\n0\r\n\r\n"
    let outcome = read_line_outcome(data, async fn(reader) {
      ignore(reader.read_response(auto_decompress=false, request_method=None))
      reader.read_all().length().to_string()
    })
    log.write_string("\{line.escape()} => \{outcome}\n")
  }
  inspect(
    log.to_string(),
    content=(
      #|"1f" => 31
      #|"1f;a" => 31
      #|"1f ;a" => 31
      #|"1f\t; a = b ; c" => 31
      #|"1f;a=\"x\\\"y\"" => 31
      #|"1f;a=\"é\"" => 31
      #|"1f;a=\"中\"" => BadRequest
      #|"1f;" => BadRequest
      #|"1f;a=" => BadRequest
      #|"1f;a=\"x" => BadRequest
      #|"1f;a\"b\"" => BadRequest
      #|"1f;a b" => BadRequest
      #|"1f " => BadRequest
      #|"1f;a=b c" => BadRequest
      #|
    ),
  )
}

///|
async test "request, status and header lines" {
  let log = StringBuilder()
  for
    line in [
      "GET /x HTTP/1.1", "PROPFIND / HTTP/1.0", "GET  HTTP/1.1", "GET /x", "GET /x HTTP/2",
      "G(T /x HTTP/1.1", " /x HTTP/1.1",
    ] {
    let data = @utf8.encode(line) + b"\r\nX:  two spaces\r\n\r\n"
    let outcome = read_line_outcome(data, async fn(reader) {
      let r = reader.read_request()
      "\{@debug.to_string(r.meth)} \{r.path.escape()} \{r.headers.get("X").unwrap().escape()}"
    })
    log.write_string("\{line.escape()} => \{outcome}\n")
  }
  for
    line in [
      "HTTP/1.1 200 OK", "HTTP/1.0 404 Not Found", "HTTP/1.1 204 ", "HTTP/1.1 200",
      "HTTP/2 200 OK", "HTTP/1.1 2x0 OK", "HTTP/1.1",
    ] {
    let data = @utf8.encode(line) + b"\r\n\r\n"
    let outcome = read_line_outcome(data, async fn(reader) {
      let r = reader.read_response(auto_decompress=false, request_method=None)
      "\{r.code} \{r.reason.escape()}"
    })
    log.write_string("\{line.escape()} => \{outcome}\n")
  }
  for line in ["Bad Name: v", ": v", "X-Y:v", "X(Y: v"] {
    let data = b"GET / HTTP/1.1\r\n" + @utf8.encode(line) + b"\r\n\r\n"
    let outcome = read_line_outcome(data, async fn(reader) {
      let r = reader.read_request()
      @debug.to_string(r.headers)
    })
    log.write_string("\{line.escape()} => \{outcome}\n")
  }
  inspect(
    log.to_string(),
    content=(
      #|"GET /x HTTP/1.1" => Get "/x" " two spaces"
      #|"PROPFIND / HTTP/1.0" => Extension("PROPFIND") "/" " two spaces"
      #|"GET  HTTP/1.1" => Get "" " two spaces"
      #|"GET /x" => BadRequest
      #|"GET /x HTTP/2" => HttpVersionNotSupported("HTTP/2")
      #|"G(T /x HTTP/1.1" => BadRequest
      #|" /x HTTP/1.1" => BadRequest
      #|"HTTP/1.1 200 OK" => 200 "OK"
      #|"HTTP/1.0 404 Not Found" => 404 "Not Found"
      #|"HTTP/1.1 204 " => 204 ""
      #|"HTTP/1.1 200" => BadRequest
      #|"HTTP/2 200 OK" => HttpVersionNotSupported("HTTP/2")
      #|"HTTP/1.1 2x0 OK" => BadRequest
      #|"HTTP/1.1" => BadRequest
      #|"Bad Name: v" => BadRequest
      #|": v" => BadRequest
      #|"X-Y:v" => { "X-Y": "v" }
      #|"X(Y: v" => BadRequest
      #|
    ),
  )
}
