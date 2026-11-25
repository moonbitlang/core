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
async test "multicast no loopback" {
  if @event_loop.platform is MacOS {
    // MacOS requires the user clicking a GUI alertbox for UDP multicast since MacOS 15
    return
  }
  let log = []
  @async.with_task_group() <| group => {
    let server = @socket.UdpServer::multicast(
      @socket.Addr::parse("239.0.0.1:0"),
    )
    group.spawn_bg(no_wait=true) <| () => {
      defer server.close()
      for ;; {
        let (data, _) = server.recv(max_len=1024)
        log.push("server received: \{@utf8.decode(data)}")
        if @event_loop.platform is Windows {
          server.set_multicast_loopback(false)
        }
      }
    }
    let client = @socket.UdpClient(
      @socket.Addr::parse("239.0.0.1:\{server.local_addr().port}"),
    )
    defer client.close()
    client.set_multicast_ttl(0)
    log.push("client sending: abcd")
    let _ = client.send(b"abcd")
    if !(@event_loop.platform is Windows) {
      client.set_multicast_loopback(false)
    }
    @async.sleep(200)
    log.push("client sending: xyzw")
    let _ = client.send(b"xyzw")
    @async.sleep(200)
  }
  json_inspect(log, content=[
    "client sending: abcd", "server received: abcd", "client sending: xyzw",
  ])
}
