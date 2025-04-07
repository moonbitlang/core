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
test "monotonic clock" {
  let ts = monotonic_clock_start()
  let mut sum: UInt64 = 0
  for i in 0..=100000 {
    sum += i.to_uint64()
  }
  let diff = monotonic_clock_end(ts)
  println("elapsed time: \{diff} us")
  assert_true!(diff > 0.0)
  assert_false!(diff.is_inf())
  assert_eq!(sum, 5000050000UL)
}
