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
/// Construct one with `make` (deferred) or `pure` (already evaluated). For
/// fallible work, see `try_make`, which bridges a raising thunk into a
/// `Lazy[Result[A, Error]]` so the failure becomes data on `force`.
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
///   obviously right. The escape hatch is `try_make`: lift the failure
///   into a `Result` value at construction, then handle it at the call
///   site you control. MoonBit's effect-on-signature design makes that
///   bridge a one-liner — something OCaml/F# `Lazy.t` cannot express
///   cleanly because their function arrows do not carry the effect.
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
///   let cell = @lazy.make(() => {
///     runs += 1
///     42
///   })
///   assert_eq(cell.force(), 42)
///   assert_eq(cell.force(), 42)
///   assert_eq(runs, 1)
/// }
/// ```
#as_free_fn
pub fn[A] Lazy::make(thunk : () -> A) -> Lazy[A] {
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
///   let cell = @lazy.make(() => 1 + 1)
///   assert_false(cell.is_forced())
///   ignore(cell.force())
///   assert_true(cell.is_forced())
/// }
/// ```
pub fn[A] Lazy::is_forced(self : Lazy[A]) -> Bool {
  self.state is Forced(_)
}

///|
/// Wraps a thunk that may raise. Forcing the resulting cell never raises;
/// instead the success or failure is observed as a `Result`. The thunk
/// runs at most once, regardless of outcome — both `Ok` and `Err` are
/// memoized.
///
/// This is the recommended way to defer a fallible computation: the
/// failure mode becomes part of the value, visible in the type, and
/// handled at the call site that consumes the cell.
///
/// ```mbt check
/// test {
///   let cell : @lazy.Lazy[Result[Int, Error]] = @lazy.try_make(() => {
///     if false {
///       fail("unreachable")
///     }
///     42
///   })
///   assert_true(cell.force() is Ok(42))
/// }
/// ```
#as_free_fn
pub fn[A] Lazy::try_make(thunk : () -> A raise?) -> Lazy[Result[A, Error]] {
  Lazy::make(() => try? thunk())
}
