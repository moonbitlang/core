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
pub using @env_util {platform}

///|
priv struct EventLoop {
  bus : EventBus
  fds : Map[@fd_util.Fd, IoHandle]
  extra : PlatformEventLoopExtra
  /// a special file descriptor used to indicate job completion message from thread pool
  notify_recv : @fd_util.Fd
  max_worker_count : Int32
  mut job_id : Int32
  job_queue : @set.Set[QueuedJob]
  idle_workers : @deque.Deque[Worker]
  running_workers : Map[Int32, Worker]
  jobs : Map[Int32, @coroutine.Coroutine]
  timers : @sorted_set.SortedSet[Timer]
  mut main : @coroutine.Coroutine?
  mut killed_by_signal : Int32?
  mut blocked_tasks : Int32
}

///|
priv struct QueuedJob {
  job_id : Int32
  job : Job
  waiter : @coroutine.Coroutine
}

///|
impl Eq for QueuedJob with fn equal(x, y) {
  x.job_id == y.job_id
}

///|
impl Hash for QueuedJob with fn hash_combine(job, hasher) {
  Hash::hash_combine(job.job_id, hasher)
}

///|
let curr_loop : @ref.Ref[EventLoop?] = Ref(None)

///|
priv struct EventLoopHook {
  init : (() -> Unit raise)?
  exit : (() -> Unit raise)?
}

///|
let hooks : Array[EventLoopHook] = []

///|
/// Register hooks that run on creation/disposal of event loop.
pub fn register_hook(
  init? : () -> Unit raise,
  exit? : () -> Unit raise,
) -> Unit {
  hooks.push({ init, exit, })
}

///|
fn EventLoop::new(max_worker_count~ : Int32) -> EventLoop raise {
  let bus = EventBus::new()
  errdefer bus.destroy()
  let notify_recv = init_thread_pool_ffi(bus)
  if !@fd_util.fd_is_valid(notify_recv) {
    @os_error.check_errno("initialize thread pool")
  }
  let extra = PlatformEventLoopExtra::new()
  {
    bus,
    fds: Map([]),
    extra,
    notify_recv,
    max_worker_count,
    job_id: 0,
    job_queue: Set([]),
    idle_workers: Deque([]),
    running_workers: Map([]),
    jobs: Map([]),
    timers: SortedSet([]),
    main: None,
    killed_by_signal: None,
    blocked_tasks: 0,
  }
}

///|
fn EventLoop::destroy(evloop : EventLoop) -> Unit {
  evloop.bus.destroy()
  destroy_thread_pool()
  evloop.extra.destroy()
}

///|
let external_loop : @ref.Ref[&@external_loop_integration.ExternalEventLoop?] = Ref(
  None,
)

///|
/// Set an external event loop.
/// When an external event loop is set, MoonBit will run its own async runtime in a dedicated thread,
/// and wake the user's custom event loop when new events arrive on MoonBit's event loop.
/// This way, the user can integrate async MoonBit code with a custom event loop,
/// such as GUI event loop provided by the operating system.
pub fn set_external_event_loop(
  extloop : &@external_loop_integration.ExternalEventLoop,
) -> Unit {
  if curr_loop.val is Some(evloop) && evloop.main is Some(_) {
    abort("`set_external_event_loop` called after event loop already started")
  }
  guard external_loop.val is None else {
    abort("An external event loop is already set")
  }
  external_loop.val = Some(extloop)
}

///|
/// Create a new event loop and run `f` within the event loop.
/// The event loop will be automatically disposed after `f` completes or on error.
/// `max_worker_count` determines the internal limit for worker threads in the thread pool.
pub fn with_event_loop(
  f : async () -> Unit,
  max_worker_count~ : Int32 = 1024,
) -> Unit raise {
  guard! curr_loop.val is None
  let evloop = EventLoop::new(max_worker_count~)
  defer evloop.destroy()
  curr_loop.val = Some(evloop)
  defer {
    curr_loop.val = None
  }
  for hook in hooks {
    if hook.init is Some(init) {
      init()
    }
  }
  setup_signal_handler()
  let main = @coroutine.spawn(() => {
    defer evloop.terminate_signal_handler()
    f()
  })
  @coroutine.reschedule()
  evloop.main = Some(main)
  try {
    if external_loop.val is Some(extloop) {
      external_loop.val = None
      defer extloop.terminate()
      evloop.run_with_external_loop(extloop)
    } else {
      evloop.run_forever()
    }
  } catch {
    err => {
      eprintln("fatal runtime error: \{err}")
      panic()
    }
  }
  ignore(main.unwrap())
}

///|
async fn EventLoop::suspend(evloop : EventLoop) -> Unit noraise {
  evloop.blocked_tasks += 1
  defer {
    evloop.blocked_tasks -= 1
  }
  @coroutine.suspend()
}

///|
async fn EventLoop::suspend_check_cancel(
  evloop : EventLoop,
) -> @coroutine.SuspendResult noraise + nocancel {
  evloop.blocked_tasks += 1
  defer {
    evloop.blocked_tasks -= 1
  }
  @coroutine.suspend_check_cancel()
}

///|
/// Get current time since Unix EPOCH in milliseconds.
/// The event loop uses the same timer as `now()` for timers.
#cfg(target="native")
pub fn now() -> Int64 {
  @env.now().reinterpret_as_int64()
}

///|
/// Get current time since Unix EPOCH in milliseconds.
/// The event loop uses the same timer as `now()` for timers.
#cfg(target="wasm")
#unsafe_skip_stub_check
pub fn now() -> Int64 = "moonbitlang/async" "time/get_ms_since_epoch"

///|
fn EventLoop::wait_for_event(self : EventLoop, timeout~ : Int32) -> Int32 raise {
  let n = self.bus.wait(timeout~)
  if n < 0 {
    if @errno_util.get_errno() == @errno_util.operation_aborted {
      // `EINTR`
      return 0
    }
    @os_error.check_errno("runtime internal: poll_wait")
  }
  n
}

///|
fn EventLoop::handle_completed_job(self : Self, job_id : Int32) -> Unit {
  // The thread pool pipe may receive job completion event or signal events.
  // Here we encode signal events by setting the most significant bit to one.
  guard (job_id & (1 << 31)) == 0 else {
    // signal
    if self.main is Some(main) {
      main.cancel()
    }
    self.killed_by_signal = Some(job_id ^ (1 << 31))
  }
  guard self.running_workers.get(job_id) is Some(worker) else { return }
  // Completion message for a job may receive in two cases:
  //
  // - the job indeed completed
  // - the job is being cancelled, and we need to retry cancellation
  //
  // `check_cancellation_retry` check the second case and perform retry automatically.
  // If the completion message is for retry, do not wake the waiter yet.
  if worker.check_cancellation_retry() {
    return
  }

  self.running_workers.remove(job_id)
  match self.job_queue.iter().next() {
    None => {
      worker.enter_idle()
      self.idle_workers.push_back(worker)
    }
    Some(job) => {
      self.running_workers[job.job_id] = worker
      worker.wake(job.job_id, job.job)
      self.job_queue.remove(job)
      job.waiter.wake()
    }
  }
  if self.jobs.get(job_id) is Some(coro) {
    coro.wake()
  }
}

///|
/// Determine if file descriptor leak check should be enabled
pub let check_fd_leak : @ref.Ref[Bool] = Ref(
  @env.get_env_var("MOONBIT_ASYNC_CHECK_FD_LEAK") is Some(_),
)

///|
fn EventLoop::check_fd_leak(self : Self) -> Unit {
  if !self.fds.is_empty() {
    let leaked_handles = [
      for handle in self.fds.values() => @debug.to_string(handle.kind)
    ].join(", ")
    eprintln("file descriptor leak detected: \{leaked_handles}")
    panic()
  }
}

///|
fn EventLoop::cleanup(self : Self) -> Unit raise {
  for hook in hooks {
    if hook.exit is Some(exit) {
      exit()
    }
  }
  for fd, handle in self.fds {
    if handle.read is Waiting(coro) {
      coro.cancel()
    }
    if handle.write is Waiting(coro) {
      coro.cancel()
    }
    @fd_util.close(
      fd,
      kind=handle.kind,
      context="runtime internal: close leaking fd",
    )
  }
  if check_fd_leak.val {
    self.check_fd_leak()
  }
  self.fds.clear()
  for _, coro in self.jobs {
    coro.cancel()
  }
  self.extra.cleanup()
  for worker in self.idle_workers {
    worker.free()
  }
}

///|
fn EventLoop::get_next_timeout(self : Self) -> Int32 {
  if @coroutine.has_immediately_ready_task() {
    0
  } else if !self.timers.is_empty() {
    guard! self.timers.iter().head() is Some(first_timer)
    let timeout = first_timer.expire_time - now()
    @cmp.maximum(0, timeout.to_int())
  } else {
    -1
  }
}

///|
fn EventLoop::handle_timers(self : Self) -> Unit {
  let now = now()
  for timer in self.timers {
    if timer.expire_time <= now {
      (timer.callback)()
    } else {
      break
    }
  }
}

///|
let deadlock_handler : @ref.Ref[(Array[SourceLoc]) -> Unit] = Ref(locs => {
  let locs = locs.map(loc => loc.to_string())
  eprintln(
    "Dead lock detected. Tasks spawned at the following locations are still alive: \{@debug.Repr(locs)}",
  )
  panic()
})

///|
/// Set a custom handler for dead lock condition
pub fn set_deadlock_handler(f : (Array[SourceLoc]) -> Unit) -> Unit {
  deadlock_handler.val = f
}

///|
fn EventLoop::check_dead_lock(_self : Self) -> Unit {
  let all_coros = @coroutine.all_coroutines().iter()
  let all_coros = all_coros.map(coro => coro.loc).collect()
  if all_coros.length() > 0 {
    (deadlock_handler.val)(all_coros)
  }
}

///|
fn EventLoop::run_forever(self : Self) -> Unit raise {
  let mut checked_deadlock = false
  while !@coroutine.all_coroutines().is_empty() {
    let timeout = self.get_next_timeout()
    if timeout < 0 && self.blocked_tasks is 0 && !checked_deadlock {
      // The user may decide to ignore deadlock situation,
      // in this case we only perform the deadlock check once.
      checked_deadlock = true
      self.check_dead_lock()
    }
    let n = self.wait_for_event(timeout~)
    if timeout >= 0 {
      self.handle_timers()
    }
    for i in 0..<n {
      let event = self.bus.get_event(i)
      self.extra.handle_event(self, event)
    }
    @coroutine.reschedule()
  }
  self.cleanup()
}

///|
#cfg(target="native")
fn EventLoop::run_with_external_loop(
  self : Self,
  extloop : &@external_loop_integration.ExternalEventLoop,
) -> Unit raise {
  let waiter = self.bus.spawn_waiter(
    wakeup_callback=extloop.get_wakeup_callback_for_foreign_thread(),
  )
  if waiter.0.is_null() {
    @os_error.check_errno("runtime internal: spawn waiter")
  }
  defer waiter.terminate()
  while !@coroutine.all_coroutines().is_empty() {
    let timeout = match self.get_next_timeout() {
      _..<0 => None
      timeout => Some(timeout)
    }
    extloop.poll(timeout?)
    if !self.timers.is_empty() {
      self.handle_timers()
    }
    let n = waiter.get_events()
    if n > 0 {
      defer waiter.wake()
      for i in 0..<n {
        let event = self.bus.get_event(i)
        self.extra.handle_event(self, event)
      }
    } else if n < 0 {
      @os_error.check_errno("runtime internal: poll_wait")
    }
    @coroutine.reschedule()
  }
  self.cleanup()
}

///|
#cfg(target="wasm")
fn EventLoop::run_with_external_loop(
  _self : Self,
  _extloop : &@external_loop_integration.ExternalEventLoop,
) -> Unit raise {
  raise Failure::Failure(
    "external event loop integration is not supported on Wasm",
  )
}

///|
priv enum CancellationStatus {
  NoWait
  NeedWait
  RetryLater
}

///|
/// Generic function for performing cancellation on an IO operation.
/// `cancel_func` performs the cancellation work under the hood.
/// For Windows IOCP/thread pool operations, the OS/thread pool hold references to user objects.
/// We must wait for the completion of the operation before dropping those user objects,
/// even in case of cancellation.
async fn wait_for_cancellation(
  cancel_func : () -> CancellationStatus raise,
) -> Unit nocancel {
  guard! curr_loop.val is Some(evloop)
  let status = {
    errdefer @coroutine.protect_from_cancel(() => evloop.suspend())
    cancel_func()
  }
  match status {
    NeedWait =>
      // The cancellation operation has succeeded,
      // but the thread pool or OS may need some more time to finish all the cleanup.
      // So wait for the completion of the cleanup process here.
      @coroutine.protect_from_cancel(() => evloop.suspend())
    NoWait =>
      // The cancellation operation has succeeded,
      // and the cancelled operation has already terminated.
      // Return immediately here.
      ()
    RetryLater => {
      // Due to some inherent race condition, the cancellaion attempt did not succeed.
      // Retry again after a small timeout.
      @coroutine.protect_from_cancel(() => sleep(10))
      wait_for_cancellation(cancel_func)
    }
  }
}

///|
async fn EventLoop::wait_for_job(
  evloop : EventLoop,
  job_id : Int32,
  cancellable~ : Bool,
  context~ : String,
) -> Unit {
  evloop.jobs[job_id] = @coroutine.current_coroutine()
  defer evloop.jobs.remove(job_id)
  if cancellable {
    match evloop.suspend_check_cancel() {
      Continue => ()
      Cancelled =>
        // The cancellation error is swallowed here,
        // because in case the operation completed before cancellation,
        // we need to return the result normally to retain cancellation safety
        // and avoid data loss.
        // In case the cancellation succeeded,
        // the underlying operation itself should report cancelled status properly
        // via error code (`EINTR` or `ERROR_OPERATION_ABORTED`)
        wait_for_cancellation(() => {
          evloop.cancel_job_in_worker(job_id, context~)
        })
    }
  } else {
    @coroutine.protect_from_cancel(() => evloop.suspend())
  }
}

///|
async fn perform_job_in_worker(
  job : Job,
  context~ : String,
  cancellable~ : Bool = false,
) -> Int32 {
  @coroutine.check_cancellation()
  guard! curr_loop.val is Some(evloop)
  let job_id = evloop.job_id
  evloop.job_id += 1
  match evloop.idle_workers.pop_front() {
    None if evloop.running_workers.length() >= evloop.max_worker_count => {
      let waiter = @coroutine.current_coroutine()
      let queued_job = { job_id, job, waiter, }
      evloop.job_queue.add(queued_job)
      match @coroutine.suspend_check_cancel() {
        Continue => ()
        Cancelled if evloop.job_queue.contains(queued_job) => {
          evloop.job_queue.remove(queued_job)
          @coroutine.raise_cancellation_signal()
        }
        Cancelled =>
          // If `queued_job` is already removed, the job must have been submitted already,
          // within the same tick as the cancellation request.
          // In this case, swallow the cancellation to avoid problems. 
          ()
      }
    }
    None => {
      let worker = Worker::spawn(job_id, job)
      evloop.running_workers[job_id] = worker
    }
    Some(worker) => {
      evloop.running_workers[job_id] = worker
      worker.wake(job_id, job)
    }
  }
  evloop.wait_for_job(job_id, cancellable~, context~)
  if job.err() is err && err > 0 {
    if @coroutine.is_being_cancelled() && err == @errno_util.operation_aborted {
      @coroutine.raise_cancellation_signal()
    } else {
      raise @os_error.from_errno(err, context~)
    }
  } else {
    job.copy_output()
    job.ret()
  }
}

///|
fn EventLoop::cancel_job_in_worker(
  evloop : EventLoop,
  job_id : Int32,
  context~ : String,
) -> CancellationStatus raise {
  if evloop.running_workers.get(job_id) is Some(worker) {
    worker.cancel(context~)
  } else {
    NoWait
  }
}
