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
fn iter_n_microseconds(inner : () -> Unit, k : Int) -> Double {
  let ts = monotonic_clock_start()
  for i in 0..<k {
    inner()
  }
  let diff = monotonic_clock_end(ts)
  diff
}

///|
fn iter_count(inner : () -> Unit, count : UInt) -> Summary {
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
  let samples = Array::new(capacity=count)
  samples.resize(count, 0.0)
  for i in 0..<count {
    samples[i] = iter_n_microseconds(inner, batch_size) / batch_size.to_double()
  }
  winsorize(samples, 5.0)
  Summary::new(samples, batch_size)
}

///|
pub fn bench(self : T, f : () -> Unit, count~ : UInt = 10) -> Unit {
  let summary = iter_count(f, count)
  if not(self.buffer.is_empty()) {
    self.buffer.write_char(',')
  }
  self.buffer.write_string(summary.to_json().stringify())
  self.summaries.push(summary)
}

///|
pub fn single_bench(f : () -> Unit, count~ : UInt = 10) -> Summary {
  let summary = iter_count(f, count)
  summary
}
