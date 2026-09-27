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
/// Creates an iterator that iterates over a range of Int with default step 1.
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int from `start` to `end - 1`.
pub fn Int::until(
  self : Int,
  end : Int,
  step? : Int = 1,
  inclusive? : Bool = false,
) -> Iter[Int] {
  until_impl(self, end, step, inclusive)
}

///|
/// Creates an iterator that iterates over a range of Int64 with default step 1L.
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1L).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator that iterates over the range of Int64 from `start` to `end - 1`.
pub fn Int64::until(
  self : Int64,
  end : Int64,
  step? : Int64 = 1L,
  inclusive? : Bool = false,
) -> Iter[Int64] {
  until_impl(self, end, step, inclusive)
}

///|
/// Creates an iterator that iterates over a range of Double with default step 1.0 .
/// To grow the range downward, set the `step` parameter to a negative value.
///
/// # Arguments
///
/// * `start` - The starting value of the range (inclusive).
/// * `end` - The ending value of the range (exclusive by default).
/// * `step` - The step size of the range (default 1.0).
/// * `inclusive` - Whether the ending value is inclusive (default false).
///
/// # Returns
///
/// Returns an iterator yielding `self`, `self + step`, `self + 2 * step`, ...,
/// stopping before the first element that is not below `end` (above `end`
/// for a negative `step`). Each element after `self` is computed directly as
/// `self + k * step` rather than by repeated addition, so rounding errors do
/// not accumulate (from element 2^53 on, where `k + 1.0` no longer
/// advances, it falls back to repeated addition). With `inclusive`, `end` is
/// yielded only when some element rounds to exactly `end`:
/// `0.0.until(1.0, step=0.1, inclusive=true)` ends with `1.0`, but
/// `0.0.until(0.3, step=0.1, inclusive=true)` stops at `0.2` because
/// `0.0 + 3 * 0.1` is `0.30000000000000004`. To hit decimal end points
/// exactly, iterate over integers and divide, e.g.
/// `(0).until(3, inclusive=true).map(k => k.to_double() / 10.0)`. Returns an
/// empty iterator when `step` is `0.0`.
pub fn Double::until(
  self : Double,
  end : Double,
  step? : Double = 1.0,
  inclusive? : Bool = false,
) -> Iter[Double] {
  if step == 0.0 {
    return [||]
  }
  // `k` counts elements; a Double counter is exact up to 2^53 and, unlike
  // Int64, stays a plain number on js. From element 2^53 on, `k + 1.0` no
  // longer advances, so fall back to repeated addition there.
  let mut k = 0.0
  let mut value = self
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    let curr = value
    if (step > 0.0 && curr < end) || (step < 0.0 && curr > end) {
      k = k + 1.0
      value = if k < 9007199254740992.0 { self + k * step } else { curr + step }
      Some(curr)
    } else {
      done = true
      if inclusive && curr == end {
        Some(curr)
      } else {
        None
      }
    }
  })
}
