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
fn iter_n_microseconds(inner : () -> Unit, k : Int) -> Double {
  let ts = monotonic_clock_start()
  for i in 0..<k {
    inner()
  }
  let diff = monotonic_clock_end(ts)
  diff
}

///|
fn iter_count(name? : String, inner : () -> Unit, count : UInt) -> Summary {
  let count = count.land(0x7FFFFFFF).reinterpret_as_int()
  let threshold = 100000.0 // 100 ms
  let target_batch_size = loop 1 {
    trial => {
      let single_us = iter_n_microseconds(inner, trial) / trial.to_double()
      let target_batch_size = threshold /
        (if single_us < 1.0 { 1.0 } else { single_us })
      if trial.to_double() * single_us > threshold {
        break target_batch_size
      }
      continue trial * 2
    }
  }
  let batch_size = if target_batch_size < 1.0 {
    1
  } else {
    target_batch_size.ceil().to_int()
  }
  let samples = Array::makei(count, _ => iter_n_microseconds(inner, batch_size) /
    batch_size.to_double())
  samples.sort()
  winsorize(sorted_data=samples, 5.0)
  Summary::new(name?, sorted_data=samples, batch_size)
}

///|
/// Run a benchmark in batch mode
pub fn Bench::bench(
  self : Bench,
  name? : String,
  f : () -> Unit,
  count? : UInt = 10,
) -> Unit {
  let summary = iter_count(name?, f, count)
  if !self.buffer.is_empty() {
    self.buffer.write_char(',')
  }
  self.buffer.write_string(summary.to_json().stringify(escape_slash=true))
  self.summaries.push(summary)
}

///|
/// Run a benchmark and return its summary
pub fn single_bench(
  name? : String,
  f : () -> Unit,
  count? : UInt = 10,
) -> Summary {
  iter_count(name?, f, count)
}

// NOTE: use a type parameter `Any` to avoid exposing `trait OpaqueValue` to users

///|
/// Keep a value to prevent the optimizer from removing 
/// the calculation that produces it.
pub fn[Any] Bench::keep(self : Bench, value : Any) -> Unit {
  let trait_object : &OpaqueValue = value
  self._storage = trait_object
}

///|
/// Returns a JSON array string containing all collected benchmark summaries.
/// This helper is mainly used internally for tests and diagnostics.
#coverage.skip
pub fn Bench::dump_summaries(self : Bench) -> String {
  "[\{self.buffer.to_string()}]"
}

///|
#skip("slow benchmarking test")
test "bench - single_bench basic functionality" {
  let bench_result = single_bench(
    () => {
      // Simple operation
      let x = 1 + 1
      ignore(x)
    },
    count=2,
  )

  // Check that summary fields are properly populated
  inspect(bench_result.runs, content="2")
  inspect(bench_result.batch_size > 0, content="true")
  inspect(bench_result.sum > 0.0, content="true")
  inspect(bench_result.min <= bench_result.max, content="true")
}

///|
#skip("slow benchmarking test")
test "bench - Summary struct properties" {
  // Create a very simple bench and extract the summary
  let bench_result = single_bench(
    () => {
      // Simple operation
      let x = 1
      ignore(x)
    },
    count=5,
  )

  // Test that all the properties are accessible
  inspect(bench_result.mean >= 0, content="true")
  inspect(bench_result.median >= 0, content="true")
  inspect(bench_result.std_dev >= 0, content="true")
  inspect(bench_result.std_dev_pct >= 0, content="true")
  inspect(bench_result.median_abs_dev >= 0, content="true")
  inspect(bench_result.median_abs_dev_pct >= 0, content="true")

  // The quartiles should be in ascending order
  let (q1, q2, q3) = bench_result.quartiles
  inspect(q1 <= q2, content="true")
  inspect(q2 <= q3, content="true")

  // IQR should be q3 - q1
  inspect((q3 - q1 - bench_result.iqr).abs() < 0.001, content="true")
}

///|
#skip("slow benchmarking test")
test "bench - T struct and bench method" {
  let bench_obj = new()

  // Ensure the buffer is initially empty
  inspect(bench_obj.buffer.is_empty(), content="true")
  inspect(bench_obj.summaries.is_empty(), content="true")

  // Run a benchmark
  bench_obj.bench(
    () => {
      // Simple operation
      let x = 20 * 20
      ignore(x)
    },
    count=2,
  )

  // After running, the buffer should not be empty and there should be one summary
  inspect(bench_obj.buffer.is_empty(), content="false")
  inspect(bench_obj.summaries.length(), content="1")

  // Run another benchmark to ensure we can add multiple
  bench_obj.bench(
    () => {
      // Another operation
      let y = 30 * 30
      ignore(y)
    },
    count=2,
  )

  // Should now have two summaries
  inspect(bench_obj.summaries.length(), content="2")
}

///|
#skip("slow benchmarking test")
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
  inspect(elapsed >= 0.0, content="true")
}

///|
test "bench - keep stores value" {
  let b = new()
  assert_eq(b.summaries.length(), 0)
  b.keep(123)
  assert_eq(b.summaries.length(), 0)
  b.keep(456)
  assert_eq(b.summaries.length(), 0)
}
