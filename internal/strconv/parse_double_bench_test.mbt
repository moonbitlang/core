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
let parse_double_bench_repeats = 512

///|
let parse_double_plain_bench_inputs : FixedArray[String] = [
  "123456789012345.0", "876543210987654.0", "1234567890123.45", "7654321098765.25",
  "123456789012345e-2", "876543210987654e-3", "1234567890123e+2", "7654321098765e-1",
]

///|
let parse_double_underscore_bench_inputs : FixedArray[String] = [
  "123_456_789_012_345.0", "876_543_210_987_654.0", "1_234_567_890_123.45", "7_654_321_098_765.25",
  "123_456_789_012_345e-2", "876_543_210_987_654e-3", "1_234_567_890_123e+2", "7_654_321_098_765e-1",
]

///|
fn parse_double_bench_sum(inputs : FixedArray[String]) -> Double {
  let mut sum = 0.0
  for _ in 0..<parse_double_bench_repeats {
    for input in inputs {
      sum += try! @strconv.parse_double(input)
    }
  }
  sum
}

///|
test "bench parse_double fast digits n=4096" (it : @bench.T) {
  it.bench(fn() {
    it.keep(parse_double_bench_sum(parse_double_plain_bench_inputs))
  })
}

///|
test "bench parse_double underscores n=4096" (it : @bench.T) {
  it.bench(fn() {
    it.keep(parse_double_bench_sum(parse_double_underscore_bench_inputs))
  })
}
