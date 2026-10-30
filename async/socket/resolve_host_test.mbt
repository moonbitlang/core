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
async test "resolve mooncakes.io" {
  inspect(
    @socket.Addr::resolve("mooncakes.io", port=443),
    content="34.219.237.228:443",
  )
}

///|
async test "resolve cancel" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let lock = @async.Semaphore(1, initial_value=1)
    let task = root.spawn(() => {
      lock.release()
      log.write_object(@socket.Addr::resolve("does.not.exist", port=443))
    })
    lock.acquire() // make sure the task already started
    task.cancel()
    log <+ "host resolution cancelled\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|host resolution cancelled
      #|
    ),
  )
}

///|
async test "resolve failure" {
  assert_true(
    (@test.expect_error_async <| () => {
      @socket.Addr::resolve("does.not.exist", port=443)
    })
    is @socket.ResolveHostnameError(_),
  )
}

///|
async test "resolve preference" {
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=FavorV4),
    content="127.0.0.1:80",
  )
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=OnlyV4),
    content="127.0.0.1:80",
  )
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=FavorV6),
    content="[::1]:80",
  )
  inspect(
    @socket.Addr::resolve("localhost", port=80, protocol=OnlyV6),
    content="[::1]:80",
  )
}

///|
async test "resolve plain IP" {
  inspect(@socket.Addr::resolve("8.8.8.8", port=53), content="8.8.8.8:53")
  inspect(@socket.Addr::resolve("[::1]", port=80), content="[::1]:80")
  inspect(
    @socket.Addr::resolve("[fe80::b65e:e4fa:c7f6:c3fd]", port=80),
    content=(
      #|[fe80::b65e:e4fa:c7f6:c3fd]:80
    ),
  )
}
