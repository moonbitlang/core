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
/// Ascending values, or a fixed permutation of them (`i * 7919 % n`; 7919 is
/// prime and coprime to `n`).
fn balance_bench_values(scrambled~ : Bool) -> Array[Int32] {
  Array::makei(balance_bench_size, i => {
    if scrambled {
      i * 7919 % balance_bench_size
    } else {
      i
    }
  })
}

///|
fn balance_bench_build(values : Array[Int32]) -> @sorted_set.SortedSet[Int32] {
  let mut s = @sorted_set.new()
  for v in values {
    s = s.add(v)
  }
  s
}

///|
test "bench SortedSet::add ascending n=10000" (it : @bench.T) {
  let values = balance_bench_values(scrambled=false)
  it.bench(fn() { it.keep(balance_bench_build(values)) })
}

///|
test "bench SortedSet::add scrambled n=10000" (it : @bench.T) {
  let values = balance_bench_values(scrambled=true)
  it.bench(fn() { it.keep(balance_bench_build(values)) })
}

///|
test "bench SortedSet::remove ascending n=10000" (it : @bench.T) {
  let values = balance_bench_values(scrambled=false)
  let s = balance_bench_build(values)
  it.bench(fn() {
    let mut s = s
    for v in values {
      s = s.remove(v)
    }
    it.keep(s)
  })
}

///|
test "bench SortedSet::remove scrambled n=10000" (it : @bench.T) {
  let values = balance_bench_values(scrambled=true)
  let s = balance_bench_build(values)
  it.bench(fn() {
    let mut s = s
    for v in values {
      s = s.remove(v)
    }
    it.keep(s)
  })
}

///|
test "bench SortedSet::contains ascending-built n=10000" (it : @bench.T) {
  let s = balance_bench_build(balance_bench_values(scrambled=false))
  let probes = balance_bench_values(scrambled=true)
  it.bench(fn() {
    let mut hits = 0
    for v in probes {
      if s.contains(v) {
        hits = hits + 1
      }
    }
    it.keep(hits)
  })
}

///|
test "bench SortedSet::contains scrambled-built n=10000" (it : @bench.T) {
  let values = balance_bench_values(scrambled=true)
  let s = balance_bench_build(values)
  it.bench(fn() {
    let mut hits = 0
    for v in values {
      if s.contains(v) {
        hits = hits + 1
      }
    }
    it.keep(hits)
  })
}
