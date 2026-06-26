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
fn sort_bench_data(n : Int) -> Array[Int] {
  Array::makei(n, i => (i * 1103515245 + 12345) & 0x7fffffff)
}

///|
test "bench Array::sort n=1000" (it : @bench.T) {
  let base = sort_bench_data(1000)
  it.bench(fn() {
    let a = base.copy()
    a.sort()
    it.keep(a)
  })
}

///|
test "bench Array::sort n=100000" (it : @bench.T) {
  let base = sort_bench_data(100000)
  it.bench(fn() {
    let a = base.copy()
    a.sort()
    it.keep(a)
  })
}

///|
test "bench Array::sort_by n=10000" (it : @bench.T) {
  let base = sort_bench_data(10000)
  it.bench(fn() {
    let a = base.copy()
    a.sort_by((x, y) => x - y)
    it.keep(a)
  })
}
