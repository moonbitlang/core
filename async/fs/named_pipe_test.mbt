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
#cfg(not(platform="windows"))
#borrow(path)
extern "C" fn mkfifo(path : @os_string.OsString, mode : Int32) -> Int32 = "mkfifo"

///|
#cfg(not(platform="windows"))
async test "cancel named fifo open" {
  let path = "_build/cancel_open_test"
  if mkfifo(@os_string.from_string(path), 0o644) < 0 {
    @os_error.check_errno("mkfifo")
  }
  defer @fs.remove(path)
  let result = @async.with_timeout_opt(500, () => {
    @fs.open(path, mode=ReadOnly).close()
  })
  debug_inspect(result, content="None")
}

///|
#cfg(platform="windows")
async test "cancel named pipe open" {
  let context = "cancel named pipe open test"
  let path = "\\\\.\\pipe\\moonbitlang_async_cancel_open_test"
  let server = @fd_util.create_named_pipe_server(
    @os_string.from_string(path),
    is_async=false,
  )
  if !@fd_util.fd_is_valid(server) {
    @os_error.check_errno(context)
  }
  defer (try! @fd_util.close(server, kind=Pipe, context~))
  let client1 = @fs.open(path, mode=ReadOnly)
  defer client1.close()
  let result = @async.with_timeout_opt(500, () => {
    @fs.open(path, mode=ReadOnly).close()
  })
  debug_inspect(result, content="None")
}

///|
#cfg(not(platform="windows"))
async test "named fifo" {
  @async.with_task_group() <| group => {
    let path = "_build/named_pipe_test"
    if mkfifo(@os_string.from_string(path), 0o644) < 0 {
      @os_error.check_errno("mkfifo")
    }
    group.add_defer(() => @fs.remove(path))
    group.spawn_bg() <| () => {
      let r = @fs.open(path, mode=ReadOnly)
      defer r.close()
      inspect(r.text.read_until("\n").unwrap_or(""), content="abcd")
      debug_inspect(
        @async.with_timeout_opt(250, () => r.text.read_all()),
        content="None",
      )
      inspect(r.text.read_all(), content="efgh")
    }
    group.spawn_bg() <| () => {
      let w = @fs.open(path, mode=WriteOnly)
      defer w.close()
      w.write(b"abcd\n")
      @async.sleep(500)
      w.write(b"efgh")
    }
  }
}

///|
#cfg(platform="windows")
async test "named pipe" {
  @async.with_task_group() <| group => {
    let context = "named pipe test"
    let path = "\\\\.\\pipe\\moonbitlang_async_named_pipe_test"
    let w = @fd_util.create_named_pipe_server(
      @os_string.from_string(path),
      is_async=true,
    )
    if !@fd_util.fd_is_valid(w) {
      @os_error.check_errno(context)
    }
    group.spawn_bg() <| () => {
      let r = @fs.open(path, mode=ReadOnly)
      defer r.close()
      inspect(r.text.read_until("\n").unwrap_or(""), content="abcd")
      debug_inspect(
        @async.with_timeout_opt(250, () => r.text.read_all()),
        content="None",
      )
      inspect(r.text.read_all(), content="efgh")
    }
    group.spawn_bg() <| () => {
      // wait for the client to connect
      @async.sleep(200)
      let w = @event_loop.IoHandle::from_fd(w, kind=Pipe)
      defer w.close()
      ignore(w.write(b"abcd\n", offset=0, len=5, context=""))
      @async.sleep(500)
      ignore(w.write(b"efgh", offset=0, len=4, context=""))
    }
  }
}

///|
#cfg(platform="windows")
async test "named pipe multiple client" {
  let log = []
  let context = "named pipe test"
  let path = "\\\\.\\pipe\\moonbitlang_async_named_pipe_multiple_client_test"
  let w = @fd_util.create_named_pipe_server(
    @os_string.from_string(path),
    is_async=true,
  )
  if !@fd_util.fd_is_valid(w) {
    @os_error.check_errno(context)
  }
  let w = @event_loop.IoHandle::from_fd(w, kind=Pipe)
  defer w.close()
  @async.with_task_group() <| group => {
    for i in 1..<=2 {
      group.spawn_bg() <| () => {
        @async.sleep(i * 50)
        let r = @fs.open(path, mode=ReadOnly)
        defer r.close()
        log.push("client #\{i} connected")
        ignore(
          w.write(
            b"abcd",
            offset=0,
            len=4,
            context="writing to named pipe server",
          ),
        )
        inspect(@utf8.decode(r.read_exactly(4)), content="abcd")
        if i is 1 {
          @async.sleep(300)
          log.push("server disconnecting")
          @fd_util.disconnect_named_pipe_server(w.fd())
          @async.sleep(100)
          log.push("server connecting again")
          @fd_util.connect_named_pipe_server_sync(w.fd())
        }
      }
    }
  }
  json_inspect(log, content=[
    "client #1 connected", "server disconnecting", "server connecting again", "client #2 connected",
  ])
}
