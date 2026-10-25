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
/// `Task[X]` represents a running task with result type `X`,
/// it can be used to wait and retrieve the result value of the task.
struct Task[X] {
  value : @ref.Ref[X?]
  coro : @coroutine.Coroutine
}

///|
/// Special error indicating a waited task is cancelled.
/// Note that this error has nothing to do with cancellation of *current* task.
#alias(TaskCancelled, deprecated)
pub suberror WaitedTaskAlreadyCancelled derive(@debug.Debug, @json.ToJson)

///|
/// Wait for a task and retrieve its result value.
/// If the task fails, `wait` will also fail with the same error.
/// If the target task terminated due to cancellation, `wait` will raise `TaskCancelled`.
pub async fn[X] Task::wait(self : Task[X]) -> X {
  match self.coro.wait() {
    Continue => self.value.val.unwrap()
    Cancelled => raise WaitedTaskAlreadyCancelled
  }
}

///|
/// Try to obtain the result of the task.
/// If the task already terminated, its result value will be returned.
/// If the task already failed, `try_wait` will fail immediately.
/// If the task is still running, `try_wait` returns `None`.
/// `try_wait` is a synchoronous function: it never blocks.
pub fn[X] Task::try_wait(self : Task[X]) -> X? raise {
  self.coro.check_error()
  self.value.val
}

///|
/// Cancel a task. Subsequent attempt to wait for the task will receive error.
pub fn[X] Task::cancel(self : Task[X]) -> Unit {
  self.coro.cancel()
}
