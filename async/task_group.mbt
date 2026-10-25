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
priv enum TaskGroupState {
  Done
  Fail(Error)
  Cancelled
  Running
}

///|
priv struct GroupDeferBlock(async () -> Unit nocancel)

///|
/// A `TaskGroup` can be used to spawn children tasks that run in parallel.
/// Task groups implements *structured concurrency*:
/// a task group will only return after all its children task terminates.
///
/// Task groups also handles *error propagation*:
/// by default, if any child task raises error,
/// the whole task group will also raise that error,
/// and all other remaining child tasks will be cancelled.
///
/// The type parameter `X` in `TaskGroup[X]` is the result type of the group,
/// see `with_task_group` for more detail.
struct TaskGroup {
  children : @set.Set[@coroutine.Coroutine]
  parent : @coroutine.Coroutine
  mut waiting : Int32
  mut state : TaskGroupState
  group_defer : Array[GroupDeferBlock]
}

///|
fn TaskGroup::spawn_coroutine(
  self : TaskGroup,
  f : async () -> Unit,
  no_wait~ : Bool,
  allow_failure~ : Bool,
  loc~ : SourceLoc,
) -> @coroutine.Coroutine {
  guard self.state is Running || !self.children.is_empty() else {
    abort("trying to spawn from a terminated task group")
  }
  if !no_wait {
    self.waiting += 1
  }
  async fn worker() {
    let coro = @coroutine.current_coroutine()
    defer {
      self.children.remove(coro)
      if !no_wait {
        self.waiting -= 1
        if self.waiting == 0 && self.state is Running {
          for child in self.children {
            child.cancel()
          }
          self.state = Done
        }
      }
      if self.children.is_empty() {
        self.parent.wake()
      }
    }
    f() catch {
      err if allow_failure => raise err
      err => {
        if self.state is Running {
          for child in self.children {
            child.cancel()
          }
          self.state = Fail(err)
        } else {
          self.state = Fail(err)
        }
        raise err
      }
    }
  }

  let coro = @coroutine.spawn(worker, loc~)
  self.children.add(coro)
  if !(self.state is Running) {
    coro.cancel()
  }
  coro
}

///|
/// Spawn a child task in a task group, and run it asynchronously in the background.
///
/// Unless `no_wait` (`false` by default) is `true`,
/// the task group will wait for this task to complete before normal exit.
/// No matter what the value of `no_wait` is,
/// `with_task_group` will only return after all child tasks terminate.
/// The task will be cancelled automatically if it is still running
/// when the task group wishes to terminate,
///
/// Unless `allow_failure` (`false` by default) is `true`,
/// the whole task group will also fail if the spawned task fails, 
/// other tasks in the group will be cancelled in this case.
///
/// Cancelled task (either cancelled by the group or manually cancelled via `Task::cancel`)
/// are not consider failing, although they raise a cancellation error.
/// However, if the task raise some other error during cancellation handling,
/// it will be considered failing.
///
/// If the task group is already cancelled, but `with_task_group` is still running
/// (i.e. there are still other running child task in the group),
/// `spawn_bg` will still succeed, but the child task will be cancelled immediately.
/// In this case, the child task still get a chance to start execution
/// (which means you can rely on `defer` at the start of child task being triggered),
/// but will be in cancelled state from the very beginning
/// (e.g. all async IO operation will be cancelled immediately before starting).
///
/// Calling `spawn_bg` after `with_task_group` completed or inside `group.add_defer` 
/// is not allowed, and will abort the program immediately.
///
/// It is undefined whether the child task will start running immediately
/// before `spawn_bg` returns.
#callsite(autofill(loc))
pub fn TaskGroup::spawn_bg(
  self : TaskGroup,
  f : async () -> Unit,
  no_wait~ : Bool = false,
  allow_failure~ : Bool = false,
  loc~ : SourceLoc,
) -> Unit {
  ignore(self.spawn_coroutine(f, no_wait~, allow_failure~, loc~))
}

///|
/// Spawn a child task in a task group, compute a result asynchronously.
/// A task handle will be returned, the result value of the task can be waited
/// and retrieved using `.wait()`, or cancelled using `.cancel()`.
///
/// Unless `no_wait` (`false` by default) is `true`,
/// the task group will wait for this task to complete before normal exit.
/// No matter what the value of `no_wait` is,
/// `with_task_group` will only return after all child tasks terminate.
/// The task will be cancelled automatically if it is still running
/// when the task group wishes to terminate,
///
/// Unless `allow_failure` (`false` by default) is `true`,
/// Ithe whole task group will also fail if the spawned task fails, 
/// other tasks in the group will be cancelled in this case.
///
/// Cancelled task (either cancelled by the group or manually cancelled via `Task::cancel`)
/// are not consider failing, although they raise a cancellation error.
/// However, if the task raise some other error during cancellation handling,
/// it will be considered failing.
///
/// If the task group is already cancelled, but `with_task_group` is still running
/// (i.e. there are still other running child task in the group),
/// `spawn` will still succeed, but the child task will be cancelled immediately.
/// In this case, the child task still get a chance to start execution
/// (which means you can rely on `defer` at the start of child task being triggered),
/// but will be in cancelled state from the very beginning
/// (e.g. all async IO operation will be cancelled immediately before starting).
///
/// Calling `spawn` after `with_task_group` completed or inside `group.add_defer` 
/// is not allowed, and will abort the program immediately.
///
/// It is undefined whether the child task will start running immediately
/// before `spawn` returns.
#callsite(autofill(loc))
pub fn[X] TaskGroup::spawn(
  self : TaskGroup,
  f : async () -> X,
  no_wait~ : Bool = false,
  allow_failure~ : Bool = false,
  loc~ : SourceLoc,
) -> Task[X] {
  let value = @ref.Ref(None)
  let coro = self.spawn_coroutine(
    () => value.val = Some(f()),
    no_wait~,
    allow_failure~,
    loc~,
  )
  { value, coro, }
}

///|
/// Attach a defer block, represented as a cleanup function, to a task group.
/// The clenaup function will be invoked when the group terminates,
/// so all child task of the group (created via `spawn` or `spawn_bg`)
/// must have terminated when any group defer code is invoked.
/// Calling `spawn` or `spawn_bg` inside group defer is not allowed,
/// and will abort the program immediately.
///
/// Group scoped defer blocks are executed in FILO order, just like normal `defer`.
/// `with_task_group` will only exit after all group defer blocks terminate.
///
/// Group scoped `defer` must be `nocancel`.
/// If cancellable code have to be run anyway, use `protect_from_cancel`.
/// It is highly recommended to add a hard timeout to async defer block in this case,
/// to avoid infinite hanging due to blocked operation.
pub fn TaskGroup::add_defer(
  self : TaskGroup,
  block : async () -> Unit nocancel,
) -> Unit {
  guard self.state is Running else {
    abort("trying to attach defer to a terminated task group")
  }
  self.group_defer.push(block)
}

///|
/// `with_task_group(f)` creates a new task group and run `f` with the new group.
/// `f` itself will be run in a child task of the new group.
///
/// `with_task_group` exits after the whole group terminates,
/// which means all child tasks in the group have terminated, including `f`.
///
/// When:
/// - certain task in the group raises an fatal error,
/// - `return_immediately` is invoked on the group
/// - the whole `with_task_group` call is cancelled
/// `with_task_group` will cancel all remaining children task automatically.
/// `with_task_group` will still wait for all (cancelled) children to complete, though.
#callsite(autofill(loc))
pub async fn with_task_group(
  f : async (TaskGroup) -> Unit,
  loc~ : SourceLoc,
) -> Unit {
  let tg = {
    children: Set([]),
    parent: @coroutine.current_coroutine(),
    waiting: 0,
    state: Running,
    group_defer: [],
  }
  tg.spawn_bg(loc~, () => f(tg))
  match @coroutine.suspend_check_cancel() {
    Continue => ()
    Cancelled => {
      if tg.state is Running {
        tg.state = Cancelled
      }
      if !tg.children.is_empty() {
        for child in tg.children {
          child.cancel()
        }
        protect_from_cancel(() => @coroutine.suspend())
      }
    }
  }
  guard! tg.children.is_empty()
  while tg.group_defer.pop() is Some(defer_block) {
    defer_block() catch {
      err => if tg.state is Done { tg.state = Fail(err) }
    }
  }
  match tg.state {
    Done => ()
    Fail(err) => raise err
    Cancelled => @coroutine.raise_cancellation_signal()
    Running => panic()
  }
}

///|
/// Force a task group to terminate immediately.
/// All child tasks in the group, including potentially the current one,
/// will be cancelled.
pub async fn TaskGroup::return_immediately(self : TaskGroup) -> Unit noraise {
  if self.state is Running {
    self.state = Done
    for child in self.children {
      child.cancel()
    }
  }
  @coroutine.check_cancellation()
}

///|
/// Similar to `spawn_bg`, but the spawn a loop,
/// i.e. the spawned task will be restarted after it terminates.
/// The spawned task can terminate the loop by raising
/// the special error `BreakFromSpawnLoop`,
/// the loop will terminate normally instead of failing in this case.
///
/// If `retry_method` is set, within each loop,
/// the spawned task will be automatically restarted on failure.
/// The restart strategy is determined by the value of `retry_method`.
/// `max_retry` and `fatal_error` will be passed as-is to `retry`.
/// See `retry` and `RetryMethod` for more details.
///
/// The meaning of `no_wait` and `allow_failure` is the same as `spawn_bg`.
pub fn TaskGroup::spawn_loop(
  self : TaskGroup,
  f : async () -> Unit,
  no_wait~ : Bool = false,
  allow_failure~ : Bool = false,
  retry? : RetryMethod,
  max_retry? : Int32,
  fatal_error? : (Error) -> Bool,
) -> Unit {
  self.spawn_bg(no_wait~, allow_failure~) <| () => {
    try {
      match retry {
        None =>
          for ;; {
            f()
          }
        Some(strategy) => {
          let fatal_error = err => {
            err is BreakFromSpawnLoop || (fatal_error is Some(f) && f(err))
          }
          for ;; {
            moonbitlang_async_retry(strategy, f, max_retry?, fatal_error~)
          }
        }
      }
    } catch {
      BreakFromSpawnLoop => ()
      err => raise err
    }
  }
}

///|
/// A special error used to break away from `TaskGroup::spawn_loop`.
pub(all) suberror BreakFromSpawnLoop
