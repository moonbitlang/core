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
async test "reuse addr" {
  async fn run_server(server : @socket.TcpServer) -> Unit {
    defer server.close()
    let port = server.addr.port()
    @async.with_task_group <| group => {
      group.spawn_bg() <| () => {
        let (conn, _) = server.accept()
        defer conn.close()
        conn.write(b"abcd")
      }
      group.spawn_bg() <| () => {
        let conn = @socket.Tcp::connect(
          @socket.Addr::parse("127.0.0.1:\{port}"),
        )
        defer conn.close()
        inspect(@utf8.decode(conn.read_all()), content="abcd")
      }
    }
  }
  for _ in 0..<2; port = 0 {
    let server = @socket.TcpServer(
      @socket.Addr::parse("127.0.0.1:\{port}"),
      reuse_addr=true,
    )
    defer server.close()
    run_server(server)
    continue server.addr.port()
  }
}
