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
test "bench Arbitrary String size=10000 count=100" (it : @bench.T) {
  it.bench(fn() {
    let state = @splitmix.new()
    let mut total = 0
    for _ in 0..<100 {
      let value : String = @quickcheck.Arbitrary::arbitrary(10000, state)
      total += value.length()
    }
    it.keep(total)
  })
}
