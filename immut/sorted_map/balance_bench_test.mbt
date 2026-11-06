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
let balance_bench_size = 10_000

///|
/// Ascending keys, or a fixed permutation of them (`i * 7919 % n`; 7919 is
/// prime and coprime to `n`).
fn balance_bench_keys(scrambled~ : Bool) -> Array[Int32] {
  Array::makei(balance_bench_size, i => {
    if scrambled {
      i * 7919 % balance_bench_size
    } else {
      i
    }
  })
}

///|
fn balance_bench_build(
  keys : Array[Int32],
) -> @sorted_map.SortedMap[Int32, Int32] {
  let mut m = @sorted_map.new()
  for k in keys {
    m = m.add(k, k)
  }
  m
}

///|
test "bench SortedMap::add ascending n=10000" (it : @bench.T) {
  let keys = balance_bench_keys(scrambled=false)
  it.bench(fn() { it.keep(balance_bench_build(keys)) })
}

///|
test "bench SortedMap::add scrambled n=10000" (it : @bench.T) {
  let keys = balance_bench_keys(scrambled=true)
  it.bench(fn() { it.keep(balance_bench_build(keys)) })
}

///|
test "bench SortedMap::remove ascending n=10000" (it : @bench.T) {
  let keys = balance_bench_keys(scrambled=false)
  let m = balance_bench_build(keys)
  it.bench(fn() {
    let mut m = m
    for k in keys {
      m = m.remove(k)
    }
    it.keep(m)
  })
}

///|
test "bench SortedMap::remove scrambled n=10000" (it : @bench.T) {
  let keys = balance_bench_keys(scrambled=true)
  let m = balance_bench_build(keys)
  it.bench(fn() {
    let mut m = m
    for k in keys {
      m = m.remove(k)
    }
    it.keep(m)
  })
}

///|
test "bench SortedMap::get ascending-built n=10000" (it : @bench.T) {
  let m = balance_bench_build(balance_bench_keys(scrambled=false))
  let probes = balance_bench_keys(scrambled=true)
  it.bench(fn() {
    let mut sum = 0
    for k in probes {
      if m.get(k) is Some(v) {
        sum = sum + v
      }
    }
    it.keep(sum)
  })
}

///|
test "bench SortedMap::get scrambled-built n=10000" (it : @bench.T) {
  let keys = balance_bench_keys(scrambled=true)
  let m = balance_bench_build(keys)
  it.bench(fn() {
    let mut sum = 0
    for k in keys {
      if m.get(k) is Some(v) {
        sum = sum + v
      }
    }
    it.keep(sum)
  })
}
