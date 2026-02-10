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
#external
type Timestamp

///|
fn instant_elapsed_as_secs_f64(x : Timestamp) -> Double = "__moonbit_time_unstable" "instant_elapsed_as_secs_f64"

///|
/// Capture the current monotonic timestamp.
///
/// Use the returned timestamp with `monotonic_clock_end` to measure elapsed
/// time. A monotonic clock is not affected by system clock adjustments.
///
/// Example:
///
/// ```mbt check
/// test {
///   let start = @bench.monotonic_clock_start()
///   let mut acc = 0
///   for _ in 0..<100 {
///     acc += 1
///   }
///   ignore(acc)
///   let elapsed_us = @bench.monotonic_clock_end(start)
///   inspect(elapsed_us >= 0.0, content="true")
/// }
/// ```
pub fn monotonic_clock_start() -> Timestamp = "__moonbit_time_unstable" "instant_now"

///|
/// Compute elapsed time in microseconds since `ts`.
///
/// Parameters:
///
/// - `ts`: a timestamp created by `monotonic_clock_start`.
///
/// Returns elapsed time in microseconds.
///
/// Example:
///
/// ```mbt check
/// test {
///   let start = @bench.monotonic_clock_start()
///   let mut x = 0
///   for _ in 0..<100 {
///     x = x + 1
///   }
///   ignore(x)
///   let elapsed_us = @bench.monotonic_clock_end(start)
///   inspect(elapsed_us >= 0.0, content="true")
/// }
/// ```
pub fn monotonic_clock_end(ts : Timestamp) -> Double {
  let elapsed_secs : Double = instant_elapsed_as_secs_f64(ts)
  elapsed_secs * 1000000.0
}
