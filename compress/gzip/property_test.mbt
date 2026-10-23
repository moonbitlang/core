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

// Property-based tests for the gzip container wrapper.

///|
/// Property: `compress` round-trips arbitrary bytes at every level, and
/// the optimal path round-trips too.
test "property: gzip round-trips at every level" {
  @quickcheck.check(
    (data : Bytes) => {
      for level in 0..<10 {
        if @gzip.decompress(@gzip.compress(data, level~)) != data {
          return false
        }
      }
      if @gzip.decompress(@gzip.compress_optimal(data, iterations=3)) != data {
        return false
      }
      true
    },
    count=40,
    max_size=2000,
    seed=0x6A7F001,
  )
}
