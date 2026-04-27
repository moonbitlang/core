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
/// Shared body for `Int::until`, `Int64::until`, and `Double::until`.
/// `Default::default()` is taken to be the additive identity (zero) of
/// `T`, which is true for the built-in numeric types this is used with.
fn[T : Add + Compare + Default] until_impl(
  start : T,
  end : T,
  step : T,
  inclusive : Bool,
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
