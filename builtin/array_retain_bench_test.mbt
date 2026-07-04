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
let array_retain_bench_size = 100_000

///|
fn make_array_retain_bench_ints() -> Array[Int] {
  Array::makei(array_retain_bench_size, i => i)
}

///|
fn make_array_retain_bench_refs() -> Array[Ref[Int]] {
  Array::makei(array_retain_bench_size, i => Ref(i))
}

///|
test "bench Array::retain all keep Int n=100000" (it : @bench.T) {
  let data = make_array_retain_bench_ints()
  it.bench(fn() {
    let mut checksum = 0
    data.retain(x => {
      checksum = checksum ^ x
      true
    })
    it.keep(checksum)
  })
}

///|
test "bench Array::retain all keep Ref n=100000" (it : @bench.T) {
  let data = make_array_retain_bench_refs()
  it.bench(fn() {
    let mut checksum = 0
    data.retain(x => {
      checksum = checksum ^ x.val
      true
    })
    it.keep(checksum)
  })
}

///|
test "bench Array::retain drop tail n=100000" (it : @bench.T) {
  let base = make_array_retain_bench_ints()
  let last = array_retain_bench_size - 1
  it.bench(fn() {
    let data = base.copy()
    data.retain(x => x < last)
    it.keep(data.length())
  })
}

///|
test "bench Array::retain late sparse drop n=100000" (it : @bench.T) {
  let base = make_array_retain_bench_ints()
  let half = array_retain_bench_size / 2
  it.bench(fn() {
    let data = base.copy()
    data.retain(x => x < half || (x & 1) == 0)
    it.keep(data.length())
  })
}

///|
test "bench Array::retain drop first n=100000" (it : @bench.T) {
  let base = make_array_retain_bench_ints()
  it.bench(fn() {
    let data = base.copy()
    data.retain(x => x > 0)
    it.keep(data.length())
  })
}
