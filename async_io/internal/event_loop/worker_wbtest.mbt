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
extern "C" fn Job::sleep(time : Int32) -> Job = "moonbit_rt_make_sleep_job"

///|
#cfg(target="wasm")
#unsafe_skip_stub_check
fn JobHandle::sleep(time : Int32) -> JobHandle = "moonbitlang/async" "thread_pool/make_sleep_job"

///|
#cfg(target="wasm")
fn Job::sleep(time : Int32) -> Job {
  Job(JobHandle::sleep(time))
}

///|
#cfg(any(target="native", target="wasm"))
async fn perform_sleep_job(t : Int32) -> Unit {
  let job = Job::sleep(t)
  defer job.free()
  perform_job_in_worker(job, context="") |> ignore
}

///|
#cfg(target="js")
async fn perform_sleep_job(t : Int32) -> Unit {
  @async_io.protect_from_cancel(() => @async_io.sleep(t))
}

///|
async test "worker basic" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      for _ in 0..<3 {
        @async_io.sleep(400)
        log <+ "tick\n"
      }
    }
    perform_sleep_job(1000)
    log <+ "done\n"
  }
  inspect(
    log.to_string(),
    content=(
      #|tick
      #|tick
      #|done
      #|tick
      #|
    ),
  )
}

///|
async test "worker multiple" {
  let start = @async_io.now()
  @async_io.with_task_group() <| group => {
    for _ in 0..<3 {
      group.spawn_bg(() => perform_sleep_job(200))
    }
  }
  let t = (@async_io.now() - start + 50) / 200
  inspect(t, content="1")
}

///|
async test "worker cancel1" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      for _ in 0..<4 {
        @async_io.sleep(200)
        log <+ "tick\n"
      }
    }
    let task = root.spawn(() => {
      match @async_io.handle_cancellation(() => perform_sleep_job(1000)) {
        None => log.write_string("sleep cancelled with\n")
        Some(_) => log <+ "done\n"
      }
    })
    @async_io.sleep(500)
    log <+ "trying to cancel\n"
    task.cancel()
  }
  inspect(
    log.to_string(),
    content=(
      #|tick
      #|tick
      #|trying to cancel
      #|tick
      #|tick
      #|done
      #|
    ),
  )
}

///|
async test "worker cancel2" {
  let log = StringBuilder()
  @async_io.with_task_group() <| root => {
    root.spawn_bg() <| () => {
      for _ in 0..<3 {
        @async_io.sleep(400)
        log <+ "tick\n"
      }
    }
    root.spawn_bg(allow_failure=true) <| () => {
      match @async_io.handle_cancellation(() => perform_sleep_job(1000)) {
        None => log.write_string("sleep cancelled\n")
        Some(_) => log <+ "done\n"
      }
    }
    @async_io.sleep(600)
    log <+ "trying to terminate now\n"
    root.return_immediately()
  }
  inspect(
    log.to_string(),
    content=(
      #|tick
      #|trying to terminate now
      #|done
      #|
    ),
  )
}

///|
#cfg(any(target="native", target="wasm"))
test "max worker limit" {
  let time_of_jobs = [0, 0, 0, 0]
  with_event_loop(max_worker_count=2, () => {
    @async_io.with_task_group <| group => {
      for i in 0..<4 {
        group.spawn_bg() <| () => {
          let start = @async_io.now()
          perform_sleep_job(200)
          let t = (@async_io.now() - start).to_int() / 200
          time_of_jobs[i] = t
        }
      }
    }
  })
  @json.json_inspect(time_of_jobs, content=[1, 1, 2, 2])
}

///|
#cfg(any(target="native", target="wasm"))
test "cancel queued job" {
  let log = []
  with_event_loop(max_worker_count=1, () => {
    @async_io.with_task_group <| group => {
      let start = @async_io.now()
      fn tick() {
        (@async_io.now() - start + 50).to_int() / 200
      }
      group.spawn_bg() <| () => {
        log.push("queued job starting at tick #\{tick()}")
        // The job here is not cancellable once it start running.
        // But all jobs are cancellable while they are queued.
        try @async_io.with_timeout(200, () => perform_sleep_job(600)) catch {
          _ => log.push("queued job cancelled at tick #\{tick()}")
        } noraise {
          _ => log.push("queued job completed at tick #\{tick()}")
        }
      }
      log.push("main job starting at tick #\{tick()}")
      perform_sleep_job(400)
      log.push("main job completed at tick #\{tick()}")
    }
  })
  @json.json_inspect(log, content=[
    "main job starting at tick #0", "queued job starting at tick #0", "queued job cancelled at tick #1",
    "main job completed at tick #2",
  ])
}
