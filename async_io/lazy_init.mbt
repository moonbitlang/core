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
priv enum LazyValueState[X] {
  Uninitialized
  Running(@coroutine.Coroutine)
  Done(X)
  Fail(Error)
}

///|
/// A lazily initialized value that requires async operation to compute.
/// The async initialization process will start as soon as the result is requested.
/// the result will be cached, so the initialization process will run only once.
/// If no one is waiting for the result anymore before initialization completes,
/// the initialization process will be cancelled automatically.
struct Lazy[X] {
  worker : async () -> X
  waiters : @set.Set[@coroutine.Coroutine]
  mut state : LazyValueState[X]
  loc : SourceLoc
}

///|
/// Wait for the result of a lazily initialized value.
///
/// If the initialization of the value has not yet started,
/// it will be started automatically.
///
/// If the initialization of the value has already completed,
/// the cached result will be returned automatically.
pub async fn[X] Lazy::wait(self : Lazy[X]) -> X {
  match self.state {
    Done(result) => return result
    Fail(err) => raise err
    Running(_) => ()
    Uninitialized => {
      let coro = @coroutine.spawn(loc=self.loc, () => {
        try @coroutine.handle_cancellation(self.worker) catch {
          err => self.state = Fail(err)
        } noraise {
          None => self.state = Uninitialized
          Some(ret) => self.state = Done(ret)
        }
        for waiter in self.waiters {
          waiter.wake()
        }
      })
      self.state = Running(coro)
    }
  }
  let curr_coro = @coroutine.current_coroutine()
  self.waiters.add(curr_coro)
  defer {
    self.waiters.remove(curr_coro)
    if self.waiters.is_empty() && self.state is Running(coro) {
      coro.cancel()
    }
  }
  @coroutine.suspend()
  match self.state {
    Done(result) => result
    Fail(err) => raise err
    Running(_) | Uninitialized => abort("@async_io.Lazy::wait")
  }
}

///|
/// Create a new lazily initialized value by passing an async initialization function.
/// The function `f` will be started in the background automatically
/// when someone request for the result of the lazy value.
///
/// If all waiters are cancelled before `f` completes,
/// `f` will be cancelled automatically.
/// After `f` is cancelled, calling `.wait()` on the lazy value will start `f` again.
///
/// If `f` completes normally or due to an error,
/// the result will be cached, and subsequent `.wait()` on the lazy value
/// always complete immediately.
#as_free_fn(lazy_init, deprecated="use `@async_io.Lazy(..)` instead")
#alias(new, deprecated)
#callsite(autofill(loc))
pub fn[X] Lazy::Lazy(f : async () -> X, loc~ : SourceLoc) -> Lazy[X] {
  { worker: f, waiters: Set([]), state: Uninitialized, loc, }
}
