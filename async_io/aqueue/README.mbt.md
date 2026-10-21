# Async Queue (`@moonbitlang/async/aqueue`)

An asynchronous, single-process queue for passing values between tasks
in the same task group. `@aqueue.Queue` is the fundamental primitive
for fan-in / fan-out, producer–consumer pipelines, and applying
backpressure to fast producers.

The queue is **MPMC**: any number of tasks may call `put`, any number
of tasks may call `get`. Because the runtime is single-threaded and
cooperative, all queue state mutations are race-free — no locks
required from your code.

## Table of Contents

- [Quick Start](#quick-start)
- [Queue Kinds](#queue-kinds)
  - [Unbounded](#unbounded)
  - [Blocking(n) — Backpressure](#blockingn--backpressure)
  - [DiscardOldest(n)](#discardoldestn)
  - [DiscardLatest(n)](#discardlatestn)
- [Closing a Queue](#closing-a-queue)
  - [Soft close (drain then end)](#soft-close-drain-then-end)
  - [Hard close (clear and end)](#hard-close-clear-and-end)
  - [Custom close error](#custom-close-error)
- [Non-blocking Operations](#non-blocking-operations)
- [Patterns](#patterns)
  - [Fan-in: many producers, one consumer](#fan-in-many-producers-one-consumer)
  - [Fan-out: one producer, worker pool](#fan-out-one-producer-worker-pool)
  - [Fairness across readers](#fairness-across-readers)
- [Cancellation Safety](#cancellation-safety)
- [Types Reference](#types-reference)
- [Best Practices](#best-practices)

## Quick Start

A producer task pushes values; a consumer task pulls them. The
`with_task_group` boundary makes sure both tasks have finished before
control returns.

```moonbit check
///|
async test "quick start" {
  let log = []
  @async_io.with_task_group <| group => {
    let q : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for _ in 0..<3 {
        let v = q.get()
        log.push("get() => \{v}")
      }
    }
  }
  json_inspect(log, content=[
    "put(0)", "put(1)", "put(2)", "get() => 0", "get() => 1", "get() => 2",
  ])
}
```

A few things worth noticing in the trace:

- `put` on an `Unbounded` queue **never suspends**, so the producer
  runs all three iterations before yielding.
- `get` does suspend when the queue is empty, so only after the
  producer finishes does the consumer wake up and drain the buffer.

This is cooperative scheduling in action: there is no preemption, so
the order of operations is exactly what the code structure implies.

## Queue Kinds

The `kind` argument decides what `put` does when the queue is full.
There are four flavors.

### Unbounded

The queue grows without limit. `put` is effectively synchronous and
never blocks; if the consumer hangs, memory grows unboundedly. Use
this only when you trust the consumer to keep up.

```moonbit check
///|
async test "unbounded never blocks" {
  let q : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
  for i in 0..<1000 {
    q.put(i)
  }
  // All 1000 items now sit in the buffer.
  let first = q.try_get()
  debug_inspect(first, content="Some(0)")
}
```

### Blocking(n) — Backpressure

`Blocking(n)` is the workhorse: the queue holds at most `n` items,
and once it is full, `put` **suspends** until a consumer drains an
item. This applies backpressure automatically.

```moonbit check
///|
async test "blocking creates backpressure" {
  let log = []
  @async_io.with_task_group <| group => {
    let q = @aqueue.Queue(kind=Blocking(1))
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for _ in 0..<3 {
        let x = q.get()
        log.push("get() => \{x}")
        @async_io.sleep(100)
      }
    }
  }
  json_inspect(log, content=[
    "put(0)", "get() => 0", "put(1)", "get() => 1", "put(2)", "get() => 2",
  ])
}
```

The producer is forced to wait for the slow consumer. Setting
capacity to `0` is also valid — it makes the queue a pure
synchronization point (rendezvous channel): every `put` pairs
directly with a `get`.

```moonbit check
///|
async test "blocking with zero capacity is a rendezvous" {
  let log = []
  @async_io.with_task_group <| group => {
    let q = @aqueue.Queue(kind=Blocking(0))
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put(i)
        log.push("put(\{i})")
      }
    }
    group.spawn_bg() <| () => {
      for _ in 0..<3 {
        let x = q.get()
        log.push("get() => \{x}")
        @async_io.sleep(50)
      }
    }
  }
  // Every `get` strictly precedes the matching `put`'s log entry,
  // because the producer cannot record `put(i)` until the buffer
  // (size 0) hands the value off to a waiting reader.
  json_inspect(log, content=[
    "get() => 0", "put(0)", "get() => 1", "put(1)", "get() => 2", "put(2)",
  ])
}
```

### DiscardOldest(n)

When the buffer is full, the **oldest** item is silently dropped to
make room for the new one. `put` never blocks. Useful for "latest
state" channels where stale data is uninteresting.

```moonbit check
///|
async test "discard oldest" {
  let q = @aqueue.Queue(kind=DiscardOldest(2))
  for i in 1..<=3 {
    q.put(i)
  }
  // Item `1` was pushed out by `3`.
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[2, 3])
}
```

`n` can be zero, in this case, data transfer can only happen
when a reader and a writer are both present.

### DiscardLatest(n)

When the buffer is full, the **incoming** item is silently dropped.
`put` never blocks. Useful for sampling or rate limiting.

```moonbit check
///|
async test "discard latest" {
  let q = @aqueue.Queue(kind=DiscardLatest(2))
  for i in 1..<=3 {
    q.put(i)
  }
  // Item `3` was dropped because the buffer was already full.
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[1, 2])
}
```

> **Note:** `try_put` is stricter than `put` — it returns `false` for
> a full `DiscardOldest`/`DiscardLatest` queue rather than performing
> the discard. Use `try_put` when you want to *know* if the queue
> accepted the value.

`n` can be zero, in this case, data transfer can only happen
when a reader and a writer are both present.

## Closing a Queue

`close()` marks the queue as terminated. The exact behavior depends on
which side of the queue you are on and on the `clear` flag.

### Soft close (drain then end)

By default (`clear=false`), already-buffered items can still be
drained by `get` / `try_get`. Once the buffer is empty, subsequent
reads raise `QueueAlreadyClosed`. This makes `close()` a clean
end-of-stream signal.

```moonbit check
///|
async test "soft close drains buffered items" {
  let q = @aqueue.Queue(kind=Unbounded)
  q.put(1)
  q.put(2)
  q.close()
  // Reads still succeed until the buffer is empty.
  debug_inspect(q.get(), content="1")
  debug_inspect(q.get(), content="2")
  inspect(@test.expect_error_async(() => q.get()), content="QueueAlreadyClosed")
}
```

### Hard close (clear and end)

Pass `clear=true` to drop any buffered items immediately. All
subsequent reads raise `QueueAlreadyClosed`.

```moonbit check
///|
async test "hard close discards buffered items" {
  let q = @aqueue.Queue(kind=Unbounded)
  q.put(1)
  q.put(2)
  q.close(clear=true)
  inspect(@test.expect_error_async(() => q.get()), content="QueueAlreadyClosed")
}
```

After close, all writes — buffered or otherwise — fail immediately:

```moonbit check
///|
async test "writes after close fail" {
  let q = @aqueue.Queue(kind=Unbounded)
  q.close()
  debug_inspect(
    @test.expect_error_async(() => q.put(42)),
    content="QueueAlreadyClosed",
  )
  debug_inspect(
    @test.expect_error_async(() => q.try_put(42)),
    content="QueueAlreadyClosed",
  )
}
```

A common pattern is the producer calling `close()` when it is done,
and the consumer looping with `try ... catch { _ => break }`:

```moonbit check
///|
async test "close as end-of-stream signal" {
  let received = []
  @async_io.with_task_group <| group => {
    // Capacity 1 forces the producer to suspend between puts,
    // so the consumer can drain each item before `close()` runs.
    let q = @aqueue.Queue(kind=Blocking(1))
    group.spawn_bg() <| () => {
      for word in ["alpha", "beta", "gamma"] {
        q.put(word)
      }
      q.close()
    }
    while true {
      let v = q.get() catch { _ => break }
      received.push(v)
    }
  }
  json_inspect(received, content=["alpha", "beta", "gamma"])
}
```

If a task is currently suspended inside `put` on a `Blocking` queue
when `close()` is called, that `put` is unblocked with
`QueueAlreadyClosed`:

```moonbit check
///|
async test "blocked put fails when queue is closed" {
  @async_io.with_task_group(root => {
    let q = @aqueue.Queue(kind=Blocking(1))
    q.put(1) // fills the buffer
    root.spawn_bg(() => {
      @async_io.sleep(50)
      q.close()
    })
    // This `put` blocks because the buffer is full, then gets
    // unblocked when `close()` runs.
    debug_inspect(
      @test.expect_error_async(() => q.put(2)),
      content="QueueAlreadyClosed",
    )
  })
}
```

### Custom close error

Closing with a custom `error` lets callers tell *why* the stream
ended (e.g. an upstream failure vs. a normal completion).

```moonbit check
///|
suberror MyDone derive(Debug)

///|
async test "custom close error" {
  let q : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
  q.close(error=MyDone)
  debug_inspect(@test.expect_error_async(() => q.get()), content="MyDone")
}
```

## Non-blocking Operations

`try_get` and `try_put` give you synchronous, non-suspending access to
the queue. They are useful for opportunistic draining, polling, or
inside non-async contexts.

```moonbit check
///|
test "try_get and try_put" {
  let q = @aqueue.Queue(kind=Blocking(2))
  // Empty queue: try_get returns None.
  debug_inspect(q.try_get(), content="None")
  // Two slots: two try_puts succeed, the third does not.
  assert_true(q.try_put(1))
  assert_true(q.try_put(2))
  assert_false(q.try_put(3))
  // Drain.
  debug_inspect(q.try_get(), content="Some(1)")
  debug_inspect(q.try_get(), content="Some(2)")
  debug_inspect(q.try_get(), content="None")
}
```

`try_get`/`try_put` never break the FIFO behavior of blocking `get`/`put`.
When there is one or more blocked `get`/`put` operations waiting,
`try_get`/`try_put` always returns `None`/`false`, even if a value happens to have just arrived.

## Patterns

### Fan-in: many producers, one consumer

Multiple producers can safely `put` into the same queue — items are
interleaved in arrival order. A single consumer drains the merged
stream. Below, two producers feed numbered items into one consumer.

```moonbit check
///|
async test "fan-in merges multiple producers" {
  let received = []
  @async_io.with_task_group <| group => {
    let q : @aqueue.Queue[String] = Queue(kind=Unbounded)
    // Producer A puts items at time 0, 100, 200 ms.
    group.spawn_bg() <| () => {
      for i in 0..<3 {
        q.put("A\{i}")
        @async_io.sleep(100)
      }
    }
    // Producer B puts items at 50, 150, 250 ms.
    group.spawn_bg() <| () => {
      @async_io.sleep(50)
      for i in 0..<3 {
        q.put("B\{i}")
        @async_io.sleep(100)
      }
    }
    // Consumer drains 6 items.
    for _ in 0..<6 {
      received.push(q.get())
    }
  }
  json_inspect(received, content=["A0", "B0", "A1", "B1", "A2", "B2"])
}
```

### Fan-out: one producer, worker pool

One producer feeds items; N worker tasks each call `get` and process
items in parallel. The queue load-balances automatically because
`get` is first-come-first-served.

To signal "no more work" to a worker pool,
simply close the queue with `clear=false` (the default):

```moonbit check
///|
async test "fan-out distributes work to a pool" {
  let work_by_worker : Array[Array[Int32]] = [[], [], []]
  @async_io.with_task_group <| group => {
    let q : @aqueue.Queue[Int32] = Queue(kind=Blocking(1))
    for w in 0..<3 {
      group.spawn_bg(allow_failure=true) <| () => {
        for ;; {
          let item = q.get()
          work_by_worker[w].push(item)
          @async_io.sleep(20) // simulate per-item processing cost
        }
      }
    }
    for i in 0..<9 {
      q.put(i)
    }
    q.close()
  }
  // Every item is processed exactly once, and the union of the
  // workers' logs is the full input range.
  let total = []
  for arr in work_by_worker {
    for x in arr {
      total.push(x)
    }
  }
  total.sort()
  json_inspect(total, content=[0, 1, 2, 3, 4, 5, 6, 7, 8])
}
```

### Fairness across readers

When multiple tasks are blocked on `get`, the queue wakes them in
FIFO order — *the order they arrived to wait*, not the order they
were spawned. The example below uses staggered `sleep` to make the
wait order explicit.

```moonbit check
///|
async test "readers are woken FIFO" {
  let log = []
  @async_io.with_task_group(root => {
    let q : @aqueue.Queue[Int32] = Queue(kind=Unbounded)
    // Reader 1 starts waiting at ~0 ms.
    root.spawn_bg(() => log.push("r1 got \{q.get()}"))
    // Reader 2 starts waiting at ~50 ms.
    root.spawn_bg(() => {
      @async_io.sleep(50)
      log.push("r2 got \{q.get()}")
    })
    // Producer puts two items at 100 ms.
    @async_io.sleep(100)
    q.put(1)
    q.put(2)
  })
  // Reader 1 enqueued first, so it gets `1`; reader 2 gets `2`.
  json_inspect(log, content=["r1 got 1", "r2 got 2"])
}
```

## Cancellation Safety

`@async_io.Queue::get` and `@async_io.Queue::put` are both **cancellation-safe**.
When they fail due to cancellation, it is guaranteed that
the cancelled `get`/`put` operation will not trigger any visible side effect
(i.e. it appears as if the `get`/`put` operation never happened).

## Types Reference

### `Queue[X]`

The queue itself, generic over the element type `X`.

- `Queue::Queue(kind~ : Kind) -> Queue[X]` — construct.
- `async Queue::put(self, X) -> Unit` — push; may suspend if the
  kind is `Blocking` and the buffer is full.
- `async Queue::get(self) -> X` — pop; may suspend if the buffer is
  empty.
- `Queue::try_put(self, X) -> Bool raise` — non-blocking push.
  Returns `false` if the buffer is full (even for discarding kinds).
  Raises `QueueAlreadyClosed` if the queue is closed.
- `Queue::try_get(self) -> X? raise` — non-blocking pop. Returns
  `None` when empty. Raises `QueueAlreadyClosed` once the queue is
  closed and empty.
- `Queue::close(self, error? : Error, clear? : Bool) -> Unit` —
  terminate. `error` defaults to `QueueAlreadyClosed`; `clear`
  defaults to `false`.

### `Kind`

- `Unbounded` — no capacity limit; `put` never blocks.
- `Blocking(n)` — capacity `n`; `put` suspends when full.
- `DiscardOldest(n)` — capacity `n`; `put` evicts the oldest item.
- `DiscardLatest(n)` — capacity `n`; `put` drops the new item.

All bounded kinds permit `n = 0`; the meaning is "no buffer" — pure
rendezvous for `Blocking(0)`, drop-everything for the discard kinds.

### `QueueAlreadyClosed`

Default error raised by reads/writes against a closed queue. You can
substitute a custom error via `close(error=...)`.

## Best Practices

1. **Pick a bounded kind by default.** `Unbounded` is convenient but
   hides backpressure bugs. Reach for `Blocking(n)` first and only
   widen if you have a reason to.
2. **Close the queue when the producer is done.** This converts a
   queue into a finite stream and lets consumers exit cleanly via
   `try ... catch`.
3. **Use the discard kinds for "latest only" telemetry.** Metrics,
   UI state, or sensor readings where stale data is useless are good
   fits.
4. **Don't close a queue you don't own.** Closing is global — it
   affects every other reader and writer.
5. **Prefer `get` over `try_get` inside async code.** `try_get` plus
   a busy-loop is almost always a bug; let the scheduler do the
   waiting for you.
