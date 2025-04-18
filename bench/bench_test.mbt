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
test "bench - single_bench basic functionality" {
  let bench_result = single_bench(
    fn() {
      // Simple operation
      let x = 1 + 1
      ignore(x)
    },
    count=2,
  )

  // Check that summary fields are properly populated
  inspect!(bench_result.runs, content="2")
  inspect!(bench_result.batch_size > 0, content="true")
  inspect!(bench_result.sum > 0.0, content="true")
  inspect!(bench_result.min <= bench_result.max, content="true")
}

///|
test "bench - Summary struct properties" {
  // Create a very simple bench and extract the summary
  let bench_result = single_bench(
    fn() {
      // Simple operation
      let x = 1
      ignore(x)
    },
    count=5,
  )

  // Test that all the properties are accessible
  inspect!(bench_result.mean >= 0, content="true")
  inspect!(bench_result.median >= 0, content="true")
  inspect!(bench_result.std_dev >= 0, content="true")
  inspect!(bench_result.std_dev_pct >= 0, content="true")
  inspect!(bench_result.median_abs_dev >= 0, content="true")
  inspect!(bench_result.median_abs_dev_pct >= 0, content="true")

  // The quartiles should be in ascending order
  let (q1, q2, q3) = bench_result.quartiles
  inspect!(q1 <= q2, content="true")
  inspect!(q2 <= q3, content="true")

  // IQR should be q3 - q1
  inspect!((q3 - q1 - bench_result.iqr).abs() < 0.001, content="true")
}

///|
test "bench - T struct and bench method" {
  let bench_obj = new()

  // Ensure the buffer is initially empty
  inspect!(bench_obj.buffer.is_empty(), content="true")
  inspect!(bench_obj.summaries.is_empty(), content="true")

  // Run a benchmark
  bench_obj.bench(
    fn() {
      // Simple operation
      let x = 20 * 20
      ignore(x)
    },
    count=2,
  )

  // After running, the buffer should not be empty and there should be one summary
  inspect!(bench_obj.buffer.is_empty(), content="false")
  inspect!(bench_obj.summaries.length(), content="1")

  // Run another benchmark to ensure we can add multiple
  bench_obj.bench(
    fn() {
      // Another operation
      let y = 30 * 30
      ignore(y)
    },
    count=2,
  )

  // Should now have two summaries
  inspect!(bench_obj.summaries.length(), content="2")
}

///|
test "bench - monotonic clock functionality" {
  // Test that the clock functions work properly
  let start = monotonic_clock_start()

  // Do some simple work
  let mut result = 0
  for _ in 0..<1000 {
    result += 1
  }
  ignore(result)
  let elapsed = monotonic_clock_end(start)

  // Elapsed time should be non-negative
  inspect!(elapsed >= 0.0, content="true")
}
