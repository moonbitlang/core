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
/// Trait for types that can be used as the element of a numeric range.
///
/// `Default::default()` must return the additive identity (zero) so that
/// the sign of `step` can be compared against it. `one()` supplies the
/// default step value when the caller omits `step`.
pub(open) trait Step: Add + Compare + Default {
  one() -> Self
}

///|
pub impl Step for Int with one() {
  1
}

///|
pub impl Step for Int64 with one() {
  1L
}

///|
pub impl Step for UInt with one() {
  1U
}

///|
pub impl Step for UInt64 with one() {
  1UL
}

///|
pub impl Step for Float with one() {
  (1.0 : Float)
}

///|
pub impl Step for Double with one() {
  1.0
}

///|
/// Creates an iterator over a numeric range.
///
/// Works for any `T : Step` — in the standard library that covers
/// `Int`, `Int64`, `UInt`, `UInt64`, `Float`, and `Double`. User types
/// can opt in by implementing `Step`.
///
/// # Arguments
///
/// * `start` — inclusive starting value.
/// * `end` — ending value (exclusive by default, inclusive when
///   `inclusive=true`).
/// * `step` — increment applied each iteration (default `1`). A negative
///   step produces a descending range; a zero step produces an empty
///   iterator.
///
/// # Examples
///
/// ```mbt nocheck
/// test {
///   inspect(@range.range(0, 10, step=3), content="[0, 3, 6, 9]")
///   inspect(@range.range(10, 0, step=-2), content="[10, 8, 6, 4, 2]")
///   inspect(
///     @range.range(0.0, 1.0, step=0.25, inclusive=true),
///     content="[0, 0.25, 0.5, 0.75, 1]",
///   )
/// }
/// ```
pub fn[T : Step] range(
  start : T,
  end : T,
  step? : T = T::one(),
  inclusive? : Bool = false,
) -> Iter[T] {
  let zero = T::default()
  if step == zero {
    return Iter::empty()
  }
  let mut i = start
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    guard (step > zero && i < end) ||
      (step < zero && i > end) ||
      (inclusive && i == end) else {
      None
    }
    let value = i
    let next = i + step
    if (step > zero && next >= i) || (step < zero && next <= i) {
      i = next
    } else {
      done = true
    }
    Some(value)
  })
}
