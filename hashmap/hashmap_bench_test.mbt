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
let hashmap_bench_n = 50000

///|
test "bench HashMap::set n=50000" (it : @bench.T) {
  it.bench(fn() {
    let m = @hashmap.HashMap([])
    for i in 0..<hashmap_bench_n {
      m.set(i * 1103515245, i)
    }
    it.keep(m.length())
  })
}

///|
test "bench HashMap::get n=50000" (it : @bench.T) {
  let m = @hashmap.HashMap([])
  for i in 0..<hashmap_bench_n {
    m.set(i * 1103515245, i)
  }
  it.bench(fn() {
    let mut hits = 0
    for i in 0..<hashmap_bench_n {
      if m.get(i * 1103515245) is Some(_) {
        hits += 1
      }
    }
    it.keep(hits)
  })
}

///|
test "bench HashMap::get miss n=50000" (it : @bench.T) {
  let m = @hashmap.HashMap([])
  for i in 0..<hashmap_bench_n {
    m.set(i * 1103515245, i)
  }
  it.bench(fn() {
    let mut misses = 0
    for i in 0..<hashmap_bench_n {
      if m.get(i * 1103515245 + 1) is None {
        misses += 1
      }
    }
    it.keep(misses)
  })
}

///|
/// Named for what it actually measures: the harness has no per-iteration
/// setup hook, so the map has to be rebuilt inside the timed closure and the
/// removal cost cannot be isolated from the insertion cost.
test "bench HashMap::set+remove n=50000" (it : @bench.T) {
  it.bench(fn() {
    let m = @hashmap.HashMap([])
    for i in 0..<hashmap_bench_n {
      m.set(i * 1103515245, i)
    }
    for i in 0..<hashmap_bench_n {
      m.remove(i * 1103515245)
    }
    it.keep(m.length())
  })
}

///|
/// Removal isolated as far as the harness allows: `@bench.T` has no
/// per-iteration setup hook, so a prebuilt map is copied inside the timed
/// closure instead of being rebuilt with 50000 `set` calls. The copy is a
/// single pass over the table rather than 50000 hash-and-probe insertions,
/// so the removal work dominates. The companion "copy only" benchmark below
/// measures the residue that remains attributable to the copy.
test "bench HashMap::copy+remove n=50000" (it : @bench.T) {
  let template = @hashmap.HashMap([])
  for i in 0..<hashmap_bench_n {
    template.set(i * 1103515245, i)
  }
  it.bench(fn() {
    let m = template.copy()
    for i in 0..<hashmap_bench_n {
      m.remove(i * 1103515245)
    }
    it.keep(m.length())
  })
}

///|
test "bench HashMap::copy n=50000" (it : @bench.T) {
  let template = @hashmap.HashMap([])
  for i in 0..<hashmap_bench_n {
    template.set(i * 1103515245, i)
  }
  it.bench(fn() { it.keep(template.copy().length()) })
}
