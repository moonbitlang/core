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
async test "all basic" {
  let start = @async_io.now()
  let results = @async_io.all([
    () => {
      @async_io.sleep(400)
      1
    },
    () => {
      @async_io.sleep(200)
      2
    },
    () => 3,
  ])
  let duration = (@async_io.now() - start).to_int()
  json_inspect(results, content=[1, 2, 3])
  inspect((duration + 50) / 200, content="2")
}

///|
async test "all preserves order" {
  let log = []
  let results = @async_io.all([
    () => {
      @async_io.sleep(300)
      log.push("task 0")
      0
    },
    () => {
      @async_io.sleep(100)
      log.push("task 1")
      1
    },
    () => {
      log.push("task 2")
      2
    },
  ])
  json_inspect(log, content=["task 2", "task 1", "task 0"])
  json_inspect(results, content=[0, 1, 2])
}

///|
async test "all with max_concurrent" {
  let log = []
  let result = @async_io.all(
    [
      () => {
        log.push("task #1 started")
        defer log.push("task #1 completed")
        @async_io.sleep(200)
        0
      },
      () => {
        log.push("task #2 started")
        defer log.push("task #2 completed")
        @async_io.sleep(100)
        1
      },
      () => {
        log.push("task #3 started")
        defer log.push("task #3 completed")
        @async_io.sleep(200)
        2
      },
    ],
    max_concurrent=2,
  )
  json_inspect(result, content=[0, 1, 2])
  json_inspect(log, content=[
    "task #1 started", "task #2 started", "task #2 completed", "task #3 started",
    "task #1 completed", "task #3 completed",
  ])
}

///|
async test "all empty" {
  let results : Array[Int32] = @async_io.all([])
  json_inspect(results, content=[])
}

///|
async test "all single task" {
  let result = @async_io.all([() => 42])
  json_inspect(result, content=[42])
}

///|
async test "all failure propagates" {
  let log = []
  let result = @test.expect_error_async <| () => {
    @async_io.all([
      () => {
        @async_io.sleep(100)
        log.push("task #1 completed")
      },
      () => {
        @async_io.sleep(200)
        log.push("task #2 failing")
        raise Failure::Failure("Err")
      },
      () => {
        match @async_io.handle_cancellation(() => @async_io.sleep(300)) {
          None => log.push("task #3 cancelled")
          Some(_) => log.push("task #3 completed")
        }
      },
    ])
  }
  inspect(
    result,
    content=(
      #|Failure(Err)
    ),
  )
  json_inspect(log, content=[
    "task #1 completed", "task #2 failing", "task #3 cancelled",
  ])
}

///|
async test "all cancelled" {
  let log = []
  async fn task(idx : Int32, sleep_time : Int32) -> Int32 {
    match @async_io.handle_cancellation(() => @async_io.sleep(sleep_time)) {
      None => log.push("task #\{idx} cancelled")
      Some(_) => log.push("task #\{idx} completed")
    }
    idx
  }

  let result = @async_io.with_timeout_opt(300, () => {
    @async_io.all([() => task(1, 450), () => task(2, 150)])
  })
  debug_inspect(result, content="None")
  json_inspect(log, content=["task #2 completed", "task #1 cancelled"])
}

///|
async test "any basic" {
  let start = @async_io.now()
  let result = @async_io.any([
    () => {
      @async_io.sleep(600)
      1
    },
    () => {
      @async_io.sleep(200)
      2
    },
    () => {
      @async_io.sleep(400)
      3
    },
  ])
  let duration = (@async_io.now() - start).to_int()
  json_inspect(result, content=2)
  inspect((duration + 50) / 200, content="1")
}

///|
async test "any returns first success" {
  let log = []
  async fn task(idx : Int32, sleep_time : Int32) -> Int32 {
    match @async_io.handle_cancellation(() => @async_io.sleep(sleep_time)) {
      None => {
        log.push("task #\{idx} cancelled")
        @coroutine.check_cancellation()
      }
      Some(_) => log.push("task #\{idx} completed")
    }
    idx
  }

  let result = @async_io.any([
    () => task(1, 600),
    () => task(2, 200),
    () => task(3, 400),
  ])
  json_inspect(result, content=2)
  json_inspect(log, content=[
    "task #2 completed", "task #1 cancelled", "task #3 cancelled",
  ])
}

///|
async test "any failure without allow_failure" {
  let log = []
  let result = @test.expect_error_async <| () => {
    @async_io.any([
      () => {
        match @async_io.handle_cancellation(() => @async_io.sleep(300)) {
          None => log.push("task #1 cancelled")
          Some(_) => log.push("task #1 completed")
        }
      },
      () => {
        @async_io.sleep(150)
        raise Failure::Failure("Err")
      },
    ])
  }
  inspect(
    result,
    content=(
      #|Failure(Err)
    ),
  )
  json_inspect(log, content=["task #1 cancelled"])
}

///|
async test "any with allow_failure" {
  let log = []
  let result = @async_io.any(
    [
      () => {
        @async_io.sleep(300)
        log.push("task #1 failing")
        raise Err
      },
      () => {
        @async_io.sleep(150)
        log.push("task #2 failing")
        raise Failure::Failure("fail")
      },
      () => {
        @async_io.sleep(450)
        log.push("task #3 completed")
        2
      },
    ],
    allow_failure=true,
  )
  json_inspect(log, content=[
    "task #2 failing", "task #1 failing", "task #3 completed",
  ])
  json_inspect(result, content=2)
}

///|
async test "any with allow_failure all fail" {
  let log = []
  let result : Error = @test.expect_error_async <| async fn() -> Unit {
    @async_io.any(
      [
        () => {
          @async_io.sleep(300)
          log.push("task #1 failing")
          raise Err
        },
        () => {
          @async_io.sleep(150)
          log.push("task #2 failing")
          raise Failure::Failure("fail")
        },
      ],
      allow_failure=true,
    )
  }
  json_inspect(log, content=["task #2 failing", "task #1 failing"])
  debug_inspect(result, content="Err")
}

///|
async test "any single task" {
  let result = @async_io.any([() => 42])
  json_inspect(result, content=42)
}

///|
async test "any empty fails" {
  debug_inspect(
    @test.expect_error_async(() => (@async_io.any([]) : Unit)),
    content=(
      #|Failure("async_io/all_any_test.mbt:288:37-288:54@moonbitlang/core FAILED: no tasks provided to any()")
    ),
  )
}

///|
async test "any cancelled" {
  let log = []
  async fn task(idx : Int32, sleep_time : Int32) -> Int32 {
    match @async_io.handle_cancellation(() => @async_io.sleep(sleep_time)) {
      None => log.push("task #\{idx} cancelled")
      Some(_) => log.push("task #\{idx} completed")
    }
    idx
  }

  let result = @async_io.with_timeout_opt(200, () => {
    @async_io.any([() => task(1, 400), () => task(2, 400)])
  })
  debug_inspect(result, content="None")
  json_inspect(log, content=["task #1 cancelled", "task #2 cancelled"])
}
