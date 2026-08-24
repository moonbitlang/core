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
test "bench Generator::zip_with n=1000000" (it : @bench.T) {
  let generator = @quickcheck.int_range(0, 1000).zip_with(
    @quickcheck.int_range(0, 1000),
    (a, b) => a + b,
  )
  it.bench(fn() {
    let state = @splitmix.new()
    let mut sum = 0
    for _ in 0..<1000000 {
      sum += generator.run(100, state)
    }
    it.keep(sum)
  })
}
