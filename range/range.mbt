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
trait Step: Add + Compare {
  direction(Self) -> Int
  step_one() -> Self
}

///|
pub impl Step for Int with direction(self) {
  if self > 0 {
    1
  } else if self < 0 {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Int with step_one() {
  1
}

///|
pub impl Step for Int64 with direction(self) {
  if self > 0L {
    1
  } else if self < 0L {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Int64 with step_one() {
  1L
}

///|
pub impl Step for UInt with direction(self) {
  if self > 0U {
    1
  } else {
    0
  }
}

///|
pub impl Step for UInt with step_one() {
  1U
}

///|
pub impl Step for UInt64 with direction(self) {
  if self > 0UL {
    1
  } else {
    0
  }
}

///|
pub impl Step for UInt64 with step_one() {
  1UL
}

///|
pub impl Step for Float with direction(self) {
  if self > (0.0 : Float) {
    1
  } else if self < (0.0 : Float) {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Float with step_one() {
  (1.0 : Float)
}

///|
pub impl Step for Double with direction(self) {
  if self > 0.0 {
    1
  } else if self < 0.0 {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Double with step_one() {
  1.0
}

///|
pub impl Step for Int16 with direction(self) {
  if self > (0 : Int16) {
    1
  } else if self < (0 : Int16) {
    -1
  } else {
    0
  }
}

///|
pub impl Step for Int16 with step_one() {
  (1 : Int16)
}

///|
pub impl Step for UInt16 with direction(self) {
  if self > (0 : UInt16) {
    1
  } else {
    0
  }
}

///|
pub impl Step for UInt16 with step_one() {
  (1 : UInt16)
}

///|
pub impl Step for Byte with direction(self) {
  if self > (0 : Byte) {
    1
  } else {
    0
  }
}

///|
pub impl Step for Byte with step_one() {
  (1 : Byte)
}

///|
pub impl Step for @bigint.BigInt with direction(self) {
  if self > 0N {
    1
  } else if self < 0N {
    -1
  } else {
    0
  }
}

///|
pub impl Step for @bigint.BigInt with step_one() {
  1N
}

///|
/// Creates an iterator over `from, from + step, from + 2*step, ...`
/// while the value is on the correct side of `to`.
///
/// All three positional concepts are passed by label. `step` defaults
/// to `T::step_one()` (the type's natural unit step), so a simple
/// ascending range is just `iter(from=0, to=10)`. A negative step
/// descends; a positive step ascends; a zero (or `NaN`) step yields
/// the empty iterator — or just `[from]` when `inclusive=true` and
/// `from == to`. By default `to` is exclusive; pass `inclusive=true`
/// to include it.
///
/// The loop terminates as soon as `current + step` fails to make
/// progress past `current`. For integral types this only happens at
/// numeric overflow (e.g. `iter(from=MAX_VALUE - 1, to=MAX_VALUE,
/// inclusive=true)` yields `[MAX_VALUE - 1, MAX_VALUE]` and stops).
/// For `Float`/`Double` it also terminates when the step is too small
/// relative to the current accumulator to advance it (sub-precision
/// step), which prevents an otherwise silent infinite loop.
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
///   inspect(@range.iter(from=0, to=10), content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
///   inspect(@range.iter(from=0, to=10, step=3), content="[0, 3, 6, 9]")
///   inspect(@range.iter(from=10, to=0, step=-3), content="[10, 7, 4, 1]")
///   inspect(
///     @range.iter(from=0, to=5, inclusive=true),
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
  let n = T::direction(step)
  let dir : Direction = if n > 0 {
    Forward
  } else if n < 0 {
    Backward
  } else {
    Still
  }
  let mut i = from
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    let in_range = match dir {
      Forward => i.compare(to) < 0
      Backward => i.compare(to) > 0
      Still => false
    }
    guard in_range || (inclusive && i == to) else { None }
    let value = i
    let next = i + step
    let progress = match dir {
      Forward => next.compare(i) > 0
      Backward => next.compare(i) < 0
      Still => false
    }
    if progress {
      i = next
    } else {
      done = true
    }
    Some(value)
  })
}
