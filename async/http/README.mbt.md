HTTP support for `moonbitlang/core/async`.

## Making simple HTTP request

Simple HTTP request can be made in just one line:

```moonbit check
///|
#cfg(any(target="native", target="js"))
async test {
  let (response, body) = @http.get_text("https://www.moonbitlang.com")
  inspect(response.code, content="200")
  assert_true(body.has_prefix("<!doctype html>"))
}
```

Use `@http.get_text()` to get a UTF-8-decoded `String`,
`@http.get_binary()` to get raw `Bytes`, or `@http.get_json()` to get `Json`.

## Generic HTTP client
Sometimes, the simple one-time `@http.get_xxx` etc. is insufficient,
for example you need to reuse the same connection for multiple requests,
or the request/response body is very large and need to be processed lazily.
In this case, you can use the `@http.Client` type.
`@http.Client` can be created via `@http.Client(uri)`.

The workflow of performing a request with `@http.Client` is:

1. initiate the request via `client.request(..)`
1. send the request body by using `@http.Client` as a `@io.BinaryWriter`.
   Text payload can also be written through `client.text` as an `@io.TextWriter`.
1. complete the request and obtain response header from the server
  via `client.end_request()`
1. read the response body by using `@http.Client` as a `@io.BinaryReader`.
   You can also ignore the body via `client.skip_response_body()`.
   Text responses can be read through `client.text` as an `@io.TextReader`.

The helpers `client.get(..)`, `client.put_text(..)` etc.
can be used to perform step (1)-(3) above.
For a one-shot streaming request, `@http.get_stream()`, `@http.post_stream()` etc.
can be used to perform client creation plus step (1) above.

A complete example:

```moonbit check
///|
#cfg(any(target="native", target="js"))
async test {
  let client = @http.Client("https://www.moonbitlang.com")
  defer client.close()
  let response = client..request(Get, "/").end_request()
  inspect(response.code, content="200")
  let body = client.text.read_all()
  assert_true(body.has_prefix("<!doctype html>"))
}
```

All HTTP client API, including the simple request helpers `@http.get_xxx` etc.,
are supported on JavaScript backend using `fetch` API,
meaning that you can use these API in browser environment.
Notice that some feature, such as proxy, is not supported on JavaScript backend.

## Writing HTTP servers
The recommended way to create HTTP servers is `@http.Server::run_forever(..)`.
A HTTP server should first get created via `@http.Server(..)`,
after that, `server.run_forever(f)` automatically start and run the server.
The callback function `f` is used to handle HTTP requests.
It receives three parameters:

- the request to process
- a `@http.ServerConnection` that can be used to read request body or send response.

Content of the incoming request body can be read streamingly
using `@io.BinaryReader` interface (or `@io.TextReader` interface through the builtin `.text` view)
on the `@http.ServerConnection` directly.

The procedure to send a response is:
1. initiate a response and send response header via `.send_response()`
2. send response body by using the `@http.ServerConnection` as `@io.BinaryWriter`.
   Text content can be written directly via `conn.text`
   through the `@io.TextWriter` interface as well
3. (optional) complete the response via `.end_response()`.
    If `.end_response()` is not called, it will be called automatically
    after `f` returns normally.

Here's an example server that returns 404 to every request:

```moonbit check
///|
/// A simple HTTP server that return 404 for every request
#cfg(target="native")
pub async fn server(listen_addr : @socket.Addr) -> Unit {
  @http.Server(listen_addr).run_forever((request, conn) => {
    conn.send_response(404, "NotFound")
    conn.text.write("`\{request.path}` not found")
  })
}
```
