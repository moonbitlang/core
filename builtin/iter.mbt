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
/// Control signal used by deprecated iterator callbacks.
///
/// `IterContinue` keeps iteration running, `IterEnd` stops it.
///
#deprecated(skip_current_package=true)
pub(all) enum IterResult {
  IterEnd // false
  IterContinue // true
} derive(Eq)

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
/// Returns an iterator that iterates over the range of Double from `start` to `end - 1`.
pub fn Double::until(
  self : Double,
  end : Double,
  step? : Double = 1.0,
  inclusive? : Bool = false,
) -> Iter[Double] {
  until_impl(self, end, step, inclusive)
}
