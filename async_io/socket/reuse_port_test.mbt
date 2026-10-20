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
async test "reuse port lb" {
  // `SO_REUSEPORT` load-balances only on Linux. The option exists on the BSDs
  // and MacOS too, but there which socket accepts a given connection is
  // unspecified, so there is nothing to observe. `#cfg(platform=..)` cannot
  // express this — it only knows `windows` — so the check is made at runtime.
  if !(@event_loop.platform is Linux) {
    return
  }
  let mut accepted1 = 0
  let mut accepted2 = 0
  let finished = @async_io.with_timeout_opt(10000, () => {
    @async_io.with_task_group() <| group => {
      let server1 = @socket.TcpServer(
        @socket.Addr::parse("127.0.0.1:0"),
        reuse_port_lb=true,
      )
      let addr = server1.addr
      // Binding the same address again while `server1` is still listening only
      // succeeds because both sockets set `SO_REUSEPORT`.
      let server2 = @socket.TcpServer(addr, reuse_port_lb=true)
      // Each server is owned by the task that accepts on it: the group body
      // returns as soon as the tasks are spawned, so closing here would pull
      // the socket out from under a pending `accept`.
      group.spawn_bg() <| () => {
        defer server1.close()
        let (conn, _) = server1.accept()
        defer conn.close()
        accepted1 += 1
      }
      group.spawn_bg() <| () => {
        defer server2.close()
        let (conn, _) = server2.accept()
        defer conn.close()
        accepted2 += 1
      }
      // The kernel picks the target socket per connection, so keep connecting
      // until both have taken one. Only "both servers received a connection" is
      // asserted — never the split, which is not deterministic.
      group.spawn_bg(no_wait=true) <| () => {
        while accepted1 == 0 || accepted2 == 0 {
          let conn = @socket.Tcp::connect(addr)
          conn.close()
          @async_io.sleep(5)
        }
      }
    }
  })
  inspect(finished is Some(_), content="true")
  inspect(accepted1 > 0 && accepted2 > 0, content="true")
}
