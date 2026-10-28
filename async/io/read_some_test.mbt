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
async test "read basic" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg(() => writer(log, w))
    while r.read() is Some(chunk) {
      log <+ "received chunk: \{@utf8.decode(chunk)}\n"
    }
  }
  inspect(
    log,
    content=(
      #|writing 4 bytes of data
      #|received chunk: abcd
      #|writing 4 bytes of data
      #|received chunk: efgh
      #|writing 4 bytes of data
      #|received chunk: ijkl
      #|
    ),
  )
}

///|
async fn read_test_writer(log : StringBuilder, w : @io.PipeWrite) -> Unit {
  defer w.close()
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"abcd")
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"efgh")
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"ijkl")
  @async.sleep(20)
  log <+ "writing 4 bytes of data\n"
  w.write(b"mnop")
}

///|
async test "read_at_least fixed minimum" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg(() => read_test_writer(log, w))
    try {
      for ;; {
        let chunk = r.read_at_least(6)
        log <+ "received chunk: \{@utf8.decode(chunk)}\n"
      }
    } catch {
      @io.ReaderClosed => ()
      err => raise err
    }
  }
  inspect(
    log,
    content=(
      #|writing 4 bytes of data
      #|writing 4 bytes of data
      #|received chunk: abcdefgh
      #|writing 4 bytes of data
      #|writing 4 bytes of data
      #|received chunk: ijklmnop
      #|
    ),
  )
}

///|
async test "read_at_least increasing minimum" {
  let log = StringBuilder()
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg(() => read_test_writer(log, w))
    try {
      for min_len = 2; ; min_len = min_len + 2 {
        let chunk = r.read_at_least(min_len)
        log <+ "received chunk: \{@utf8.decode(chunk)}\n"
      }
    } catch {
      @io.ReaderClosed => ()
      err => raise err
    }
  }
  inspect(
    log,
    content=(
      #|writing 4 bytes of data
      #|received chunk: abcd
      #|writing 4 bytes of data
      #|received chunk: efgh
      #|writing 4 bytes of data
      #|writing 4 bytes of data
      #|received chunk: ijklmnop
      #|
    ),
  )
}

///|
async test "read_at_least preserves a short EOF tail" {
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg() <| () => {
      defer w.close()
      w.write(b"abc")
    }
    try r.read_at_least(4) |> ignore catch {
      @io.ReaderClosed => ()
      err => raise err
    } noraise {
      _ => fail("expected ReaderClosed")
    }
    assert_eq(r.read(), Some(b"abc"))
    assert_eq(r.read(), None)
  }
}

///|
async test "peek_at_least preserves and does not consume a short EOF tail" {
  @async.with_task_group() <| root => {
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg() <| () => {
      defer w.close()
      w.write(b"abc")
    }
    try r.peek_at_least(4) |> ignore catch {
      @io.ReaderClosed => ()
      err => raise err
    } noraise {
      _ => fail("expected ReaderClosed")
    }
    guard r.peek() is Some(first) else { fail("missing buffered tail") }
    assert_eq(first, b"abc")
    guard r.peek() is Some(second) else { fail("missing buffered tail") }
    assert_eq(second, b"abc")
    assert_eq(r.read(), Some(b"abc"))
    assert_eq(r.peek(), None)
  }
}

///|
async test "read returned chunks remain stable" {
  @async.with_task_group() <| root => {
    let first_expected = Bytes::make(1024, b'a')
    let second_expected = Bytes::make(1024, b'b')
    let (r, w) = @io.pipe()
    defer r.close()
    root.spawn_bg() <| () => {
      defer w.close()
      w.write(first_expected)
      w.write(second_expected)
    }
    let first = r.read_at_least(1024)
    let second = r.read_at_least(1024)
    assert_eq(first, first_expected)
    assert_eq(second, second_expected)
  }
}
