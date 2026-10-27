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
async test "ReadableStream roundtrip" {
  let log = []
  let (r, w) = @js_async.JsReadableStream::new_pipe()
  let r = @js_async.ReadableStream::from_js(r)
  let start_reading = @async.Cond()
  @async.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      defer w.close()
      async fn write(msg : String) {
        w.write(@utf8.encode(msg))
        log.push("writer: \{msg}")
      }
      write("message1")
      write("message2")
      group.spawn_bg() <| () => {
        @async.sleep(200)
        start_reading.signal()
      }
      // there should be back pressure here
      write("message3")
      @async.sleep(200)
      write("message4")
    }
    group.spawn_bg() <| () => {
      defer r.close()
      start_reading.wait()
      while r.read() is Some(data) {
        log.push("reader: \{@utf8.decode(data)}")
      }
    }
  }
  json_inspect(log, content=[
    "writer: message1", "writer: message2", "reader: message1", "writer: message3",
    "reader: message2", "reader: message3", "writer: message4", "reader: message4",
  ])
}

///|
async test "ReadableStream read cancelled" {
  let (r, w) = @js_async.JsReadableStream::new_pipe()
  let r = @js_async.ReadableStream::from_js(r)
  defer w.close()
  defer r.close()
  json_inspect(@async.with_timeout_opt(300, () => r.read()), content=null)
  w.write(b"message")
  json_inspect(@async.with_timeout_opt(300, () => r.read()), content=[
    ["message"],
  ])
}

///|
async test "ReadableStream write cancelled" {
  let msgs = []
  let (r, w) = @js_async.JsReadableStream::new_pipe()
  let r = @js_async.ReadableStream::from_js(r)
  defer w.close()
  defer r.close()
  w.write(b"message1")
  w.write(b"message2")
  json_inspect(
    @async.with_timeout_opt(300, () => w.write(b"message3")),
    content=null,
  )
  for _ in 0..<2 {
    msgs.push(r.read())
  }
  @async.with_task_group() <| group => {
    group.spawn_bg(() => msgs.push(r.read()))
    json_inspect(@async.with_timeout_opt(300, () => w.write(b"message4")), content=[
      null,
    ])
  }
  json_inspect(msgs, content=[["message1"], ["message2"], ["message4"]])
}

///|
extern "js" fn failing_readable_stream() -> @js_async.JsReadableStream =
  #| () => new ReadableStream({
  #|   start(controller) {
  #|     controller.error(new TypeError("expected stream failure"))
  #|   },
  #| })

///|
async test "ReadableStream propagates JS stream errors" {
  let r = @js_async.ReadableStream::from_js(failing_readable_stream())
  let err = @test.expect_error_async(() => r.read())
  debug_inspect(
    err,
    content=(
      #|<moonbitlang/core/async/js_async.JsError.JsError: ...>
    ),
  )
  // Cancelling an already errored JS ReadableStream returns a rejected promise.
  // ReadableStream::close must observe that rejection instead of leaking an
  // unhandled rejection to the JavaScript host.
  r.close()
  @async.pause()
}
