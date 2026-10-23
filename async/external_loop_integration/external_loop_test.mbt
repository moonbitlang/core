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
#cfg(target="native")
test "external loop mixed" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async.set_external_event_loop(main_loop)
    @async.with_timeout(500) <| () => {
      @async.with_task_group <| group => {
        let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
        group.spawn_bg() <| () => {
          defer server.close()
          let (conn, _) = server.accept()
          defer conn.close()
        }
        let conn = @socket.Tcp::connect(server.addr)
        defer conn.close()
      }
    }
    @external_loop_test.trigger_main_loop_event(delay=150)
    @async.with_timeout(300, () => main_loop.wait())
  }
  assert_true(main_loop.terminated)
}

///|
#cfg(target="native")
test "external loop blocked on external only" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async.set_external_event_loop(main_loop)
    @external_loop_test.trigger_main_loop_event(delay=150)
    @async.with_timeout(300, () => main_loop.wait())
  }
  assert_true(main_loop.terminated)
}

///|
#cfg(target="native")
test "external loop blocked on async only" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async.set_external_event_loop(main_loop)
    let (r, w) = @pipe.pipe()
    defer r.close()
    defer w.close()
    @external_loop_test.trigger_event(w.fd(), 42, delay=150)
    guard! @async.with_timeout(300, () => r.read_exactly(4)) is [i32le(data)]
    inspect(data, content="42")
  }
  assert_true(main_loop.terminated)
}

///|
#cfg(target="native")
test "non-blocking read & external waiter race" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async.set_external_event_loop(main_loop)
    let (r, w) = @pipe.pipe()
    defer r.close()
    @async.with_task_group <| group => {
      // The following three tasks will start running at the same scheduler slice
      group.spawn_bg() <| () => {
        defer w.close()
        // The `write` here will generate a read-readiness event for the pipe
        w.write(b"abcd")
        @async.sleep(200)
        w.write(b"xyzw")
      }
      group.spawn_bg() <| () => {
        // do some spinning here to ensure the waiter thread has generated
        // the read readiness event before we drain the pipe
        let start = @async.now()
        while @async.now() - start < 10 {

        }
        // The `read` here will execute after the `write` above,
        // so it would immediately succeed and drain all data in the pipe.
        // At this point, the read readiness event for the pipe
        // is still in the event bus and not yet consumed.
        guard r.read() is Some(data) else {
          fail("expected data, no data found")
        }
        inspect(@utf8.decode(data), content="abcd")
      }
      group.spawn_bg() <| () => {
        // The `read` here has no data to read, because the pipe
        // is already drained by the first `read` above.
        // The first non-blocking `read` attempt here will fail with `EAGAIN`,
        // and the task will start waiting for read readiness of the pipe.
        //
        // Now, the event loop will enter the next slice.
        // The main loop will get waken by the event from the waiter thread,
        // and the stale read readiness event will wake this task up.
        // But at this point, there is still no data in the pipe,
        // so the second `read` attempt still fail with `EAGAIN`, failing the whole test
        guard r.read() is Some(data) else {
          fail("expected data, no data found")
        }
        inspect(@utf8.decode(data), content="xyzw")
      }
    }
  }
  assert_true(main_loop.terminated)
}
