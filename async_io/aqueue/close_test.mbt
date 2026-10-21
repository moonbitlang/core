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
async test "put after closed" {
  let q = @async_io.Queue(kind=Unbounded)
  q.close()
  debug_inspect(
    @test.expect_error_async(() => q.put(42)),
    content="QueueAlreadyClosed",
  )
  debug_inspect(
    @test.expect_error_async(() => q.try_put(42)),
    content="QueueAlreadyClosed",
  )
}

///|
async test "get after closed" {
  let q = @async_io.Queue(kind=Unbounded)
  q.put(42)
  q.close()
  debug_inspect(q.get(), content="42")
  debug_inspect(
    @test.expect_error_async(() => q.get()),
    content="QueueAlreadyClosed",
  )
}

///|
async test "try_get after closed" {
  let q = @async_io.Queue(kind=Unbounded)
  q.put(42)
  q.close()
  debug_inspect(q.try_get(), content="Some(42)")
  debug_inspect(
    @test.expect_error_async(() => q.try_get()),
    content="QueueAlreadyClosed",
  )
}

///|
async test "get after hard close" {
  let q = @async_io.Queue(kind=Unbounded)
  q.put(42)
  q.close(clear=true)
  debug_inspect(
    @test.expect_error_async(() => q.get()),
    content="QueueAlreadyClosed",
  )
}

///|
async test "try_get after hard close" {
  let q = @async_io.Queue(kind=Unbounded)
  q.put(42)
  q.close(clear=true)
  debug_inspect(
    @test.expect_error_async(() => q.try_get()),
    content="QueueAlreadyClosed",
  )
}

///|
async test "close with blocking put" {
  let q = @async_io.Queue(kind=Blocking(1))
  q.put(1)
  @async_io.with_task_group() <| group => {
    let start = @async_io.now()
    group.spawn_bg() <| () => {
      @async_io.sleep(300)
      q.close()
    }
    debug_inspect(
      @test.expect_error_async(() => q.put(2)),
      content="QueueAlreadyClosed",
    )
    let now = @async_io.now()
    let duration = (now + 50 - start) / 300
    inspect(duration, content="1")
  }
}

///|
async test "close zero buffered with blocking put" {
  let q = @async_io.Queue(kind=Blocking(0))
  @async_io.with_task_group() <| group => {
    let start = @async_io.now()
    group.spawn_bg() <| () => {
      @async_io.sleep(300)
      q.close()
    }
    debug_inspect(
      @test.expect_error_async(() => q.put(2)),
      content="QueueAlreadyClosed",
    )
    let now = @async_io.now()
    let duration = (now + 50 - start) / 300
    inspect(duration, content="1")
  }
}

///|
async test "close with blocking get" {
  let q : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
  @async_io.with_task_group() <| group => {
    let start = @async_io.now()
    group.spawn_bg() <| () => {
      @async_io.sleep(300)
      q.close()
    }
    debug_inspect(
      @test.expect_error_async(() => q.get()),
      content="QueueAlreadyClosed",
    )
    let now = @async_io.now()
    let duration = (now + 50 - start) / 300
    inspect(duration, content="1")
  }
}

///|
async test "close with completed get" {
  let q : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
  @async_io.with_task_group() <| group => {
    group.spawn_bg() <| () => {
      debug_inspect(
        q.get(),
        content=(
          #|42
        ),
      )
    }
    // let the `get` fire first
    @async_io.pause()
    q.put(42)
    // here the value we just put is already delivered to `get`
    q.close()
    // one of `get` above and `try_get` here should suceed,
    // the value should not get swallowed.
    debug_inspect(
      @test.expect_error_async(() => q.try_get()),
      content=(
        #|QueueAlreadyClosed
      ),
    )
  }
}
