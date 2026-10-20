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
    @async_io.set_external_event_loop(main_loop)
    @async_io.with_task_group <| group => {
      let server = @socket.TcpServer(@socket.Addr::parse("127.0.0.1:0"))
      let start = @async_io.now()
      fn tick() {
        (@async_io.now() - start + 50) / 150
      }
      group.spawn_bg() <| () => {
        defer server.close()
        let (conn, _) = server.accept()
        defer conn.close()
        main_loop.log("TCP server received connection at #\{tick()}")
      }
      group.spawn_bg() <| () => {
        @async_io.sleep(300)
        main_loop.log("attempting connect")
        let conn = @socket.Tcp::connect(server.addr)
        @async_io.sleep(100)
        defer conn.close()
      }
      group.spawn_bg(no_wait=true) <| () => {
        for ;; {
          main_loop.wait()
          main_loop.log("received main loop specific event at #\{tick()}")
        }
      }
      group.spawn_bg() <| () => {
        @external_loop_test.trigger_main_loop_event(delay=150)
      }
      group.spawn_bg() <| () => {
        @external_loop_test.trigger_main_loop_event(delay=450)
      }
      @async_io.sleep(600)
    }
  }
  json_inspect(main_loop.log, content=[
    "main loop: received custom event", "received main loop specific event at #1",
    "attempting connect", "TCP server received connection at #2", "main loop: received custom event",
    "received main loop specific event at #3", "terminate main loop",
  ])
}

///|
#cfg(target="native")
test "external loop blocked on external only" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async_io.set_external_event_loop(main_loop)
    @async_io.with_task_group <| group => {
      let start = @async_io.now()
      fn tick() {
        (@async_io.now() - start + 50) / 150
      }
      group.spawn_bg() <| () => {
        @external_loop_test.trigger_main_loop_event(delay=150)
      }
      main_loop.wait()
      main_loop.log("main loop received custom event at #\{tick()}")
    }
  }
  json_inspect(main_loop.log, content=[
    "main loop: received custom event", "main loop received custom event at #1",
    "terminate main loop",
  ])
}

///|
#cfg(target="native")
test "external loop blocked on async only" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async_io.set_external_event_loop(main_loop)
    @async_io.with_task_group <| group => {
      let (r, w) = @pipe.pipe()
      defer r.close()
      defer w.close()
      let start = @async_io.now()
      fn tick() {
        (@async_io.now() - start + 50) / 150
      }
      for i, delay in [150, 300] {
        group.spawn_bg() <| () => {
          @external_loop_test.trigger_event(w.fd(), i, delay~)
        }
      }
      for _ in 0..<2 {
        guard! r.read_exactly(4) is [i32le(data)]
        main_loop.log("main loop received \{data} at #\{tick()}")
      }
    }
  }
  json_inspect(main_loop.log, content=[
    "main loop received 0 at #1", "main loop received 1 at #2", "terminate main loop",
  ])
}

///|
#cfg(target="native")
test "non-blocking read & external waiter race" {
  let main_loop = @external_loop_test.MainLoop()
  @event_loop.with_event_loop <| () => {
    @async_io.set_external_event_loop(main_loop)
    let (r, w) = @pipe.pipe()
    defer r.close()
    @async_io.with_task_group <| group => {
      // The following three tasks will start running at the same scheduler slice
      group.spawn_bg() <| () => {
        defer w.close()
        // The `write` here will generate a read-readiness event for the pipe
        w.write(b"abcd")
        @async_io.sleep(150)
        w.write(b"xyzw")
      }
      group.spawn_bg() <| () => {
        // do some spinning here to ensure the waiter thread has generated
        // the read readiness event before we drain the pipe
        let start = @async_io.now()
        while @async_io.now() - start < 10 {

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
}
