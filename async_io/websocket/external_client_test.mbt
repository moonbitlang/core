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
async test "external client" {
  let log = []
  @async_io.with_task_group() <| group => {
    let server = @http.Server(@socket.Addr::parse("127.0.0.1:0"))
    let port = server.addr.port()
    group.spawn_bg(no_wait=true) <| () => {
      server.run_forever() <| ((request, conn) => {
        log.push("new client to \{request.path}")
        let ws = @websocket.from_http_server(request, conn)
        defer ws.close()
        for ;; {
          let msg = ws.recv()
          let data = msg.text.read_all()
          log.push("\{@debug.to_string(msg.kind)}: \{data}")
          ws.start_message(msg.kind)
          ws.text.write(data)
          ws.end_message()
        }
      })
    }
    let result = @process.run(
      "node",
      ["async_io/websocket/client.ts", "ws://127.0.0.1:\{port}"],
      stdout=@process.read_from_process(),
    )
    inspect(
      result.stdout_text(),
      content=(
        #|Connection opened
        #|Message from server:  Hello, Server!
        #|Connection closed
        #|
      ),
    )
  }
  json_inspect(log, content=["new client to /", "Text: Hello, Server!"])
}
