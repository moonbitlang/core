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
suberror ServerTerminate

///|
async fn server_main(server : @socket.TcpServer) -> Int32 {
  let mut num_connection = 0
  (server.run_forever(allow_failure=false) <| ((conn, _) => {
    num_connection += 1
    while conn.read() is Some(msg) {
      if msg == b"exit" {
        @async.sleep(20)
        raise ServerTerminate
      }
    }
  })) catch {
    ServerTerminate => return num_connection
    err => raise err
  }
  panic()
}

///|
async fn client(msg : Bytes, addr : @socket.Addr) -> Unit {
  let conn = @socket.Tcp::connect(addr)
  defer conn.close()
  conn.write(msg)
}

///|
async test "connection burst" {
  let mut result = 0
  @async.with_task_group() <| root => {
    let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
    let addr = server.addr
    root.spawn_bg(() => result = server_main(server))
    root.spawn_bg() <| () => {
      @async.with_task_group() <| fn(ctx) {
        for _ in 0..<6 {
          ctx.spawn_bg(() => client(b"ping", addr))
        }
      }
      root.spawn_bg(() => client(b"exit", addr))
    }
  }
  inspect(result, content="7")
}

///|
async test "connection burst with ipv6" {
  let mut result = 0
  @async.with_task_group() <| root => {
    let server = @socket.TcpServer(
      @socket.Addr::parse("[::1]:0"),
      dual_stack=false,
    )
    let addr = server.addr
    root.spawn_bg(() => result = server_main(server))
    root.spawn_bg() <| () => {
      @async.with_task_group() <| fn(ctx) {
        for _ in 0..<6 {
          ctx.spawn_bg(() => client(b"ping", addr))
        }
      }
      root.spawn_bg(() => client(b"exit", addr))
    }
  }
  inspect(result, content="7")
}
