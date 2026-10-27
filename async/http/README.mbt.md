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

## Streaming message body

For HTTP messages with large body, collecting the whole body in memory could be a bad idea.
The `@http` package also provide convenient API for manipulating message body streamingly:

```moonbit check
///|
#cfg(any(target="native", target="js"))
async test {
  let (response, conn) = @http.get("https://www.moonbitlang.com")
  defer conn.close()
  inspect(response.code, content="200")
  let body = conn.text.read_all()
  assert_true(body.has_prefix("<!doctype html>"))
}
```

Here, `@http.get(url)` performs a `GET` request to URL,
and returns the response header from the server,
plus the HTTP connection assigned for this request.
The content of response body can be read from the connection through the `@io.BinaryReader` interface,
or through the `@io.TextReader` interface using the `.text` view on the connection.
The connection must be closed via `.close()` after finishing the request.

`@http.put` and `@http.post` work similarly, except that the response header will not be returned immediately.
`@http.put` and `@http.post` only returns the HTTP connection for the request.
The caller should first write the content of request body
through the `@io.BinaryWriter` interface on the connection
(or through the `@io.TextWriter` interface via `.text`).
After finishing the request body, `.end_request` should be invoked on the connection
to finish the request and obtain response header from the server.
After `.end_request`, body of response message can be read from the connection as in the `@http.get` case above.

## Generic HTTP client
When performing multiple requests to the same host,
sharing and reusing HTTP connection can save a lot of resource.
The generic `@http.Client` type provides connection pool backed HTTP client support.
A HTTP client can be created via `@http.Client(..)` and must be closed via `.close()`.
Users can perform requests through the client via `.request(..)`, `.get(..)` etc.,
the semantic of these methods are similar to `@http.request(..)`, `@http.get(..)` etc.,
except that they can reuse the client's existing connections to save resource.
Multiple requests can be performed on the same client concurrently,
the client will automatically create new connection if necessary to fulfill requests.

> note: currently the `@http.Client` is just a placeholder that create a new connection for every request.
> Proper connection pool support will be implemented in the near future.

## JavaScript compatibility
All HTTP client API, including the toplevel `@http.xxx` helpers and the generic `@http.Client` type,
has browser-compatible JavaScript backend support using `fetch` API,
Notice that some feature, such as proxy and streaming request body building,
are not supported on JavaScript backend due to limitation of `fetch` API.

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
