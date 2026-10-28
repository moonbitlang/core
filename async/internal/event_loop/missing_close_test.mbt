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
test "missing_close" {
  let log = StringBuilder()
  @event_loop.check_fd_leak.val = false
  @event_loop.with_event_loop() <| () => {
    @async.with_task_group() <| root => {
      let (r, w) = @pipe.pipe()
      root.spawn_bg() <| () => {
        let data = r.read_exactly(4) |> @utf8.decode
        @async.sleep(10)
        log <+ "received \{data}\n"
      }
      root.spawn_bg() <| () => {
        let data = "abcd"
        w.write(@utf8.encode(data))
        log <+ "written \{data}\n"
      }
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|written abcd
      #|received abcd
      #|
    ),
  )
}
