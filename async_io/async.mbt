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
/// The operating system that the program is currently running on.
/// For Wasm backend, the actual operating system can only be known at runtime,
/// because the same Wasm binary may be run on different operating systems,
/// hence `platform` is not a compile-time constant.
/// Program supporting Wasm backend should always use `platform`
/// instead of `#cfg` to detect current operating system.
///
/// Currently supported operating systems: `Linux`, `MacOS`, `Windows`.
#cfg(any(target="native", target="wasm"))
pub using @event_loop {platform}

///|
/// Pause current task and give other tasks chance to execute.
/// When performing long running pure computation (i.e. no IO involved),
/// `pause` can be used to avoid starving other tasks.
pub using @coroutine {pause}

///|
/// Returns `true` if current task is being cancelled.
/// In this case, all work should be stopped except cleanup jobs.
/// Usually there is no need to check for cancellation manually,
/// the cancellation error will automatically get things done.
/// However, some patterns, such as writing catch all error handler
/// inside loop body, may result in infinite loop on cancellation.
/// In this case, `is_being_cancelled` can be used to avoid dead loop.
pub using @coroutine {is_being_cancelled}

///|
#deprecated("`catch` can no longer capture cancellation, and cancellation is no longer represented as an error, so `is_cancellation_error` is now meaningless. Use `with_cancellation_handler` or `is_being_cancelled` instead.")
pub fn is_cancellation_error(_ : Error) -> Bool {
  false
}

///|
/// `handle_cancellation(f)` runs the asynchronous function `f`.
/// The result of `handle_cancellation(f)` is:
///
/// - `Some(result)`, if `f` returns `result`
/// - `None`, if `f` is cancelled normally
/// - `raise err`, if `f` raises `err`
///
/// `handle_cancellation` can be used to react to cancellation,
/// but it cannot be used to revert cancellation.
/// When `handle_cancellation` returns `None`, subsequent unprotected `async` operations
/// will still get cancelled immediately.
/// To truly protect a piece of code from cancellation, use `protect_from_cancel` instead.
pub using @coroutine {handle_cancellation}

///|
/// `with_cancellation_handler(f, handler~)` runs the asynchronous function `f`.
/// If `f` is cancelled and does not produce a result, `handler` will be invoked.
/// If `f` succeed or fail with a fatal error, the result of `f` will be returned as-is.
#deprecated("use `handle_cancellation` instead")
pub async fn[X] with_cancellation_handler(
  f : async () -> X,
  handler~ : async () -> Unit,
) -> X {
  match handle_cancellation(f) {
    None => {
      handler()
      @coroutine.raise_cancellation_signal()
    }
    Some(ret) => ret
  }
}

///|
/// Default error raised by `@async_io.with_timeout` when timeout expires
pub suberror TimeoutError derive(@debug.Debug, @json.ToJson)

///|
/// `with_timeout(timeout, f)` run the async function `f`.
///
/// - If `f` return `value` before `timeout`,
///   `with_timeout` will return `value` immediately.
///
/// - If `f` fail before `timeout`, `with_timeout` will fail immediately.
///
/// - If `f` is still running after `timeout` milliseconds,
///   `with_timeout` will fail with `TimeoutError`,
///   or the value of `error`, if explicitly specified.
///
/// - If the whole `with_timeout` call is cancelled before `f` completes,
///   `f` will be cancelled immediately
///
/// Note that `with_timeout` will succeed as long as `f` completes,
/// and the result of `f` is never silently discarded.
pub async fn[X] with_timeout(
  time : Int32,
  f : async () -> X,
  error~ : Error = TimeoutError,
) -> X {
  match with_timeout_opt(time, f) {
    Some(result) => result
    None => raise error
  }
}

///|
/// `with_timeout_opt(timeout, f)` run the async function `f`.
///
/// - If `f` return `value` before `timeout`,
///   `with_timeout_opt` will return `Some(value)` immediately.
///
/// - If `f` fail before `timeout`, `with_timeout_opt` will fail immediately.
///
/// - If `f` is still running after `timeout` milliseconds,
///   `with_timeout_opt` will return `None` immediately, and `f` will be cancelled.
///
/// - If the whole `with_timeout_opt` call is cancelled before `f` completes,
///   `f` will be cancelled immediately
///
/// Note that `with_timeout_opt` will succeed as long as `f` completes,
/// and the result of `f` is never silently discarded.
pub async fn[X] with_timeout_opt(time : Int32, f : async () -> X) -> X? {
  let mut result = None
  let status = @coroutine.handle_cancellation <| () => {
    with_task_group() <| group => {
      group.spawn_bg(no_wait=true) <| () => {
        sleep(time)
        group.return_immediately()
      }
      result = Some(f())
    }
  }
  match result {
    Some(_) => result
    None if status is Some(_) => None
    None => @coroutine.raise_cancellation_signal()
  }
}

///|
/// `protect_from_cancel(f)` executes `f` and protect `f` from cancellation.
/// If current task is cancelled while running `protect_from_cancel(f)`,
/// `f` will be protected from the cancellation and still run to finish.
/// Things waiting for current task, such as the task group,
/// will also wait until `f` finish.
///
/// The program will resume normally after `f` returns,
/// even if current task is cancelled.
/// The task will remain in cancelled state, though.
/// So the next unprotected async operation will get cancelled immediately.
///
/// This function should be use with extra care and only when absolutely necessary,
/// because it will break other abstraction such as `with_timeout`.
/// A common scenario is avoiding corrupted state due to partial write to file etc.
pub using @coroutine {protect_from_cancel}

///|
/// Get current time, measured in milliseconds.
/// `now` uses the same clock as timers in `moonbitlang/async`.
///
/// `now` can be used to measure elapsed time, such as benchmarking,
/// but the meaning of the absolute time value returned by `now`
/// is undefined, and should not be depended on.
pub using @event_loop {now}

///|
/// When `moonbitlang/async` detects a a deadlock situation
/// (i.e. all remaining tasks are mutually blocked on each other,
/// no one is waiting for any timer or IO),
/// the runtime automatically panic and report error to `stderr`
/// to avoid stucking forever.
///
/// This behavior can be altered by `set_deadlock_handler`.
/// The handler will receive the source location of remaining tasks as input,
/// the user may choose to output log via a file or other means and panic,
/// or simply ignore the deadlock situation by setting a custom callback.
///
/// If the deadlock handler return normally without aborting the program,
/// the runtime will ignore the deadlock and continue execution,
/// disabling deadlock detection in effect.
/// Note that the program will likely hang forever in this case.
#cfg(any(target="native", target="wasm"))
pub using @event_loop {set_deadlock_handler}

///|
pub using @aqueue {type Queue}

///|
pub using @semaphore {type Semaphore}

///|
pub using @cond_var {type Cond}

///|
/// `RetryMethod` describes different retry strategies used by various APIs:
///
/// - `Immediate`: failed task will immediately be restarted.
///
/// - `FixedDelay(t)`,
///   failed task will be restarted after sleeping for `t` milliseconds
///
/// - `ExponentialDelay(initial~, factor~, maximum~)`:
///   failed task will be restarted with an exponentially growing delay.
///   The initial delay is `initial`, and after every failure,
///   the delay will be multiplied by `factor`, but will never exceed `maximum`.
pub(all) enum RetryMethod {
  Immediate
  FixedDelay(Int32)
  ExponentialDelay(initial~ : Int32, factor~ : Double, maximum~ : Int32)
}

///|
/// `retry(strategy, f)` will keep retrying some async operation until success.
/// If `f` returns `value` normally, `retry` will immediately return `value`.
/// If `f` fails with error, `retry` will restart `f` again.
/// The restart strategy is determined by `strategy`,
/// see the `RetryMethod` type for more details.
///
/// If current task is cancelled, `retry` will be cancelled too.
///
/// By default, the number of retry attempt is unbounded.
/// However, if `max_retry` is set,
/// the number of retry attempts will not exceed the value of `max_retry`.
/// If retry attempts reaches limit, `retry` will raise the error from `f`'s last attempt.
///
/// If `fatal_error` is present, and `f` raises an error `err` such that
/// `fatal_error(err)` is `true`, `retry` will fail immediately with `err`.
#alias(retry, visibility="pub")
// the long name here is used to avoid name clash with
// labelled argument `retry` of `spawn_loop`.
async fn[X] moonbitlang_async_retry(
  strategy : RetryMethod,
  max_retry? : Int32,
  fatal_error? : (Error) -> Bool,
  f : async () -> X,
) -> X {
  match strategy {
    Immediate =>
      for i = 0; ; i = i + 1 {
        try f() catch {
          err if fatal_error is Some(f) && f(err) => raise err
          err if @coroutine.is_being_cancelled() => raise err
          err if max_retry is Some(max) && i >= max => raise err
          _ => ()
        } noraise {
          result => return result
        }
      }
    FixedDelay(t) =>
      for i = 0; ; i = i + 1 {
        try f() catch {
          err if fatal_error is Some(f) && f(err) => raise err
          err if @coroutine.is_being_cancelled() => raise err
          err if max_retry is Some(max) && i >= max => raise err
          _ => sleep(t)
        } noraise {
          result => return result
        }
      }
    ExponentialDelay(initial~, factor~, maximum~) =>
      for i = 0, timeout = initial; ; i = i + 1 {
        try f() catch {
          err if fatal_error is Some(f) && f(err) => raise err
          err if @coroutine.is_being_cancelled() => raise err
          err if max_retry is Some(max) && i >= max => raise err
          _ => {
            sleep(timeout)
            continue i + 1,
              @cmp.minimum(maximum, (timeout.to_double() * factor).to_int())
          }
        } noraise {
          result => return result
        }
      }
  }
}

///|
/// `all(tasks, max_concurrent?)` waits for all tasks to complete and returns their results.
///
/// - All tasks are spawned and executed (optionally with `max_concurrent` limit).
/// - If all tasks succeed, `all` returns an array of results in the same order as `tasks`.
/// - If any task fails, `all` fails with that error and other running tasks are cancelled.
///
/// The `max_concurrent` parameter limits the number of tasks that can run concurrently.
/// If not specified, all tasks run at once.
pub async fn[X] all(
  tasks : ArrayView[async () -> X],
  max_concurrent? : Int32,
) -> Array[X] {
  let semaphore = if max_concurrent is Some(p) {
    Some(Semaphore(p))
  } else {
    None
  }
  let results = Array::make(tasks.length(), None)
  with_task_group() <| tg => {
    for i, task in tasks {
      if semaphore is Some(sem) {
        sem.acquire()
      }
      tg.spawn_bg() <| () => {
        // We rely on the assumption that the task spawned will 100% executed
        // even if it is cancelled, so that we can release the semaphore properly.
        defer (if semaphore is Some(sem) { sem.release() })
        let result = task()
        results[i] = Some(result)
      }
    }
  }
  results.map(r => r.unwrap())
}

///|
/// `any(tasks, max_concurrent?, allow_failure?)` waits for the first task to complete successfully.
///
/// - All tasks are spawned and executed (optionally with `max_concurrent` limit).
/// - When the first task completes successfully, `any` returns its result immediately
///   and all other running tasks are cancelled.
/// - If `allow_failure` is `false` (default), `any` fails as soon as any task fails.
/// - If `allow_failure` is `true`, failing tasks are ignored and `any` waits for the first success.
/// - If all tasks fail, `any` fails with the error from a random task.
///
/// The `max_concurrent` parameter limits the number of tasks that can run concurrently.
/// If not specified, all tasks run at once.
///
/// `any` requires at least one task and will fail if the array is empty.
#callsite(autofill(loc))
#warnings("-fragile_catch_all")
pub async fn[X] any(
  tasks : ArrayView[async () -> X],
  max_concurrent? : Int32,
  allow_failure~ : Bool = false,
  loc~ : SourceLoc,
) -> X {
  let semaphore = if max_concurrent is Some(p) {
    Some(Semaphore(p))
  } else {
    None
  }
  if tasks.is_empty() {
    fail("no tasks provided to any()", loc~)
  }
  let mut result = None
  let mut last_err = None
  with_task_group() <| tg => {
    for task in tasks {
      if semaphore is Some(sem) {
        sem.acquire()
      }
      tg.spawn_bg(allow_failure~) <| () => {
        // We rely on the assumption that the task spawned will 100% executed
        // even if it is cancelled, so that we can release the semaphore properly.
        defer (if semaphore is Some(sem) { sem.release() })
        result = Some(task()) catch {
          e => {
            last_err = Some(e)
            raise e
          }
        }
        tg.return_immediately()
      }
    }
  }
  if result is Some(result) {
    result
  } else {
    raise last_err.unwrap()
  }
}
