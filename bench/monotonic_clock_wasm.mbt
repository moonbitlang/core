// Copyright 2025 International Digital Economy Academy
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
/// Opaque timestamp returned by `monotonic_clock_start`.
///
/// # Example
/// ```mbt check
/// test {
///   let ts = @bench.monotonic_clock_start()
///   let elapsed = @bench.monotonic_clock_end(ts)
///   inspect(elapsed >= 0.0, content="true")
/// }
/// ```
#external
type Timestamp

///|
/// Return elapsed seconds for a monotonic timestamp.
fn instant_elapsed_as_secs_f64(x : Timestamp) -> Double = "__moonbit_time_unstable" "instant_elapsed_as_secs_f64"

///|
/// Return a monotonic clock timestamp.
///
/// # Example
/// ```mbt check
/// test {
///   let ts = @bench.monotonic_clock_start()
///   let elapsed = @bench.monotonic_clock_end(ts)
///   inspect(elapsed >= 0.0, content="true")
/// }
/// ```
pub fn monotonic_clock_start() -> Timestamp = "__moonbit_time_unstable" "instant_now"

///|
/// Compute elapsed microseconds from a monotonic timestamp.
///
/// # Example
/// ```mbt check
/// test {
///   let ts = @bench.monotonic_clock_start()
///   let elapsed = @bench.monotonic_clock_end(ts)
///   inspect(elapsed >= 0.0, content="true")
/// }
/// ```
pub fn monotonic_clock_end(ts : Timestamp) -> Double {
  let elapsed_secs : Double = instant_elapsed_as_secs_f64(ts)
  elapsed_secs * 1000000.0
}
