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
/// Internal three-way classification of a step value's progress.
/// Kept private so it doesn't leak into the public API; `iter` uses
/// it to read more clearly than chaining `if dir > 0 ...` predicates.
priv enum Direction {
  Backward
  Still
  Forward
}

///|
/// Trait for additive ordered types with a canonical unit step,
/// suitable as the element type of `iter`.
///
/// Sealed for now: only this package may add impls. The set of
/// supported types may expand in future releases. The trait can be
/// reopened later without breaking existing users.
///
/// `direction(step)` reports `1` for ascending steps, `-1` for
/// descending, and `0` for "no progress" (zero or, for floats, NaN).
/// `step_one()` is the natural unit step for the type (`1` for ints,
/// `1.0` for floats, `1N` for `BigInt`, etc.).
///
/// `enumerate` is the body of `iter`. The default adds `step` to the
/// previous element, which is exact for the integral types. `Float` and
/// `Double` override it to compute element `k` directly as
/// `from + k * step`, so rounding error does not accumulate. Their two
/// loops differ only in how element `k` is computed.
trait Step: Add + Compare {
  fn direction(Self) -> Int
  fn step_one() -> Self
  fn enumerate(from : Self, to : Self, step : Self, inclusive : Bool) -> Iter[
    Self,
  ] = _
}

///|
impl Step with fn enumerate(from, to, step, inclusive) {
  let dir = direction_of(step)
  let mut i = from
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    guard in_range(dir, i, to) || (inclusive && i == to) else { None }
    let value = i
    let next = i + step
    if progresses(dir, i, next) {
      i = next
    } else {
      done = true
    }
    Some(value)
  })
}

///|
fn[T : Step] direction_of(step : T) -> Direction {
  let n = T::direction(step)
  if n > 0 {
    Forward
  } else if n < 0 {
    Backward
  } else {
    Still
  }
}

///|
/// Whether `i` is strictly on the near side of `to`.
fn[T : Compare] in_range(dir : Direction, i : T, to : T) -> Bool {
  match dir {
    Forward => Compare::compare(i, to) < 0
    Backward => Compare::compare(i, to) > 0
    Still => false
  }
}

///|
/// Whether `next` lies strictly beyond `i` in the step's direction.
fn[T : Compare] progresses(dir : Direction, i : T, next : T) -> Bool {
  match dir {
    Forward => Compare::compare(next, i) > 0
    Backward => Compare::compare(next, i) < 0
    Still => false
  }
}

///|
/// 2^53: from here on a `Double` counter no longer advances (`k + 1.0 == k`).
const COUNTER_LIMIT : Double = 9007199254740992.0

///|
pub impl Step for Int with fn direction(self) {
  if self > 0 {
    1
  } else if self < 0 {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Int with fn step_one() {
  1
}

///|
pub impl Step for Int64 with fn direction(self) {
  if self > 0L {
    1
  } else if self < 0L {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Int64 with fn step_one() {
  1L
}

///|
pub impl Step for UInt with fn direction(self) {
  if self > 0U {
    1
  } else {
    0
  }
}

///|
pub impl Step for UInt with fn step_one() {
  1U
}

///|
pub impl Step for UInt64 with fn direction(self) {
  if self > 0UL {
    1
  } else {
    0
  }
}

///|
pub impl Step for UInt64 with fn step_one() {
  1UL
}

///|
pub impl Step for Float with fn direction(self) {
  if self > (0.0 : Float) {
    1
  } else if self < (0.0 : Float) {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Float with fn step_one() {
  (1.0 : Float)
}

///|
/// Element `k` is `from + k * step` computed in `Double`, then rounded to
/// `Float`. `k` never reaches `COUNTER_LIMIT` here: the enumeration stops as
/// soon as an element fails to move strictly past the previous one, and
/// there are fewer than 2^32 `Float`s.
pub impl Step for Float with fn enumerate(from, to, step, inclusive) {
  let from_d = from.to_double()
  let step_d = step.to_double()
  let dir = direction_of(step)
  let mut i = from
  // index of the element after `i`, a `Double` so that it stays a plain
  // number on js (an `Int64` counter would be a BigInt there)
  let mut k = 1.0
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    guard in_range(dir, i, to) || (inclusive && i == to) else { None }
    let value = i
    let next = Float::from_double(from_d + k * step_d)
    k = k + 1.0
    if progresses(dir, i, next) {
      i = next
    } else {
      done = true
    }
    Some(value)
  })
}

///|
pub impl Step for Double with fn direction(self) {
  if self > 0.0 {
    1
  } else if self < 0.0 {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Double with fn step_one() {
  1.0
}

///|
/// Element `k` is `from + k * step`.
///
/// `k * step` can overflow to infinity while the sum is still finite, when
/// `from` has the opposite sign (`from=-1e308, step=1e308` reaches `1e308` at
/// `k = 2`). The element is then computed as
/// `(from * 0.5 + k * (step * 0.5)) * 2.0`. Overflow needs
/// `|step| > MAX / 2^53`, far above the subnormals, so halving `step` and
/// `k * step` is exact. Halving `from` can round only when `|from|` is
/// below 2^-1021, and such a `from` is far below half an ULP of the other
/// term, so it cannot change the sum. The final doubling is exact unless the true
/// element overflows. The element therefore rounds exactly like
/// `from + k * step` would with an unbounded exponent range.
///
/// From element 2^53 on, the counter `k` saturates, so this falls back to
/// repeated addition; the progress check still guarantees termination.
pub impl Step for Double with fn enumerate(from, to, step, inclusive) {
  let dir = direction_of(step)
  let mut i = from
  // index of the element after `i`, a `Double` so that it stays a plain
  // number on js (an `Int64` counter would be a BigInt there); exact up to
  // `COUNTER_LIMIT`
  let mut k = 1.0
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    guard in_range(dir, i, to) || (inclusive && i == to) else { None }
    let value = i
    let next = if k >= COUNTER_LIMIT {
      i + step
    } else {
      let offset = k * step
      if offset.is_inf() {
        (from * 0.5 + k * (step * 0.5)) * 2.0
      } else {
        from + offset
      }
    }
    k = k + 1.0
    if progresses(dir, i, next) {
      i = next
    } else {
      done = true
    }
    Some(value)
  })
}

///|
pub impl Step for Int16 with fn direction(self) {
  if self > (0 : Int16) {
    1
  } else if self < (0 : Int16) {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Int16 with fn step_one() {
  (1 : Int16)
}

///|
pub impl Step for UInt16 with fn direction(self) {
  if self > (0 : UInt16) {
    1
  } else {
    0
  }
}

///|
pub impl Step for UInt16 with fn step_one() {
  (1 : UInt16)
}

///|
pub impl Step for Byte with fn direction(self) {
  if self > (0 : Byte) {
    1
  } else {
    0
  }
}

///|
pub impl Step for Byte with fn step_one() {
  (1 : Byte)
}

///|
pub impl Step for @bigint.BigInt with fn direction(self) {
  if self > 0N {
    1
  } else if self < 0N {
    -1
  } else {
    0
  }
}

///|
pub impl Step for @bigint.BigInt with fn step_one() {
  1N
}

///|
/// Creates an iterator over `from, from + step, from + 2*step, ...`
/// while the value is on the correct side of `to`.
///
/// For `Float` and `Double`, element `k` is computed directly as
/// `from + k * step` (for `Float`, in `Double` precision and then rounded)
/// rather than by adding `step` to the previous element, so rounding error
/// does not accumulate: `iter(from=0.0, to=1.0, step=0.1)` has 10 elements.
/// `inclusive=true` yields `to` only when some element equals it exactly,
/// and `from + 3 * 0.1` is `0.30000000000000004`, so
/// `iter(from=0.0, to=0.3, step=0.1, inclusive=true)` stops at `0.2`. To hit
/// decimal end points exactly, iterate over integers and scale, e.g.
/// `iter(from=0, to=3, inclusive=true).map(k => k.to_double() / 10.0)`.
///
/// All three positional concepts are passed by label. `step` defaults
/// to `T::step_one()` (the type's natural unit step), so a simple
/// ascending range is just `iter(from=0, to=10)`. A negative step
/// descends; a positive step ascends; a zero (or `NaN`) step yields
/// the empty iterator — or just `[from]` when `inclusive=true` and
/// `from == to`. By default `to` is exclusive; pass `inclusive=true`
/// to include it.
///
/// The loop terminates as soon as the next element fails to make
/// progress past the current one. For integral types this only happens at
/// numeric overflow (e.g. `iter(from=MAX_VALUE - 1, to=MAX_VALUE,
/// inclusive=true)` yields `[MAX_VALUE - 1, MAX_VALUE]` and stops).
/// For `Float`/`Double` it also terminates as soon as the next element
/// rounds to the current one, which prevents an otherwise silent infinite
/// loop. That happens when `step` is not much larger than the spacing of
/// representable values near the elements: always when it is below that
/// spacing (e.g. `step=1.0` from `1.0e300`), and possibly when it is less
/// than about twice it (from 2^53, where the spacing is `2.0`, `step=1.5`
/// yields three elements). The elements are therefore always strictly
/// monotonic.
///
/// The inclusive end check uses `==` (so a `NaN` `to` never matches),
/// which keeps the iterator from looping when the comparison ordering
/// is unordered.
///
/// The function is named `iter` rather than `range` so that a future
/// first-class `Range[T]` struct can take the `Range`/`range` names
/// without breaking this entry point.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   debug_inspect(
///     @range.iter(from=0, to=10).to_array(),
///     content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]",
///   )
///   debug_inspect(
///     @range.iter(from=0, to=10, step=3).to_array(),
///     content="[0, 3, 6, 9]",
///   )
///   debug_inspect(
///     @range.iter(from=10, to=0, step=-3).to_array(),
///     content="[10, 7, 4, 1]",
///   )
///   debug_inspect(
///     @range.iter(from=0, to=5, inclusive=true).to_array(),
///     content="[0, 1, 2, 3, 4, 5]",
///   )
/// }
/// ```
pub fn[T : Step] iter(
  from~ : T,
  to~ : T,
  step? : T = T::step_one(),
  inclusive? : Bool = false,
) -> Iter[T] {
  T::enumerate(from, to, step, inclusive)
}
