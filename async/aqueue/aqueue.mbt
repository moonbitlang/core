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
/// A blocked reader or writer of a async queue
priv struct Waiter[X] {
  /// For reader, the value is
  ///
  /// - `Some(_)` if the reader already received a value and has been woken
  /// - `None` otherwise
  ///
  /// For writer, the value is
  ///
  /// - `None` if the value provided by this writer is already delivered
  /// - `Some(_)` otherwise
  mut value : X?
  /// `None` indicates that the reader is cancelled
  coro : @coroutine.Coroutine
  /// For intrusive cancellable queue
  mut index : Int32
  mut next : Int32
  mut prev : Int32
}

///|
impl[X] @cancellable_queue.Element for Waiter[X] with fn get_index(self) {
  self.index
}

///|
impl[X] @cancellable_queue.Element for Waiter[X] with fn set_index(self, value) {
  self.index = value
}

///|
impl[X] @cancellable_queue.Element for Waiter[X] with fn get_next(self) {
  self.next
}

///|
impl[X] @cancellable_queue.Element for Waiter[X] with fn set_next(self, value) {
  self.next = value
}

///|
impl[X] @cancellable_queue.Element for Waiter[X] with fn get_prev(self) {
  self.prev
}

///|
impl[X] @cancellable_queue.Element for Waiter[X] with fn set_prev(self, value) {
  self.prev = value
}

///|
extend Waiter with @cancellable_queue.Element::{is_queued}

///|
/// Options for different behavior of `put` in async queue.
/// - `Unbounded`: the queue has unbounded size, so `put` always succeed and never blocks.
///   However, if the reader of the queue hangs silently,
///   elements will accumulate infinitely in the queue, causing memory leak
/// - `Blocking(n)`: the queue can contain at most `n` elements,
///   if the queue is full, `put` will block until some value is consumed.
///   If multiple blocked writers coexist, they will be accepted in a FIFO manner
/// - `DiscardOldest(n)`: the queue can contain at most `n` elements,
///   if the queue is full, the oldest elements will be discarded,
///   so `put` always succeed and never block
/// - `DiscardLatest(n)`: the queue can contain at most `n` elements,
///   if the queue is full, the newest elements, i.e. the argument of `put`,
///   will be silently discarded.
pub(all) enum Kind {
  Unbounded
  Blocking(Int32)
  DiscardOldest(Int32)
  DiscardLatest(Int32)
}

///|
/// An asynchronous queue, where reader can wait for data to arrive
/// in a non-blocking manner.
pub struct Queue[X] {
  kind : Kind
  /// invariant: if `readers` is non-empty, `buffer` must be empty
  priv readers : @cancellable_queue.Queue[Waiter[X]]
  /// invariant: if `writers` is non-empty, `buffer` must be full
  priv writers : @cancellable_queue.Queue[Waiter[X]]
  /// invariant: if `buffer` is non-empty, `readers` must be empty; 
  /// if `buffer` is not full, `writers` must be empty
  priv buffer : @deque.Deque[X]
  /// `Some(err)` if the queue is already closed
  priv mut closed : Error?
}

///|
/// Create an empty queue.
/// The behavior of `put` is determined by the `kind` argument,
/// see the type `@aqueue.Kind` for more details.
#as_free_fn(new, deprecated)
#alias(new, deprecated)
pub fn[X] Queue::Queue(kind~ : Kind) -> Queue[X] {
  match kind {
    Unbounded => ()
    Blocking(n) | DiscardOldest(n) | DiscardLatest(n) =>
      if n < 0 {
        abort("queue size must not be negative")
      }
  }
  { kind, writers: Queue(), readers: Queue(), buffer: Deque([]), closed: None, }
}

///|
/// Put a new element into a queue.
///
/// - if there are readers blocked on this thread,
///   the first reader will be woken to process the data
/// - if there are no readers currently blocking,
///   but the queue still have enough spare space,
///   the new element will be placed in the queue,
///   and `put` will return immediately without suspension
/// - if the queue is already full, the behavior is determined by
///   the `kind` argument provided on queue creation:
///     - `Unbounded`: the queue has unbounded size, so can never be full
///     - `DiscardOldest`: the oldest element in the queue is discarded
///     - `DiscardLatest`: the argument of `put` is silently discarded,
///       and `put` will have not effect
///   
/// Although `put` is an async function,
/// if will not suspend unless the queue is `Blocking` and already full.
/// So for `Unbounded`/`DiscardOldest`/`DiscardLatest`,
/// it is safe to assume that `put` is actually synchronous.
/// For context where async function is not allowed, use `try_put` instead.
///
/// `put` itself never fails. But for `Blocking` queues,
/// `put` may be cancelled before it succeed,
/// in this case `put` will fail with a cancellation error.
/// It is guaranteed that the element will be added to the queue
/// *if and only if* `put` return normally.
///
/// If the queue is already closed, `put` will fail immediately.
/// If the queue is a blocking queue, and is closed while `put` is blocking,
/// `put` will also fail immediately.
pub async fn[X] Queue::put(self : Queue[X], data : X) -> Unit {
  if self.closed is Some(err) {
    raise err
  }
  if !self.try_put(data) {
    match self.kind {
      Unbounded => panic()
      Blocking(_) => {
        let writer = {
          value: Some(data),
          coro: @coroutine.current_coroutine(),
          index: -1,
          prev: -1,
          next: -1,
        }
        self.writers.push(writer)
        match @coroutine.suspend_check_cancel() {
          Continue =>
            if writer.value is Some(_) {
              guard! self.closed is Some(err)
              raise err
            }
          Cancelled if writer.value is None => ()
          Cancelled => {
            if writer.is_queued() {
              // This may happen if the queue is closed while `put` is cancelled.
              // Currently we let cancellation win in this case,
              // but the `writer` would not be in `self.writer` in this case
              self.writers.remove(writer)
            }
            @coroutine.raise_cancellation_signal()
          }
        }
        if self.closed is Some(err) {
          raise err
        }
      }
      DiscardOldest(n) =>
        if n > 0 {
          let _ = self.buffer.pop_front()
          self.buffer.push_back(data)
        }
      DiscardLatest(_) => ()
    }
  }
}

///|
/// Try to put a new element into an async queue.
/// If the queue still have enough room, the element will be added to the queue,
/// and `true` will be returned.
/// If the queue is already full,
/// the element will not be added and `false` will be returned.
/// Note that even for `DiscardOldest` or `DiscardLatest` queues,
/// where `put` never blocks, `try_put` will still return `false` if the queue is full,
/// instead of discarding the oldest/newest element.
///
/// If the queue is already closed, `try_put` will fail with error immediately.
pub fn[X] Queue::try_put(self : Queue[X], data : X) -> Bool raise {
  if self.closed is Some(err) {
    raise err
  }
  if self.readers.pop() is Some(reader) {
    // after waking the reader, it may not start execution immediately.
    // And a lot of things could happen in the middle.
    // So instead of using `self.buffer`,
    // we pass `data` to the woker reader in a point-to-point manner
    // to avoid some edge cases.
    reader.value = Some(data)
    reader.coro.wake()
    true
  } else {
    match self.kind {
      Unbounded => {
        self.buffer.push_back(data)
        true
      }
      Blocking(n) | DiscardOldest(n) | DiscardLatest(n) =>
        if self.buffer.length() < n {
          self.buffer.push_back(data)
          true
        } else {
          false
        }
    }
  }
}

///|
/// Fetch an element from the queue.
/// If the queue is currently empty, `get` will block and wait until data arrive.
/// If there are multiple readers blocked on `get`,
/// new data will be delivered in a first-come-first-serve manner.
///
/// `get` itself never fail, and will wait indefinitely.
/// However, since `get` is a blocking point, the task running `get` may be cancelled,
/// in this case, an cancellation will be raised from `get`.
///
/// If the queue is already closed and there is no buffered elements,
/// `get` will fail immediately.
/// If the queue is closed while `get` is waiting, `get` will also fail immediately.
pub async fn[X] Queue::get(self : Queue[X]) -> X {
  if self.try_get() is Some(data) {
    return data
  }
  let reader = {
    value: None,
    coro: @coroutine.current_coroutine(),
    index: -1,
    next: -1,
    prev: -1,
  }
  self.readers.push(reader)
  match @coroutine.suspend_check_cancel() {
    Continue =>
      if reader.value is Some(value) {
        value
      } else {
        guard! self.closed is Some(err)
        raise err
      }
    Cancelled if reader.value is Some(value) =>
      // This may happen if:
      //
      // - `put` is called, the value is removed from the queue
      //   and assigned to `reader.value`
      // - the task is cancelled after `put`, before `get` is actually woken
      //
      // In this case, if we cancel `get`,
      // the value would be swollen, which is incorrect.
      // It is also difficult to put the value back to the queue
      // while maintaining correct order.
      // So we choose to swallow the cancellation signal here,
      // which is fine because cancellation is level-triggered.
      value
    Cancelled => {
      if reader.is_queued() {
        // This may happen if the queue is closed while `get` is cancelled.
        // Currently we let cancellation win in this case,
        // but the `reader` would not be in `self.readers` in this case
        self.readers.remove(reader)
      }
      @coroutine.raise_cancellation_signal()
    }
  }
}

///|
/// Try to fetch an element from the queue without blocking.
/// If no element is in the queue at the moment, `None` is returned.
///
/// If the queue is already closed and there is no buffered elements,
/// `try_get` will fail immediately.
pub fn[X] Queue::try_get(self : Queue[X]) -> X? raise {
  let data = self.buffer.pop_front()
  if self.writers.pop() is Some(writer) {
    // must be blocking queue, otherwise `self.writers` is always empty
    guard! writer.value is Some(value)
    writer.value = None
    writer.coro.wake()
    if data is None {
      return Some(value)
    } else {
      self.buffer.push_back(value)
    }
  }
  if data is None && self.closed is Some(err) {
    raise err
  }
  data
}

///|
/// Default error raised when trying to access an already-closed queue
pub suberror QueueAlreadyClosed derive(@debug.Debug, @json.ToJson)

///|
/// Close an async queue. After the queue is closed:
///
/// - blocking `put` and `get` operations will fail immediately.
/// - subsequent `put` and `try_put` operations also fail immediately
/// - if `clear = false` (`false` by default),
///   sbusequent `get` and `try_get` operations can still retrieve
///   buffered elements in the queue before `close`.
///   After the queue becomes empty,
///   subsequent `get` and `try_get` operations also fail immediately
/// - if `clear = true`, buffered elements in the queue will be cleared
///
/// By default, writing to or reading from a closed queue
/// will receive the `QueueAlreadyClosed` error.
/// But this error can be customized via the `error` parameter.
pub fn[X] Queue::close(
  self : Queue[X],
  error~ : Error = QueueAlreadyClosed,
  clear~ : Bool = false,
) -> Unit {
  self.closed = Some(error)
  while self.writers.pop() is Some(writer) {
    writer.coro.wake()
  }
  while self.readers.pop() is Some(reader) {
    reader.coro.wake()
  }
  if clear {
    self.buffer.clear()
  }
}
