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
/// `sleep` will wait for the given time (in milliseconds) before returning.
/// Other task can still run while current task is sleeping.
/// If current task is cancelled, `sleep` will return early with an error.
pub using @event_loop {sleep}

///|
priv enum TimerState {
  // The timer is active, and there is some one waiting for it
  Running(@event_loop.Timer)
  // The timer is active, but no one is waiting for it.
  // So we do not keep track of the timer in the event loop to save resource
  Detached
  // The timer has terminated normally
  Terminated
  // The timer is manually cancelled
  Cancelled(Error)
}

///|
/// A timer that expires after a fixed duration
/// with support for multiple waiters and refreshing.
/// The timer will expire only once.
///
/// The timer object itself has no side effect.
/// The only way to observe the existence of a timer is by waiting for it.
/// So if no one is waiting for a timer,
/// the timer will not block program termination even if it is still active.
pub struct Timer {
  duration : Int32
  priv mut state : TimerState
  priv mut expire_time : Int64
  // invariant: `waiters` is non-empty iff `state` is `Running`
  priv waiters : @set.Set[@coroutine.Coroutine]
}

///|
/// Create a new timer that expires after `duration` milliseconds.
/// The timer will start immediately, and expire after the duration elapsed.
#alias(new, deprecated)
pub fn Timer::Timer(duration : Int32) -> Timer {
  let expire_time = now() + duration.to_int64()
  { state: Detached, duration, expire_time, waiters: Set([]), }
}

///|
fn Timer::wake(timer : Timer, target_state : TimerState) -> Unit {
  for coro in timer.waiters {
    coro.wake()
  }
  match timer.state {
    Running(t) => t.cancel()
    Detached | Terminated => ()
    Cancelled(_) => return
  }
  timer.state = target_state
}

///|
/// When waiting for a timer, if the timer is explicitly cancelled,
/// the waiter will receive this error.
pub suberror TimerCancelled derive(@debug.Debug, @json.ToJson)

///|
/// Manually cancel a timer.
/// All waiters on the timer will fail immediately with `err`
/// (`TimerCancelled` by default).
/// All subsequent waiters will also fail with `err` immediately.
pub fn Timer::cancel(timer : Timer, err~ : Error = TimerCancelled) -> Unit {
  timer.wake(Cancelled(err))
}

///|
/// Wait for the expiration of a timer.
/// If the timer has already terminated, `wait` will return immediately.
/// If the timer has already been cancelled,
/// or if the timer is cancelled during the wait,
/// `wait` will fail immediately.
pub async fn Timer::wait(timer : Timer) -> Unit {
  match timer.state {
    Running(_) => ()
    Detached => {
      let duration = timer.expire_time - now()
      guard duration > 0 else { return }
      timer.state = Running(
        @event_loop.Timer::new(duration.to_int()) <| () => {
          timer.wake(Terminated)
        },
      )
    }
    Terminated => return
    Cancelled(err) => raise err
  }

  let coro = @coroutine.current_coroutine()
  timer.waiters.add(coro)
  defer timer.waiters.remove(coro)
  @coroutine.suspend()
  if timer.state is Cancelled(err) {
    raise err
  }
}

///|
/// Refresh a timer.
/// If the timer has already terminated, it is restarted immediately,
/// and will be triggered again after the timer expires.
/// If the timer is currently active,
/// its expiration time will be delayed to current time + duration of the timer.
/// If the timer has been cancelled, `refresh` has no effect.
pub fn Timer::refresh(timer : Timer) -> Unit {
  match timer.state {
    Running(t) => t.cancel()
    Detached | Terminated => ()
    Cancelled(_) => return
  }
  timer.expire_time = now() + timer.duration.to_int64()
  if timer.waiters.is_empty() {
    timer.state = Detached
  } else {
    timer.state = Running(
      @event_loop.Timer::new(timer.duration, () => timer.wake(Terminated)),
    )
  }
}
