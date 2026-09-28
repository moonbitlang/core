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
/// Creates an iterator that iterates over a range of Float with default step 1.0 .
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `self` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1.0).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator yielding `self`, `self + step`, `(self + step) + step`,
/// ..., stopping before `end` (or at `end` when `inclusive` is set). Returns
/// an empty iterator when `step` is `0.0`.
///
/// Deprecated: each element is the previous one plus `step`, so rounding
/// error accumulates (`Float(0.0).until(1.0, step=0.01)` yields 101
/// elements, the last `0.9999993`). And once adding `step` no longer changes
/// the element, it is yielded forever: a `step` below the element's precision
/// (`Float(1.0e8).until(1.0e8 + 100.0)`), an infinite start, or an element
/// that reached infinity with `inclusive` set and an infinite `end`.
///
/// Use `@range.iter` (package `moonbitlang/core/range`) instead, typing the
/// start as `Float` (e.g. `from=Float(0)`; a bare `0.0` is a `Double`). It
/// computes element `k` as `start + k * step` and stops as soon as the next
/// element would not advance, so all of the cases above terminate. Its results
/// differ from this function's wherever rounding error has accumulated,
/// wherever this function would repeat an element, and for a zero `step`:
/// `@range.iter(from=x, to=x, step=0.0, inclusive=true)` yields `[x]`, while
/// this function yields nothing. For exact decimal end points, iterate over
/// integers and scale, e.g. `(0).until(10).map(k => Float::from_int(k) / 10.0)`.
#deprecated("Use `@range.iter(from=start, to=end, step=..., inclusive=...)` instead; `Float::until` accumulates rounding error")
#coverage.skip
pub fn Float::until(
  self : Float,
  end : Float,
  step? : Float = 1.0,
  inclusive? : Bool = false,
) -> Iter[Float] {
  if step == 0.0 {
    return [||]
  }
  let mut curr_value = Some(self)
  Iter::new(() => {
    guard curr_value is Some(i) else { None }
    guard (step > 0.0 && i < end) ||
      (step < 0.0 && i > end) ||
      (inclusive && i == end) else {
      None
    }
    let next = i + step
    if (step > 0.0 && next >= i) || (step < 0.0 && next <= i) {
      curr_value = Some(next)
    } else {
      // overflow
      curr_value = None
    }
    Some(i)
  })
}
