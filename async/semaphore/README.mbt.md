# Semaphore (`@moonbitlang/async/semaphore`)

A counting semaphore for limiting concurrency, building mutexes, and
signaling between tasks. A `Semaphore` holds an integer count of
**permits**: `acquire` takes a permit (blocking when none are
available), `release` returns one. That's the entire primitive —
every higher-level pattern (mutex, bounded concurrency, one-shot
signal, count-down latch) is just a different choice of `size`,
`initial_value`, and *who* calls `release`.

Because `moonbitlang/async` is single-threaded and cooperative, you
do **not** need a semaphore to protect ordinary in-memory state —
any code stretch without a suspension point is already atomic.
Reach for `Semaphore` when you need to:

- limit how many tasks run a section of code in parallel,
- serialize access to a *shared async resource* (e.g. a file handle
  or a remote connection that does not support interleaved use),
- park a task until another task signals "you may proceed."

## Table of Contents

- [Quick Start: Mutex](#quick-start-mutex)
- [Bounded Concurrency](#bounded-concurrency)
- [Signaling](#signaling)
  - [One-shot signal](#one-shot-signal)
  - [Count-down latch](#count-down-latch)
- [Non-blocking `try_acquire`](#non-blocking-try_acquire)
- [Fairness](#fairness)
- [Cancellation Safety](#cancellation-safety)
- [Types Reference](#types-reference)
- [Best Practices](#best-practices)

## Quick Start: Mutex

A semaphore with `size = 1` is a mutex. Use it to serialize access
to a critical section.

```moonbit check
///|
async test "mutex serializes access" {
  let mutex = @semaphore.Semaphore(1)
  let log = []
  @async.with_task_group <| group => {
    for i in 0..<3 {
      group.spawn_bg() <| () => {
        mutex.acquire()
        defer mutex.release()
        log.push("task \{i}: enter")
        @async.sleep(50)
        log.push("task \{i}: leave")
      }
    }
  }
  // Every "enter" is followed by the same task's "leave" before
  // any other task enters.
  json_inspect(log, content=[
    "task 0: enter", "task 0: leave", "task 1: enter", "task 1: leave", "task 2: enter",
    "task 2: leave",
  ])
}
```

Two things are worth pointing out:

- **`defer release()`** is the safest idiom — the permit is returned
  even if the body raises or is cancelled. Without `defer`, an
  exception inside the critical section leaks the permit forever.
- The waiters are woken in **FIFO** order, so task 0 (which started
  acquiring first) runs first.

## Bounded Concurrency

A semaphore with `size = N` caps how many tasks may be inside the
section at once. This is the canonical "limit max in-flight jobs"
pattern, used by the `xargs` example to keep at most `--jobs N`
subprocesses running.

```moonbit check
///|
async test "bounded concurrency caps in-flight tasks" {
  let limit = @semaphore.Semaphore(3)
  let mut active = 0
  let mut peak = 0
  @async.with_task_group <| group => {
    for _ in 0..<8 {
      group.spawn_bg() <| () => {
        limit.acquire()
        defer limit.release()
        active = active + 1
        if active > peak {
          peak = active
        }
        @async.sleep(30)
        active = active - 1
      }
    }
  }
  // 8 tasks competed for 3 permits; peak in-flight is exactly 3.
  inspect(peak, content="3")
  // All tasks finished — the counter is back to zero.
  inspect(active, content="0")
}
```

Notice that the read / compare / write on `active` and `peak`
happens with **no suspension point** between `acquire()` and
`@async.sleep`, so
the read-modify-write is atomic without any explicit lock. If you
introduced an `@async.sleep` between `acquire()` and the increment,
the value could change underneath you — that's the only reason you
ever need this kind of sync in single-threaded async code.

## Signaling

When you set `initial_value` below `size`, the semaphore starts with
fewer permits than its capacity. Setting `initial_value = 0` lets
you use the semaphore as a **signal**: one task waits in `acquire()`
until another task calls `release()`.

### One-shot signal

```moonbit check
///|
async test "one-shot signal" {
  // size 1, but starts empty — acquire blocks until release().
  let ready = @semaphore.Semaphore(1, initial_value=0)
  let log = []
  @async.with_task_group <| group => {
    group.spawn_bg() <| () => {
      log.push("waiter: parking")
      ready.acquire()
      log.push("waiter: unblocked")
    }
    group.spawn_bg() <| () => {
      log.push("signaller: setup")
      @async.sleep(50)
      log.push("signaller: release")
      ready.release()
    }
  }
  json_inspect(log, content=[
    "waiter: parking", "signaller: setup", "signaller: release", "waiter: unblocked",
  ])
}
```

> **Caveat:** `release()` wakes **one** waiter. If multiple tasks
> need to react to the same event, use `@async.Cond` (broadcast
> notification) instead.

### Count-down latch

A semaphore of size `N` with `initial_value = 0` is a count-down
latch: each "done" producer calls `release()` once; the consumer
calls `acquire()` `N` times to wait for all of them.

```moonbit check
///|
async test "count-down latch waits for N events" {
  let n = 3
  let done = @semaphore.Semaphore(n, initial_value=0)
  let log = []
  @async.with_task_group <| group => {
    for i in 0..<n {
      group.spawn_bg() <| () => {
        @async.sleep(20 * (i + 1))
        log.push("worker \{i} done")
        done.release()
      }
    }
    for _ in 0..<n {
      done.acquire()
    }
    log.push("all workers reported")
  }
  json_inspect(log, content=[
    "worker 0 done", "worker 1 done", "worker 2 done", "all workers reported",
  ])
}
```

In this pattern the `release` is *not* paired with an `acquire` from
the same task — the workers only `release` (counting up), and the
coordinator only `acquire`s (counting down). That's perfectly fine
as long as the total number of releases never exceeds `size`.

> In most real code, prefer `with_task_group`'s implicit join over a
> count-down latch — the group already waits for every child to
> finish. Reach for a latch only when you want the *coordinator* to
> proceed mid-group, before the children's resources are released.

## Non-blocking `try_acquire`

`try_acquire()` is the synchronous variant — returns `true` if it
took a permit, `false` if none were available. It never suspends,
and it does not require an `async` context.

```moonbit check
///|
test "try_acquire never blocks" {
  let sem = @semaphore.Semaphore(2)
  assert_true(sem.try_acquire()) // 2 -> 1
  assert_true(sem.try_acquire()) // 1 -> 0
  assert_false(sem.try_acquire()) // 0 -> 0 (no permits, returns false)
  sem.release() // 0 -> 1
  assert_true(sem.try_acquire()) // 1 -> 0
}
```

Use `try_acquire` for "opportunistic" patterns — sampling, rate
limiting where it's OK to drop a job, or polling. **Do not** use it
in a busy-loop instead of `acquire()`; let the scheduler do the
waiting for you.

Note that `try_acquire` never break the FIFO fairness of `acquire`.
When there are blocked `acquire` operations on the same semaphore,
`try_acquire` always return `false`.

## Fairness

When multiple tasks are blocked on `acquire()`, the semaphore wakes
them in **FIFO** order — the order they arrived to wait, not the
order they were spawned. The test below pins task 1's wait to start
before task 2's via a sleep:

```moonbit check
///|
async test "waiters are woken FIFO" {
  let sem = @semaphore.Semaphore(1)
  sem.acquire() // main holds the permit
  let log = []
  @async.with_task_group <| group => {
    // Task A starts waiting at ~0 ms.
    group.spawn_bg() <| () => {
      sem.acquire()
      log.push("A acquired")
      sem.release()
    }
    // Task B starts waiting at ~50 ms.
    group.spawn_bg() <| () => {
      @async.sleep(50)
      sem.acquire()
      log.push("B acquired")
      sem.release()
    }
    @async.sleep(100)
    sem.release() // main hands off the permit
  }
  // A queued first, so A wakes first.
  json_inspect(log, content=["A acquired", "B acquired"])
}
```

## Cancellation Safety

`@async.Semaphore::acquire` is **cancellation-safe**.
When `acquire` is cancelled and fail with an error,
it is guaranteed that the cancelled `acquire` operation will not trigger any visible side effect
(i.e. it appears as if the `acquire` operation never happened).

## Types Reference

### `Semaphore`

- `Semaphore::Semaphore(size : Int, initial_value? : Int) -> Self`
  - `size` must be **positive**.
  - `initial_value` defaults to `size` (i.e. fully replenished).
    Must lie in `[0, size]`.
- `async Semaphore::acquire(self) -> Unit` — take a permit; suspends
  if none are available.
- `Semaphore::release(self) -> Unit` — return a permit. **Aborts
  the program** if it would push the count above `size`, so keep
  releases balanced with acquires.
- `Semaphore::try_acquire(self) -> Bool` — non-blocking acquire.
  Returns `true` if a permit was taken, `false` otherwise.

## Best Practices

1. **`defer release()` after `acquire()`.** Pair the two so the
   permit is always returned, even on failure or cancellation.
2. **Don't over-release.** `release()` aborts if the count would
   exceed `size`. The compiler can't enforce balance — your code
   structure has to.
3. **Use `defer` instead of manual cleanup paths.** Multiple exit
   points (early return, exception, cancellation) each need to
   release; `defer` collapses them into one obviously-correct line.
4. **Reach for `@cond_var` if you need broadcast.** A `release()`
   wakes one waiter. If many tasks must react to a single event,
   you want a condition variable.
5. **Don't use a semaphore as a substitute for thinking about
   suspension points.** Single-threaded async code is already atomic
   across straight-line, non-suspending code. The semaphore is for
   *async* mutual exclusion (suspension inside the critical section)
   and for *concurrency limiting* — not for protecting plain reads
   and writes.
