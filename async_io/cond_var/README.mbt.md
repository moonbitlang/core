# Condition Variable (`@moonbitlang/async/cond_var`)

A condition variable is a **notification primitive**. Tasks call
`wait()` to park themselves; other tasks call `signal()` to wake one
parked task, or `broadcast()` to wake every parked task. Unlike a
`Semaphore`, a `Cond` does **not** count signals — if no task is
parked when you signal, the signal is *lost*. The conventional
mitigation is the predicate-loop idiom described below.

Reach for `Cond` when **N tasks must react to a single event** and
`N` may not be known up front: "config changed, every cache please
reload"; "shutdown requested, every worker pool please drain"; "the
queue went from empty to non-empty, every idle worker please wake."
For point-to-point hand-offs of *values*, prefer `@aqueue.Queue`.
For one-shot one-to-one wakeups or for limiting concurrency, prefer
`@semaphore.Semaphore`.

## Table of Contents

- [The API](#the-api)
- [Signal vs Broadcast](#signal-vs-broadcast)
- [The Lost-Wakeup Trap](#the-lost-wakeup-trap)
- [Fairness](#fairness)
- [Cancellation Safety](#cancellation-safety)
- [Choosing Between `Cond`, `Semaphore`, and `Queue`](#choosing-between-cond-semaphore-and-queue)
- [Types Reference](#types-reference)

## The API

- `@cond_var.Cond()` — construct a new condition variable.
- `async Cond::wait(self) -> Unit` — park the current task; resumes
  on `signal`, `broadcast`, or cancellation.
- `Cond::signal(self) -> Unit` — wake one parked waiter (FIFO).
  No-op if no waiter is parked.
- `Cond::broadcast(self) -> Unit` — wake every parked waiter.
  No-op if no waiter is parked.

`signal` and `broadcast` are synchronous; they never block.

## Signal vs Broadcast

`signal()` wakes one waiter (in FIFO order). `broadcast()` wakes all
of them with a single call.

```moonbit check
///|
async test "broadcast wakes every parked waiter" {
  let cond = @cond_var.Cond()
  let log = []
  @async_io.with_task_group <| group => {
    for i in 0..<3 {
      group.spawn_bg() <| () => {
        cond.wait()
        log.push("waiter \{i}: unblocked")
      }
    }
    @async_io.sleep(50) // ensure all three are parked
    log.push("broadcast()")
    cond.broadcast()
  }
  json_inspect(log, content=[
    "broadcast()", "waiter 0: unblocked", "waiter 1: unblocked", "waiter 2: unblocked",
  ])
}
```

With `signal()`, only one of the three would have woken. The other
two would stay parked — and because `with_task_group` waits for
every child, the test would hang. Use `signal` only when you know
exactly one waiter should be woken (e.g. a producer handing off to
one of several interchangeable consumers).

## The Lost-Wakeup Trap

`signal()` on an empty waiter queue is a **silent no-op**. If a task
signals before any waiter has parked, the signal disappears, and a
late `wait()` will block indefinitely. The test below demonstrates
the hazard by capping the late wait with `with_timeout`:

```moonbit check
///|
async test "signal before wait is lost" {
  let cond = @cond_var.Cond()
  // Signal first, with no waiters — this signal is dropped.
  cond.signal()
  // Now park; the signal we issued above will not save us.
  @test.assert_raise_async <| () => {
    @async_io.with_timeout(100, () => cond.wait())
  }
}
```

This is *not* a bug in `Cond` — it's the defining property of
condition variables, and it is why the predicate-loop idiom (next
section) is mandatory in real use.

## Fairness

When multiple tasks are parked and you call `signal()`, the queue
wakes them in **FIFO** order — the order they called `wait()`.

```moonbit check
///|
async test "signal wakes waiters FIFO" {
  let cond = @cond_var.Cond()
  let log = []
  @async_io.with_task_group <| group => {
    // Task A parks at ~0 ms.
    group.spawn_bg() <| () => {
      cond.wait()
      log.push("A")
    }
    // Task B parks at ~50 ms.
    group.spawn_bg() <| () => {
      @async_io.sleep(50)
      cond.wait()
      log.push("B")
    }
    // Two signals, 50 ms apart.
    @async_io.sleep(100)
    cond.signal()
    @async_io.sleep(50)
    cond.signal()
  }
  json_inspect(log, content=["A", "B"])
}
```

## Cancellation Safety

`@async_io.Cond::wait` is **cancellation-safe**.
When they fail due to cancellation, it is guaranteed that
the cancelled `wait` operation will not trigger any visible side effect
(i.e. it appears as if the `wait` operation never happened).

## Choosing Between `Cond`, `Semaphore`, and `Queue`

| You want… | Use |
|---|---|
| Pass *values* between tasks | `@aqueue.Queue` |
| Limit how many tasks run something | `@semaphore.Semaphore(N)` |
| Wake exactly *one* task on an event | `@semaphore.Semaphore(1, initial_value=0)` (or `Cond.signal` with a predicate) |
| Wake *every* task on an event | **`@cond_var.Cond` with `broadcast()`** |

`Cond` is the lowest-level of the three. If a queue or semaphore
fits, prefer them — they encode the predicate for you, so you can't
forget the loop. Reach for `Cond` when your "predicate" is custom
shared state.

## Types Reference

### `Cond`

- `Cond::Cond() -> Cond` — construct.
- `async Cond::wait(self) -> Unit` — park; resumes on signal,
  broadcast, or cancellation.
- `Cond::signal(self) -> Unit` — wake one FIFO waiter; no-op if
  none are parked.
- `Cond::broadcast(self) -> Unit` — wake every parked waiter;
  no-op if none are parked.
