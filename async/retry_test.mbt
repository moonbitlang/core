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
async test "retry immediate" {
  let log = StringBuilder()
  let mut i = 0
  @async.retry(Immediate) <| () => {
    log <+ "tick \{i}\n"
    i = i + 1
    if i < 3 {
      raise Err
    }
  }
  inspect(
    log.to_string(),
    content=(
      #|tick 0
      #|tick 1
      #|tick 2
      #|
    ),
  )
}

///|
async test "retry fixed" {
  let log = []
  let start = @async.now()
  fn tick() {
    (@async.now() - start + 50).to_int() / 200
  }
  let mut i = 0
  @async.retry(FixedDelay(200)) <| () => {
    log.push("loop \{i} at tick #\{tick()}")
    i = i + 1
    if i < 3 {
      raise Err
    }
  }
  log.push("retry completed at tick #\{tick()}")
  json_inspect(log, content=[
    "loop 0 at tick #0", "loop 1 at tick #1", "loop 2 at tick #2", "retry completed at tick #2",
  ])
}

///|
async test "retry exponential" {
  let log = []
  let start = @async.now()
  fn tick() {
    (@async.now() - start + 50).to_int() / 200
  }
  let mut i = 0
  @async.retry(ExponentialDelay(initial=200, factor=2, maximum=600)) <| () => {
    log.push("loop \{i} at tick #\{tick()}")
    i = i + 1
    if i < 4 {
      raise Err
    }
  }
  log.push("retry completed at tick #\{tick()}")
  json_inspect(log, content=[
    "loop 0 at tick #0", "loop 1 at tick #1", "loop 2 at tick #3", "loop 3 at tick #6",
    "retry completed at tick #6",
  ])
}

///|
async test "retry cancelled1" {
  let log = StringBuilder()
  let mut i = 0
  @async.with_timeout(500, () => {
    @async.retry(Immediate) <| () => {
      @async.sleep(200)
      log <+ "loop \{i}\n"
      i = i + 1
      raise Err
    }
  }) catch {
    @async.TimeoutError => ()
    err => raise err
  }
  inspect(
    log.to_string(),
    content=(
      #|loop 0
      #|loop 1
      #|
    ),
  )
}

///|
async test "retry cancelled2" {
  let log = StringBuilder()
  let mut i = 0
  @async.with_timeout(500, () => {
    @async.retry(FixedDelay(200)) <| () => {
      log <+ "loop \{i}\n"
      i = i + 1
      raise Err
    }
  }) catch {
    @async.TimeoutError => ()
    err => raise err
  }
  inspect(
    log.to_string(),
    content=(
      #|loop 0
      #|loop 1
      #|loop 2
      #|
    ),
  )
}

///|
async test "retry fatal_error" {
  let log = StringBuilder()
  fn fatal_error(err) {
    !(err is @async.TimeoutError)
  }

  let mut i = 0
  async fn worker() {
    log <+ "worker run #\{i}\n"
    i = i + 1
    if i < 3 {
      @async.with_timeout(100, () => @async.sleep(1000))
    } else {
      raise Failure::Failure("fatal error")
    }
  }

  debug_inspect(
    @test.expect_error_async <| () => {
      @async.retry(Immediate, fatal_error~, worker)
    },
    content=(
      #|Failure("fatal error")
    ),
  )
  inspect(
    log.to_string(),
    content=(
      #|worker run #0
      #|worker run #1
      #|worker run #2
      #|
    ),
  )
}
