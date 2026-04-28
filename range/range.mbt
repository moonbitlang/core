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
/// Direction implied by a step value: ascending, stationary, or
/// descending. Returned by `Step::direction`. `Still` covers both an
/// arithmetic zero and floating-point `NaN` (since neither makes
/// progress).
pub(all) enum Direction {
  Backward
  Still
  Forward
} derive(Eq)

///|
/// Trait for types that can be enumerated by an explicit step.
///
/// `Add` advances the iterator (`current + step`); `Compare` decides
/// when the iterator has reached `end`. `direction(step)` reports
/// whether the step moves forward, stays put, or moves backward —
/// so `range` knows which inequality to check against `end`.
///
/// There is intentionally no implicit "one"/default step value:
/// callers must pass `step` explicitly, which keeps the trait usable
/// for non-numeric or non-unit-having types.
pub(open) trait Step: Add + Compare {
  direction(Self) -> Direction
}

///|
pub impl Step for Int with direction(self) {
  if self > 0 {
    Forward
  } else if self < 0 {
    Backward
  } else {
    Still
  }
}

///|
pub impl Step for Int64 with direction(self) {
  if self > 0L {
    Forward
  } else if self < 0L {
    Backward
  } else {
    Still
  }
}

///|
pub impl Step for UInt with direction(self) {
  if self > 0U {
    Forward
  } else {
    Still
  }
}

///|
pub impl Step for UInt64 with direction(self) {
  if self > 0UL {
    Forward
  } else {
    Still
  }
}

///|
pub impl Step for Float with direction(self) {
  if self > (0.0 : Float) {
    Forward
  } else if self < (0.0 : Float) {
    Backward
  } else {
    Still
  }
}

///|
pub impl Step for Double with direction(self) {
  if self > 0.0 {
    Forward
  } else if self < 0.0 {
    Backward
  } else {
    Still
  }
}

///|
pub impl Step for @bigint.BigInt with direction(self) {
  if self > 0N {
    Forward
  } else if self < 0N {
    Backward
  } else {
    Still
  }
}

///|
/// Creates an iterator over `start, start+step, start+2*step, ...`
/// while the value is on the correct side of `end`.
///
/// `step` is required. A negative step descends; a positive step
/// ascends; a zero (or `NaN`) step yields the empty iterator (or just
/// `[start]` when `inclusive=true && start == end`). By default `end`
/// is exclusive; pass `inclusive=true` to include it.
///
/// The loop terminates as soon as `current + step` fails to make
/// progress past `current`. For integral types this only happens at
/// numeric overflow (e.g. `range(MAX_VALUE - 1, MAX_VALUE, 1,
/// inclusive=true)` yields `[MAX_VALUE - 1, MAX_VALUE]` and stops).
/// For `Float`/`Double` it also terminates when the step is too small
/// relative to the current accumulator to advance it (sub-precision
/// step), which prevents an otherwise silent infinite loop.
///
/// The inclusive end check uses `==` (so a `NaN` end never matches),
/// which keeps the iterator from looping when the comparison ordering
/// is unordered.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   inspect(@range.range(0, 10, 3), content="[0, 3, 6, 9]")
///   inspect(@range.range(0, 5, 1, inclusive=true), content="[0, 1, 2, 3, 4, 5]")
///   inspect(@range.range(10, 0, -3), content="[10, 7, 4, 1]")
/// }
/// ```
pub fn[T : Step] range(
  start : T,
  end : T,
  step : T,
  inclusive? : Bool = false,
) -> Iter[T] {
  let dir = T::direction(step)
  let mut i = start
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    let in_range = match dir {
      Forward => i.compare(end) < 0
      Backward => i.compare(end) > 0
      Still => false
    }
    guard in_range || (inclusive && i == end) else { None }
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
