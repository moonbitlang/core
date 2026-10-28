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
#cfg(any(target="native", target="wasm"))
async fn non_responding_tcp_server(group : @async.TaskGroup) -> Int32 {
  let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
  group.add_defer(() => server.close())
  server.addr.port()
}

///|
#cfg(target="js")
#external
type TcpServer

///|
#cfg(target="js")
extern "js" fn TcpServer::create() -> @js_async.Promise[TcpServer] =
  #| () => {
  #|   const net = require('node:net')
  #|   const server = net.createServer({})
  #|   server.listen(0, "127.0.0.1")
  #|   return new Promise((resolve) => {
  #|     server.on('listening', () => resolve(server))
  #|   })
  #| }

///|
#cfg(target="js")
extern "js" fn TcpServer::close(server : TcpServer) =
  #| (server) => server.close()

///|
#cfg(target="js")
extern "js" fn TcpServer::port(server : TcpServer) -> Int32 =
  #| (server) => server.address().port

///|
#cfg(target="js")
async fn non_responding_tcp_server(group : @async.TaskGroup) -> Int32 {
  let server = TcpServer::create().wait()
  group.add_defer(() => server.close())
  server.port()
}

///|
#cfg(any(target="native", target="wasm"))
async fn test_server(group : @async.TaskGroup, log : &Logger) -> Int32 {
  let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
  group.spawn_bg(no_wait=true) <| () => {
    server.run_forever() <| ((request, conn) => {
      match request.path {
        "/no-response" => {
          @async.sleep(10000)
          return
        }
        "/no-response-body" => {
          conn..send_response(200, "OK").flush()
          @async.sleep(10000)
          return
        }
        "/get-streaming" | "/put-streaming" | "/post-streaming" => {
          let meth = @debug.to_string(request.meth).to_upper()
          log <+ "server received request: \{meth} \{request.path}\n"
          while conn.text.read() is Some(data) {
            log <+ "server received: \{data}"
          }
          conn.send_response(200, "OK")
          log <+ "server: sending \{meth} response part 1\n"
          conn.text.write("\{meth} response part 1\n")
          conn.flush()
          @async.sleep(300)
          log <+ "server: sending \{meth} response part 2\n"
          conn.text.write("\{meth} response part 2\n")
          conn.flush()
        }
        "/informational" => {
          conn
          ..send_response(100, "CONTINUE", extra_headers={ "Info": "round1" })
          .end_response()
          @async.sleep(300)
          conn
          ..send_response(100, "CONTINUE", extra_headers={ "Info": "round2" })
          .end_response()
          @async.sleep(100)
          conn..send_response(200, "OK").end_response()
        }
        path => raise Failure("unknown request path: \{path}")
      }
    })
  }
  server.addr.port()
}

///|
#cfg(target="js")
#external
type Server

///|
#cfg(target="js")
extern "js" fn Server::close(server : Server) =
  #| (server) => {
  #|   server.close()
  #|   server.closeAllConnections()
  #| }

///|
#cfg(target="js")
extern "js" fn Server::port(server : Server) -> Int32 =
  #| (server) => server.address().port

///|
#cfg(target="js")
extern "js" fn Server::create(
  logger : (String) -> Unit,
) -> @js_async.Promise[Server] =
  #| (logger) => {
  #|   const http = require('node:http')
  #|   const server = http.createServer()
  #|   server.on('request', (req, response) => {
  #|     logger(`server received request: ${req.method} ${req.url}\n`)
  #|     if (req.url === '/no-content') {
  #|       response.statusCode = 204
  #|       response.end()
  #|       return
  #|     }
  #|     if (req.url === '/reset-content') {
  #|       response.statusCode = 205
  #|       response.end()
  #|       return
  #|     }
  #|     if (req.url === '/not-modified') {
  #|       response.statusCode = 304
  #|       response.end()
  #|       return
  #|     }
  #|     if (req.method === 'HEAD') {
  #|       response.statusCode = 200
  #|       response.end()
  #|       return
  #|     }
  #|     if (req.url === '/no-response') {
  #|       return
  #|     }
  #|     if (req.url === '/no-response-body') {
  #|       response.statusCode = 200
  #|       response.flushHeaders()
  #|       return
  #|     }
  #|     if (
  #|       req.url === '/get-streaming'
  #|       || req.url === '/put-streaming'
  #|       || req.url === '/post-streaming'
  #|     ) {
  #|       req.on('data', (data) => {
  #|         logger(`server received: ${data}`)
  #|       })
  #|       req.on('end', () => {
  #|         response.statusCode  = 200
  #|         response.statusMessage = "OK"
  #|         logger(`server: sending ${req.method} response part 1\n`)
  #|         response.write(`${req.method} response part 1\n`, () => {
  #|           setTimeout(() => {
  #|             logger(`server: sending ${req.method} response part 2\n`)
  #|             response.end(`${req.method} response part 2\n`)
  #|           }, 100)
  #|         })
  #|       })
  #|       return
  #|     }
  #|     throw Error(`unknown request path: ${req.url}`)
  #|   })
  #|   server.listen(0, '127.0.0.1')
  #|   return new Promise((resolve) => {
  #|     server.on('listening', () => resolve(server))
  #|   })
  #| }

///|
#cfg(target="js")
async fn test_server(group : @async.TaskGroup, log : &Logger) -> Int32 {
  let server = Server::create(msg => log.write_string(msg)).wait()
  group.add_defer(() => server.close())
  server.port()
}
