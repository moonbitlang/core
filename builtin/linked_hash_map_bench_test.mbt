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
let map_bench_n = 50000

///|
test "bench Map::set n=50000" (it : @bench.T) {
  it.bench(fn() {
    let m : Map[Int, Int] = Map([])
    for i in 0..<map_bench_n {
      m.set(i * 1103515245, i)
    }
    it.keep(m.length())
  })
}

///|
test "bench Map::get n=50000" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<map_bench_n {
    m.set(i * 1103515245, i)
  }
  it.bench(fn() {
    let mut hits = 0
    for i in 0..<map_bench_n {
      if m.get(i * 1103515245) is Some(_) {
        hits += 1
      }
    }
    it.keep(hits)
  })
}

///|
test "bench Map::get miss n=50000" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<map_bench_n {
    m.set(i * 1103515245, i)
  }
  it.bench(fn() {
    let mut misses = 0
    for i in 0..<map_bench_n {
      if m.get(i * 1103515245 + 1) is None {
        misses += 1
      }
    }
    it.keep(misses)
  })
}

///|
/// Named for what it measures: `@bench.T` has no per-iteration setup hook,
/// so the map has to be rebuilt inside the timed closure and the removal
/// cost cannot be isolated from the insertion cost.
test "bench Map::set+remove n=50000" (it : @bench.T) {
  it.bench(fn() {
    let m : Map[Int, Int] = Map([])
    for i in 0..<map_bench_n {
      m.set(i * 1103515245, i)
    }
    for i in 0..<map_bench_n {
      m.remove(i * 1103515245)
    }
    it.keep(m.length())
  })
}

///|
/// Insertion-ordered iteration, which is the reason `Map` keeps a list at
/// all, so it is worth guarding against regressions here.
test "bench Map::each n=50000" (it : @bench.T) {
  let m : Map[Int, Int] = Map([])
  for i in 0..<map_bench_n {
    m.set(i * 1103515245, i)
  }
  it.bench(fn() {
    let mut total = 0
    m.each((_, v) => total = total + v)
    it.keep(total)
  })
}
