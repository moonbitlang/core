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
/// Internal cell state.
///
/// - `Unforced(thunk)`: the thunk has not yet run.
/// - `Forcing`: the thunk is currently running. Used to detect reentrant
///   `force` calls on the same cell, which would otherwise re-evaluate
///   the thunk and silently break the at-most-once guarantee.
/// - `Forced(v)`: the thunk has produced `v`; the thunk reference is
///   dropped so its captures can be reclaimed.
priv enum LazyState[A] {
  Unforced(() -> A)
  Forcing
  Forced(A)
}

///|
/// A memoized thunk: the first call to `force` runs the thunk and caches
/// the result; later calls return the cached value without re-running it.
///
/// Construct one with `Lazy(thunk)` (deferred) or `pure(value)` (already
/// evaluated). For fallible work, wrap the result in a `Result` value
/// inside the thunk — failure as data is the recommended shape; see the
/// rationale below.
///
/// ## Why force is non-raising / non-async
///
/// `force` has signature `(Self[A]) -> A` — no `raise?`, no async. That is
/// a deliberate choice given how MoonBit surfaces effects in signatures:
///
/// - **No raise.** A raising thunk would make `force` raise too, which
///   would then leak into every consumer that touches a lazy cell — and
///   any data structure built on top (lazy lists, lazy trees, memoized
///   graph nodes) would inherit the effect at every traversal point.
///   Memoizing the failure also forces a choice between "cache the
///   exception and re-raise on every retry" (OCaml-style) and "retry on
///   each force" (Rust-style); both are defensible but neither is
///   obviously right. The recommended pattern for a fallible deferred
///   computation is to make the failure data: `Lazy(() => try? f())`
///   produces a `Lazy[Result[A, Error]]`, and the consumer handles the
///   result at the call site it controls.
///
/// - **No async.** Async memoization additionally needs an in-flight
///   state to handle two coroutines racing to force the same cell, which
///   would pull a concurrency primitive into a type whose only job is to
///   delay a value. The right tool for an async deferred value is the
///   language's promise/future type (which already gives "compute once,
///   await many"), not a thunk wrapper.
///
/// ## Concurrency
///
/// `Lazy[A]` is not thread-safe. Sharing one across threads requires
/// external synchronization.
struct Lazy[A] {
  mut state : LazyState[A]
}

///|
/// Wraps a thunk. The thunk is not invoked until `force` is called; on
/// the first `force`, its result is memoized.
///
/// ```mbt check
/// test {
///   let mut runs = 0
///   let cell = @lazy.Lazy(() => {
///     runs += 1
///     42
///   })
///   assert_eq(cell.force(), 42)
///   assert_eq(cell.force(), 42)
///   assert_eq(runs, 1)
/// }
/// ```
#as_free_fn
pub fn[A] Lazy::Lazy(thunk : () -> A) -> Lazy[A] {
  { state: Unforced(thunk) }
}

///|
/// Wraps an already-evaluated value. `force` returns it directly without
/// running any code.
///
/// ```mbt check
/// test {
///   let cell = @lazy.pure(7)
///   assert_eq(cell.force(), 7)
///   assert_true(cell.is_forced())
/// }
/// ```
#as_free_fn
pub fn[A] Lazy::pure(value : A) -> Lazy[A] {
  { state: Forced(value) }
}

///|
/// Returns the cell's value, running the thunk on the first call and
/// caching the result. Later calls return the cached value in O(1).
///
/// Reentrant forces (a thunk that, while running, forces the same cell
/// again — e.g., through a captured `Ref`) are detected and aborted.
/// Without that check, the inner force would silently re-run the thunk
/// and break the at-most-once memoization guarantee.
pub fn[A] Lazy::force(self : Lazy[A]) -> A {
  match self.state {
    Forced(v) => v
    Forcing => abort("Lazy::force: reentrant force on the same cell")
    Unforced(thunk) => {
      self.state = Forcing
      let v = thunk()
      self.state = Forced(v)
      v
    }
  }
}

///|
/// Reports whether the cell has already been forced. Useful when forcing
/// the value would itself be expensive or have observable cost (e.g., to
/// decide whether a debug-only path is cheap to log).
///
/// ```mbt check
/// test {
///   let cell = @lazy.Lazy(() => 1 + 1)
///   assert_false(cell.is_forced())
///   ignore(cell.force())
///   assert_true(cell.is_forced())
/// }
/// ```
pub fn[A] Lazy::is_forced(self : Lazy[A]) -> Bool {
  self.state is Forced(_)
}
